--!strict
local Framework = require("../Framework")
local Lobby = require("../../src/shared/Config/Lobby")
local LeaveWait = require("../../src/shared/LeaveWait")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local SECONDS = 5
local RADIUS = 1

local function at(x: number, z: number): LeaveWait.Position
	return { x = x, y = 3, z = z }
end

test("LeaveWait: standing still for the full time finishes the wait", function()
	local state = LeaveWait.start(at(10, 20), 100)
	local state1, status1 = LeaveWait.step(state, at(10, 20), 102, RADIUS, SECONDS)
	assertEquals(status1, "waiting")
	assertTrue(state1 ~= nil)
	local state2, status2 = LeaveWait.step(state, at(10, 20), 104.9, RADIUS, SECONDS)
	assertEquals(status2, "waiting")
	assertTrue(state2 ~= nil)
	local state3, status3 = LeaveWait.step(state, at(10, 20), 105, RADIUS, SECONDS)
	assertEquals(status3, "done")
	assertEquals(state3, nil)
end)

test("LeaveWait: small drift inside the radius does not cancel", function()
	local state = LeaveWait.start(at(0, 0), 0)
	local _, status = LeaveWait.step(state, at(0.5, -0.5), 3, RADIUS, SECONDS)
	assertEquals(status, "waiting")
end)

test("LeaveWait: moving farther than the radius cancels the wait", function()
	local state = LeaveWait.start(at(0, 0), 0)
	local next, status = LeaveWait.step(state, at(3, 0), 2, RADIUS, SECONDS)
	assertEquals(status, "moved")
	assertEquals(next, nil)
	-- Also when it happens in the last moment.
	local _, late = LeaveWait.step(state, at(0, 5), 5, RADIUS, SECONDS)
	assertEquals(late, "moved")
end)

test("LeaveWait: height changes (a jump) count as movement", function()
	local state = LeaveWait.start(at(0, 0), 0)
	local _, status = LeaveWait.step(state, { x = 0, y = 10, z = 0 }, 1, RADIUS, SECONDS)
	assertEquals(status, "moved")
end)

test("LeaveWait: the movement is measured from the start, not from the last check", function()
	local state = LeaveWait.start(at(0, 0), 0)
	-- Creeping away in small steps is still caught, because the anchor stays at the start.
	local _, s1 = LeaveWait.step(state, at(0.8, 0), 1, RADIUS, SECONDS)
	local _, s2 = LeaveWait.step(state, at(1.6, 0), 2, RADIUS, SECONDS)
	assertEquals(s1, "waiting")
	assertEquals(s2, "moved")
end)

test("LeaveWait: invalid input cancels instead of finishing", function()
	local state = LeaveWait.start(at(0, 0), 0)
	local _, nan = LeaveWait.step(state, at(0 / 0, 0), 6, RADIUS, SECONDS)
	assertEquals(nan, "moved")
end)

test("LeaveWait: remaining counts down and never goes below zero", function()
	local state = LeaveWait.start(at(0, 0), 10)
	assertEquals(LeaveWait.remaining(state, 10, SECONDS), 5)
	assertEquals(LeaveWait.remaining(state, 13, SECONDS), 2)
	assertEquals(LeaveWait.remaining(state, 99, SECONDS), 0)
end)

test("LeaveWait: the config asks for five seconds standing still", function()
	assertEquals(Lobby.leaveSeconds, 5)
	assertTrue(Lobby.leaveStillRadius > 0 and Lobby.leaveStillRadius < 5)
end)
