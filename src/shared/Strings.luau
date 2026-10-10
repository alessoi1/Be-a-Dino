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
		points = "Punkte",
	},
	dinos = dinos,
}
