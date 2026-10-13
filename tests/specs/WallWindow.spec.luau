--!strict
local Framework = require("../Framework")
local Arena = require("../../src/shared/Config/Arena")
local WallWindow = require("../../src/shared/WallWindow")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local function windowPieces(count: number, center: number, width: number): { number }
	local list = {}
	for index = 1, count do
		if WallWindow.isWindowPiece(index, count, center, width) then
			table.insert(list, index)
		end
	end
	return list
end

test("WallWindow: the window is as many pieces wide as asked, centered on its direction", function()
	local pieces = windowPieces(64, 90, 4)
	assertEquals(#pieces, 4)
	-- 90 degrees is between piece 16 and 17.
	assertEquals(pieces[1], 15)
	assertEquals(pieces[4], 18)
end)

test("WallWindow: the window pieces are neighbors, also across the 0 degree seam", function()
	local pieces = windowPieces(64, 0, 4)
	assertEquals(#pieces, 4)
	assertTrue(table.find(pieces, 1) ~= nil and table.find(pieces, 64) ~= nil, "wraps around")
end)

test("WallWindow: no window pieces for no window", function()
	assertEquals(#windowPieces(64, 90, 0), 0)
	assertEquals(#windowPieces(0, 90, 4), 0)
end)

test("WallWindow: looksThrough covers the window and a margin beside it", function()
	local center = math.rad(90)
	assertTrue(WallWindow.looksThrough(center, 64, 90, 4, 0))
	assertTrue(not WallWindow.looksThrough(math.rad(60), 64, 90, 4, 0))
	assertTrue(not WallWindow.looksThrough(math.rad(103), 64, 90, 4, 0), "just outside")
	assertTrue(WallWindow.looksThrough(math.rad(103), 64, 90, 4, 1), "inside with one piece of margin")
	assertTrue(WallWindow.looksThrough(math.rad(90) + math.pi * 2, 64, 90, 4, 0), "full turns do not matter")
end)

test("WallWindow: the window in the real arena config is a few pieces wide", function()
	local pieces = windowPieces(Arena.wallSegments, Arena.windowAngleDegrees, Arena.windowSegments)
	assertEquals(#pieces, Arena.windowSegments)
	assertTrue(#pieces >= 2 and #pieces < Arena.wallSegments / 4, "a window, not half the wall")
end)
