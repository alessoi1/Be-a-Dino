--!strict
local Framework = require("../Framework")
local Icons = require("../../src/shared/Config/Icons")
local Lobby = require("../../src/shared/Config/Lobby")
local MenuBar = require("../../src/shared/MenuBar")
local MenuConfig = require("../../src/shared/Config/Menu")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

local known = { "shop", "dex", "boost" }

test("MenuBar: a tap opens a window, a second tap closes it", function()
	assertEquals(MenuBar.toggle(nil, "shop", known), "shop")
	assertEquals(MenuBar.toggle("shop", "shop", known), nil)
end)

test("MenuBar: a tap on another button switches the window", function()
	assertEquals(MenuBar.toggle("shop", "dex", known), "dex")
end)

test("MenuBar: an unknown id changes nothing", function()
	assertEquals(MenuBar.toggle("shop", "arena", known), "shop")
	assertEquals(MenuBar.toggle(nil, "", known), nil)
end)

test("MenuBar: a window is shown in its circle or when opened with the bar", function()
	assertTrue(MenuBar.visible("shop", nil, "shop"))
	assertTrue(MenuBar.visible("", "shop", "shop"))
	assertTrue(not MenuBar.visible("dex", nil, "shop"))
	assertTrue(not MenuBar.visible("", "dex", "shop"))
	assertTrue(not MenuBar.visible(nil, nil, "shop"))
	assertTrue(not MenuBar.visible(5, nil, "shop"))
end)

test("MenuBar: the entries are valid and match the circles and the icons", function()
	assertEquals(#MenuBar.validate(MenuConfig.entries), 0)
	local windows: { [string]: boolean } = {}
	for _, zone in Lobby.zones do
		if zone.kind == "window" then
			windows[zone.id] = true
		end
	end
	for _, entry in MenuConfig.entries do
		assertTrue(windows[entry.id] == true, entry.id .. " is a window circle of the lobby")
		assertTrue((Icons :: any)[entry.icon] ~= nil, entry.icon .. " exists in the icons")
	end
	assertEquals(#MenuConfig.entries, 3)
end)

test("MenuBar: broken entries are reported", function()
	assertTrue(#MenuBar.validate({ { id = "a", icon = "x" }, { id = "a", icon = "y" } }) > 0, "duplicate")
	assertTrue(#MenuBar.validate({ { id = "", icon = "x" } }) > 0, "no id")
	assertTrue(#MenuBar.validate({ { id = "a", icon = "" } }) > 0, "no icon")
end)
