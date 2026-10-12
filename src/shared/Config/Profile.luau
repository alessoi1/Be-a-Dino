--!strict
-- Values for the saved player profile. Changing the format needs a migration and a test.

return {
	-- Name of the DataStore that holds the profiles.
	storeName = "BeDinoProfiles",
	-- Most entries a profile may hold in the reached-stages list (guards against junk data).
	maxReachedStages = 64,
	-- Most bought skins and most chosen skins (one per dino) a profile may hold.
	maxOwnedSkins = 64,
	maxEquippedSkins = 16,
	-- Most coins a player may hold.
	maxCoins = 1000000000000,
	-- Largest number of kills or seconds in the arena a profile may hold.
	maxStat = 1000000000000000,
}
