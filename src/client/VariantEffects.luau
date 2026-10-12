--!strict
-- Animates the rainbow variant: the colors of the parts of a rainbow dino keep moving around the
-- color circle. This only changes the colors on this client (nothing is sent), and only for the
-- few dinos nearest to the camera, so many rainbow dinos do not slow down a phone. The server
-- marks such a look with the attribute `Variant` = "rainbow" and gives it the first colors.
-- Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Variants = require(Shared:WaitForChild("Variants"))
local VariantConfig = require(Shared:WaitForChild("Config"):WaitForChild("Variants"))

-- The look model inside a character is called like this (see AppearanceService).
local LOOK_NAME = "DinoLook"
-- Seconds between two searches for rainbow dinos (the colors are updated every frame).
local SEARCH_SECONDS = 1

local VariantEffects = {}

type Entry = { model: Model, parts: { BasePart } }

function VariantEffects.start()
	local entries: { Entry } = {}
	local sinceSearch = SEARCH_SECONDS

	-- Finds the rainbow dinos among all characters in the world.
	local function search()
		local found: { Entry } = {}
		for _, container in workspace:GetChildren() do
			if container:IsA("Model") then
				local look = container:FindFirstChild(LOOK_NAME)
				if look ~= nil and look:IsA("Model") and look:GetAttribute("Variant") == "rainbow" then
					local parts: { BasePart } = {}
					for _, descendant in look:GetDescendants() do
						-- Eyes and dark details keep their colors (the server marks them).
						if descendant:IsA("BasePart") and descendant:GetAttribute("NoVariant") ~= true then
							table.insert(parts, descendant)
						end
					end
					table.insert(found, { model = look, parts = parts })
				end
			end
		end
		entries = found
	end

	RunService.RenderStepped:Connect(function(dt: number)
		sinceSearch += dt
		if sinceSearch >= SEARCH_SECONDS then
			sinceSearch = 0
			search()
		end
		if #entries == 0 then
			return
		end
		local camera = workspace.CurrentCamera
		if camera == nil then
			return
		end
		local cameraPosition = camera.CFrame.Position

		-- The nearest few within the distance get animated.
		local near: { { entry: Entry, distance: number } } = {}
		for _, entry in entries do
			if entry.model.Parent ~= nil then
				local distance = (entry.model:GetPivot().Position - cameraPosition).Magnitude
				if distance <= VariantConfig.rainbowMaxDistance then
					table.insert(near, { entry = entry, distance = distance })
				end
			end
		end
		table.sort(near, function(a, b)
			return a.distance < b.distance
		end)

		local offset = (os.clock() * VariantConfig.rainbowCyclesPerSecond) % 1
		for index = 1, math.min(#near, VariantConfig.rainbowMaxModels) do
			local parts = near[index].entry.parts
			local count = #parts
			for partIndex, part in parts do
				local color = Variants.rainbowColor(
					partIndex,
					count,
					offset,
					VariantConfig.rainbowSaturation,
					VariantConfig.rainbowValue
				)
				part.Color = Color3.fromRGB(color.r, color.g, color.b)
			end
		end
	end)
end

return VariantEffects
