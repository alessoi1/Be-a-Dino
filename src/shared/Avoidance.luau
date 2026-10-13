--!strict
-- Pure steering around round obstacles (trees, rocks): when the straight way to a goal runs into
-- an obstacle, a waypoint on the tangent around it is returned. Used by the bots and the autofarm,
-- which walk with MoveTo and would stick to trees otherwise. Obstacles are discs on the floor
-- plane. No Roblox services, no logging.

export type Point = { x: number, z: number }
export type Disc = { x: number, z: number, r: number }

-- The waypoint lies on a circle this much wider than the blocking radius, so the way to it is
-- free and the dino does not scrape along the obstacle.
local DETOUR_FACTOR = 1.05
-- Smallest angle (radians) around the obstacle between the dino and the waypoint, so the
-- waypoint is not behind the dino when it is already close to the edge.
local MIN_DETOUR_ANGLE = math.rad(25)

local Avoidance = {}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function validPoint(point: Point): boolean
	return isFinite(point.x) and isFinite(point.z)
end

local function validDisc(disc: Disc): boolean
	return isFinite(disc.x) and isFinite(disc.z) and isFinite(disc.r) and disc.r > 0
end

-- Distance of a point to the segment a-b, and how far along the segment (0 to 1) the nearest point is.
local function distanceToSegment(px: number, pz: number, a: Point, b: Point): (number, number)
	local dx, dz = b.x - a.x, b.z - a.z
	local lengthSquared = dx * dx + dz * dz
	local t = 0
	if lengthSquared > 1e-12 then
		t = math.clamp(((px - a.x) * dx + (pz - a.z) * dz) / lengthSquared, 0, 1)
	end
	local nx, nz = a.x + dx * t, a.z + dz * t
	local ex, ez = px - nx, pz - nz
	return math.sqrt(ex * ex + ez * ez), t
end

-- Whether the obstacle counts for the way a -> b: the way passes closer than its radius plus
-- the clearance, and neither end is inside that reach (then the obstacle is ignored: a dino
-- that already stands next to a tree, or a goal beside it, must still be able to move).
local function blocks(a: Point, b: Point, disc: Disc, clearance: number): (boolean, number)
	local reach = disc.r + clearance
	local fromX, fromZ = a.x - disc.x, a.z - disc.z
	if fromX * fromX + fromZ * fromZ < reach * reach then
		return false, 0
	end
	local toX, toZ = b.x - disc.x, b.z - disc.z
	if toX * toX + toZ * toZ < reach * reach then
		return false, 0
	end
	local gap, t = distanceToSegment(disc.x, disc.z, a, b)
	return gap < reach, t
end

-- Whether any obstacle blocks the way a -> b.
function Avoidance.segmentBlocked(a: Point, b: Point, obstacles: { Disc }, clearance: number): boolean
	for _, disc in obstacles do
		if validDisc(disc) and (blocks(a, b, disc, clearance)) then
			return true
		end
	end
	return false
end

-- The tangent point around `disc` on the side away from where the obstacle lies relative to
-- the way `from` -> `goal`.
local function tangentPoint(from: Point, goal: Point, disc: Disc, clearance: number): Point
	local radius = (disc.r + clearance) * DETOUR_FACTOR
	local dirX, dirZ = goal.x - from.x, goal.z - from.z
	local dirLength = math.sqrt(dirX * dirX + dirZ * dirZ)
	dirX, dirZ = dirX / dirLength, dirZ / dirLength
	-- The perpendicular on the side the dino passes on. The obstacle lies on the other side
	-- (a dead-center obstacle counts as lying on the left, so the dino goes right every time).
	local side = dirX * (disc.z - from.z) - dirZ * (disc.x - from.x)
	local passX, passZ = dirZ, -dirX
	if side < 0 then
		passX, passZ = -dirZ, dirX
	end

	local toX, toZ = from.x - disc.x, from.z - disc.z
	local distance = math.sqrt(toX * toX + toZ * toZ)
	local baseAngle = math.atan2(toZ, toX)
	local angle = math.max(math.acos(math.min(1, radius / distance)), MIN_DETOUR_ANGLE)

	local best: Point = { x = disc.x, z = disc.z }
	local bestSide = -math.huge
	for _, sign in { 1, -1 } do
		local x = disc.x + math.cos(baseAngle + sign * angle) * radius
		local z = disc.z + math.sin(baseAngle + sign * angle) * radius
		local lean = (x - disc.x) * passX + (z - disc.z) * passZ
		if lean > bestSide then
			bestSide = lean
			best = { x = x, z = z }
		end
	end
	return best
end

-- The point to walk to now. Without a blocking obstacle within `lookAhead` studs it is the
-- goal; otherwise the tangent point around the nearest blocker. After a detour the way to the
-- waypoint is checked again, up to `maxDetours` times (obstacles standing close together).
-- `clearance` is the room the body needs beside an obstacle.
function Avoidance.steer(
	from: Point,
	goal: Point,
	obstacles: { Disc },
	clearance: number,
	lookAhead: number,
	maxDetours: number
): Point
	if not validPoint(from) or not validPoint(goal) or not isFinite(clearance) or not isFinite(lookAhead) then
		return goal
	end
	local target = goal
	for _ = 1, math.max(0, math.floor(maxDetours)) do
		local dx, dz = target.x - from.x, target.z - from.z
		local length = math.sqrt(dx * dx + dz * dz)
		if length < 1e-6 then
			return target
		end
		-- Only the stretch ahead counts.
		local ahead = math.min(length, lookAhead)
		local limit: Point = { x = from.x + dx / length * ahead, z = from.z + dz / length * ahead }

		local blocker: Disc? = nil
		local blockerT = math.huge
		for _, disc in obstacles do
			if validDisc(disc) then
				local blocked, t = blocks(from, limit, disc, clearance)
				-- The goal check uses the real target, not the end of the look-ahead stretch.
				if blocked and t < blockerT then
					local goalX, goalZ = target.x - disc.x, target.z - disc.z
					local reach = disc.r + clearance
					if goalX * goalX + goalZ * goalZ >= reach * reach then
						blocker = disc
						blockerT = t
					end
				end
			end
		end
		if blocker == nil then
			return target
		end
		target = tangentPoint(from, target, blocker, clearance)
	end
	return target
end

return Avoidance
