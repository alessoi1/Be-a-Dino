--!strict
-- All texts the player sees (English, for an international audience). No texts in the other files.

-- Dino names by stage id (see Config/Dinos).
local dinos: { [string]: string } = {
	compy = "Compy",
	raptor = "Raptor",
	stego = "Stego",
	trex = "T-Rex",
}

-- Skin names by skin id (see Config/Skins).
local skinNames: { [string]: string } = {
	compy_default = "Default",
	compy_mint = "Mint",
	compy_berry = "Berry",
	raptor_default = "Default",
	raptor_sunset = "Sunset",
	raptor_midnight = "Midnight",
	stego_default = "Default",
	stego_moss = "Moss",
	stego_volcano = "Volcano",
	trex_default = "Default",
	trex_gold = "Gold",
	trex_frost = "Frost",
}

return {
	game = {
		title = "Be a Dino",
	},
	sprint = {
		button = "Sprint",
	},
	status = {
		-- Shown as "Raptor · 120 points".
		points = "points",
		-- %d = points still missing, then the name of the next dino.
		toNext = "%d points to %s",
		maxStage = "Biggest dino!",
		-- %s = size, for example 1.4.
		size = "×%s",
	},
	leaderboard = {
		title = "Leaderboard",
	},
	collection = {
		-- Button and window title.
		button = "Dinos",
		title = "Collection",
		-- %d of %d dinos reached
		count = "%d of %d dinos",
		-- %d = points
		best = "Best round: %d points",
		locked = "???",
		-- %d = points needed
		hint = "Reach %d points",
		guest = "Not saved",
		close = "X",
		back = "<",
		-- Shown below the best round while the progress is saved.
		skinsHint = "Tap a dino to see its skins",
		skinEquipped = "Equipped",
		skinEquip = "Equip",
		-- %s = dino name
		lockedReach = "Locked: reach the %s",
		-- %d = points
		lockedBest = "Locked: best round %d points",
		lockedOther = "Locked",
		-- Neutral wording for a skin that can be bought (the Roblox dialog shows the price).
		skinOffer = "View offer",
		skinOfferNeedsSaving = "Not available without saving",
	},
	skins = skinNames,
	-- Messages when eating or being eaten (%s = name, %d = points).
	notice = {
		ate = "You ate %s (+%d)",
		eaten = "%s ate you",
		-- %s = dino name
		evolved = "You are now a %s!",
		-- %s = skin name
		skinUnlocked = "New skin: %s",
	},
	data = {
		-- The profile could not be loaded; the player keeps playing without saving.
		guest = "Your progress is not being saved right now.",
		-- Shown when the profile was opened on another server.
		sessionEnded = "You were signed out because your data was opened on another server.",
	},
	lobby = {
		-- Labels above the circles (by zone id, see Config/Lobby).
		zones = {
			play = "PLAY",
			shop = "SHOP",
			dex = "DINODEX",
			boost = "BOOSTERS",
		},
		hint = "Step into a glowing circle",
		-- %d = seconds until the arena is entered
		entering = "Entering the arena in %d",
		full = "Arena full, please wait",
		-- Button in the arena that goes back to the lobby.
		leave = "Lobby",
		-- %d = seconds left; tapping again cancels
		leaving = "Leaving in %d (tap to cancel)",
		comingSoon = "Coming soon",
		shopTitle = "Shop",
		boostTitle = "Boosters",
	},
	respawn = {
		-- %d = seconds
		countdown = "Respawn in %d",
	},
	dinos = dinos,
}
