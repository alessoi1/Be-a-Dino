--!strict
-- The food frenzy: a repeating event for the whole server (see Config/Frenzy and Frenzy). While it
-- runs, the points from food are multiplied. The schedule comes from the seconds since the server
-- start; the state is published as attributes of the workspace (`FrenzyActive`, `FrenzyEndsAt`,
-- `FrenzyNextAt`, in server time) for the banner (display only). Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Frenzy = require(Shared:WaitForChild("Frenzy"))
local Log = require(Shared:WaitForChild("Log"))
local FrenzyConfig = require(Shared:WaitForChild("Config"):WaitForChild("Frenzy"))

local ServerClock = require(script.Parent:WaitForChild("ServerClock"))

-- Seconds between two looks at the schedule.
local CHECK_SECONDS = 1

local log = Log.new("FrenzyService")

local startedAt = 0
local currentPhase: Frenzy.Phase = { active = false, secondsLeft = 0, secondsToNext = 0 }

local FrenzyService = {}

-- The factor for points from food right now (1 when no frenzy runs).
function FrenzyService.factor(): number
	return Frenzy.factor(currentPhase, FrenzyConfig)
end

local function update()
	local now = ServerClock.now()
	local phase = Frenzy.phase(now - startedAt, FrenzyConfig)
	if phase.active ~= currentPhase.active then
		log.info(if phase.active then "frenzy started" else "frenzy ended", { factor = FrenzyConfig.pointsFactor })
	end
	currentPhase = phase
	workspace:SetAttribute("FrenzyActive", phase.active)
	workspace:SetAttribute("FrenzyEndsAt", now + phase.secondsLeft)
	workspace:SetAttribute("FrenzyNextAt", now + phase.secondsToNext)
end

function FrenzyService.start()
	local problems = Frenzy.validate(FrenzyConfig)
	if #problems > 0 then
		log.error("frenzy config invalid", { problems = table.concat(problems, "; ") })
		return
	end
	startedAt = ServerClock.now()
	update()
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			local ok, err = pcall(update)
			if not ok then
				log.error("frenzy update failed", { error = tostring(err) })
			end
		end
	end)
	log.info("started", { calm = FrenzyConfig.calmSeconds, duration = FrenzyConfig.durationSeconds })
end

return FrenzyService
