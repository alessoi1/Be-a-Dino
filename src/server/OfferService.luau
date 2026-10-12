--!strict
-- The paid offers: what a purchase gives and what the potions do. A purchase arrives through the
-- ReceiptService (one handler here); it is granted once per purchase id and saved before Roblox is
-- told. A revive or a bounty is saved as a credit in the profile and used at once when the death
-- window is open (see DeathService), otherwise it waits for the next death. Potions are stored
-- as seconds in the profile and count down only while the player is in the arena. The effects are
-- asked by the other services (food, coins, speed, spawn protection). The values are published as
-- player attributes for the display. Nothing here changes who can eat whom. Only checkable in
-- Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Offers = require(Shared:WaitForChild("Offers"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local OfferConfig = require(Shared:WaitForChild("Config"):WaitForChild("Offers"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ReceiptService = require(script.Parent:WaitForChild("ReceiptService"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type CreditHandler = (player: Player, kind: string) -> ()

-- Seconds between two countdown steps of the potions.
local TICK_INTERVAL = 1

local log = Log.new("OfferService")

local creditHandlers: { CreditHandler } = {}
local lastTick = 0

local OfferService = {}

-- The offer fields of the live profile, or nil without one (guests, loading).
local function stateOf(player: Player): Offers.State?
	local data = DataService.getData(player)
	if data == nil then
		return nil
	end
	return data
end

local function publish(player: Player)
	local state = stateOf(player)
	player:SetAttribute("ReviveCredits", if state ~= nil then Offers.credits(state, "revive") else 0)
	player:SetAttribute("BountyCredits", if state ~= nil then Offers.credits(state, "bounty") else 0)
	player:SetAttribute("Potions", if state ~= nil then Offers.encodePotions(state, OfferConfig.potionOrder) else "")
end

-- Registers a function that runs after a revive or bounty was granted, so it can be used at once
-- (the death window may be open).
function OfferService.onCredit(handler: CreditHandler)
	table.insert(creditHandlers, handler)
end

function OfferService.credits(player: Player, kind: string): number
	local state = stateOf(player)
	return if state ~= nil then Offers.credits(state, kind) else 0
end

-- Uses one saved credit. Returns false when there is none.
function OfferService.takeCredit(player: Player, kind: string): boolean
	local state = stateOf(player)
	if state == nil or not Offers.takeCredit(state, kind) then
		return false
	end
	publish(player)
	log.info("credit used", { userId = player.UserId, kind = kind })
	-- Save soon, so a used credit cannot come back after a crash.
	task.spawn(DataService.saveNow, player)
	return true
end

-- Gives a credit back (the use failed).
function OfferService.giveCredit(player: Player, kind: string)
	local state = stateOf(player)
	if state ~= nil then
		Offers.addCredit(state, kind, OfferConfig.maxCredits)
		publish(player)
		log.info("credit given back", { userId = player.UserId, kind = kind })
	end
end

local function factorOf(player: Player, effect: string): number
	local state = stateOf(player)
	if state == nil or PlayerState.getMode(player) ~= "playing" then
		return 1
	end
	return Offers.factor(state, OfferConfig, effect)
end

-- Factor for the points from food while a growth potion runs (1 otherwise).
function OfferService.growthFactor(player: Player): number
	return factorOf(player, "growth")
end

-- Factor for the coins earned while a coin potion runs (1 otherwise).
function OfferService.coinFactor(player: Player): number
	return factorOf(player, "coin")
end

-- Factor for the walk speed while a speed potion runs (1 otherwise).
function OfferService.speedFactor(player: Player): number
	return factorOf(player, "speed")
end

-- Extra seconds of spawn protection while a shield potion runs (0 otherwise). Asked at the start
-- of a round, when the potion is still stored (the mode is not "playing" yet).
local function shieldBonus(player: Player): number
	local state = stateOf(player)
	if state == nil then
		return 0
	end
	return Offers.shieldBonus(state, OfferConfig)
end

local function notice(player: Player, kind: string, detail: string)
	Remotes.event(Remotes.names.notice):FireClient(player, kind, detail, 0)
end

local function handleReceipt(_player: Player, data: any, info: ReceiptService.Info): ReceiptService.Outcome?
	if Offers.productFor(OfferConfig, info.productId) == nil then
		return nil
	end
	local outcome = Offers.grant(data, OfferConfig, info.productId, info.purchaseId)
	if outcome == "granted" then
		log.info("offer granted", { userId = info.userId, productId = info.productId })
	elseif outcome == "duplicate" then
		log.warn("repeated receipt ignored", { userId = info.userId, productId = info.productId })
	end
	return outcome
end

local function onGranted(player: Player, _data: any, info: ReceiptService.Info)
	publish(player)
	local product = Offers.productFor(OfferConfig, info.productId)
	if product == nil then
		return
	end
	if product.kind == "potion" and product.potionId ~= nil then
		notice(player, "potion", product.potionId)
		return
	end
	for _, handler in creditHandlers do
		local ok, err = pcall(handler, player, product.kind)
		if not ok then
			log.error("credit handler failed", { userId = player.UserId, kind = product.kind, error = tostring(err) })
		end
	end
end

-- Counts the potions of players in the arena down.
local function tick()
	local now = ServerClock.now()
	local dt = now - lastTick
	lastTick = now
	for _, player in Players:GetPlayers() do
		local state = stateOf(player)
		if state ~= nil and next(state.potionSeconds) ~= nil and PlayerState.getMode(player) == "playing" then
			local ended = Offers.tickPotions(state, dt)
			for _, potionId in ended do
				log.info("potion ended", { userId = player.UserId, potion = potionId })
				notice(player, "potionEnded", potionId)
			end
			publish(player)
		end
	end
end

function OfferService.start()
	local problems = Offers.validate(OfferConfig)
	for _, problem in problems do
		log.error("offer config invalid", { problem = problem })
	end

	ReceiptService.register({
		name = "offers",
		handle = handleReceipt,
		onGranted = onGranted,
	})
	PlayerState.setProtectionBonus(shieldBonus)

	DataService.onLoaded(function(player: Player, _data: any)
		publish(player)
	end)
	local function onPlayerAdded(player: Player)
		publish(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	lastTick = ServerClock.now()
	local sinceTick = 0
	RunService.Heartbeat:Connect(function(dt: number)
		sinceTick += dt
		if sinceTick < TICK_INTERVAL then
			return
		end
		sinceTick = 0
		local ok, err = pcall(tick)
		if not ok then
			log.error("potion tick failed", { error = tostring(err) })
		end
	end)

	log.info("started", { potions = #OfferConfig.potionOrder })
end

return OfferService
