--!strict
-- Bounties: a marked player has a "BOUNTY" sign above the head that everybody can see, and
-- whoever eats them gets more coins (Config/Bounty). The marks live here on the server and end
-- after their time, when the player is eaten, goes back to the lobby or leaves the arena.
-- Placing a bounty is paid (with Robux) in a later step; for now only a Studio debug key places one.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Bounty = require(Shared:WaitForChild("Bounty"))
local Log = require(Shared:WaitForChild("Log"))
local Strings = require(Shared:WaitForChild("Strings"))
local BountyConfig = require(Shared:WaitForChild("Config"):WaitForChild("Bounty"))

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

-- Looks of the sign (no game values).
local MARKER_NAME = "BountyMarker"
local MARKER_WIDTH = 190
local MARKER_HEIGHT = 44
local MARKER_MAX_DISTANCE = 400
-- The sign floats this many studs above the figure center, plus more for a bigger figure.
local MARKER_BASE_HEIGHT = 2
local MARKER_HEIGHT_PER_SCALE = 4
-- Seconds between two checks for ended bounties and sign positions.
local SWEEP_INTERVAL = 1

local log = Log.new("BountyService")

local state: Bounty.State = {}

local BountyService = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root ~= nil and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function removeMarker(player: Player)
	local root = rootOf(player)
	local marker = root and root:FindFirstChild(MARKER_NAME)
	if marker ~= nil then
		marker:Destroy()
	end
end

-- Creates the sign if it is missing and keeps it at the right height for the current size.
local function updateMarker(player: Player)
	local root = rootOf(player)
	if root == nil then
		return
	end
	local scale = PlayerState.scaleOf(player)
	local offset = Vector3.new(0, MARKER_BASE_HEIGHT + MARKER_HEIGHT_PER_SCALE * scale, 0)
	local existing = root:FindFirstChild(MARKER_NAME)
	if existing ~= nil and existing:IsA("BillboardGui") then
		existing.StudsOffset = offset
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = MARKER_NAME
	gui.Size = UDim2.fromOffset(MARKER_WIDTH, MARKER_HEIGHT)
	gui.AlwaysOnTop = true
	gui.MaxDistance = MARKER_MAX_DISTANCE
	gui.StudsOffset = offset
	gui.Adornee = root
	gui.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 215, 90)
	label.TextStrokeTransparency = 0.3
	label.Text = string.format(Strings.bounty.marker, BountyConfig.multiplier)
	label.Parent = gui
end

local function endBounty(player: Player)
	Bounty.clear(state, player.UserId)
	removeMarker(player)
	player:SetAttribute("BountyUntil", 0)
end

-- Puts a bounty on the player (it renews when there already is one). Returns true when the
-- player was not marked before.
function BountyService.place(target: Player): boolean
	local isNew = Bounty.place(state, target.UserId, ServerClock.now(), BountyConfig.durationSeconds)
	target:SetAttribute("BountyUntil", state[target.UserId] or 0)
	updateMarker(target)
	log.info("bounty placed", { userId = target.UserId, isNew = isNew })
	return isNew
end

-- Called when the player was eaten: returns the multiplier for the coins of the eater (the
-- configured one while a bounty was active, otherwise 1) and removes the bounty.
function BountyService.claimMultiplier(target: Player): number
	local multiplier = Bounty.multiplierFor(state, target.UserId, ServerClock.now(), BountyConfig.multiplier)
	Bounty.claim(state, target.UserId, ServerClock.now())
	removeMarker(target)
	target:SetAttribute("BountyUntil", 0)
	return multiplier
end

function BountyService.isMarked(target: Player): boolean
	return Bounty.isActive(state, target.UserId, ServerClock.now())
end

function BountyService.start()
	-- A bounty ends when the player starts a new round or goes back to the lobby.
	PlayerState.onStage(function(player: Player, _stageId: string, reason: string)
		if reason == "round" or reason == "reset" then
			endBounty(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		Bounty.clear(state, player.UserId)
	end)

	local lastSweep = ServerClock.now()
	RunService.Heartbeat:Connect(function()
		local now = ServerClock.now()
		if now - lastSweep < SWEEP_INTERVAL then
			return
		end
		lastSweep = now
		for _, userId in Bounty.sweep(state, now) do
			local player = Players:GetPlayerByUserId(userId)
			if player ~= nil then
				endBounty(player)
				log.info("bounty ended", { userId = userId })
			end
		end
		for userId in state do
			local player = Players:GetPlayerByUserId(userId)
			if player ~= nil then
				updateMarker(player)
			end
		end
	end)

	log.info("started")
end

return BountyService
