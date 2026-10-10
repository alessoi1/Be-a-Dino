--!strict
-- The window after a player was eaten: who ate them and how long they can choose. The window is
-- shown by the client from the player attributes `DeathUntil` and `DeathKiller`. Today only
-- "back to lobby" works; reviving and putting a bounty on the killer are paid with Robux and
-- come in a later step (they are already part of the rules in DeathOffer). The server decides
-- everything; the client only sends the intention. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DeathOffer = require(Shared:WaitForChild("DeathOffer"))
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DeathConfig = require(Shared:WaitForChild("Config"):WaitForChild("Death"))

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

-- Which choices exist right now. Revive and bounty are added with the paid step.
local AVAILABLE: { [string]: boolean } = { lobby = true }
-- Minimum seconds between two choices of one player.
local MIN_INTERVAL = 0.3
-- Seconds between two checks for offers that ran out.
local SWEEP_INTERVAL = 1

local log = Log.new("DeathService")

local offers: { [Player]: DeathOffer.Offer } = {}
local lastChoice: { [Player]: number } = {}

local DeathService = {}

local function publish(player: Player)
	local offer = offers[player]
	local open = offer ~= nil and DeathOffer.isOpen(offer, ServerClock.now())
	player:SetAttribute("DeathUntil", if open and offer ~= nil then offer.expiresAt else 0)
	player:SetAttribute("DeathKiller", if open and offer ~= nil then offer.killerName else "")
end

local function close(player: Player)
	offers[player] = nil
	publish(player)
end

-- Opens the window for a player who was just eaten by `killer`.
function DeathService.open(victim: Player, killer: Player)
	offers[victim] = DeathOffer.open(ServerClock.now(), DeathConfig.offerSeconds, killer.UserId, killer.DisplayName)
	publish(victim)
	log.info("death offer opened", { userId = victim.UserId, killerId = killer.UserId })
end

local function onChoice(player: Player, choice: any, limiter: Limiter)
	local userId = player.UserId
	if type(choice) ~= "string" then
		limiter.reject(userId, "DeathChoice", "bad_type")
		return
	end
	local now = ServerClock.now()
	local last = lastChoice[player]
	if last ~= nil and now - last < MIN_INTERVAL then
		limiter.reject(userId, "DeathChoice", "rate_limited")
		return
	end
	lastChoice[player] = now

	local ok, reason = DeathOffer.check(offers[player], choice, now, AVAILABLE)
	if not ok then
		limiter.reject(userId, "DeathChoice", reason or "refused")
		return
	end

	if choice == "lobby" then
		-- The player is in the lobby already; the window just closes.
		close(player)
		log.info("death window closed by the player", { userId = userId })
	end
end

function DeathService.start(limiter: Limiter)
	Remotes.event(Remotes.names.deathChoice).OnServerEvent:Connect(function(player: Player, choice: any)
		onChoice(player, choice, limiter)
	end)

	-- Entering the arena again ends the window.
	PlayerState.onStage(function(player: Player, _stageId: string, reason: string)
		if reason == "round" then
			close(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		offers[player] = nil
		lastChoice[player] = nil
	end)

	local lastSweep = ServerClock.now()
	RunService.Heartbeat:Connect(function()
		local now = ServerClock.now()
		if now - lastSweep < SWEEP_INTERVAL then
			return
		end
		lastSweep = now
		for player, offer in offers do
			if not DeathOffer.isOpen(offer, now) then
				close(player)
			end
		end
	end)

	log.info("started")
end

return DeathService
