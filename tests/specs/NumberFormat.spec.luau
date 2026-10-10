--!strict
local Framework = require("../Framework")
local NumberFormat = require("../../src/shared/NumberFormat")

local test = Framework.test
local assertEquals = Framework.assertEquals

test("NumberFormat: small numbers are shown whole", function()
	assertEquals(NumberFormat.compact(0), "0")
	assertEquals(NumberFormat.compact(7), "7")
	assertEquals(NumberFormat.compact(999), "999")
	assertEquals(NumberFormat.compact(999.9), "999", "cut off, not rounded")
end)

test("NumberFormat: thousands with three significant digits", function()
	assertEquals(NumberFormat.compact(1000), "1K")
	assertEquals(NumberFormat.compact(1234), "1.23K")
	assertEquals(NumberFormat.compact(1500), "1.5K")
	assertEquals(NumberFormat.compact(12345), "12.3K")
	assertEquals(NumberFormat.compact(123456), "123K")
	assertEquals(NumberFormat.compact(9999), "9.99K")
end)

test("NumberFormat: digits are cut off, so nothing jumps up by rounding", function()
	assertEquals(NumberFormat.compact(1999), "1.99K")
	assertEquals(NumberFormat.compact(999950), "999K")
	assertEquals(NumberFormat.compact(999999), "999K")
	assertEquals(NumberFormat.compact(1999999), "1.99M")
end)

test("NumberFormat: the larger units", function()
	assertEquals(NumberFormat.compact(1000000), "1M")
	assertEquals(NumberFormat.compact(2500000), "2.5M")
	assertEquals(NumberFormat.compact(1000000000), "1B")
	assertEquals(NumberFormat.compact(16556291), "16.5M")
	assertEquals(NumberFormat.compact(1e12), "1T")
	assertEquals(NumberFormat.compact(1.5e15), "1.5Qa")
	assertEquals(NumberFormat.compact(3e18), "3Qi")
	assertEquals(NumberFormat.compact(999e18), "999Qi")
end)

test("NumberFormat: beyond the largest unit uses scientific notation", function()
	assertEquals(NumberFormat.compact(1e21), "1.0e21")
	assertEquals(NumberFormat.compact(1.26e24), "1.3e24")
end)

test("NumberFormat: negative and invalid numbers", function()
	assertEquals(NumberFormat.compact(-1500), "-1.5K")
	assertEquals(NumberFormat.compact(0 / 0), "0")
	assertEquals(NumberFormat.compact(math.huge), "0")
	assertEquals(NumberFormat.compact(-math.huge), "0")
	assertEquals(NumberFormat.compact("5" :: any), "0")
end)

test("NumberFormat: the unit steps are monotone", function()
	local previousLength = 0
	for exponent = 0, 18 do
		local text = NumberFormat.compact(10 ^ exponent)
		-- Every power of ten has a short text of at most five characters.
		assertEquals(#text <= 5, true, text)
		previousLength = #text
	end
	assertEquals(previousLength > 0, true)
end)
