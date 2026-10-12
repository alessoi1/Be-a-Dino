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

-- Variant names by variant id (see Config/Variants), and the normal look.
local variantNames: { [string]: string } = {
	normal = "Normal",
	glowing = "Glowing",
	gold = "Gold",
	shadow = "Shadow",
	rainbow = "Rainbow",
}

return {
	game = {
		title = "Be a Dino",
	},
	sprint = {
		button = "Sprint",
	},
	autofarm = {
		-- The autofarm button: off, and on (two lines, the button is small).
		off = "Auto",
		on = "Auto\nON",
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
		-- Shown below the best size while the progress is saved: %d of %d variants found.
		variantsLine = "Variants: %d of %d (tap a dino)",
		variantEquipped = "Equipped",
		variantEquip = "Equip",
		variantLocked = "Find it in eggs",
	},
	variants = variantNames,
	-- Messages when eating or being eaten (%s = name, then the size gained as a short number).
	notice = {
		ate = "You ate %s (+%s)",
		-- %s = name, size gained, coins gained (short numbers)
		ateCoins = "You ate %s (+%s size, +%s coins)",
		ateBounty = "Bounty! You ate %s (+%s size, +%s coins)",
		eaten = "%s ate you",
		-- %s = dino name
		evolved = "You are now a %s!",
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
	boards = {
		-- Titles of the global leaderboards in the lobby (by list id, see Config/Leaderboards).
		kills = "Most kills",
		size = "Biggest size",
		time = "Longest playtime",
		loading = "Loading...",
		empty = "No entries yet",
		unavailable = "Unavailable",
		-- Shown when the name of a player cannot be found.
		unknownName = "Unknown",
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
