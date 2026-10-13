--!strict
-- The menu bar in the lobby: one button per window that is otherwise opened by walking into a circle
-- (the ids are the zone ids of Config/Lobby; the label comes from Strings.lobby.zones, the icon from
-- Config/Icons).

export type Entry = { id: string, icon: string }

local entries: { Entry } = {
	{ id = "shop", icon = "shop" },
	{ id = "dex", icon = "dex" },
	{ id = "boost", icon = "boost" },
}

return {
	entries = entries,
	-- Distance of the bar to the right screen edge (base pixels) and gap between two buttons.
	margin = 12,
	gap = 10,
}
