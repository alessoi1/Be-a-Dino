--!strict
-- Hides the Roblox elements that the own interface replaces (player list, backpack) and the
-- touch jump button (jumping is off, and the sprint button takes its place at the bottom
-- right). The chat stays. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))

-- The core scripts may not be ready right at the start, so a few tries are made.
local ATTEMPTS = 5
local RETRY_SECONDS = 1
-- Seconds to wait for each part of the Roblox touch controls to appear.
local TOUCH_GUI_WAIT = 10

local log = Log.new("CoreGuiSetup")

local CoreGuiSetup = {}

-- The touch controls build their buttons themselves, so the jump button is searched and
-- kept hidden. A missing button is only logged: the sprint button still works.
local function hideJumpButton()
	if not UserInputService.TouchEnabled then
		return
	end
	task.spawn(function()
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		local touchGui = playerGui:WaitForChild("TouchGui", TOUCH_GUI_WAIT)
		local frame = touchGui and touchGui:WaitForChild("TouchControlFrame", TOUCH_GUI_WAIT)
		local jump = frame and frame:WaitForChild("JumpButton", TOUCH_GUI_WAIT)
		if jump == nil or not jump:IsA("GuiObject") then
			log.warn("jump button not found, it may overlap the sprint button")
			return
		end
		jump.Visible = false
		jump:GetPropertyChangedSignal("Visible"):Connect(function()
			if jump.Visible then
				jump.Visible = false
			end
		end)
		log.info("jump button hidden")
	end)
end

function CoreGuiSetup.start()
	hideJumpButton()
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
