--!strict
-- Values for the Studio-only debug helper. Never active on live servers.

return {
	-- Share of the way to the next stage that one press of the debug grow key adds (0.25 = a
	-- quarter). Points would not do: the stages are far apart.
	growFraction = 0.25,
}
