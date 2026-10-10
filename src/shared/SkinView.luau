--!strict
-- Pure helpers for the skin list in the menu: the chosen and the unlocked skins as short
-- texts (the server publishes them as player attributes) and the rows the menu shows.
-- Display only. No Roblox services, no logging.

export type Skin = {
	id: string,
	dinoId: string,
	unlock: { kind: string, stageId: string?, points: number?, productId: number? },
	colors: { body: { r: number, g: number, b: number }, accent: { r: number, g: number, b: number } }?,
}

export type Status = "equipped" | "available" | "locked"

export type Row = { skin: Skin, status: Status }

local SkinView = {}

-- Most entries the decoders keep (guards against junk text).
SkinView.MAX_ENTRIES = 64

local function isId(text: string): boolean
	return string.match(text, "^[a-z0-9_]+$") ~= nil
end

-- "compy=compy_mint,raptor=raptor_default", sorted by dino id for a stable text.
function SkinView.encodeEquipped(equipped: { [string]: string }): string
	local dinoIds: { string } = {}
	for dinoId, skinId in equipped do
		if isId(dinoId) and isId(skinId) then
			table.insert(dinoIds, dinoId)
		end
	end
	table.sort(dinoIds)
	local parts: { string } = {}
	for _, dinoId in dinoIds do
		table.insert(parts, dinoId .. "=" .. equipped[dinoId])
	end
	return table.concat(parts, ",")
end

function SkinView.decodeEquipped(text: string): { [string]: string }
	local equipped: { [string]: string } = {}
	if type(text) ~= "string" then
		return equipped
	end
	local count = 0
	for part in string.gmatch(text, "[^,]+") do
		local dinoId, skinId = string.match(part, "^([a-z0-9_]+)=([a-z0-9_]+)$")
		if dinoId ~= nil and skinId ~= nil then
			equipped[dinoId] = skinId
			count += 1
			if count >= SkinView.MAX_ENTRIES then
				break
			end
		end
	end
	return equipped
end

-- Skin ids separated by commas.
function SkinView.encodeUnlocked(ids: { string }): string
	return table.concat(ids, ",")
end

-- The rows for one dino in config order. Skins that are for sale but have no product id yet
-- are hidden. `equippedId` is the skin shown now (nil means the default one).
function SkinView.rows(skins: { Skin }, dinoId: string, unlocked: { [string]: boolean }, equippedId: string?): { Row }
	local rows: { Row } = {}
	local shown: { Skin } = {}
	for _, skin in skins do
		if skin.dinoId == dinoId then
			local hidden = skin.unlock.kind == "product" and (skin.unlock.productId or 0) == 0
			if not hidden then
				table.insert(shown, skin)
			end
		end
	end

	local equipped = equippedId
	if equipped == nil then
		for _, skin in shown do
			if skin.unlock.kind == "free" then
				equipped = skin.id
				break
			end
		end
	end

	for _, skin in shown do
		local status: Status
		if skin.id == equipped then
			status = "equipped"
		elseif unlocked[skin.id] == true then
			status = "available"
		else
			status = "locked"
		end
		table.insert(rows, { skin = skin, status = status })
	end
	return rows
end

return SkinView
