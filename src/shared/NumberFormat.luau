--!strict
-- Short numbers for the interface: 1234 -> 1.23K, 12345 -> 12.3K, 1234567 -> 1.23M, up to Qi.
-- Three significant digits, always cut off (never rounded up), so 1999 shows as 1.99K and no
-- number ever jumps to the next unit by rounding. No Roblox services.

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }
local STEP = 1000
-- Guards against floating point noise when cutting off digits.
local EPSILON = 1e-9

local NumberFormat = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Formats value (>= 1, < 1000) with three significant digits and no trailing zeros.
local function digits(value: number): string
	local decimals = if value < 10 then 2 elseif value < 100 then 1 else 0
	local factor = 10 ^ decimals
	local scaled = math.floor(value * factor + EPSILON)
	if decimals == 0 then
		return string.format("%d", scaled)
	end
	local whole = scaled // factor
	local fraction = scaled % factor
	if fraction == 0 then
		return string.format("%d", whole)
	end
	local text = string.format("%d.%0" .. decimals .. "d", whole, fraction)
	-- Drop trailing zeros of the fraction (1.50 -> 1.5).
	text = string.gsub(text, "0+$", "")
	return text
end

function NumberFormat.compact(value: number): string
	if not isFinite(value) then
		return "0"
	end
	if value < 0 then
		return "-" .. NumberFormat.compact(-value)
	end
	if value < STEP then
		return string.format("%d", math.floor(value))
	end

	local scaled = value
	local index = 0
	while scaled >= STEP and index < #SUFFIXES do
		scaled /= STEP
		index += 1
	end
	if scaled >= STEP then
		-- Beyond the largest unit: scientific notation, for example 1.2e21.
		local text = string.format("%.1e", value)
		local clean = string.gsub(text, "e%+", "e")
		return clean
	end
	return digits(scaled) .. SUFFIXES[index]
end

return NumberFormat
