--!strict
-- Pure circle zones of the lobby: which circle a point is in, and the time a player has to
-- stand in a circle before it triggers. No Roblox services, no logging.

export type Zone = { id: string, x: number, z: number, radius: number, dwell: number }

-- State of one player: the circle they stand in, since when, and whether it already fired.
export type Dwell = { zoneId: string?, since: number, fired: boolean }

local Zones = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function distance(zone: Zone, x: number, z: number): number
	local dx = x - zone.x
	local dz = z - zone.z
	return math.sqrt(dx * dx + dz * dz)
end

-- The circle that contains the point (border included). If circles overlap, the nearest
-- center wins, then the smaller id. Invalid coordinates are in no circle.
function Zones.zoneAt(zones: { Zone }, x: number, z: number): Zone?
	if not isFinite(x) or not isFinite(z) then
		return nil
	end
	local best: Zone? = nil
	local bestDistance = math.huge
	for _, zone in zones do
		local d = distance(zone, x, z)
		if d <= zone.radius and (d < bestDistance or (d == bestDistance and best ~= nil and zone.id < best.id)) then
			best = zone
			bestDistance = d
		end
	end
	return best
end

-- True when the point keeps at least `margin` studs away from every circle.
function Zones.isClear(zones: { Zone }, x: number, z: number, margin: number): boolean
	for _, zone in zones do
		if distance(zone, x, z) < zone.radius + margin then
			return false
		end
	end
	return true
end

-- Returns a list of problems (empty when the zones are usable). The circles must be inside
-- the platform (with `margin` to the edge) and must not overlap.
function Zones.validate(zones: { Zone }, platformSize: number, margin: number): { string }
	local errors: { string } = {}
	local half = platformSize / 2 - margin
	local seen: { [string]: boolean } = {}
	for index, zone in zones do
		local where = "zone " .. zone.id
		if seen[zone.id] then
			table.insert(errors, where .. ": duplicate id")
		end
		seen[zone.id] = true
		if not isFinite(zone.radius) or zone.radius <= 0 then
			table.insert(errors, where .. ": radius must be above 0")
		elseif not isFinite(zone.x) or not isFinite(zone.z) then
			table.insert(errors, where .. ": position must be a number")
		elseif math.abs(zone.x) + zone.radius > half or math.abs(zone.z) + zone.radius > half then
			table.insert(errors, where .. ": must be inside the platform")
		end
		if not isFinite(zone.dwell) or zone.dwell < 0 then
			table.insert(errors, where .. ": dwell must be 0 or more")
		end
		for other = index + 1, #zones do
			local second = zones[other]
			if distance(zone, second.x, second.z) <= zone.radius + second.radius then
				table.insert(errors, where .. ": overlaps zone " .. second.id)
			end
		end
	end
	return errors
end

function Zones.newDwell(): Dwell
	return { zoneId = nil, since = 0, fired = false }
end

-- Advances the state of a player standing in `zone` (nil = in no circle) at time `now`.
-- Returns the new state (the old one is not changed) and whether the circle triggers now;
-- it triggers once per stay, after `dwell` seconds, and leaving the circle resets it.
function Zones.step(state: Dwell, zone: Zone?, now: number): (Dwell, boolean)
	if zone == nil then
		return Zones.newDwell(), false
	end
	local current = state
	if state.zoneId ~= zone.id then
		current = { zoneId = zone.id, since = now, fired = false }
	end
	if not current.fired and now - current.since >= zone.dwell then
		return { zoneId = current.zoneId, since = current.since, fired = true }, true
	end
	return current, false
end

-- Seconds left until the circle triggers (0 when it fired or the player is in no circle).
function Zones.remaining(state: Dwell, zone: Zone?, now: number): number
	if zone == nil or state.zoneId ~= zone.id or state.fired then
		return 0
	end
	return math.max(0, zone.dwell - (now - state.since))
end

return Zones
