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

test("NameTag: with the real height of the dino the tag floats right above its head", function()
	local top = 3
	local layout = NameTag.layout(config, 1, 10, top)
	assertNear(layout.offsetY, top + layout.height / 2 + config.tagGap, 1e-9)
	-- A taller dino (a long neck) gets a higher tag than a low one of the same scale.
	local low = NameTag.layout(config, 1, 10, 1)
	local high = NameTag.layout(config, 1, 10, 5)
	assertTrue(high.offsetY > low.offsetY)
	-- Without the height, or with an invalid one, the old estimate is used.
	local estimate = NameTag.layout(config, 1, 10)
	assertNear(NameTag.layout(config, 1, 10, 0 / 0).offsetY, estimate.offsetY, 1e-9)
end)

test("NameTag: the tag stays above the dino whatever its scale", function()
	for _, scale in { 1, 2, 4, 8 } do
		local layout = NameTag.layout(config, scale, 10, 1.1 * scale)
		assertTrue(layout.offsetY - layout.height / 2 >= 1.1 * scale, "the tag does not sink into the dino")
	end
end)
