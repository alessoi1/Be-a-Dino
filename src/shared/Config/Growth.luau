--!strict
-- Values for how growth is shown on the character.

return {
	-- The character scale is only applied again when it changed by at least this much
	-- (scale units), so eating a piece of food does not rescale the model every time.
	scaleApplyStep = 0.02,
}
