--!strict
-- Coins: earned by growing, never bought with Robux. Every newly reached stage gives coins
-- (also the ones skipped by a big jump). The amount lives in the profile; guests and players
-- whose profile is still loading collect in a session counter that is moved into the profile
-- when it arrives. The value is published as a player attribute for the display.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Coins = require(Shared:WaitForChild("Coins"))
local Log = require(Shared:WaitForChild("Log"))
local CoinConfig = require(Shared:WaitForChild("Config"):WaitForChild("Coins"))
local ProfileConfig = require(Shared:WaitForChild("Config"):WaitForChild("Profile"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local OfferService = require(script.Parent:WaitForChild("OfferService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local log = Log.new("CoinService")

-- Coins collected without a profile (guests, loading).
local sessionCoins: { [Player]: number } = {}

local CoinService = {}

local function publish(player: Player)
	local data = DataService.getData(player)
	local total = if data ~= nil then data.coins else sessionCoins[player] or 0
	player:SetAttribute("Coins", total)
end

-- The coins of the player: the profile when loaded, otherwise the session counter.
function CoinService.get(player: Player): number
	local data = DataService.getData(player)
	if data ~= nil then
		return data.coins
	end
	return sessionCoins[player] or 0
end

-- Adds coins (never above the limit). Used for stage rewards; later also for other rewards.
function CoinService.add(player: Player, amount: number)
	local data = DataService.getData(player)
	if data ~= nil then
		data.coins = Coins.add(data.coins, amount, ProfileConfig.maxCoins)
	else
		sessionCoins[player] = Coins.add(sessionCoins[player] or 0, amount, ProfileConfig.maxCoins)
	end
	publish(player)
end

-- Adds coins that were earned by playing (stage rewards, eating): a running coin potion
-- raises the amount. Returns the coins actually added.
function CoinService.addEarned(player: Player, amount: number): number
	local boosted = Coins.boosted(amount, OfferService.coinFactor(player))
	if boosted > 0 then
		CoinService.add(player, boosted)
	end
	return boosted
end

-- Takes `price` coins. Returns false (and takes nothing) when there are not enough.
function CoinService.spend(player: Player, price: number): boolean
	local data = DataService.getData(player)
	local current = if data ~= nil then data.coins else sessionCoins[player] or 0
	local left = Coins.spend(current, price)
	if left == nil then
		return false
	end
	if data ~= nil then
		data.coins = left
	else
		sessionCoins[player] = left
	end
	publish(player)
	return true
end

function CoinService.start()
	PlayerState.onGrow(function(player: Player, fromIndex: number, toIndex: number)
		local amount = Coins.forStages(fromIndex, toIndex, CoinConfig.perStageFactor)
		if amount > 0 then
			local added = CoinService.addEarned(player, amount)
			log.info("coins earned", { userId = player.UserId, amount = added, from = fromIndex, to = toIndex })
		end
	end)

	DataService.onLoaded(function(player: Player, data: any)
		-- What was earned while the profile loaded is added to the saved coins.
		local earned = sessionCoins[player] or 0
		if earned > 0 then
			data.coins = Coins.add(data.coins, earned, ProfileConfig.maxCoins)
			sessionCoins[player] = 0
			log.info("session coins moved into the profile", { userId = player.UserId, amount = earned })
		end
		publish(player)
	end)

	local function onPlayerAdded(player: Player)
		sessionCoins[player] = 0
		publish(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		sessionCoins[player] = nil
	end)

	log.info("started")
end

return CoinService
