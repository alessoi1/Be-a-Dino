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

local ELEVATIONS = { 8, 28, 48, 68, 82 }

test("DomeShape: the glass has one panel per cell between two ribs and two rings", function()
	local panels = DomeShape.panels(RADIUS, 12, ELEVATIONS, 1)
	-- Six bands (foot to the first ring, between the rings, last ring to the top) times 12 ribs.
	assertEquals(#panels, 6 * 12)
end)

test("DomeShape: every panel sits just inside the sphere, faces outward and is above the floor", function()
	for _, panel in DomeShape.panels(RADIUS, 12, ELEVATIONS, 1) do
		local distance = math.sqrt(panel.x ^ 2 + panel.y ^ 2 + panel.z ^ 2)
		assertTrue(distance <= RADIUS and distance >= RADIUS * 0.95, "close to the ribs, a little inside")
		assertNear(math.sqrt(panel.nx ^ 2 + panel.ny ^ 2 + panel.nz ^ 2), 1, 1e-9)
		-- The normal points away from the middle: it is the direction of the panel itself.
		assertNear(panel.nx * panel.x + panel.ny * panel.y + panel.nz * panel.z, distance, 1e-6)
		assertTrue(panel.y > 0, "above the floor")
		assertTrue(panel.width > 0 and panel.height > 0)
	end
end)

test("DomeShape: panels are narrower higher up and cover the cells without gaps", function()
	local panels = DomeShape.panels(RADIUS, 12, ELEVATIONS, 1)
	local lowest, highest = panels[1], panels[1]
	for _, panel in panels do
		if panel.y < lowest.y then
			lowest = panel
		end
		if panel.y > highest.y then
			highest = panel
		end
	end
	assertTrue(highest.width < lowest.width, "the top is narrower")
	-- Around a band the panels together span the whole circle (the widths add up to at least the chord).
	local band = {}
	for _, panel in panels do
		if math.abs(panel.y - lowest.y) < 1e-6 then
			table.insert(band, panel)
		end
	end
	assertEquals(#band, 12)
	local total = 0
	for _, panel in band do
		total += panel.width
	end
	-- The lowest band runs from 0 to 8 degrees: the polygon through its ribs, at the middle of the band.
	local middle = math.rad(4)
	local polygon = 12 * 2 * RADIUS * math.cos(middle) * math.sin(math.pi / 12)
	assertTrue(total >= polygon * 0.99, "no gap around the band")
end)

test("DomeShape: the overlap makes the panels a little bigger", function()
	local plain = DomeShape.panels(RADIUS, 12, ELEVATIONS, 1)[1]
	local wide = DomeShape.panels(RADIUS, 12, ELEVATIONS, 1.1)[1]
	assertNear(wide.width, plain.width * 1.1, 1e-9)
	assertNear(wide.height, plain.height * 1.1, 1e-9)
end)

test("DomeShape: no panels without ribs or rings", function()
	assertEquals(#DomeShape.panels(RADIUS, 0, ELEVATIONS, 1), 0)
	assertEquals(#DomeShape.panels(RADIUS, 12, {}, 1), 12, "a single band from the foot to the top")
end)
