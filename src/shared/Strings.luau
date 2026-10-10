--!strict
-- All texts the player sees (German). No texts in the other files.

-- Dino names by stage id (see Config/Dinos).
local dinos: { [string]: string } = {
	compy = "Compy",
	raptor = "Raptor",
	stego = "Stego",
	trex = "T-Rex",
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
	},
	-- Messages when eating or being eaten (%s = name, %d = points).
	notice = {
		ate = "Du hast %s gefressen (+%d)",
		eaten = "%s hat dich gefressen",
		-- %s = dino name
		evolved = "Du bist jetzt ein %s!",
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
