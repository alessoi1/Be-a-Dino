--!strict
local Framework = require("../Framework")
local ScenerySpawn = require("../../src/shared/ScenerySpawn")
local Scenery = require("../../src/shared/Config/Scenery")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

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
