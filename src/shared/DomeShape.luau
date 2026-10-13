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

-- One flat piece of glass: where its middle is on the sphere, which way it faces (outward, a unit
-- vector) and how wide (around) and high (up the dome) it is, in studs.
export type Panel = {
	x: number,
	y: number,
	z: number,
	nx: number,
	ny: number,
	nz: number,
	width: number,
	height: number,
}

-- The glass between the ribs and rings: one flat panel per cell. The cells are bounded by `ribCount`
-- ribs (evenly around) and by the rings at `elevationsDegrees` (plus the foot and the top). Each panel
-- lies on the plane through the four corners of its cell (the ribs and rings); its width is the average
-- chord of the band and its height the chord up the band, both times `overlap` (a little over 1, so no gap shows at the
-- edges of the flat pieces). A piece of glass is seen from both sides (a thin block).
function DomeShape.panels(radius: number, ribCount: number, elevationsDegrees: { number }, overlap: number): { Panel }
	local panels: { Panel } = {}
	local count = math.floor(ribCount)
	if count <= 0 then
		return panels
	end
	local edges: { number } = { 0 }
	for _, degrees in elevationsDegrees do
		table.insert(edges, math.rad(degrees))
	end
	table.insert(edges, QUARTER)
	table.sort(edges)
	local step = TWO_PI / count
	for band = 1, #edges - 1 do
		local low, high = edges[band], edges[band + 1]
		local middle = (low + high) / 2
		-- The width is the average of the lower and the upper edge of the cell (it is a trapezoid).
		local width = radius * (math.cos(low) + math.cos(high)) * math.sin(step / 2) * overlap
		local height = 2 * radius * math.sin((high - low) / 2) * overlap
		-- A flat piece touching the sphere in its middle would stand off the ribs at its edges (up to
		-- 10 studs). It lies on the plane through the four corners of its cell instead: the middle of
		-- the cell moves toward the center by how far the corners lie behind it on average.
		local depth = 0
		for _, corner in { { -1, low }, { 1, low }, { -1, high }, { 1, high } } do
			local cornerAzimuth = (corner[1] :: number) * step / 2
			depth += math.cos(corner[2] :: number) * math.cos(middle) * math.cos(cornerAzimuth) + math.sin(
				corner[2] :: number
			) * math.sin(middle)
		end
		depth /= 4
		for rib = 1, count do
			-- Centered between two ribs.
			local azimuth = (rib - 0.5) * step
			local x, y, z = DomeShape.point(radius, azimuth, middle)
			table.insert(panels, {
				x = x * depth,
				y = y * depth,
				z = z * depth,
				nx = x / radius,
				ny = y / radius,
				nz = z / radius,
				width = width,
				height = height,
			})
		end
	end
	return panels
end

return DomeShape
