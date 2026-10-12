--!strict
-- The window after a player was eaten: who ate them and how long they can choose. The window is
-- shown by the client from the player attributes `DeathUntil` and `DeathKiller`. Three choices:
-- back to lobby (free), revive at the size the player had and put a bounty on the killer (both
-- paid with Robux through the OfferService: a bought one is saved as a credit and used here). The
-- server decides everything; the client only sends the intention. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DeathOffer = require(Shared:WaitForChild("DeathOffer"))
local Log = require(Shared:WaitForChild("Log"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DeathConfig = require(Shared:WaitForChild("Config"):WaitForChild("Death"))

local BountyService = require(script.Parent:WaitForChild("BountyService"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local OfferService = require(script.Parent:WaitForChild("OfferService"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

type Limiter = { reject: (userId: number, remote: string, reason: string) -> (), forget: (userId: number) -> () }

-- Minimum seconds between two choices of one player.
local MIN_INTERVAL = 0.3
-- Seconds between two checks for offers that ran out.
local SWEEP_INTERVAL = 1

-- The killer id of an offer when a bot ate the player (real user ids are above 0).
local BOT_KILLER_ID = 0

local log = Log.new("DeathService")

local offers: { [Player]: DeathOffer.Offer } = {}
local lastChoice: { [Player]: number } = {}
-- Puts the player back into the arena with their points (set by the LobbyService); returns
-- whether it worked.
local reviveHandler: ((player: Player, points: number) -> boolean)? = nil

local DeathService = {}

local function publish(player: Player)
	local offer = offers[player]
	local open = offer ~= nil and DeathOffer.isOpen(offer, ServerClock.now())
	player:SetAttribute("DeathUntil", if open and offer ~= nil then offer.expiresAt else 0)
	player:SetAttribute("DeathKiller", if open and offer ~= nil then offer.killerName else "")
	-- Display only: a bounty cannot be put on a bot.
	player:SetAttribute("DeathKillerBot", open and offer ~= nil and offer.killerId == BOT_KILLER_ID)
end

local function close(player: Player)
	offers[player] = nil
	publish(player)
end

function DeathService.setReviveHandler(handler: (player: Player, points: number) -> boolean)
	reviveHandler = handler
end

-- The paid choices need a loaded profile (the credits live in it), so guests only have the lobby.
local function availableFor(player: Player): { [string]: boolean }
	local saved = DataService.getData(player) ~= nil
	local offer = offers[player]
	local byBot = offer ~= nil and offer.killerId == BOT_KILLER_ID
	return { lobby = true, revive = saved, bounty = saved and not byBot }
end

local function notice(player: Player, kind: string, detail: string)
	Remotes.event(Remotes.names.notice):FireClient(player, kind, detail, 0)
end

-- Opens the window for a player who was just eaten by `killer`; `points` is what they had.
function DeathService.open(victim: Player, killer: Player, points: number)
	offers[victim] =
		DeathOffer.open(ServerClock.now(), DeathConfig.offerSeconds, killer.UserId, killer.DisplayName, points)
	publish(victim)
	log.info("death offer opened", { userId = victim.UserId, killerId = killer.UserId })
end

-- Opens the window for a player who was just eaten by a bot (no bounty is possible then).
function DeathService.openByBot(victim: Player, botName: string, points: number)
	offers[victim] = DeathOffer.open(ServerClock.now(), DeathConfig.offerSeconds, BOT_KILLER_ID, botName, points)
	publish(victim)
	log.info("death offer opened", { userId = victim.UserId, killer = "bot" })
end

-- Uses a saved revive: the offer is used up first (so it cannot run twice), the player goes back
-- into the arena with the points they had, and if that fails the credit and the offer come back.
local function useRevive(player: Player, offer: DeathOffer.Offer)
	local userId = player.UserId
	offers[player] = DeathOffer.use(offer)
	publish(player)
	task.spawn(function()
		local handler = reviveHandler
		local worked = false
		if handler ~= nil then
			local ok, result = pcall(handler, player, offer.points)
			if ok then
				worked = result == true
			else
				log.error("revive failed", { userId = userId, error = tostring(result) })
			end
		end
		if worked then
			log.info("revived", { userId = userId, points = offer.points })
			notice(player, "revived", "")
			return
		end
		-- Not possible (arena full, no character): the credit stays and the window opens again.
		OfferService.giveCredit(player, "revive")
		if player.Parent ~= nil and ServerClock.now() < offer.expiresAt then
			offers[player] = offer
			publish(player)
		end
		log.warn("revive not possible", { userId = userId })
		notice(player, "reviveFailed", "")
	end)
end

-- Uses a saved bounty on the killer, who must still be in the arena.
local function useBounty(player: Player, offer: DeathOffer.Offer)
	local userId = player.UserId
	local killer = Players:GetPlayerByUserId(offer.killerId)
	if killer == nil or PlayerState.getMode(killer) ~= "playing" then
		OfferService.giveCredit(player, "bounty")
		log.info("bounty not possible", { userId = userId, killerId = offer.killerId })
		notice(player, "bountyFailed", offer.killerName)
		return
	end
	BountyService.place(killer)
	offers[player] = DeathOffer.use(offer)
	publish(player)
	log.info("bounty put on the killer", { userId = userId, killerId = offer.killerId })
	notice(player, "bountyPlaced", offer.killerName)
end

-- Takes a saved credit and runs the choice. Returns false when there is no credit or the choice
-- is not allowed right now.
local function useCredit(player: Player, kind: string): boolean
	local offer = offers[player]
	local ok = DeathOffer.check(offer, kind, ServerClock.now(), availableFor(player))
	if not ok or offer == nil then
		return false
	end
	if not OfferService.takeCredit(player, kind) then
		return false
	end
	if kind == "revive" then
		useRevive(player, offer)
	else
		useBounty(player, offer)
	end
	return true
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

	local ok, reason = DeathOffer.check(offers[player], choice, now, availableFor(player))
	if not ok then
		limiter.reject(userId, "DeathChoice", reason or "refused")
		return
	end

	if choice == "lobby" then
		-- The player is in the lobby already; the window just closes.
		close(player)
		log.info("death window closed by the player", { userId = userId })
	elseif not useCredit(player, choice) then
		-- The client only asks when it saw a saved credit; without one the purchase has to come first.
		limiter.reject(userId, "DeathChoice", "no_credit")
	end
end

function DeathService.start(limiter: Limiter)
	Remotes.event(Remotes.names.deathChoice).OnServerEvent:Connect(function(player: Player, choice: any)
		onChoice(player, choice, limiter)
	end)

	-- A revive or bounty that was just bought is used at once when the window is open.
	OfferService.onCredit(function(player: Player, kind: string)
		useCredit(player, kind)
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
