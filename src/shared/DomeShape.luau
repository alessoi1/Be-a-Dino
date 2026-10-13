--!strict
-- Pure geometry of the glass dome: the beams of its frame (meridian ribs from the floor to the top
-- and horizontal rings) as pairs of points on a sphere. No Roblox services, no logging; the
-- DomeService turns the beams into parts. The dome is a half sphere around the arena center, its
-- foot on the floor (y = 0).

export type Beam = { ax: number, ay: number, az: number, bx: number, by: number, bz: number }

local TWO_PI = math.pi * 2
local QUARTER = math.pi / 2

local DomeShape = {}

-- A point on the sphere. `azimuth` turns around the upright axis, `elevation` is the angle above
-- the floor (0 = at the foot, pi/2 = at the top).
function DomeShape.point(radius: number, azimuth: number, elevation: number): (number, number, number)
	local flat = radius * math.cos(elevation)
	return flat * math.cos(azimuth), radius * math.sin(elevation), flat * math.sin(azimuth)
end

local function beam(radius: number, azimuthA: number, elevationA: number, azimuthB: number, elevationB: number): Beam
	local ax, ay, az = DomeShape.point(radius, azimuthA, elevationA)
	local bx, by, bz = DomeShape.point(radius, azimuthB, elevationB)
	return { ax = ax, ay = ay, az = az, bx = bx, by = by, bz = bz }
end

-- `count` ribs from the foot to the top, each cut into `segments` straight beams.
function DomeShape.ribs(radius: number, count: number, segments: number): { Beam }
	local beams: { Beam } = {}
	for rib = 1, math.max(0, math.floor(count)) do
		local azimuth = (rib - 1) / count * TWO_PI
		for segment = 1, math.max(1, math.floor(segments)) do
			local from = (segment - 1) / segments * QUARTER
			local to = segment / segments * QUARTER
			table.insert(beams, beam(radius, azimuth, from, azimuth, to))
		end
	end
	return beams
end

-- One horizontal ring per elevation (degrees). A ring higher up is smaller, so it gets fewer
-- beams (`maxSegments` at the foot, never fewer than `minSegments`).
function DomeShape.rings(
	radius: number,
	elevationsDegrees: { number },
	minSegments: number,
	maxSegments: number
): { Beam }
	local beams: { Beam } = {}
	for _, degrees in elevationsDegrees do
		local elevation = math.rad(degrees)
		local count = math.clamp(math.ceil(maxSegments * math.cos(elevation)), minSegments, maxSegments)
		for segment = 1, count do
			local from = (segment - 1) / count * TWO_PI
			local to = segment / count * TWO_PI
			table.insert(beams, beam(radius, from, elevation, to, elevation))
		end
	end
	return beams
end

return DomeShape
