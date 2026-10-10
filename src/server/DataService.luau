--!strict
-- Loads and saves player profiles through ProfileStore (session locking and autosave
-- included). Nothing else in the game touches DataStores.
--
-- Other services read the live profile with DataService.getData(player) and change it in
-- place; ProfileStore saves it. When a profile cannot be loaded or is not readable, the
-- player plays as a guest (nothing is saved, nothing is overwritten) and is told so.
-- Only checkable in Roblox Studio (needs ProfileStore and Players).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local Strings = require(Shared:WaitForChild("Strings"))
local ProfileConfig = require(Shared:WaitForChild("Config"):WaitForChild("Profile"))
local ProfileStore = require(ServerStorage:WaitForChild("ServerPackages"):WaitForChild("ProfileStore"))

local DataLogic = require(script.Parent:WaitForChild("DataLogic"))
local Migrations = require(script.Parent:WaitForChild("Migrations"))
local ProfileData = require(script.Parent:WaitForChild("ProfileData"))

local log = Log.new("Data")

type Data = ProfileData.Data
type LoadedListener = (player: Player, data: Data) -> ()
type LeavingListener = (player: Player, data: Data) -> ()

local DataService = {}

local store: any = nil
local profiles: { [Player]: any } = {}
local guests: { [Player]: boolean } = {}
local loadedListeners: { LoadedListener } = {}
local leavingListeners: { LeavingListener } = {}
local started = false

local function becomeGuest(player: Player, reason: string)
	guests[player] = true
	-- The client shows a message when it sees this attribute.
	player:SetAttribute("DataGuest", true)
	log.warn("player plays as guest, nothing is saved", { userId = player.UserId, reason = reason })
end

local function notifyLoaded(player: Player, data: Data)
	for _, listener in loadedListeners do
		local ok, err = pcall(listener, player, data)
		if not ok then
			log.error("loaded listener failed", { userId = player.UserId, error = tostring(err) })
		end
	end
end

local function loadPlayer(player: Player)
	local userId = player.UserId
	local key = DataLogic.profileKey(userId)
	if key == nil then
		log.error("invalid user id, cannot load profile", { userId = userId })
		becomeGuest(player, "invalid_user_id")
		return
	end

	log.info("loading profile", { userId = userId })
	local startOk, profile = pcall(function()
		return store:StartSessionAsync(key, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
	end)
	if not startOk then
		log.error("starting profile session errored", { userId = userId, error = tostring(profile) })
		becomeGuest(player, "session_error")
		return
	end
	if profile == nil then
		if player.Parent == Players then
			log.error("profile session could not be started", { userId = userId })
			becomeGuest(player, "no_session")
		else
			log.info("player left before the profile loaded", { userId = userId })
		end
		return
	end

	profile:AddUserId(userId)

	local outcome = DataLogic.prepare(profile.Data, ProfileData, Migrations, os.time(), ProfileConfig)
	if outcome.status == "rejected" or outcome.data == nil then
		-- Profile.Data stays untouched, so ending the session saves it unchanged.
		log.error("stored profile rejected", { userId = userId, reason = outcome.reason })
		profile:EndSession()
		becomeGuest(player, "profile_rejected")
		return
	end

	if player.Parent ~= Players then
		log.info("player left before the profile was ready", { userId = userId })
		profile:EndSession()
		return
	end

	if outcome.status ~= "loaded" then
		DataLogic.replaceContents(profile.Data, outcome.data)
	end

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:SetAttribute("DataReady", false)
		log.warn("profile session ended", { userId = userId })
		if player.Parent == Players then
			player:Kick(Strings.data.sessionEnded)
		end
	end)

	profiles[player] = profile
	-- The client shows purchase offers only while the profile is ready (display only).
	player:SetAttribute("DataReady", true)
	log.info("profile loaded", { userId = userId, status = outcome.status, version = profile.Data.version })
	notifyLoaded(player, profile.Data)
end

local function releasePlayer(player: Player)
	guests[player] = nil
	local profile = profiles[player]
	if profile == nil then
		return
	end
	log.info("saving and releasing profile", { userId = player.UserId })
	for _, listener in leavingListeners do
		local ok, err = pcall(listener, player, profile.Data)
		if not ok then
			log.error("leaving listener failed", { userId = player.UserId, error = tostring(err) })
		end
	end
	profiles[player] = nil
	profile:EndSession()
end

-- Returns the live profile data of a loaded player, or nil while loading, for guests
-- and after the session ended. Change it in place; ProfileStore saves it.
function DataService.getData(player: Player): Data?
	local profile = profiles[player]
	if profile == nil then
		return nil
	end
	return profile.Data
end

function DataService.isGuest(player: Player): boolean
	return guests[player] == true
end

-- Saves the profile right now and waits for it. Returns true when the save went through,
-- false when the player has no live profile or the save failed. Use it where a change must
-- be on disk before something is confirmed (purchase receipts).
function DataService.saveNow(player: Player): boolean
	local profile = profiles[player]
	if profile == nil then
		log.warn("save requested without a live profile", { userId = player.UserId })
		return false
	end
	local ok, err = pcall(function()
		profile:Save()
	end)
	if not ok then
		log.error("immediate save failed", { userId = player.UserId, error = tostring(err) })
		return false
	end
	log.debug("immediate save done", { userId = player.UserId })
	return true
end

-- Registers a callback that runs just before a leaving player's profile is saved and
-- released (the last chance to change it).
function DataService.onLeaving(listener: LeavingListener)
	table.insert(leavingListeners, listener)
end

-- Registers a callback that runs once a player's profile is ready.
function DataService.onLoaded(listener: LoadedListener)
	table.insert(loadedListeners, listener)
end

function DataService.start()
	if started then
		log.warn("start called twice")
		return
	end
	started = true

	store = ProfileStore.New(ProfileConfig.storeName, {})
	ProfileStore.OnError:Connect(function(message: string, storeName: string, profileKey: string)
		log.warn("ProfileStore error", { message = message, store = storeName, key = profileKey })
	end)
	ProfileStore.OnOverwrite:Connect(function(storeName: string, profileKey: string)
		log.error("ProfileStore key was overwritten by foreign data", { store = storeName, key = profileKey })
	end)

	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(releasePlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	log.info("started", { store = ProfileConfig.storeName, profileVersion = ProfileData.VERSION })
end

return DataService
