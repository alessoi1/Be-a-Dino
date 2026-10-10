--!strict
-- All texts the player sees (German). No texts in the other files.

-- Dino names by stage id (see Config/Dinos).
local dinos: { [string]: string } = {
	compy = "Compy",
	raptor = "Raptor",
	stego = "Stego",
	trex = "T-Rex",
}

-- Skin names by skin id (see Config/Skins).
local skinNames: { [string]: string } = {
	compy_default = "Standard",
	compy_mint = "Minze",
	compy_berry = "Beerenrot",
	raptor_default = "Standard",
	raptor_sunset = "Abendrot",
	raptor_midnight = "Nachtblau",
	stego_default = "Standard",
	stego_moss = "Moosgrün",
	stego_volcano = "Vulkan",
	trex_default = "Standard",
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
		-- %d = points, then the dino name.
		points = "Punkte",
		toNext = "Noch %d bis %s",
		maxStage = "Größter Dino!",
		-- %s = size with a decimal comma, for example 1,4.
		size = "×%s",
	},
	leaderboard = {
		title = "Bestenliste",
	},
	collection = {
		-- Button and window title.
		button = "Dinos",
		title = "Sammlung",
		-- %d of %d dinos reached
		count = "%d von %d Dinos",
		-- %d = points
		best = "Bestwert: %d Punkte",
		locked = "???",
		-- %d = points needed
		hint = "Ab %d Punkten",
		guest = "Wird nicht gespeichert",
		close = "X",
		back = "<",
		-- Shown below the best round while the progress is saved.
		skinsHint = "Tippe auf einen Dino für seine Skins",
		skinEquipped = "Ausgerüstet",
		skinEquip = "Ausrüsten",
		-- %s = dino name
		lockedReach = "Gesperrt: Erreiche den %s",
		-- %d = points
		lockedBest = "Gesperrt: Bestwert %d Punkte",
		lockedOther = "Gesperrt",
		-- Neutral wording for a skin that can be bought (the Roblox dialog shows the price).
		skinOffer = "Angebot ansehen",
		skinOfferNeedsSaving = "Nur mit Speichern verfügbar",
	},
	skins = skinNames,
	-- Messages when eating or being eaten (%s = name, %d = points).
	notice = {
		ate = "Du hast %s gefressen (+%d)",
		eaten = "%s hat dich gefressen",
		-- %s = dino name
		evolved = "Du bist jetzt ein %s!",
		-- %s = skin name
		skinUnlocked = "Neuer Skin: %s",
	},
	data = {
		-- The profile could not be loaded; the player keeps playing without saving.
		guest = "Dein Fortschritt wird gerade nicht gespeichert.",
		-- Shown when the profile was opened on another server.
		sessionEnded = "Du wurdest abgemeldet, weil dein Spielstand auf einem anderen Server geöffnet wurde.",
	},
	respawn = {
		-- %d = seconds
		countdown = "Neustart in %d",
	},
	dinos = dinos,
}
