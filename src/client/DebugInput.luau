--!strict
-- Studio-only: press G to ask the server for debug growth (see DebugService).
-- Does nothing on live servers. Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DebugInput = {}

function DebugInput.start()
	if not RunService:IsStudio() then
		return
	end
	local remote = Remotes.event(Remotes.names.debugGrow)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.G then
			remote:FireServer()
		end
	end)
end

return DebugInput
