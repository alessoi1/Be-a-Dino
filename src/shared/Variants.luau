--!strict
-- Pure look math for the variants: what color, material and transparency a part of a dino gets in
-- a variant, the rainbow colors and a check of the config. No Roblox services, no logging.

export type Color = { r: number, g: number, b: number }

export type Variant = {
	id: string,
	material: string,
	lighten: number?,
	darken: number?,
	body: Color?,
	accent: Color?,
	animated: boolean?,
}

-- What a part looks like in a variant.
export type Look = { color: Color, material: string, transparency: number }

local Variants = {}

-- Materials a variant may use (the server maps them to Enum.Material).
Variants.MATERIALS = { Neon = true, Metal = true, SmoothPlastic = true, Plastic = true }

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function colorOk(color: any): boolean
	if type(color) ~= "table" then
		return false
	end
	for _, value in { color.r, color.g, color.b } do
		if not isFinite(value) or value < 0 or value > 255 then
			return false
		end
	end
	return true
end

local function channel(value: number): number
	return math.clamp(math.floor(value + 0.5), 0, 255)
end

-- Moves a color toward white by `amount` (0 to 1).
function Variants.lighten(color: Color, amount: number): Color
	local t = math.clamp(amount, 0, 1)
	return {
		r = channel(color.r + (255 - color.r) * t),
		g = channel(color.g + (255 - color.g) * t),
		b = channel(color.b + (255 - color.b) * t),
	}
end

-- Moves a color toward black by `amount` (0 to 1).
function Variants.darken(color: Color, amount: number): Color
	local t = math.clamp(amount, 0, 1)
	return { r = channel(color.r * (1 - t)), g = channel(color.g * (1 - t)), b = channel(color.b * (1 - t)) }
end

-- A color from hue (0 to 1, wraps around), saturation and brightness (both 0 to 1).
function Variants.fromHsv(hue: number, saturation: number, value: number): Color
	local h = (hue % 1) * 6
	local s = math.clamp(saturation, 0, 1)
	local v = math.clamp(value, 0, 1)
	local sector = math.floor(h)
	local fraction = h - sector
	local p = v * (1 - s)
	local q = v * (1 - s * fraction)
	local t = v * (1 - s * (1 - fraction))
	local r, g, b = v, t, p
	if sector == 1 then
		r, g, b = q, v, p
	elseif sector == 2 then
		r, g, b = p, v, t
	elseif sector == 3 then
		r, g, b = p, q, v
	elseif sector == 4 then
		r, g, b = t, p, v
	elseif sector == 5 then
		r, g, b = v, p, q
	end
	return { r = channel(r * 255), g = channel(g * 255), b = channel(b * 255) }
end

-- The rainbow color of part number `index` of `count` at the color offset `offset` (a full cycle
-- is 1): the parts are spread over the whole circle, and the offset turns it.
function Variants.rainbowColor(index: number, count: number, offset: number, saturation: number, value: number): Color
	local spread = if count > 0 then (index - 1) / count else 0
	local shift = if isFinite(offset) then offset else 0
	return Variants.fromHsv(spread + shift, saturation, value)
end

function Variants.find(variants: { Variant }, id: string): Variant?
	for _, variant in variants do
		if variant.id == id then
			return variant
		end
	end
	return nil
end

-- The look of a part (`color` is its normal color, `role` "body" or "accent") in a variant.
-- `index` and `count` place the part among all parts of the dino (for the rainbow, which starts
-- at the color offset 0 and is animated afterwards by the client).
function Variants.appearance(
	variant: Variant,
	color: Color,
	role: string,
	index: number,
	count: number,
	saturation: number,
	value: number
): Look
	local result: Color = color
	if variant.animated then
		result = Variants.rainbowColor(index, count, 0, saturation, value)
	else
		local replacement = if role == "accent" then variant.accent else variant.body
		if replacement ~= nil then
			result = replacement
		end
		if variant.lighten ~= nil then
			result = Variants.lighten(result, variant.lighten)
		end
		if variant.darken ~= nil and (role ~= "accent" or variant.accent == nil) then
			result = Variants.darken(result, variant.darken)
		end
	end
	return { color = result, material = variant.material, transparency = 0 }
end

-- Returns a list of problems (empty when the variants are usable).
function Variants.validate(variants: { Variant }, normalId: string): { string }
	local errors: { string } = {}
	if #variants == 0 then
		table.insert(errors, "no variants")
	end
	local seen: { [string]: boolean } = { [normalId] = true }
	for _, variant in variants do
		local where = "variant " .. variant.id
		if string.match(variant.id, "^[a-z0-9]+$") == nil then
			table.insert(errors, where .. ": id must be lowercase letters and digits")
		end
		if seen[variant.id] then
			table.insert(errors, where .. ": duplicate id")
		end
		seen[variant.id] = true
		if not Variants.MATERIALS[variant.material] then
			table.insert(errors, where .. ": unknown material " .. tostring(variant.material))
		end
		for _, field in { "lighten", "darken" } do
			local amount = (variant :: any)[field]
			if amount ~= nil and (not isFinite(amount) or amount < 0 or amount > 1) then
				table.insert(errors, where .. ": " .. field .. " must be between 0 and 1")
			end
		end
		for _, field in { "body", "accent" } do
			local color = (variant :: any)[field]
			if color ~= nil and not colorOk(color) then
				table.insert(errors, where .. ": " .. field .. " color must be between 0 and 255")
			end
		end
	end
	return errors
end

return Variants
