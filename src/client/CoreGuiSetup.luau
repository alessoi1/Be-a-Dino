--!strict
-- Hides the Roblox elements that the own interface replaces (player list, backpack).
-- The chat stays. Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))

-- The core scripts may not be ready right at the start, so a few tries are made.
local ATTEMPTS = 5
local RETRY_SECONDS = 1

local log = Log.new("CoreGuiSetup")

local CoreGuiSetup = {}

function CoreGuiSetup.start()
	task.spawn(function()
		for attempt = 1, ATTEMPTS do
			local ok, err = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
			if ok then
				log.info("core gui adjusted")
				return
			end
			log.warn("core gui not ready", { attempt = attempt, error = tostring(err) })
			task.wait(RETRY_SECONDS)
		end
		log.error("core gui could not be adjusted")
	end)
end

return CoreGuiSetup
