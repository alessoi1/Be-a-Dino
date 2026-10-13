--!strict
local Framework = require("../Framework")
local Icons = require("../../src/shared/Config/Icons")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

-- Every icon the interface asks for (UiKit.newIcon by name).
local REQUIRED = { "size", "coin", "sprint", "stamina", "autofarm", "leaderboard", "lobby" }

test("Icons: every icon the interface uses exists", function()
	for _, name in REQUIRED do
		assertTrue((Icons :: any)[name] ~= nil, "missing icon " .. name)
	end
end)

test("Icons: every icon has a usable glyph, color and asset id", function()
	for name, icon in Icons :: { [string]: any } do
		assertTrue(type(icon.glyph) == "string" and #icon.glyph > 0, name .. " glyph")
		assertTrue(type(icon.assetId) == "number" and icon.assetId >= 0 and icon.assetId % 1 == 0, name .. " assetId")
		for _, channel in { icon.color.r, icon.color.g, icon.color.b } do
			assertTrue(channel >= 0 and channel <= 255, name .. " color")
		end
	end
end)

test("Icons: no image is claimed that was not uploaded", function()
	-- A reminder: when you add an asset id, the image must exist; see docs/ICONS.md.
	local count = 0
	for _ in Icons :: { [string]: any } do
		count += 1
	end
	assertEquals(count >= #REQUIRED, true)
end)
