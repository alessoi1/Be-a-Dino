--!strict
-- The variants of the dinos: which ones a player owns and which one is shown on each dino. The
-- numbers live in the profile; guests and players whose profile is still loading use a session
-- copy (variants granted meanwhile move into the profile when it arrives). The owned and shown
-- variants are published as player attributes for the dinodex (read only on the client). The
-- client only sends the intention "show this variant on this dino"; the server checks everything.
-- Variants never change values, only the look. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local VariantBook = require(Shared:WaitForChild("VariantBook"))
local Variants = require(Shared:WaitForChild("Variants"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))
local VariantConfig = require(Shared:WaitForChild("Config"):WaitForChild("Variants"))

local AppearanceService = require(script.Parent:WaitForChild("AppearanceService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

-- Same shapes as VariantBook.State and VariantBook.Outcome (the module is loaded by path, so its
-- types are not visible here).
type State = {
	variants: { [string]: { [string]: boolean } },
	equippedVariants: { [string]: string },
}
type Outcome = "granted" | "duplicate" | "unknown"

type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

-- Longest id the server accepts from a client, and the minimum seconds between two requests.
local MAX_ID_LENGTH = 32
local MIN_INTERVAL = 0.3

local log = Log.new("VariantService")
local random = Random.new()

-- The known ids and their order (stage order and config order).
local dinoIds: { [string]: boolean } = {}
local dinoOrder: { string } = {}
for _, stage in Dinos do
	dinoIds[stage.id] = true
	table.insert(dinoOrder, stage.id)
end
local variantIds: { [string]: boolean } = {}
local variantOrder: { string } = {}
for _, variant in VariantConfig.variants do
	variantIds[variant.id] = true
	table.insert(variantOrder, variant.id)
end

-- Variants of players without a loaded profile (guests, loading).
local session: { [Player]: State } = {}
local lastRequest: { [Player]: number } = {}

local VariantService = {}

-- The state to read and change: the live profile when there is one, otherwise the session copy.
local function stateOf(player: Player): State?
	local data = DataService.getData(player)
	if data ~= nil then
		return data
	end
	return session[player]
end

local function publish(player: Player)
	local state = stateOf(player)
	if state == nil then
		return
	end
	player:SetAttribute("Variants", VariantBook.encodeOwned(state, dinoOrder, variantOrder))
	player:SetAttribute("EquippedVariants", VariantBook.encodeEquipped(state.equippedVariants))
end

-- Gives the player a variant of a dino ("granted", "duplicate" or "unknown").
function VariantService.grant(player: Player, dinoId: string, variantId: string): Outcome
	local state = stateOf(player)
	if state == nil then
		return "unknown"
	end
	local outcome = VariantBook.grant(state, dinoId, variantId, dinoIds, variantIds)
	if outcome == "granted" then
		publish(player)
		log.info("variant granted", { userId = player.UserId, dino = dinoId, variant = variantId })
	end
	return outcome
end

-- Which variants of a dino the player owns, as a set.
function VariantService.ownedOf(player: Player, dinoId: string): { [string]: boolean }
	local state = stateOf(player)
	local owned = state and state.variants[dinoId]
	return owned or {}
end

local function currentDinoId(player: Player): string?
	local growth = PlayerState.get(player)
	if growth == nil then
		return nil
	end
	return Dinos[growth.stageIndex].id
end

-- Shows the variant on the dino and rebuilds the look when it is the dino the player is now.
local function equip(player: Player, state: State, dinoId: string, variantId: string)
	VariantBook.equip(state, dinoId, variantId, VariantConfig.normalId)
	publish(player)
	if currentDinoId(player) == dinoId then
		AppearanceService.refresh(player, dinoId)
	end
end

local function onEquip(player: Player, dinoId: any, variantId: any, limiter: Limiter)
	local userId = player.UserId
	if type(dinoId) ~= "string" or type(variantId) ~= "string" then
		limiter.reject(userId, "EquipVariant", "bad_type")
		return
	end
	if #dinoId > MAX_ID_LENGTH or #variantId > MAX_ID_LENGTH then
		limiter.reject(userId, "EquipVariant", "too_long")
		return
	end
	local now = ServerClock.now()
	local last = lastRequest[player]
	if last ~= nil and now - last < MIN_INTERVAL then
		limiter.reject(userId, "EquipVariant", "rate_limited")
		return
	end
	lastRequest[player] = now

	local state = stateOf(player)
	if state == nil then
		limiter.reject(userId, "EquipVariant", "no_state")
		return
	end
	local ok, reason = VariantBook.canEquip(state, dinoId, variantId, VariantConfig.normalId, dinoIds, variantIds)
	if not ok then
		limiter.reject(userId, "EquipVariant", reason or "refused")
		return
	end
	equip(player, state, dinoId, variantId)
	log.info("variant chosen", { userId = userId, dino = dinoId, variant = variantId })
end

-- Studio test helper: gives the player a variant they do not own yet for the dino they are now
-- and shows it at once. Returns false when there is nothing left to give.
function VariantService.debugGrant(player: Player): boolean
	local dinoId = currentDinoId(player)
	local state = stateOf(player)
	if dinoId == nil or state == nil then
		return false
	end
	local missing: { string } = {}
	for _, variantId in variantOrder do
		if not VariantBook.owns(state, dinoId, variantId) then
			table.insert(missing, variantId)
		end
	end
	if #missing == 0 then
		return false
	end
	local pick = missing[random:NextInteger(1, #missing)]
	VariantService.grant(player, dinoId, pick)
	equip(player, state, dinoId, pick)
	return true
end

function VariantService.start(limiter: Limiter)
	AppearanceService.setVariantProvider(function(player: Player, stageId: string): string?
		local state = stateOf(player)
		if state == nil then
			return nil
		end
		return VariantBook.resolve(state, stageId)
	end)

	Remotes.event(Remotes.names.equipVariant).OnServerEvent
		:Connect(function(player: Player, dinoId: any, variantId: any)
			onEquip(player, dinoId, variantId, limiter)
		end)

	DataService.onLoaded(function(player: Player, data: any)
		-- Variants granted while the profile loaded are added to the saved ones.
		local own = session[player]
		if own ~= nil then
			for dinoId, owned in own.variants do
				for variantId in owned do
					VariantBook.grant(data, dinoId, variantId, dinoIds, variantIds)
				end
			end
			session[player] = { variants = {}, equippedVariants = {} }
		end
		publish(player)
	end)

	local function onPlayerAdded(player: Player)
		session[player] = { variants = {}, equippedVariants = {} }
		publish(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		session[player] = nil
		lastRequest[player] = nil
	end)

	local problems = Variants.validate(VariantConfig.variants, VariantConfig.normalId)
	if #problems > 0 then
		log.error("variant config invalid", { problems = table.concat(problems, "; ") })
	end

	log.info("started", { variants = #variantOrder, dinos = #dinoOrder })
end

return VariantService
