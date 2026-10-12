--!strict
-- The egg in the shop: the player pays coins and gets a variant of a random dino they have
-- already reached. The client only sends the intention "open an egg"; the server checks mode,
-- profile, pause and coins, rolls the result, takes the coins, gives the variant (a double gives
-- part of the price back) and saves before it tells the client. The chances are shown to the
-- player (Eggs.percentages). Coins are never bought with Robux. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Coins = require(Shared:WaitForChild("Coins"))
local Eggs = require(Shared:WaitForChild("Eggs"))
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Dinos = require(Shared:WaitForChild("Config"):WaitForChild("Dinos"))
local EggConfig = require(Shared:WaitForChild("Config"):WaitForChild("Eggs"))
local VariantConfig = require(Shared:WaitForChild("Config"):WaitForChild("Variants"))

local CoinService = require(script.Parent:WaitForChild("CoinService"))
local CollectionService = require(script.Parent:WaitForChild("CollectionService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))
local VariantService = require(script.Parent:WaitForChild("VariantService"))

type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

local REMOTE_NAME = "OpenEgg"

local log = Log.new("EggService")
local random = Random.new()

local variantOrder: { string } = {}
local variantIds: { [string]: boolean } = {}
for _, variant in VariantConfig.variants do
	table.insert(variantOrder, variant.id)
	variantIds[variant.id] = true
end

local lastEgg: { [Player]: number } = {}
local busy: { [Player]: boolean } = {}

local EggService = {}

-- The ids of the dinos the player has reached, in dino order.
local function reachedDinos(player: Player): { string }
	local collection = CollectionService.get(player)
	local list: { string } = {}
	if collection == nil then
		return list
	end
	for _, stage in Dinos do
		if collection.reachedStages[stage.id] == true then
			table.insert(list, stage.id)
		end
	end
	return list
end

local function open(player: Player, limiter: Limiter)
	local userId = player.UserId
	if busy[player] then
		limiter.reject(userId, REMOTE_NAME, "busy")
		return
	end
	local now = ServerClock.now()
	local last = lastEgg[player]
	if last ~= nil and now - last < EggConfig.cooldownSeconds then
		limiter.reject(userId, REMOTE_NAME, "rate_limited")
		return
	end
	lastEgg[player] = now

	if PlayerState.getMode(player) ~= "lobby" then
		limiter.reject(userId, REMOTE_NAME, "not_in_lobby")
		return
	end
	if DataService.getData(player) == nil then
		limiter.reject(userId, REMOTE_NAME, "no_profile")
		return
	end
	local price = EggConfig.price
	if Coins.spend(CoinService.get(player), price) == nil then
		limiter.reject(userId, REMOTE_NAME, "not_enough_coins")
		return
	end
	local reached = reachedDinos(player)
	local result = Eggs.roll(EggConfig, variantOrder, reached, function(dinoId: string, variantId: string): boolean
		return VariantService.ownedOf(player, dinoId)[variantId] == true
	end, random:NextNumber(), random:NextNumber())
	if result == nil then
		log.warn("egg gave nothing", { userId = userId, reached = #reached })
		return
	end

	busy[player] = true
	CoinService.spend(player, price)
	local refund = 0
	if result.duplicate then
		refund = Eggs.refund(price, EggConfig.duplicateRefundShare)
		if refund > 0 then
			CoinService.add(player, refund)
		end
	else
		local outcome = VariantService.grant(player, result.dinoId, result.variantId)
		if outcome ~= "granted" then
			-- Should not happen (the roll just checked it): give the coins back.
			log.error(
				"egg grant failed",
				{ userId = userId, dino = result.dinoId, variant = result.variantId, outcome = outcome }
			)
			CoinService.add(player, price)
			busy[player] = nil
			return
		end
	end
	log.info("egg opened", {
		userId = userId,
		dino = result.dinoId,
		variant = result.variantId,
		duplicate = result.duplicate,
		price = price,
		refund = refund,
	})

	-- Save before the result is shown, so a reward the player saw is not lost.
	if not DataService.saveNow(player) then
		log.warn("egg result not saved yet", { userId = userId })
	end
	busy[player] = nil
	if player.Parent ~= nil then
		Remotes.event(Remotes.names.eggResult)
			:FireClient(player, result.dinoId, result.variantId, result.duplicate, refund)
	end
end

function EggService.start(limiter: Limiter)
	local problems = Eggs.validate(EggConfig, variantIds)
	if #problems > 0 then
		log.error("egg config invalid", { problems = table.concat(problems, "; ") })
	end

	Remotes.event(Remotes.names.eggResult)
	Remotes.event(Remotes.names.openEgg).OnServerEvent:Connect(function(player: Player)
		local ok, err = pcall(open, player, limiter)
		if not ok then
			busy[player] = nil
			log.error("egg failed", { userId = player.UserId, error = tostring(err) })
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastEgg[player] = nil
		busy[player] = nil
	end)

	log.info("started", { price = EggConfig.price })
end

return EggService
