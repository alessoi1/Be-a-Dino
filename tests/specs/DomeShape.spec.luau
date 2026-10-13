--!strict
local Framework = require("../Framework")
local DomeShape = require("../../src/shared/DomeShape")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local RADIUS = 300

local function onSphere(beam: DomeShape.Beam)
	assertNear(math.sqrt(beam.ax ^ 2 + beam.ay ^ 2 + beam.az ^ 2), RADIUS, 1e-6)
	assertNear(math.sqrt(beam.bx ^ 2 + beam.by ^ 2 + beam.bz ^ 2), RADIUS, 1e-6)
end

test("DomeShape: a point on the foot lies on the floor, at the top it is straight above", function()
	local x, y, z = DomeShape.point(RADIUS, 0, 0)
	assertNear(x, RADIUS, 1e-9)
	assertNear(y, 0, 1e-9)
	assertNear(z, 0, 1e-9)
	local tx, ty, tz = DomeShape.point(RADIUS, 1.234, math.pi / 2)
	assertNear(tx, 0, 1e-9)
	assertNear(ty, RADIUS, 1e-9)
	assertNear(tz, 0, 1e-9)
end)

test("DomeShape: ribs run from the foot to the top on the sphere", function()
	local beams = DomeShape.ribs(RADIUS, 12, 10)
	assertEquals(#beams, 120)
	local lowest, highest = math.huge, -math.huge
	for _, beam in beams do
		onSphere(beam)
		assertTrue(beam.ay >= -1e-9 and beam.by >= -1e-9, "nothing below the floor")
		lowest = math.min(lowest, beam.ay, beam.by)
		highest = math.max(highest, beam.ay, beam.by)
	end
	assertNear(lowest, 0, 1e-6)
	assertNear(highest, RADIUS, 1e-6)
end)

test("DomeShape: consecutive beams of a rib meet", function()
	local beams = DomeShape.ribs(RADIUS, 1, 5)
	for index = 1, #beams - 1 do
		assertNear(beams[index].bx, beams[index + 1].ax, 1e-9)
		assertNear(beams[index].by, beams[index + 1].ay, 1e-9)
		assertNear(beams[index].bz, beams[index + 1].az, 1e-9)
	end
end)

test("DomeShape: rings are level, close up and get fewer beams higher up", function()
	local low = DomeShape.rings(RADIUS, { 10 }, 16, 48)
	local high = DomeShape.rings(RADIUS, { 80 }, 16, 48)
	assertTrue(#low > #high, "the low ring has more beams")
	assertTrue(#high >= 16, "never fewer than the minimum")
	assertTrue(#low <= 48, "never more than the maximum")
	for _, beam in low do
		onSphere(beam)
		assertNear(beam.ay, beam.by, 1e-9)
		assertNear(beam.ay, RADIUS * math.sin(math.rad(10)), 1e-6)
	end
	local first, last = low[1], low[#low]
	assertNear(first.ax, last.bx, 1e-6)
	assertNear(first.az, last.bz, 1e-6)
end)

test("DomeShape: no beams for nothing", function()
	assertEquals(#DomeShape.ribs(RADIUS, 0, 10), 0)
	assertEquals(#DomeShape.rings(RADIUS, {}, 16, 48), 0)
end)
