--!strict
local Framework = require("../Framework")
local NameTag = require("../../src/shared/NameTag")
local NameTagConfig = require("../../src/shared/Config/NameTags")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

local config: NameTag.Config = NameTagConfig

test("NameTag: a tag near the dino is visible and opaque", function()
	local layout = NameTag.layout(config, 1, 10)
	assertTrue(layout.visible)
	assertEquals(layout.transparency, 0)
	assertTrue(layout.width > 0 and layout.height > 0)
end)

test("NameTag: a bigger dino gets a bigger tag that floats higher, but the tag grows slower than the body", function()
	local small = NameTag.layout(config, 1, 10)
	local big = NameTag.layout(config, 8, 10)
	assertTrue(big.width > small.width and big.height > small.height)
	assertTrue(big.offsetY > small.offsetY)
	assertTrue(big.width < small.width * 8, "grows slower than the scale")
end)

test("NameTag: the tag is hidden beyond the range, a giant is seen farther away", function()
	local limitSmall = NameTag.maxDistance(config, 1)
	local limitBig = NameTag.maxDistance(config, 8)
	assertTrue(limitBig > limitSmall)
	assertTrue(NameTag.layout(config, 1, limitSmall - 1).visible)
	assertTrue(not NameTag.layout(config, 1, limitSmall).visible)
	assertTrue(NameTag.layout(config, 8, limitSmall + 10).visible)
end)

test("NameTag: the tag fades out at the end of its range", function()
	local limit = NameTag.maxDistance(config, 1)
	local start = limit * config.fadeStart
	assertEquals(NameTag.layout(config, 1, start).transparency, 0)
	local middle = NameTag.layout(config, 1, (start + limit) / 2)
	assertNear(middle.transparency, 0.5, 1e-9)
	local last = NameTag.layout(config, 1, limit - 0.001)
	assertTrue(last.transparency > 0.99 and last.transparency <= 1)
end)

test("NameTag: invalid numbers give an invisible tag", function()
	assertTrue(not NameTag.layout(config, 0, 10).visible)
	assertTrue(not NameTag.layout(config, -1, 10).visible)
	assertTrue(not NameTag.layout(config, 1, -5).visible)
	assertTrue(not NameTag.layout(config, 0 / 0, 10).visible)
	assertTrue(not NameTag.layout(config, 1, math.huge).visible)
end)

test("NameTag: the config is usable", function()
	assertTrue(config.fadeStart > 0 and config.fadeStart < 1)
	assertTrue(NameTagConfig.nameShare > 0 and NameTagConfig.nameShare < 1)
	assertTrue(NameTagConfig.updateInterval > 0)
end)
