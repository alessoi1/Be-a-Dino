--!strict
local Framework = require("../Framework")
local PlayMode = require("../../src/shared/PlayMode")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertTrue = Framework.assertTrue

test("PlayMode: the arena takes players until it is full", function()
	assertTrue((PlayMode.canEnter(0, 24)))
	assertTrue((PlayMode.canEnter(23, 24)))
	local ok, reason = PlayMode.canEnter(24, 24)
	assertTrue(not ok)
	assertEquals(reason, "full")
	assertEquals(select(2, PlayMode.canEnter(30, 24)), "full")
end)

test("PlayMode: invalid numbers are refused", function()
	assertEquals(select(2, PlayMode.canEnter(0 / 0, 24)), "invalid")
	assertEquals(select(2, PlayMode.canEnter(-1, 24)), "invalid")
	assertEquals(select(2, PlayMode.canEnter(1, 0 / 0)), "invalid")
	assertEquals(select(2, PlayMode.canEnter("1" :: any, 24)), "invalid")
end)

test("PlayMode: only lobby to playing and back is a change", function()
	assertTrue(PlayMode.canTransition("lobby", "playing"))
	assertTrue(PlayMode.canTransition("playing", "lobby"))
	assertTrue(not PlayMode.canTransition("lobby", "lobby"))
	assertTrue(not PlayMode.canTransition("playing", "playing"))
end)

test("PlayMode: countPlaying counts the playing entries", function()
	assertEquals(PlayMode.countPlaying({}), 0)
	assertEquals(PlayMode.countPlaying({ a = "lobby", b = "playing", c = "playing" }), 2)
	assertEquals(PlayMode.countPlaying({ "lobby", "lobby" }), 0)
end)
