--!strict
-- The remotes between client and server. The server creates them (once, at
-- start); the client waits for them. Names are defined only here.
-- Client -> server remotes carry intentions only, never sizes or amounts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local Remotes = {
	names = {
		-- Add remotes here with a comment: direction, arguments, meaning.
		-- client -> server event: (active: boolean), the player holds or releases sprint
		sprint = "Sprint",
		-- client -> server event: (no arguments), Studio only: adds debug points (see Config/Debug)
		debugGrow = "DebugGrow",
		-- client -> server event: (no arguments), Studio only: puts a bounty on the other players
		debugBounty = "DebugBounty",
		-- client -> server event: (choice: string), what the player chose in the window after being
		-- eaten ("lobby" today; "revive" and "bounty" come with the paid step); checked by the server
		deathChoice = "DeathChoice",
		-- client -> server event: (no arguments), Studio only: jumps to the next dino
		debugNextStage = "DebugNextStage",
		-- client -> server event: (skinId: string), the player chooses a skin (checked by the server)
		equipSkin = "EquipSkin",
		-- client -> server event: (active: boolean), the player asks to go back to the lobby (true)
		-- or cancels the wait (false); the server checks mode and time
		leaveArena = "LeaveArena",
		-- server -> client event: (kind: "ate" | "eaten" | "skin", otherName: string, points: number,
		-- coins: number?, bounty: boolean?), display only
		notice = "Notice",
	},
}

local function getFolder(): Instance
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if existing ~= nil then
			return existing
		end
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

local function getRemote(name: string, className: string): Instance
	local folder = getFolder()
	if RunService:IsServer() then
		local existing = folder:FindFirstChild(name)
		if existing ~= nil then
			return existing
		end
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	return folder:WaitForChild(name)
end

function Remotes.event(name: string): RemoteEvent
	return getRemote(name, "RemoteEvent") :: RemoteEvent
end

function Remotes.func(name: string): RemoteFunction
	return getRemote(name, "RemoteFunction") :: RemoteFunction
end

return Remotes
