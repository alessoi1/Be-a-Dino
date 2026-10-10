--!strict
-- The one time source of the server: seconds with fractions, the same for all
-- services. Used for cooldowns, regrowth and protection times.
-- Only checkable in Roblox Studio.

local ServerClock = {}

function ServerClock.now(): number
	return workspace:GetServerTimeNow()
end

return ServerClock
