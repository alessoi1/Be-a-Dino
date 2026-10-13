--!strict
local Framework = require("../Framework")
local Avoidance = require("../../src/shared/Avoidance")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local CLEARANCE = 2
local LOOK_AHEAD = 40
local DETOURS = 3

local function steer(from: Avoidance.Point, goal: Avoidance.Point, obstacles: { Avoidance.Disc }): Avoidance.Point
	return Avoidance.steer(from, goal, obstacles, CLEARANCE, LOOK_AHEAD, DETOURS)
end

local function distance(a: Avoidance.Point, b: Avoidance.Point): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

test("Avoidance: without obstacles the goal is returned", function()
	local result = steer({ x = 0, z = 0 }, { x = 30, z = 10 }, {})
	assertEquals(result.x, 30)
	assertEquals(result.z, 10)
end)

test("Avoidance: an obstacle beside the path does not matter", function()
	local goal = { x = 30, z = 0 }
	local result = steer({ x = 0, z = 0 }, goal, { { x = 15, z = 10, r = 3 } })
	assertEquals(result.x, 30)
	assertEquals(result.z, 0)
end)

test("Avoidance: an obstacle behind is ignored", function()
	local result = steer({ x = 0, z = 0 }, { x = 30, z = 0 }, { { x = -10, z = 0, r = 3 } })
	assertEquals(result.x, 30)
end)

test("Avoidance: an obstacle farther than the look-ahead is ignored", function()
	local result = steer({ x = 0, z = 0 }, { x = 200, z = 0 }, { { x = 100, z = 0, r = 3 } })
	assertEquals(result.x, 200)
end)

test("Avoidance: an obstacle in the way gives a waypoint around it", function()
	local obstacle = { x = 20, z = 0, r = 3 }
	local result = steer({ x = 0, z = 0 }, { x = 60, z = 0 }, { obstacle })
	assertTrue(result.z ~= 0, "the waypoint leaves the straight line")
	assertTrue(distance(result, obstacle) >= obstacle.r + CLEARANCE - 1e-6, "the waypoint is outside the clearance")
	assertTrue(not Avoidance.segmentBlocked({ x = 0, z = 0 }, result, { obstacle }, CLEARANCE), "the way to it is free")
end)

test("Avoidance: goes around on the side away from the obstacle center", function()
	local left = steer({ x = 0, z = 0 }, { x = 60, z = 0 }, { { x = 20, z = 1, r = 3 } })
	local right = steer({ x = 0, z = 0 }, { x = 60, z = 0 }, { { x = 20, z = -1, r = 3 } })
	assertTrue(left.z < 0, "obstacle slightly to +z: pass on -z")
	assertTrue(right.z > 0, "obstacle slightly to -z: pass on +z")
end)

test("Avoidance: a goal inside an obstacle is walked to directly", function()
	local result = steer({ x = 0, z = 0 }, { x = 20, z = 0 }, { { x = 20, z = 1, r = 3 } })
	assertEquals(result.x, 20)
	assertEquals(result.z, 0)
end)

test("Avoidance: standing inside the clearance of an obstacle does not flip the direction", function()
	local result = steer({ x = 0, z = 0 }, { x = 30, z = 0 }, { { x = 1, z = 0, r = 2 } })
	assertEquals(result.x, 30)
	assertEquals(result.z, 0)
end)

test("Avoidance: two obstacles in a row are both avoided", function()
	local obstacles = { { x = 20, z = 0, r = 3 }, { x = 20, z = -7, r = 3 } }
	local from = { x = 0, z = 0 }
	local result = steer(from, { x = 60, z = 0 }, obstacles)
	assertTrue(not Avoidance.segmentBlocked(from, result, obstacles, CLEARANCE), "the way to the waypoint is free")
end)

test("Avoidance: a dead-center obstacle picks the same side every time", function()
	local first = steer({ x = 0, z = 0 }, { x = 60, z = 0 }, { { x = 20, z = 0, r = 3 } })
	local second = steer({ x = 0, z = 0 }, { x = 60, z = 0 }, { { x = 20, z = 0, r = 3 } })
	assertEquals(first.z, second.z)
	assertTrue(first.z ~= 0)
end)

test("Avoidance: repeating the steering walks around the obstacle", function()
	local obstacle = { x = 20, z = 0, r = 3 }
	local goal = { x = 60, z = 0 }
	local position = { x = 0, z = 0 }
	local closest = math.huge
	for _ = 1, 200 do
		local waypoint = steer(position, goal, { obstacle })
		local dx, dz = waypoint.x - position.x, waypoint.z - position.z
		local length = math.sqrt(dx * dx + dz * dz)
		if length < 1e-6 then
			break
		end
		local stepLength = math.min(1, length)
		position = { x = position.x + dx / length * stepLength, z = position.z + dz / length * stepLength }
		closest = math.min(closest, distance(position, obstacle))
		if distance(position, goal) < 1 then
			break
		end
	end
	assertTrue(distance(position, goal) < 1, "reaches the goal")
	assertTrue(closest >= obstacle.r + CLEARANCE - 0.5, "never gets into the obstacle")
end)

test("Avoidance: invalid numbers give the goal back", function()
	local result = steer({ x = 0 / 0, z = 0 }, { x = 5, z = 5 }, { { x = 2, z = 2, r = 1 } })
	assertEquals(result.x, 5)
	assertEquals(result.z, 5)
	local ignored = steer({ x = 0, z = 0 }, { x = 30, z = 0 }, { { x = 0 / 0, z = 0, r = 1 } })
	assertEquals(ignored.x, 30)
end)

test("Avoidance: start equal to the goal gives the goal", function()
	local result = steer({ x = 5, z = 5 }, { x = 5, z = 5 }, { { x = 5, z = 5, r = 3 } })
	assertEquals(result.x, 5)
	assertEquals(result.z, 5)
end)
