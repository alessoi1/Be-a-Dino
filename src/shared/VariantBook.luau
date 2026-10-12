--!strict
-- Pure rules for the variants a player owns and the one shown on each dino, plus the short texts
-- the server publishes for the menu. The functions change the state table they are given (it is
-- the live profile of ProfileStore). No Roblox services, no logging.

export type State = {
	-- Owned variants: dino id -> variant id -> true.
	variants: { [string]: { [string]: boolean } },
	-- The variant shown on a dino: dino id -> variant id (no entry means the normal look).
	equippedVariants: { [string]: string },
}

export type Outcome = "granted" | "duplicate" | "unknown"

export type Reason = "unknown_dino" | "unknown_variant" | "not_owned"

export type Status = "equipped" | "available" | "locked"

export type Row = { id: string, status: Status }

local VariantBook = {}

-- Most entries the decoders keep (guards against junk text).
VariantBook.MAX_DINOS = 64
VariantBook.MAX_VARIANTS_PER_DINO = 8

local function isId(text: any): boolean
	return type(text) == "string" and string.match(text, "^[a-z0-9]+$") ~= nil
end

function VariantBook.owns(state: State, dinoId: string, variantId: string): boolean
	local owned = state.variants[dinoId]
	return owned ~= nil and owned[variantId] == true
end

-- Adds a variant of a dino. `dinoIds` and `variantIds` are the known ids. Granting the same
-- variant again changes nothing ("duplicate").
function VariantBook.grant(
	state: State,
	dinoId: string,
	variantId: string,
	dinoIds: { [string]: boolean },
	variantIds: { [string]: boolean }
): Outcome
	if dinoIds[dinoId] ~= true or variantIds[variantId] ~= true then
		return "unknown"
	end
	if VariantBook.owns(state, dinoId, variantId) then
		return "duplicate"
	end
	local owned = state.variants[dinoId]
	if owned == nil then
		owned = {}
		state.variants[dinoId] = owned
	end
	owned[variantId] = true
	return "granted"
end

-- Whether the player may show this variant on this dino. The normal look is always allowed.
function VariantBook.canEquip(
	state: State,
	dinoId: string,
	variantId: string,
	normalId: string,
	dinoIds: { [string]: boolean },
	variantIds: { [string]: boolean }
): (boolean, Reason?)
	if type(dinoId) ~= "string" or dinoIds[dinoId] ~= true then
		return false, "unknown_dino"
	end
	if variantId == normalId then
		return true, nil
	end
	if type(variantId) ~= "string" or variantIds[variantId] ~= true then
		return false, "unknown_variant"
	end
	if not VariantBook.owns(state, dinoId, variantId) then
		return false, "not_owned"
	end
	return true, nil
end

-- Shows the variant on the dino (the normal look removes the choice).
function VariantBook.equip(state: State, dinoId: string, variantId: string, normalId: string)
	if variantId == normalId then
		state.equippedVariants[dinoId] = nil
	else
		state.equippedVariants[dinoId] = variantId
	end
end

-- The variant shown on a dino: the chosen one if the player still owns it, otherwise nil (normal).
function VariantBook.resolve(state: State, dinoId: string): string?
	local chosen = state.equippedVariants[dinoId]
	if chosen ~= nil and VariantBook.owns(state, dinoId, chosen) then
		return chosen
	end
	return nil
end

-- How many variants the player owns in total.
function VariantBook.count(state: State): number
	local count = 0
	for _, owned in state.variants do
		for _, has in owned do
			if has then
				count += 1
			end
		end
	end
	return count
end

-- The rows for one dino in menu order: the normal look first, then the variants. `owned` is the
-- set of owned variant ids of that dino, `equipped` the shown one (nil = normal).
function VariantBook.rows(
	variantOrder: { string },
	normalId: string,
	owned: { [string]: boolean },
	equipped: string?
): { Row }
	local rows: { Row } = {}
	local shown = equipped or normalId
	table.insert(rows, { id = normalId, status = if shown == normalId then "equipped" else "available" })
	for _, id in variantOrder do
		local status: Status
		if shown == id then
			status = "equipped"
		elseif owned[id] == true then
			status = "available"
		else
			status = "locked"
		end
		table.insert(rows, { id = id, status = status })
	end
	return rows
end

-- "compy:glowing+gold,raptor:rainbow": the owned variants, dinos and variants in the given order.
function VariantBook.encodeOwned(state: State, dinoOrder: { string }, variantOrder: { string }): string
	local parts: { string } = {}
	for _, dinoId in dinoOrder do
		local owned = state.variants[dinoId]
		if owned ~= nil then
			local ids: { string } = {}
			for _, variantId in variantOrder do
				if owned[variantId] == true then
					table.insert(ids, variantId)
				end
			end
			if #ids > 0 then
				table.insert(parts, dinoId .. ":" .. table.concat(ids, "+"))
			end
		end
	end
	return table.concat(parts, ",")
end

function VariantBook.decodeOwned(text: string): { [string]: { [string]: boolean } }
	local result: { [string]: { [string]: boolean } } = {}
	if type(text) ~= "string" then
		return result
	end
	local dinos = 0
	for part in string.gmatch(text, "[^,]+") do
		local dinoId, list = string.match(part, "^([a-z0-9_]+):([a-z0-9+]+)$")
		if dinoId ~= nil and list ~= nil and result[dinoId] == nil then
			local owned: { [string]: boolean } = {}
			local variants = 0
			for variantId in string.gmatch(list, "[^+]+") do
				if isId(variantId) and variants < VariantBook.MAX_VARIANTS_PER_DINO then
					owned[variantId] = true
					variants += 1
				end
			end
			if variants > 0 then
				result[dinoId] = owned
				dinos += 1
				if dinos >= VariantBook.MAX_DINOS then
					break
				end
			end
		end
	end
	return result
end

-- "compy=gold,raptor=rainbow": the shown variants, sorted by dino id for a stable text.
function VariantBook.encodeEquipped(equipped: { [string]: string }): string
	local dinoIds: { string } = {}
	for dinoId, variantId in equipped do
		if string.match(dinoId, "^[a-z0-9_]+$") ~= nil and isId(variantId) then
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

function VariantBook.decodeEquipped(text: string): { [string]: string }
	local result: { [string]: string } = {}
	if type(text) ~= "string" then
		return result
	end
	local count = 0
	for part in string.gmatch(text, "[^,]+") do
		local dinoId, variantId = string.match(part, "^([a-z0-9_]+)=([a-z0-9]+)$")
		if dinoId ~= nil and variantId ~= nil then
			result[dinoId] = variantId
			count += 1
			if count >= VariantBook.MAX_DINOS then
				break
			end
		end
	end
	return result
end

return VariantBook
