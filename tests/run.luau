--!strict
-- Run with: lune run tests/run
local process = require("@lune/process")

local Framework = require("./Framework")

-- Every spec file registers its tests via Framework.test on require.
-- Add new specs here (growth, eating and spawn rules come first).
local specs: { () -> () } = {
	function()
		require("./specs/Log.spec")
	end,
	function()
		require("./specs/RejectLimiter.spec")
	end,
	function()
		require("./specs/Growth.spec")
	end,
	function()
		require("./specs/EatRules.spec")
	end,
	function()
		require("./specs/FoodSpawn.spec")
	end,
	function()
		require("./specs/Stamina.spec")
	end,
	function()
		require("./specs/MoveCheck.spec")
	end,
	function()
		require("./specs/CameraRig.spec")
	end,
	function()
		require("./specs/FoodKinds.spec")
	end,
	function()
		require("./specs/FoodField.spec")
	end,
	function()
		require("./specs/DinoLook.spec")
	end,
}

local passed = 0
local failed = 0

for _, loadSpec in specs do
	loadSpec()
	for _, case in Framework.takeCases() do
		local ok, err = pcall(case.run)
		if ok then
			passed += 1
			print("  ok   " .. case.name)
		else
			failed += 1
			print("  FAIL " .. case.name)
			print("       " .. tostring(err))
		end
	end
end

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
	process.exit(1)
end
