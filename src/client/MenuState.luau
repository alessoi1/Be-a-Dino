--!strict
-- Which window the menu bar has opened (nil = none). The windows of the shop, the dinodex and the
-- boosters listen to it next to the circles. Closed again when the player is not in the lobby.
-- Display only: the server never trusts or needs it. Only checkable in Roblox Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MenuBar = require(Shared:WaitForChild("MenuBar"))
local MenuConfig = require(Shared:WaitForChild("Config"):WaitForChild("Menu"))

local MenuState = {}

local known: { string } = {}
for _, entry in MenuConfig.entries do
	table.insert(known, entry.id)
end

local current: string? = nil
local changedEvent = Instance.new("BindableEvent")

MenuState.changed = changedEvent.Event

-- Windows that are not part of the menu bar (the daily gift, the quests) but also cover the lobby.
-- They register here, so the lobby hint can step aside while any of them is open.
local overlays: { GuiObject } = {}

function MenuState.registerOverlay(window: GuiObject)
	table.insert(overlays, window)
end

-- True while a registered window is visible.
function MenuState.overlayOpen(): boolean
	for _, window in overlays do
		if window.Visible then
			return true
		end
	end
	return false
end

function MenuState.get(): string?
	return current
end

local function set(value: string?)
	if value == current then
		return
	end
	current = value
	changedEvent:Fire()
end

-- A tap on the button of window `id`.
function MenuState.toggle(id: string)
	set(MenuBar.toggle(current, id, known))
end

function MenuState.close()
	set(nil)
end

local player = Players.LocalPlayer
player:GetAttributeChangedSignal("Mode"):Connect(function()
	if player:GetAttribute("Mode") ~= "lobby" then
		set(nil)
	end
end)

return MenuState
