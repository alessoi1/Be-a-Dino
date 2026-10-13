--!strict
-- Pure logic of the menu bar in the lobby: which window a tap opens or closes, and whether a window
-- is shown. A window is shown while the player stands in its circle, or when it was opened with
-- the bar. No Roblox services, no logging.

local MenuBar = {}

-- The window that is open after a tap on the button `id`: tapping the open window closes it, tapping
-- another one switches to it, an unknown id changes nothing.
function MenuBar.toggle(current: string?, id: string, known: { string }): string?
	if table.find(known, id) == nil then
		return current
	end
	if current == id then
		return nil
	end
	return id
end

-- Whether the window `id` is shown: the player stands in its circle (`zoneId`, anything that is not
-- a string counts as no circle), or `open` (from the bar) is this window.
function MenuBar.visible(zoneId: any, open: string?, id: string): boolean
	return zoneId == id or open == id
end

-- Returns a list of problems (empty when the entries are usable): ids must be unique, not empty,
-- and every entry needs an icon name.
function MenuBar.validate(entries: { { id: string, icon: string } }): { string }
	local errors: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, entry in entries do
		if entry.id == "" then
			table.insert(errors, "an entry has no id")
		elseif seen[entry.id] then
			table.insert(errors, "duplicate id " .. entry.id)
		end
		seen[entry.id] = true
		if entry.icon == "" then
			table.insert(errors, "no icon for " .. entry.id)
		end
	end
	return errors
end

return MenuBar
