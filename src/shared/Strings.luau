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
		-- The word under the icon of the sprint button.
		button = "Sprint",
	},
	autofarm = {
		-- The autofarm button: off, and on (two lines, the button is small).
		-- The word under the icon of the autofarm button, and the small badge while it runs.
		caption = "Auto Farm",
		off = "Auto",
		on = "ON",
	},
	hints = {
		-- At the start of a round, until the first piece is eaten.
		eatToGrow = "Eat the food to grow!",
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
		count = "\u{1F996} %d / %d",
		-- %s = size (short number)
		best = "\u{1F3C6} %s",
		locked = "\u{1F512}",
		-- %s = size needed (short number)
		hint = "\u{1F4AA} %s",
		guest = "Not saved",
		close = "X",
		back = "<",
		-- Shown below the best size while the progress is saved: %d of %d variants found.
		variantsLine = "\u{2728} %d / %d",
		variantEquipped = "Equipped",
		variantEquip = "Equip",
		variantLocked = "Find it in eggs",
	},
	variants = variantNames,
	-- Messages when eating or being eaten (%s = name, then the size gained as a short number).
	quests = {
		title = "Daily quests",
		-- One short line per quest id (see Config/Quests); %d = the goal.
		names = {
			food_60 = "Eat food",
			food_200 = "Eat lots of food",
			kill_1 = "Eat a player",
			kill_3 = "Eat 3 players",
			grow_2 = "Grow 2 dinos",
			grow_4 = "Grow 4 dinos",
			combo_10 = "Combo of 10",
			combo_25 = "Combo of 25",
			play_600 = "Play 10 minutes",
		},
	},
	frenzy = {
		-- Banner while the food frenzy runs.
		title = "Food frenzy",
	},
	daily = {
		title = "Daily gift",
		-- %d = day number in the row of gifts
		day = "Day %d",
		claim = "Claim",
	},
	notice = {
		-- %s = coins received from the daily gift (short number)
		daily = "Daily gift: +%s coins",
		ate = "You ate %s (+%s)",
		-- %s = name, size gained, coins gained (short numbers)
		ateCoins = "You ate %s (+%s size, +%s coins)",
		ateBounty = "Bounty! You ate %s (+%s size, +%s coins)",
		eaten = "%s ate you",
		-- %s = dino name
		evolved = "You are now a %s!",
		revived = "You are back!",
		reviveFailed = "Revive not possible now. It is saved for your next time.",
		-- %s = name of the player who has the bounty now
		bountyPlaced = "Bounty placed on %s",
		-- %s = name; the bounty is saved for later
		bountyFailed = "%s is not in the arena. Your bounty is saved.",
		-- %s = potion name
		potion = "%s potion added",
		potionEnded = "%s potion ended",
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
		-- The sign on the back wall of the lobby.
		title = "DINO RESEARCH STATION",
		hint = "Step into a glowing circle",
		-- %d = seconds until the arena is entered
		entering = "Entering the arena in %d",
		full = "Arena full, please wait",
		-- Button in the arena that goes back to the lobby.
		leave = "Lobby",
		-- While the wait runs (%d = seconds left); moving or tapping again cancels.
		leaving = "Stand still %d",
	},
	potions = {
		title = "Potions",
		-- Names of the potions by id (see Config/Offers).
		names = {
			growth = "Growth",
			coin = "Coin",
			speed = "Speed",
			shield = "Shield",
		},
		-- What a potion does, by id; %s = the factor or the seconds.
		effects = {
			growth = "%sx points from food",
			coin = "%sx coins",
			speed = "+%s%% speed",
			shield = "+%ss protection at the start",
		},
		-- %s = time (for example 10m)
		duration = "%s in the arena",
		-- %s = time left
		left = "%s left",
		offer = "View offer",
		full = "Full",
		unavailable = "Your progress must be saved to use potions.",
		-- The potions only run while you are in the arena.
		hint = "Potions run only in the arena.",
	},
	eggs = {
		title = "Dino egg",
		-- %s = price (short number)
		price = "%s",
		-- %s = coins the player has (short number)
		balance = "%s",
		open = "Open egg",
		opening = "Opening...",
		notEnough = "Need more coins",
		chancesTitle = "Chances",
		-- %s = variant name, %s = percent number
		chance = "%s: %s%%",
		-- %s = variant name, %s = dino name
		got = "%s %s!",
		duplicate = "You already had it",
		-- %s = coins given back (short number)
		refund = "+%s coins back",
		newOne = "New!",
		unavailable = "Your progress must be saved to open eggs.",
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
		-- Shown next to the coin icon.
		label = "%s",
	},
	bounty = {
		-- The sign above a marked player; %d = the multiplier for the coins.
		marker = "BOUNTY ×%d",
	},
	-- Names of the bots (dino names, so they do not pass for players).
	botNames = {
		"Rexy",
		"Spike",
		"Chomper",
		"Stompy",
		"Clawdia",
		"Nibbles",
		"Rumble",
		"Fern",
		"Bruno",
		"Zippy",
		"Mossy",
		"Tank",
	},
	death = {
		headline = "Eaten!",
		-- %s = name of the one who ate you
		title = "%s ate you",
		-- %d = seconds until the window closes
		closing = "Closing in %d",
		revive = "Revive",
		-- %s = name of the one who ate you
		bounty = "Bounty",
		-- Shown instead of the bounty choice when a bot ate you.
		bountyBot = "No bounty on bots",
		-- %d = saved ones that are used with a tap
		savedCount = "Use a saved one (%d left)",
		-- Second line of a paid choice that opens the purchase dialog.
		offer = "View offer",
		-- Shown on a paid choice that cannot be used (guest, or the profile is not loaded).
		needsSave = "Needs saved progress",
		lobby = "Lobby",
	},
	respawn = {
		-- %d = seconds
		countdown = "Respawn in %d",
	},
	dinos = dinos,
}
