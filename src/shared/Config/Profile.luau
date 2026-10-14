--!strict
-- Values for the saved player profile. Changing the format needs a migration and a test.

return {
	-- Name of the DataStore that holds the profiles.
	storeName = "BeDinoProfiles",
	-- Most entries a profile may hold in the reached-stages list (guards against junk data).
	maxReachedStages = 64,
	-- Most dinos a profile may hold variants for (and chosen variants), and most variants per dino.
	maxVariantDinos = 64,
	maxVariantsPerDino = 8,
	-- Most coins a player may hold.
	maxCoins = 1000000000000,
	-- Largest number of kills or seconds in the arena a profile may hold.
	maxStat = 1000000000000000,
	-- Paid offers: most potion kinds and saved-credit kinds, most seconds of one potion, most saved
	-- credits of one kind, most remembered purchase ids and the longest purchase id (guards against
	-- junk data; the real limits of the offers are in Config/Offers).
	maxPotionKinds = 16,
	maxPotionSeconds = 86400,
	maxCreditKinds = 8,
	maxCredits = 100,
	maxReceipts = 200,
	maxReceiptLength = 128,
	-- Most entries in the progress and in the claimed list of the daily quests.
	maxQuestEntries = 16,
}
