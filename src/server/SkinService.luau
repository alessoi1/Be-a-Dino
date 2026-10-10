--!strict
-- Skins: which skin each player has chosen and unlocked, and the colors the look uses.
-- Skins only change colors, never values. The client only sends the intention "use this
-- skin"; the server checks everything from its own state. The unlocked and chosen skins
-- are published as player attributes for the menu (read only on the client).
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Purchases = require(Shared:WaitForChild("Purchases"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local SkinView = require(Shared:WaitForChild("SkinView"))
local Skins = require(Shared:WaitForChild("Skins"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))
local SkinConfig = require(Shared:WaitForChild("Config"):WaitForChild("Skins"))

local AppearanceService = require(script.Parent:WaitForChild("AppearanceService"))
local CollectionService = require(script.Parent:WaitForChild("CollectionService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ReceiptService = require(script.Parent:WaitForChild("ReceiptService"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Color = { r: number, g: number, b: number }
type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

local log = Log.new("SkinService")

local skins = SkinConfig.skins

-- The chosen skin per dino for players without a loaded profile (guests, loading).
local sessionEquipped: { [Player]: { [string]: string } } = {}
local lastEquip: { [Player]: number } = {}

local SkinService = {}

local function equippedTable(player: Player): { [string]: string }
	local data = DataService.getData(player)
	if data ~= nil then
		return data.equippedSkins
	end
	local own = sessionEquipped[player]
	if own == nil then
		own = {}
		sessionEquipped[player] = own
	end
	return own
end

-- What the skin rules need to know, from the server state only.
local function stateFor(player: Player): Skins.State?
	local collection = CollectionService.get(player)
	if collection == nil then
		return nil
	end
	local data = DataService.getData(player)
	return {
		reachedStages = collection.reachedStages,
		bestPoints = collection.bestPoints,
		ownedSkins = if data ~= nil then data.ownedSkins else {},
		equippedSkins = equippedTable(player),
	}
end

local function publish(player: Player)
	local state = stateFor(player)
	if state == nil then
		return
	end
	player:SetAttribute("UnlockedSkins", SkinView.encodeUnlocked(Skins.unlockedIds(skins, state)))

	local shown: { [string]: string } = {}
	for _, stage in Dinos do
		local skin = Skins.resolve(skins, state, stage.id)
		if skin ~= nil then
			shown[stage.id] = skin.id
		end
	end
	player:SetAttribute("EquippedSkins", SkinView.encodeEquipped(shown))
end

-- The colors of the skin shown on a dino (nil keeps the original colors).
local function colorsFor(player: Player, stageId: string): { body: Color, accent: Color }?
	local state = stateFor(player)
	if state == nil then
		return nil
	end
	local skin = Skins.resolve(skins, state, stageId)
	if skin == nil then
		return nil
	end
	return skin.colors
end

local function onEquip(player: Player, skinId: any, limiter: Limiter)
	local userId = player.UserId
	if type(skinId) ~= "string" then
		limiter.reject(userId, "EquipSkin", "bad_type")
		return
	end
	if #skinId > SkinConfig.maxIdLength then
		limiter.reject(userId, "EquipSkin", "too_long")
		return
	end
	local now = ServerClock.now()
	local last = lastEquip[player]
	if last ~= nil and now - last < SkinConfig.equipMinInterval then
		limiter.reject(userId, "EquipSkin", "rate_limited")
		return
	end
	lastEquip[player] = now

	local state = stateFor(player)
	if state == nil then
		limiter.reject(userId, "EquipSkin", "no_state")
		return
	end
	local ok, reason = Skins.canEquip(skins, state, skinId)
	if not ok then
		limiter.reject(userId, "EquipSkin", reason or "refused")
		return
	end
	local skin = Skins.find(skins, skinId)
	if skin == nil then
		return
	end

	equippedTable(player)[skin.dinoId] = skin.id
	log.info("skin chosen", { userId = userId, dino = skin.dinoId, skin = skin.id })
	publish(player)

	-- Only the look of the dino the player is right now changes.
	local growth = PlayerState.get(player)
	if growth ~= nil and Dinos[growth.stageIndex].id == skin.dinoId then
		AppearanceService.refresh(player, skin.dinoId)
	end
end

-- Bought skins: the receipt handler marks the skin as owned (idempotent) and the player is told.
local function registerReceipts()
	ReceiptService.register({
		name = "skins",
		handle = function(_player: Player, data: any, info: any): string?
			local skin = Purchases.skinForProduct(skins, info.productId)
			if skin == nil then
				return nil
			end
			return Purchases.grant(data.ownedSkins, skin)
		end,
		onGranted = function(player: Player, _data: any, info: any)
			publish(player)
			local skin = Purchases.skinForProduct(skins, info.productId)
			if skin ~= nil then
				-- Display only: the client shows "new skin" with the name of this id.
				Remotes.event(Remotes.names.notice):FireClient(player, "skin", skin.id, 0)
			end
		end,
	})
end

function SkinService.start(limiter: Limiter)
	local problems = Skins.validate(skins, Dinos, SkinConfig.maxIdLength)
	if #problems > 0 then
		log.error("skin config invalid", { problems = table.concat(problems, "; ") })
	end

	AppearanceService.setSkinProvider(colorsFor)
	registerReceipts()

	Remotes.event(Remotes.names.equipSkin).OnServerEvent:Connect(function(player: Player, skinId: any)
		onEquip(player, skinId, limiter)
	end)

	CollectionService.onChanged(publish)
	DataService.onLoaded(function(player: Player)
		publish(player)
	end)

	local function onPlayerAdded(player: Player)
		publish(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		sessionEquipped[player] = nil
		lastEquip[player] = nil
	end)

	log.info("started")
end

return SkinService
