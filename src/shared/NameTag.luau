--!strict
-- Pure layout of the name tag above a dino: how big it is, how high it floats and whether it is
-- seen at this distance. No Roblox services, no logging.

export type Config = {
	baseWidth: number,
	baseHeight: number,
	sizeExponent: number,
	baseOffset: number,
	offsetPerScale: number,
	maxDistanceBase: number,
	maxDistancePerScale: number,
	fadeStart: number,
	-- Gap between the top of the dino and the bottom of the tag, per unit of scale (studs).
	tagGap: number,
}

export type Layout = {
	visible: boolean,
	width: number,
	height: number,
	offsetY: number,
	-- 0 = fully opaque, 1 = invisible.
	transparency: number,
}

local NameTag = {}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local HIDDEN: Layout = { visible = false, width = 0, height = 0, offsetY = 0, transparency = 1 }

-- How far (studs) the tag of a dino of this scale can be seen.
function NameTag.maxDistance(config: Config, scale: number): number
	return config.maxDistanceBase + config.maxDistancePerScale * scale
end

-- The layout for a dino of `scale` seen from `distance` studs. `topAboveRoot` is how far the highest
-- point of the dino is above its middle (studs): the tag then floats right above the head. Without
-- it (no look yet) the height follows from the scale. Invalid numbers and dinos that are too far
-- away give an invisible tag.
function NameTag.layout(config: Config, scale: number, distance: number, topAboveRoot: number?): Layout
	if not isFinite(scale) or not isFinite(distance) or scale <= 0 or distance < 0 then
		return HIDDEN
	end
	local limit = NameTag.maxDistance(config, scale)
	if distance >= limit then
		return HIDDEN
	end
	local fadeFrom = limit * config.fadeStart
	local transparency = 0
	if distance > fadeFrom then
		transparency = (distance - fadeFrom) / (limit - fadeFrom)
	end
	local grow = scale ^ config.sizeExponent
	local height = config.baseHeight * grow
	local offsetY = config.baseOffset + config.offsetPerScale * scale
	if topAboveRoot ~= nil and isFinite(topAboveRoot) then
		offsetY = topAboveRoot + height / 2 + config.tagGap * scale
	end
	return {
		visible = true,
		width = config.baseWidth * grow,
		height = height,
		offsetY = offsetY,
		transparency = math.clamp(transparency, 0, 1),
	}
end

return NameTag
