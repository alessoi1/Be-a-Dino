--!strict
local Framework = require("../Framework")
local ScenerySpawn = require("../../src/shared/ScenerySpawn")
local Scenery = require("../../src/shared/Config/Scenery")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue
local assertNear = Framework.assertNear

-- Radius of the round arena.
local RADIUS = 300

local function kinds(): { ScenerySpawn.Kind }
	local list: { ScenerySpawn.Kind } = {}
	for _, prop in Scenery.props do
		table.insert(list, { id = prop.id, count = prop.count, radius = prop.radius })
	end
	return list
end

local function scatterAll(seed: number): { ScenerySpawn.Placed }
	local discs = { { x = 0, z = 0, r = 90 } }
	return ScenerySpawn.scatter(
		RADIUS,
		Scenery.placement.wallMargin,
		discs,
		kinds(),
		Scenery.placement.candidates,
		Framework.seededRng(seed)
	)
end

test("ScenerySpawn: scatter places every prop of the config in the real arena", function()
	local expected = 0
	for _, prop in Scenery.props do
		expected += prop.count
	end
	assertEquals(#scatterAll(1), expected)
end)

test("ScenerySpawn: props keep away from the waterhole, the walls and each other", function()
	local placed = scatterAll(2)
	for index, prop in placed do
		assertTrue(math.sqrt(prop.x * prop.x + prop.z * prop.z) >= 90 + prop.radius, "inside the waterhole clearance")
		local limit = RADIUS - Scenery.placement.wallMargin - prop.radius
		assertTrue(math.sqrt(prop.x * prop.x + prop.z * prop.z) <= limit + 1e-9, "too close to the wall")
		for other = index + 1, #placed do
			local dx, dz = prop.x - placed[other].x, prop.z - placed[other].z
			assertTrue(math.sqrt(dx * dx + dz * dz) >= prop.radius + placed[other].radius, "props overlap")
		end
	end
end)

test("ScenerySpawn: the same seed gives the same arena", function()
	local first, second = scatterAll(3), scatterAll(3)
	assertEquals(#first, #second)
	for index, prop in first do
		assertEquals(prop.x, second[index].x)
		assertEquals(prop.z, second[index].z)
	end
end)

test("ScenerySpawn: a prop without room is left out", function()
	local placed = ScenerySpawn.scatter(
		20,
		5,
		{},
		{ { id = "Big", count = 5, radius = 9 } },
		10,
		Framework.seededRng(4)
	)
	assertTrue(#placed < 5, "should not fit")
	assertEquals(
		#ScenerySpawn.scatter(10, 8, {}, { { id = "Big", count = 1, radius = 5 } }, 10, Framework.seededRng(4)),
		0
	)
end)

test("ScenerySpawn: props spread over all four quarters of the arena", function()
	local quarters = { 0, 0, 0, 0 }
	for _, prop in scatterAll(5) do
		local index = (prop.x < 0 and 1 or 0) + (prop.z < 0 and 2 or 0) + 1
		quarters[index] += 1
	end
	for _, count in quarters do
		assertTrue(count > 20, "a quarter is nearly empty")
	end
end)

test("ScenerySpawn: clearOfProps respects radius and gap", function()
	local props: { ScenerySpawn.Placed } = { { id = "Tree", x = 0, z = 0, yaw = 0, radius = 5 } }
	assertEquals(ScenerySpawn.clearOfProps(7, 0, props, 3), false)
	assertEquals(ScenerySpawn.clearOfProps(8, 0, props, 3), true)
	assertEquals(ScenerySpawn.clearOfProps(0, 0, {}, 3), true)
end)

local function rockSpec(): ScenerySpawn.RockSpec
	local walls = Scenery.walls
	return {
		spacing = walls.rockSpacing,
		minWidth = walls.rockMinWidth,
		maxWidth = walls.rockMaxWidth,
		minHeight = walls.rockMinHeight,
		maxHeight = walls.rockMaxHeight,
		minDepth = walls.rockMinDepth,
		maxDepth = walls.rockMaxDepth,
		jitter = walls.rockJitter,
		yaw = walls.rockYaw,
		tones = #walls.rockColors,
	}
end

test("ScenerySpawn: wall rocks stand all around the wall inside the size limits", function()
	local spec = rockSpec()
	local rocks = ScenerySpawn.wallRocks(RADIUS, spec, Framework.seededRng(6))
	assertEquals(#rocks, math.floor(2 * math.pi * RADIUS / spec.spacing))
	local quarters = { 0, 0, 0, 0 }
	for _, rock in rocks do
		local turn = rock.angle % (2 * math.pi)
		local quarter = math.min(4, math.floor(turn / (math.pi / 2)) + 1)
		quarters[quarter] += 1
		assertTrue(rock.width >= spec.minWidth and rock.width <= spec.maxWidth)
		assertTrue(rock.height >= spec.minHeight and rock.height <= spec.maxHeight)
		assertTrue(rock.depth >= spec.minDepth and rock.depth <= spec.maxDepth)
		assertTrue(rock.tone >= 1 and rock.tone <= spec.tones)
	end
	for index, count in quarters do
		assertTrue(count > #rocks / 8, "quarter " .. index .. " is nearly empty")
	end
end)

test("ScenerySpawn: a path runs outward from the start and stays inside the walls", function()
	local ground = Scenery.ground
	local limit = RADIUS - ground.pathWallInset
	for angle = 0, 5 do
		local points = ScenerySpawn.pathPoints(
			angle,
			70,
			RADIUS,
			ground.pathWallInset,
			ground.pathStep,
			ground.pathWobble,
			Framework.seededRng(10 + angle)
		)
		assertTrue(#points >= 2, "path too short")
		local first, last = points[1], points[#points]
		assertTrue(math.abs(math.sqrt(first.x * first.x + first.z * first.z) - 70) < 1e-6, "wrong start")
		assertTrue(
			last.x * last.x + last.z * last.z > first.x * first.x + first.z * first.z,
			"path does not go outward"
		)
		for _, point in points do
			assertTrue(math.sqrt(point.x * point.x + point.z * point.z) <= limit, "path leaves the arena")
		end
	end
end)

test("ScenerySpawn: a path that would start outside is empty", function()
	assertEquals(#ScenerySpawn.pathPoints(0, 320, RADIUS, 10, 18, 0.2, Framework.seededRng(1)), 0)
end)

test("ScenerySpawn: patches lie fully inside the arena", function()
	local ground = Scenery.ground
	local patches = ScenerySpawn.patches(
		RADIUS,
		ground.patchMargin,
		ground.patchCount,
		ground.patchMinRadius,
		ground.patchMaxRadius,
		#ground.patchColors,
		Framework.seededRng(7)
	)
	assertEquals(#patches, ground.patchCount)
	for _, patch in patches do
		assertTrue(
			math.sqrt(patch.x * patch.x + patch.z * patch.z) + patch.radius <= RADIUS - ground.patchMargin + 1e-9
		)
		assertTrue(patch.tone >= 1 and patch.tone <= #ground.patchColors)
	end
end)

test("ScenerySpawn: obstacles are the props that have a collision radius", function()
	local placed: { ScenerySpawn.Placed } = {
		{ id = "Tree", x = 10, z = -4, yaw = 0, radius = 5 },
		{ id = "Fern", x = 1, z = 2, yaw = 0, radius = 2 },
	}
	local discs = ScenerySpawn.obstacles(placed, { Tree = 1.3 })
	assertEquals(#discs, 1)
	assertEquals(discs[1].x, 10)
	assertEquals(discs[1].z, -4)
	assertEquals(discs[1].r, 1.3)
end)

test("ScenerySpawn: every collider in the config has a usable size", function()
	local solid = 0
	for _, kind in Scenery.props do
		local collider = kind.collider
		if collider ~= nil then
			solid += 1
			assertTrue(collider.height > 0, kind.id .. " height")
			if collider.shape == "cylinder" then
				assertTrue(collider.radius > 0, kind.id .. " radius")
				assertTrue(collider.radius <= kind.radius, kind.id .. " collider inside its free space")
			else
				assertTrue(collider.width > 0 and collider.depth > 0, kind.id .. " box size")
				assertTrue(collider.width / 2 <= kind.radius, kind.id .. " collider inside its free space")
			end
		end
	end
	assertTrue(solid > 0, "some props are solid")
end)

local OASIS = { { x = 0, z = 0, r = 90 } }

local function distance(ax: number, az: number, bx: number, bz: number): number
	return math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2)
end

test("ScenerySpawn: ponds lie inside the arena, outside the exclusions and apart from each other", function()
	local ponds = ScenerySpawn.ponds(RADIUS, 20, OASIS, 6, 14, 24, 12, Framework.seededRng(10))
	assertEquals(#ponds, 6)
	for index, pond in ponds do
		assertTrue(pond.r >= 14 and pond.r <= 24, "size")
		assertTrue(distance(pond.x, pond.z, 0, 0) + pond.r <= RADIUS - 20 + 1e-9, "inside the arena")
		assertTrue(distance(pond.x, pond.z, 0, 0) >= 90 + pond.r - 1e-9, "outside the oasis")
		for other = index + 1, #ponds do
			assertTrue(
				distance(pond.x, pond.z, ponds[other].x, ponds[other].z) >= pond.r + ponds[other].r,
				"ponds overlap"
			)
		end
	end
end)

test("ScenerySpawn: a pond that finds no room is left out", function()
	assertEquals(#ScenerySpawn.ponds(30, 20, {}, 3, 14, 24, 8, Framework.seededRng(11)), 0)
end)

test("ScenerySpawn: gates are two rocks with exactly the asked gap between their edges", function()
	local gaps = { 7, 12, 20 }
	local rockRadius = 4
	local gates = ScenerySpawn.gates(RADIUS, 20, OASIS, 8, gaps, rockRadius, 12, Framework.seededRng(12))
	assertEquals(#gates, 8)
	local seen: { [number]: boolean } = {}
	for _, gate in gates do
		assertTrue(table.find(gaps, gate.gap) ~= nil, "a gap from the list")
		seen[gate.gap] = true
		local a, b = gate.rocks[1], gate.rocks[2]
		assertNear(distance(a.x, a.z, b.x, b.z) - 2 * rockRadius, gate.gap, 1e-6, "gap between the edges")
		for _, rock in gate.rocks do
			assertTrue(distance(rock.x, rock.z, 0, 0) + rockRadius <= RADIUS - 20 + 1e-9, "inside the arena")
			assertTrue(distance(rock.x, rock.z, 0, 0) >= 90 + rockRadius - 1e-9, "outside the oasis")
		end
	end
	assertTrue(seen[7] and seen[12] and seen[20], "every gap size is used")
end)

test("ScenerySpawn: gates keep apart from each other", function()
	local gates = ScenerySpawn.gates(RADIUS, 20, OASIS, 8, { 12 }, 4, 12, Framework.seededRng(13))
	for index, gate in gates do
		for other = index + 1, #gates do
			assertTrue(distance(gate.x, gate.z, gates[other].x, gates[other].z) >= gate.reach + gates[other].reach)
		end
	end
end)

test("ScenerySpawn: clusters hold their members close together inside the arena", function()
	local radii = { Bush = 2.5, Fern = 2 }
	local clusters =
		ScenerySpawn.clusters(RADIUS, 20, OASIS, 5, 4, 7, 9, { "Bush", "Fern" }, radii, 12, Framework.seededRng(14))
	assertEquals(#clusters, 5)
	for _, cluster in clusters do
		assertTrue(#cluster.members >= 4 and #cluster.members <= 7, "member count")
		for _, member in cluster.members do
			assertTrue(distance(member.x, member.z, cluster.x, cluster.z) <= 9 + 1e-9, "close to the middle")
			assertTrue(radii[member.id] ~= nil and member.radius == radii[member.id], "radius of its kind")
		end
		assertTrue(distance(cluster.x, cluster.z, 0, 0) >= 90 + 9 - 1e-9, "outside the oasis")
	end
end)

test("ScenerySpawn: vines hang all around, skip the asked directions and stay in their limits", function()
	local vines = ScenerySpawn.vines(40, 14, 32, 0.08, function(angle: number): boolean
		return angle > 1 and angle < 2
	end, Framework.seededRng(15))
	assertTrue(#vines > 25 and #vines < 40, "some skipped")
	for _, vine in vines do
		assertTrue(not (vine.angle > 1 and vine.angle < 2), "skipped direction")
		assertTrue(vine.length >= 14 and vine.length <= 32, "length")
		assertTrue(math.abs(vine.tiltX) <= 0.08 and math.abs(vine.tiltZ) <= 0.08, "tilt")
	end
	assertEquals(#ScenerySpawn.vines(0, 14, 32, 0.08, function()
		return false
	end, Framework.seededRng(1)), 0)
end)

test(
	"ScenerySpawn: the gate rocks are a real prop with a collider, and the gaps are a mix of tight and wide",
	function()
		local found = nil
		for _, kind in Scenery.props do
			if kind.id == Scenery.gates.rockId then
				found = kind
			end
		end
		assertTrue(found ~= nil and found.collider ~= nil, "gate rock prop with collider")
		local smallest, largest = math.huge, 0
		for _, gap in Scenery.gates.gaps do
			smallest = math.min(smallest, gap)
			largest = math.max(largest, gap)
		end
		assertTrue(smallest < largest, "different gap sizes")
		assertTrue(Scenery.ponds.count > 0 and Scenery.clusters.count > 0 and Scenery.vines.count > 0)
	end
)
