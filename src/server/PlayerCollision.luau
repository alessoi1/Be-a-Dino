--!strict
-- Players do not collide with each other (so a big dino can reach a small one to eat it),
-- but still collide with the floor and the walls. Only checkable in Roblox Studio.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))

local GROUP = "Dinos"

local log = Log.new("PlayerCollision")

local PlayerCollision = {}

local function assign(character: Model)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = GROUP
		end
	end
	-- Parts that are added later (the dino look) join the group too.
	character.DescendantAdded:Connect(function(descendant: Instance)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = GROUP
		end
	end)
end

function PlayerCollision.start()
	local registered, err = pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP)
	end)
	if not registered then
		log.warn("collision group already registered or failed", { error = tostring(err) })
	end
	local ok, setErr = pcall(function()
		PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)
	end)
	if not ok then
		log.error("collision setup failed", { error = tostring(setErr) })
		return
	end

	local function watch(player: Player)
		player.CharacterAdded:Connect(assign)
		if player.Character ~= nil then
			assign(player.Character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	log.info("started")
end

return PlayerCollision
