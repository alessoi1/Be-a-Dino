--!strict
-- Minimal test framework for Lune. No dependencies, no Roblox services.

local Framework = {}

export type TestCase = { name: string, run: () -> () }

local cases: { TestCase } = {}

function Framework.test(name: string, run: () -> ())
	table.insert(cases, { name = name, run = run })
end

function Framework.takeCases(): { TestCase }
	local taken = cases
	cases = {}
	return taken
end

function Framework.assertTrue(value: boolean, message: string?)
	if not value then
		error(message or "expected true, got false", 2)
	end
end

function Framework.assertEquals(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error(
			string.format("%s: expected %s, got %s", message or "values differ", tostring(expected), tostring(actual)),
			2
		)
	end
end

function Framework.assertNear(actual: number, expected: number, tolerance: number, message: string?)
	if math.abs(actual - expected) > tolerance then
		error(
			string.format(
				"%s: expected %s +/- %s, got %s",
				message or "values not near",
				tostring(expected),
				tostring(tolerance),
				tostring(actual)
			),
			2
		)
	end
end

local function deepEqual(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b or (a ~= a and b ~= b)
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

function Framework.deepEqual(a: any, b: any): boolean
	return deepEqual(a, b)
end

function Framework.assertDeepEquals(actual: any, expected: any, message: string?)
	if not deepEqual(actual, expected) then
		error(message or "tables differ", 2)
	end
end

-- Asserts that `fn` raises an error whose message contains `fragment`.
function Framework.assertErrors(fn: () -> (), fragment: string)
	local ok, err = pcall(fn)
	if ok then
		error("expected an error containing '" .. fragment .. "', but nothing was raised", 2)
	end
	if not string.find(tostring(err), fragment, 1, true) then
		error(string.format("expected error containing '%s', got '%s'", fragment, tostring(err)), 2)
	end
end

-- Rng that returns the given numbers in order and errors when exhausted,
-- so tests notice an unexpected number of random draws.
function Framework.scriptedRng(values: { number }): () -> number
	local index = 0
	return function(): number
		index += 1
		local value = values[index]
		if value == nil then
			error(string.format("scripted rng exhausted after %d draws", #values))
		end
		return value
	end
end

-- Deterministic pseudo-random generator (LCG) returning values in [0, 1).
function Framework.seededRng(seed: number): () -> number
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(): number
		state = (state * 48271) % 2147483647
		return (state - 1) / 2147483646
	end
end

return Framework
