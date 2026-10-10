--!strict
-- All texts the player sees (English, for an international audience). No texts in the other files.

-- Dino names by stage id (see Config/Dinos). Short on purpose: they have to fit on a card.
local dinos: { [string]: string } = {
	compy = "Compy",
	dromaeo = "Dromaeo",
	raptor = "Raptor",
	troodon = "Troodon",
	oviraptor = "Oviraptor",
	coelo = "Coelo",
	deino = "Deino",
	gallimimus = "Gallimimus",
	pachy = "Pachy",
	dilopho = "Dilopho",
	iguano = "Iguano",
	para = "Para",
	proto = "Proto",
	ankylo = "Ankylo",
	stego = "Stego",
	allo = "Allo",
	cerato = "Cerato",
	carno = "Carno",
	trike = "Trike",
	edmonto = "Edmonto",
	theri = "Theri",
	baryonyx = "Baryonyx",
	utah = "Utah",
	alberto = "Alberto",
	styraco = "Styraco",
	kentro = "Kentro",
	euoplo = "Euoplo",
	maia = "Maia",
	lambeo = "Lambeo",
	diplo = "Diplo",
	camara = "Camara",
	apato = "Apato",
	brachio = "Brachio",
	mamenchi = "Mamenchi",
	trex = "T-Rex",
	spino = "Spino",
	giganoto = "Giganoto",
	carcharo = "Carcharo",
	mapu = "Mapu",
	acro = "Acro",
	toro = "Toro",
	sauropelta = "Sauropelta",
	shantungo = "Shantungo",
	super = "Super",
	sauropo = "Sauropo",
	dreadnought = "Dreadnought",
	argentino = "Argentino",
	patagotitan = "Patagotitan",
	puerta = "Puerta",
	titanosaur = "Titanosaur",
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
		-- Shown as "Raptor · 1.2K size" (the size is a short number, see NumberFormat).
		points = "size",
		-- %s = size still missing (short number), then the name of the next dino.
		toNext = "%s size to %s",
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
		-- %s = size (short number)
		best = "Best size: %s",
		locked = "???",
		-- %s = size needed (short number)
		hint = "Reach %s size",
		guest = "Not saved",
		close = "X",
		back = "<",
		-- Shown below the best round while the progress is saved.
		skinsHint = "Tap a dino to see its skins",
		noSkins = "No skins for this dino yet",
		skinEquipped = "Equipped",
		skinEquip = "Equip",
		-- %s = dino name
		lockedReach = "Locked: reach the %s",
		-- %s = size (short number)
		lockedBest = "Locked: best size %s",
		lockedOther = "Locked",
		-- Neutral wording for a skin that can be bought (the Roblox dialog shows the price).
		skinOffer = "View offer",
		skinOfferNeedsSaving = "Not available without saving",
	},
	skins = skinNames,
	-- Messages when eating or being eaten (%s = name, then the size gained as a short number).
	notice = {
		ate = "You ate %s (+%s)",
		-- %s = name, size gained, coins gained (short numbers)
		ateCoins = "You ate %s (+%s size, +%s coins)",
		ateBounty = "Bounty! You ate %s (+%s size, +%s coins)",
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
	coins = {
		-- %s = amount (short number)
		label = "Coins %s",
	},
	bounty = {
		-- The sign above a marked player; %d = the multiplier for the coins.
		marker = "BOUNTY ×%d",
	},
	death = {
		-- %s = name of the one who ate you
		title = "You were eaten by %s",
		-- %d = seconds until the window closes
		closing = "Closing in %d",
		reviveSoon = "Revive at your size (soon)",
		-- %s = name of the one who ate you
		bountySoon = "Bounty on %s (soon)",
		lobby = "Back to lobby",
	},
	respawn = {
		-- %d = seconds
		countdown = "Respawn in %d",
	},
	dinos = dinos,
}
