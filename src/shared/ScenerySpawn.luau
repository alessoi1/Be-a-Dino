--!strict
-- Pure placement of the arena scenery: props spread evenly, rock blocks along the walls, dirt
-- paths and ground patches. No Roblox services, no logging. `rng` returns numbers in [0, 1).

export type Rng = () -> number
export type Disc = { x: number, z: number, r: number }
export type Kind = { id: string, count: number, radius: number }
export type Placed = { id: string, x: number, z: number, yaw: number, radius: number }
export type Point = { x: number, z: number }
export type Patch = { x: number, z: number, radius: number, tone: number }
export type WallRock = {
	-- Direction from the arena center (radians) in which the rock stands at the wall.
	angle: number,
	-- Turn around the upright axis relative to the wall.
	yaw: number,
	width: number,
	height: number,
	depth: number,
	tone: number,
}
export type RockSpec = {
	spacing: number,
	minWidth: number,
	maxWidth: number,
	minHeight: number,
	maxHeight: number,
	minDepth: number,
	maxDepth: number,
	jitter: number,
	yaw: number,
	tones: number,
}

local TWO_PI = math.pi * 2
local MAX_PATH_STEPS = 200
-- How strongly a path is pulled back to its original direction (0 = not at all, 1 = straight).
local PATH_PULL = 0.3

local ScenerySpawn = {}

local function between(rng: Rng, low: number, high: number): number
	return low + (high - low) * rng()
end

-- A random point evenly spread over the disc of `limit` around the middle (the square root of
-- the distance roll keeps the points from piling up in the middle).
local function discPoint(limit: number, rng: Rng): (number, number)
	local angle = between(rng, 0, TWO_PI)
	local distance = limit * math.sqrt(rng())
	return distance * math.cos(angle), distance * math.sin(angle)
end

-- Free space of a spot (studs) to the nearest disc and to the nearest placed prop. Negative
-- means it overlaps.
local function gaps(x: number, z: number, radius: number, discs: { Disc }, placed: { Placed }): (number, number)
	local toDisc = math.huge
	for _, disc in discs do
		local dx, dz = x - disc.x, z - disc.z
		toDisc = math.min(toDisc, math.sqrt(dx * dx + dz * dz) - disc.r - radius)
	end
	local toProp = math.huge
	for _, other in placed do
		local dx, dz = x - other.x, z - other.z
		toProp = math.min(toProp, math.sqrt(dx * dx + dz * dz) - other.radius - radius)
	end
	return toDisc, toProp
end

-- Places `count` props of each kind inside the round arena (of `radius`) with `margin` to the
-- wall. Big props first. Of `candidates` random spots the valid one with the most free space to
-- the other props wins, so the props spread evenly. A prop that finds no valid spot is left out.
function ScenerySpawn.scatter(
	radius: number,
	margin: number,
	exclusions: { Disc },
	kinds: { Kind },
	candidates: number,
	rng: Rng
): { Placed }
	local placed: { Placed } = {}
	local order = table.clone(kinds)
	table.sort(order, function(a: Kind, b: Kind): boolean
		if a.radius ~= b.radius then
			return a.radius > b.radius
		end
		return a.id < b.id
	end)
	for _, kind in order do
		local limit = radius - margin - kind.radius
		if limit > 0 then
			for _ = 1, kind.count do
				local best: Placed? = nil
				local bestGap = -math.huge
				for _ = 1, candidates do
					local x, z = discPoint(limit, rng)
					local toDisc, toProp = gaps(x, z, kind.radius, exclusions, placed)
					if toDisc >= 0 and toProp >= 0 and toProp > bestGap then
						best = { id = kind.id, x = x, z = z, yaw = between(rng, 0, TWO_PI), radius = kind.radius }
						bestGap = toProp
					end
				end
				if best ~= nil then
					table.insert(placed, best)
				end
			end
		end
	end
	return placed
end

-- Rock blocks standing in front of the wall ring, one every `spacing` studs along the wall
-- (shifted by a random share of it). Sizes and tones are random inside the spec.
function ScenerySpawn.wallRocks(radius: number, spec: RockSpec, rng: Rng): { WallRock }
	local rocks: { WallRock } = {}
	local count = math.max(1, math.floor(TWO_PI * radius / spec.spacing))
	for index = 1, count do
		local angle = (index - 0.5) / count * TWO_PI
		angle += between(rng, -spec.jitter, spec.jitter) * spec.spacing / radius
		table.insert(rocks, {
			angle = angle,
			yaw = between(rng, -spec.yaw, spec.yaw),
			width = between(rng, spec.minWidth, spec.maxWidth),
			height = between(rng, spec.minHeight, spec.maxHeight),
			depth = between(rng, spec.minDepth, spec.maxDepth),
			tone = math.floor(rng() * spec.tones) + 1,
		})
	end
	return rocks
end

-- Points of a dirt path that runs from `startRadius` (distance from the middle) in direction
-- `angle` until it is closer than `inset` to the wall. It wobbles by at most `wobble` radians
-- per step but is pulled back to the original direction.
function ScenerySpawn.pathPoints(
	angle: number,
	startRadius: number,
	radius: number,
	inset: number,
	step: number,
	wobble: number,
	rng: Rng
): { Point }
	local limit = radius - inset
	local points: { Point } = {}
	local x = math.cos(angle) * startRadius
	local z = math.sin(angle) * startRadius
	if x * x + z * z > limit * limit then
		return points
	end
	table.insert(points, { x = x, z = z })
	local heading = angle
	for _ = 1, MAX_PATH_STEPS do
		heading += between(rng, -wobble, wobble)
		heading = angle + (heading - angle) * (1 - PATH_PULL)
		x += math.cos(heading) * step
		z += math.sin(heading) * step
		if x * x + z * z > limit * limit then
			break
		end
		table.insert(points, { x = x, z = z })
	end
	return points
end

-- Round ground patches of random size and tone, fully inside the round arena with `margin` to the wall.
function ScenerySpawn.patches(
	arenaRadius: number,
	margin: number,
	count: number,
	minRadius: number,
	maxRadius: number,
	tones: number,
	rng: Rng
): { Patch }
	local patches: { Patch } = {}
	for _ = 1, count do
		local radius = between(rng, minRadius, maxRadius)
		local limit = arenaRadius - margin - radius
		if limit > 0 then
			local x, z = discPoint(limit, rng)
			table.insert(patches, {
				x = x,
				z = z,
				radius = radius,
				tone = math.floor(rng() * tones) + 1,
			})
		end
	end
	return patches
end

-- The solid discs of the placed props, for the steering around them (Avoidance). `radii` is the
-- radius of the collision shape per prop id; props without an entry are not solid.
function ScenerySpawn.obstacles(placed: { Placed }, radii: { [string]: number }): { Disc }
	local discs: { Disc } = {}
	for _, prop in placed do
		local radius = radii[prop.id]
		if radius ~= nil and radius > 0 then
			table.insert(discs, { x = prop.x, z = prop.z, r = radius })
		end
	end
	return discs
end

-- Whether a spot is at least `gap` studs away from every prop (its own radius counts).
function ScenerySpawn.clearOfProps(x: number, z: number, props: { Placed }, gap: number): boolean
	for _, prop in props do
		local dx, dz = x - prop.x, z - prop.z
		local reach = prop.radius + gap
		if dx * dx + dz * dz < reach * reach then
			return false
		end
	end
	return true
end

return ScenerySpawn
