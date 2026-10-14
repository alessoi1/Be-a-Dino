--!strict
-- Migrations of the saved profile. Entry n turns a profile of version n into
-- version n + 1 (it must set `version`). Add a migration and a test with every format change.

return {
	-- 1 -> 2: skins (bought skins and the chosen skin per dino).
	function(data: any): any
		data.ownedSkins = {}
		data.equippedSkins = {}
		data.version = 2
		return data
	end,
	-- 2 -> 3: coins.
	function(data: any): any
		data.coins = 0
		data.version = 3
		return data
	end,
	-- 3 -> 4: statistics for the global leaderboards (kills, seconds in the arena).
	function(data: any): any
		data.kills = 0
		data.playSeconds = 0
		data.version = 4
		return data
	end,
	-- 4 -> 5: variants of the dinos replace the skins (the skins were never sold; a skin choice is lost).
	function(data: any): any
		data.variants = {}
		data.equippedVariants = {}
		data.ownedSkins = nil
		data.equippedSkins = nil
		data.version = 5
		return data
	end,
	-- 5 -> 6: paid offers (potion time, saved revives and bounties, remembered purchase ids).
	function(data: any): any
		data.potionSeconds = {}
		data.credits = {}
		data.receipts = {}
		data.version = 6
		return data
	end,
	-- 6 -> 7: the daily reward (day of the last claim and the streak).
	function(data: any): any
		data.dailyClaimDay = 0
		data.dailyStreak = 0
		data.version = 7
		return data
	end,
	-- 7 -> 8: the daily quests (day, progress per quest and the claimed ones).
	function(data: any): any
		data.quests = { day = 0, progress = {}, claimed = {} }
		data.version = 8
		return data
	end,
}
