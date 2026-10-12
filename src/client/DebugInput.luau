--!strict
-- Studio-only: press G for a bit of debug growth, H to jump to the next dino and B to put a bounty on the
-- other players and V to get a variant of the current dino (see DebugService).
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
	local nextRemote = Remotes.event(Remotes.names.debugNextStage)
	local bountyRemote = Remotes.event(Remotes.names.debugBounty)
	local variantRemote = Remotes.event(Remotes.names.debugVariant)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.G then
			remote:FireServer()
		elseif input.KeyCode == Enum.KeyCode.H then
			nextRemote:FireServer()
		elseif input.KeyCode == Enum.KeyCode.B then
			bountyRemote:FireServer()
		elseif input.KeyCode == Enum.KeyCode.V then
			variantRemote:FireServer()
		end
	end)
end

return DebugInput
