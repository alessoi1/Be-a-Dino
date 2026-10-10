--!strict
local Framework = require("../Framework")
local UiLayout = require("../../src/shared/UiLayout")
local Ui = require("../../src/shared/Config/Ui")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

test("UiLayout: scale follows the shorter side", function()
	assertNear(UiLayout.scaleFor(Ui, 390, 844), 1, 1e-9)
	assertNear(UiLayout.scaleFor(Ui, 844, 390), 1, 1e-9, "landscape is the same")
end)

test("UiLayout: scale is kept between the limits", function()
	assertEquals(UiLayout.scaleFor(Ui, 200, 300), Ui.scaleMin)
	assertEquals(UiLayout.scaleFor(Ui, 2000, 1500), Ui.scaleMax)
end)

test("UiLayout: invalid sizes give safe defaults", function()
	assertEquals(UiLayout.scaleFor(Ui, 0, 0), 1)
	assertEquals(UiLayout.scaleFor(Ui, 0 / 0, 500), 1)
	assertEquals(UiLayout.buttonSize(Ui, -5, 500), Ui.buttonMin)
end)

test("UiLayout: the button is between the limits and grows with the screen", function()
	assertEquals(UiLayout.buttonSize(Ui, 360, 640), Ui.buttonMin)
	assertEquals(UiLayout.buttonSize(Ui, 390, 844), 78)
	assertEquals(UiLayout.buttonSize(Ui, 1024, 768), 120)
	assertTrue(UiLayout.buttonSize(Ui, 500, 900) >= UiLayout.buttonSize(Ui, 390, 844))
end)

test("UiLayout: a touch button is never smaller than the minimum on common phones", function()
	for _, size in { { 360, 640 }, { 375, 667 }, { 390, 844 }, { 640, 360 }, { 844, 390 } } do
		assertTrue(UiLayout.buttonSize(Ui, size[1], size[2]) >= Ui.buttonMin)
	end
end)

test("UiLayout: the smallest base text size keeps text readable", function()
	local base = UiLayout.minBaseTextSize(Ui)
	assertEquals(base, 18)
	assertTrue(base * Ui.scaleMin >= Ui.minTextSize)
end)
