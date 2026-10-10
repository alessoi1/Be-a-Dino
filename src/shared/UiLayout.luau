--!strict
-- Pure layout math for different screen sizes (phone first). No Roblox services.

export type Config = {
	referenceShortSide: number,
	scaleMin: number,
	scaleMax: number,
	buttonFraction: number,
	buttonMin: number,
	buttonMax: number,
	minTextSize: number,
}

local UiLayout = {}

local function shortSide(width: number, height: number): number
	local side = math.min(width, height)
	if side ~= side or side <= 0 then
		return 0
	end
	return side
end

-- Layout scale for panels and texts; the same in portrait and landscape.
function UiLayout.scaleFor(config: Config, width: number, height: number): number
	local side = shortSide(width, height)
	if side == 0 then
		return 1
	end
	return math.clamp(side / config.referenceShortSide, config.scaleMin, config.scaleMax)
end

-- Edge length of a round touch button in pixels.
function UiLayout.buttonSize(config: Config, width: number, height: number): number
	local side = shortSide(width, height)
	if side == 0 then
		return config.buttonMin
	end
	return math.clamp(math.floor(side * config.buttonFraction), config.buttonMin, config.buttonMax)
end

-- Smallest base text size (at scale 1) that stays readable at the smallest layout scale.
function UiLayout.minBaseTextSize(config: Config): number
	return math.ceil(config.minTextSize / config.scaleMin)
end

return UiLayout
