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
}
