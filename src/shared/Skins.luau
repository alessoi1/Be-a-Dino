--!strict
-- Pure skin rules: which skins a player may use and which one is shown. Skins only change
-- colors, never values. The server decides from its own state; nothing here trusts the
-- client. No Roblox services, no logging.

type Color = { r: number, g: number, b: number }

export type Skin = {
	id: string,
	dinoId: string,
	unlock: { kind: string, stageId: string?, points: number?, productId: number? },
	colors: { body: Color, accent: Color }?,
}

-- What the rules need to know about a player.
export type State = {
	reachedStages: { [string]: boolean },
	bestPoints: number,
	ownedSkins: { [string]: boolean },
	equippedSkins: { [string]: string },
}

export type Reason = "unknown_skin" | "not_reached" | "locked"

type Stage = { id: string }

local Skins = {}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function colorOk(color: any): boolean
	if type(color) ~= "table" then
		return false
	end
	for _, value in { color.r, color.g, color.b } do
		if not isFiniteNumber(value) or value < 0 or value > 255 then
			return false
		end
	end
	return true
end

function Skins.find(skins: { Skin }, skinId: string): Skin?
	for _, skin in skins do
		if skin.id == skinId then
			return skin
		end
	end
	return nil
end

-- The default skin of a dino (the one that is always free).
function Skins.defaultFor(skins: { Skin }, dinoId: string): Skin?
	for _, skin in skins do
		if skin.dinoId == dinoId and skin.unlock.kind == "free" then
			return skin
		end
	end
	return nil
end

-- Whether the unlock condition is met (the dino itself may not be reached yet).
function Skins.isUnlocked(skin: Skin, state: State): boolean
	local kind = skin.unlock.kind
	if kind == "free" then
		return true
	elseif kind == "reach" then
		local stageId = skin.unlock.stageId
		return stageId ~= nil and state.reachedStages[stageId] == true
	elseif kind == "best" then
		local points = skin.unlock.points
		return points ~= nil and state.bestPoints >= points
	elseif kind == "product" then
		return state.ownedSkins[skin.id] == true
	end
	return false
end

-- Ids of all skins whose condition is met, in config order.
function Skins.unlockedIds(skins: { Skin }, state: State): { string }
	local ids: { string } = {}
	for _, skin in skins do
		if Skins.isUnlocked(skin, state) then
			table.insert(ids, skin.id)
		end
	end
	return ids
end

-- Returns true, or false with the reason.
function Skins.canEquip(skins: { Skin }, state: State, skinId: string): (boolean, Reason?)
	local skin = Skins.find(skins, skinId)
	if skin == nil then
		return false, "unknown_skin"
	end
	if state.reachedStages[skin.dinoId] ~= true then
		return false, "not_reached"
	end
	if not Skins.isUnlocked(skin, state) then
		return false, "locked"
	end
	return true, nil
end

-- The skin to show for a dino: the chosen one if it is still valid and unlocked,
-- otherwise the default. Nil for an unknown dino.
function Skins.resolve(skins: { Skin }, state: State, dinoId: string): Skin?
	local chosenId = state.equippedSkins[dinoId]
	if chosenId ~= nil then
		local chosen = Skins.find(skins, chosenId)
		if chosen ~= nil and chosen.dinoId == dinoId and Skins.isUnlocked(chosen, state) then
			return chosen
		end
	end
	return Skins.defaultFor(skins, dinoId)
end

-- Returns a list of problems (empty when the config is usable).
function Skins.validate(skins: { Skin }, stages: { Stage }, maxIdLength: number): { string }
	local errors: { string } = {}
	local known: { [string]: boolean } = {}
	for _, stage in stages do
		known[stage.id] = true
	end

	local seen: { [string]: boolean } = {}
	local defaults: { [string]: number } = {}
	for _, skin in skins do
		local where = "skin " .. skin.id
		if seen[skin.id] then
			table.insert(errors, where .. ": duplicate id")
		end
		seen[skin.id] = true
		if string.match(skin.id, "^[a-z0-9_]+$") == nil or #skin.id > maxIdLength then
			table.insert(errors, where .. ": id must be lowercase letters, digits, underscores and short")
		end
		if not known[skin.dinoId] then
			table.insert(errors, where .. ": unknown dino " .. skin.dinoId)
		end

		local unlock = skin.unlock
		if unlock.kind == "free" then
			defaults[skin.dinoId] = (defaults[skin.dinoId] or 0) + 1
		elseif unlock.kind == "reach" then
			if unlock.stageId == nil or not known[unlock.stageId] then
				table.insert(errors, where .. ": reach needs a known stage")
			end
		elseif unlock.kind == "best" then
			if not isFiniteNumber(unlock.points) or (unlock.points :: number) <= 0 then
				table.insert(errors, where .. ": best needs points above 0")
			end
		elseif unlock.kind == "product" then
			local productId = unlock.productId
			if not isFiniteNumber(productId) or (productId :: number) < 0 or (productId :: number) % 1 ~= 0 then
				table.insert(errors, where .. ": product needs a product id of 0 or more")
			end
		else
			table.insert(errors, where .. ": unknown unlock kind " .. tostring(unlock.kind))
		end

		if skin.colors ~= nil and not (colorOk(skin.colors.body) and colorOk(skin.colors.accent)) then
			table.insert(errors, where .. ": color values must be between 0 and 255")
		end
	end

	for _, stage in stages do
		if defaults[stage.id] ~= 1 then
			table.insert(errors, stage.id .. ": needs exactly one default skin")
		end
	end
	return errors
end

return Skins
