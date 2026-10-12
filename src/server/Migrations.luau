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
}
