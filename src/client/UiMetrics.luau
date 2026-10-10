--!strict
-- Screen-size dependent values for the interface (scale, touch button size).
-- The math is in UiLayout (tested); this module only reads the viewport.
-- Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UiLayout = require(Shared:WaitForChild("UiLayout"))
local Ui = require(Shared:WaitForChild("Config"):WaitForChild("Ui"))

-- Used until a camera exists: a typical phone in portrait.
local FALLBACK_VIEWPORT = Vector2.new(390, 844)

local UiMetrics = {}

local function viewport(): Vector2
	local camera = workspace.CurrentCamera
	if camera == nil then
		return FALLBACK_VIEWPORT
	end
	return camera.ViewportSize
end

function UiMetrics.scale(): number
	local size = viewport()
	return UiLayout.scaleFor(Ui, size.X, size.Y)
end

function UiMetrics.buttonSize(): number
	local size = viewport()
	return UiLayout.buttonSize(Ui, size.X, size.Y)
end

-- Calls `callback` now and whenever the screen size changes.
function UiMetrics.watch(callback: () -> ())
	callback()
	local connection: RBXScriptConnection? = nil
	local function bind()
		if connection ~= nil then
			connection:Disconnect()
		end
		local camera = workspace.CurrentCamera
		if camera ~= nil then
			connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(callback)
		end
		callback()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bind)
	bind()
end

return UiMetrics
