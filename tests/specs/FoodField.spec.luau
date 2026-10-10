--!strict
local Framework = require("../Framework")
local FoodField = require("../../src/shared/FoodField")

local test = Framework.test
local assertEquals = Framework.assertEquals
local assertNear = Framework.assertNear
local assertTrue = Framework.assertTrue

test("FoodField: place and count", function()
	local field = FoodField.new()
	assertTrue(FoodField.place(field, 1, 0, 0, 1))
	assertTrue(FoodField.place(field, 2, 5, 5, 2))
	assertEquals(FoodField.count(field), 2)
end)

test("FoodField: a duplicate id is rejected", function()
	local field = FoodField.new()
	assertTrue(FoodField.place(field, 1, 0, 0, 1))
	assertTrue(not FoodField.place(field, 1, 9, 9, 1))
	assertEquals(FoodField.count(field), 1)
end)

test("FoodField: remove returns the item once", function()
	local field = FoodField.new()
	FoodField.place(field, 1, 3, 4, 2)
	local item = FoodField.remove(field, 1)
	assertTrue(item ~= nil)
	assertEquals(item and item.kind, 2)
	assertEquals(FoodField.remove(field, 1), nil)
	assertEquals(FoodField.count(field), 0)
end)

test("FoodField: inRange finds pieces inside the radius, border included", function()
	local field = FoodField.new()
	FoodField.place(field, 1, 3, 0, 1)
	FoodField.place(field, 2, 3.01, 0, 1)
	FoodField.place(field, 3, 100, 100, 1)
	local found = FoodField.inRange(field, 0, 0, 3)
	assertEquals(#found, 1)
	assertEquals(found[1].id, 1)
end)

test("FoodField: inRange sorts by distance, ties by id", function()
	local field = FoodField.new()
	FoodField.place(field, 5, 2, 0, 1)
	FoodField.place(field, 3, 1, 0, 1)
	FoodField.place(field, 4, 0, 1, 1)
	local found = FoodField.inRange(field, 0, 0, 5)
	assertEquals(#found, 3)
	assertEquals(found[1].id, 3)
	assertEquals(found[2].id, 4)
	assertEquals(found[3].id, 5)
end)

test("FoodField: removed pieces are not found", function()
	local field = FoodField.new()
	FoodField.place(field, 1, 0, 0, 1)
	FoodField.remove(field, 1)
	assertEquals(#FoodField.inRange(field, 0, 0, 10), 0)
end)

test("FoodField: invalid radius finds nothing", function()
	local field = FoodField.new()
	FoodField.place(field, 1, 0, 0, 1)
	assertEquals(#FoodField.inRange(field, 0, 0, -1), 0)
	assertEquals(#FoodField.inRange(field, 0, 0, 0 / 0), 0)
end)

test("FoodField: pickup radius grows with the scale", function()
	local config: FoodField.Config = { pickupBase = 2, pickupPerScale = 1.5 }
	assertNear(FoodField.pickupRadius(config, 1), 3.5, 1e-9)
	assertNear(FoodField.pickupRadius(config, 5), 9.5, 1e-9)
	assertNear(FoodField.pickupRadius(config, 0 / 0), 2, 1e-9)
end)
