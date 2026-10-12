--!strict
-- Short times for the interface: 45 -> "45s", 750 -> "12m", 12000 -> "3h 20m", 446400 -> "5d 4h".
-- Always cut off, never rounded up. No Roblox services.

local TimeFormat = {}

local MINUTE = 60
local HOUR = 3600
local DAY = 86400

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- A number and a smaller unit: "3h 20m", or just "3h" when the smaller part is 0.
local function pair(big: number, bigUnit: string, small: number, smallUnit: string): string
	if small == 0 then
		return string.format("%d%s", big, bigUnit)
	end
	return string.format("%d%s %d%s", big, bigUnit, small, smallUnit)
end

function TimeFormat.compact(seconds: number): string
	if not isFinite(seconds) or seconds < 0 then
		return "0s"
	end
	local whole = math.floor(seconds)
	if whole < MINUTE then
		return string.format("%ds", whole)
	elseif whole < HOUR then
		return string.format("%dm", whole // MINUTE)
	elseif whole < DAY then
		return pair(whole // HOUR, "h", (whole % HOUR) // MINUTE, "m")
	end
	return pair(whole // DAY, "d", (whole % DAY) // HOUR, "h")
end

return TimeFormat
