--!strict
-- The name tags above the dinos: the name and the size (points) of every player in the arena and
-- every bot. The tags are made on this device only (nothing is replicated); the layout (size,
-- height, range, fading) is NameTag.layout. Reads the player attributes `Mode`, `Points`, `Scale`
-- and, for bots, the model attribute `Points` and the humanoid display name. Display only.
-- Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local NameTag = require(Shared:WaitForChild("NameTag"))
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local TagConfig = require(Shared:WaitForChild("Config"):WaitForChild("NameTags"))

local TAG_NAME = "NameTag"
local BOTS_FOLDER = "Bots"

local log = Log.new("NameTags")

type Views = { gui: BillboardGui, name: TextLabel, size: TextLabel }

-- One tag per dino model; it disappears with the model (weak keys, so nothing is kept alive).
local tags: { [Model]: Views } = setmetatable({}, { __mode = "k" }) :: any

local NameTags = {}

local function color(value: { r: number, g: number, b: number }): Color3
	return Color3.fromRGB(value.r, value.g, value.b)
end

local function newLabel(parent: Instance, name: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextScaled = true
	label.TextStrokeTransparency = TagConfig.strokeTransparency
	label.Parent = parent
	return label
end

local function newTag(model: Model, root: BasePart): Views
	local gui = Instance.new("BillboardGui")
	gui.Name = TAG_NAME
	gui.Adornee = root
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.AlwaysOnTop = false
	gui.Enabled = false
	gui.Parent = root

	local name = newLabel(gui, "Name")
	name.Position = UDim2.fromScale(0, 0)
	name.Size = UDim2.fromScale(1, TagConfig.nameShare)
	local size = newLabel(gui, "Size")
	size.Position = UDim2.fromScale(0, TagConfig.nameShare)
	size.Size = UDim2.fromScale(1, 1 - TagConfig.nameShare)
	size.TextColor3 = color(TagConfig.sizeColor)

	local views = { gui = gui, name = name, size = size }
	tags[model] = views
	return views
end

-- Shows or updates the tag of one dino. `label` is the name, `points` the size, `isSelf` colors the
-- own tag.
local function show(
	model: Model,
	label: string,
	points: number,
	scale: number,
	isSelf: boolean,
	cameraPosition: Vector3
)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	local views = tags[model]
	if views == nil or views.gui.Parent == nil then
		views = newTag(model, root)
	end
	-- The tag floats right above the highest point of the dino (its real look, tail and neck included).
	local top: number? = nil
	local look = model:FindFirstChild("DinoLook")
	if look ~= nil and look:IsA("Model") then
		local boxCFrame, boxSize = look:GetBoundingBox()
		top = boxCFrame.Position.Y + boxSize.Y / 2 - root.Position.Y
	end
	local layout = NameTag.layout(TagConfig, scale, (root.Position - cameraPosition).Magnitude, top)
	views.gui.Enabled = layout.visible
	if not layout.visible then
		return
	end
	views.gui.Size = UDim2.fromScale(layout.width, layout.height)
	views.gui.StudsOffset = Vector3.new(0, layout.offsetY, 0)
	views.name.Text = label
	views.name.TextColor3 = if isSelf then color(TagConfig.selfColor) else color(TagConfig.otherColor)
	views.name.TextTransparency = layout.transparency
	views.name.TextStrokeTransparency = TagConfig.strokeTransparency
		+ (1 - TagConfig.strokeTransparency) * layout.transparency
	views.size.Text = NumberFormat.compact(points)
	views.size.TextTransparency = layout.transparency
	views.size.TextStrokeTransparency = views.name.TextStrokeTransparency
end

local function numberOr(value: any, fallback: number): number
	return if typeof(value) == "number" then value else fallback
end

local function refresh()
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end
	local cameraPosition = camera.CFrame.Position
	local localPlayer = Players.LocalPlayer

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local playing = player:GetAttribute("Mode") == "playing"
		if character ~= nil and (playing or not TagConfig.hideInLobby) then
			show(
				character,
				player.DisplayName,
				numberOr(player:GetAttribute("Points"), 0),
				numberOr(player:GetAttribute("Scale"), character:GetScale()),
				player == localPlayer,
				cameraPosition
			)
		elseif character ~= nil then
			local views = tags[character]
			if views ~= nil then
				views.gui.Enabled = false
			end
		end
	end

	local bots = workspace:FindFirstChild(BOTS_FOLDER)
	if bots ~= nil then
		for _, model in bots:GetChildren() do
			if model:IsA("Model") then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid ~= nil then
					show(
						model,
						humanoid.DisplayName,
						numberOr(model:GetAttribute("Points"), 0),
						model:GetScale(),
						false,
						cameraPosition
					)
				end
			end
		end
	end
end

function NameTags.start()
	local sinceRefresh = 0
	RunService.Heartbeat:Connect(function(dt: number)
		sinceRefresh += dt
		if sinceRefresh < TagConfig.updateInterval then
			return
		end
		sinceRefresh = 0
		local ok, err = pcall(refresh)
		if not ok then
			log.error("name tag refresh failed", { error = tostring(err) })
		end
	end)
	log.info("started")
end

return NameTags
