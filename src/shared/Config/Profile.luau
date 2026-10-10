--!strict
-- Values for the saved player profile. Changing the format needs a migration and a test.

return {
	-- Name of the DataStore that holds the profiles.
	storeName = "BeDinoProfiles",
	-- Most entries a profile may hold in the reached-stages list (guards against junk data).
	maxReachedStages = 64,
}
