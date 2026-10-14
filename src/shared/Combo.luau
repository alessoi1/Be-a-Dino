--!strict
-- Pure rules of the eating combo: a piece eaten within the window of the last one raises the
-- count, otherwise the count starts again at 1. No Roblox services.

local Combo = {}

export type State = { count: number, lastAt: number }

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- The state after eating a piece at time `now` (the state before may be nil). Invalid input
-- starts a new combo of 1.
function Combo.bump(state: State?, now: number, windowSeconds: number): State
	if state == nil or not isFinite(now) or not isFinite(windowSeconds) or windowSeconds <= 0 then
		return { count = 1, lastAt = if isFinite(now) then now else 0 }
	end
	if now >= state.lastAt and now - state.lastAt <= windowSeconds then
		return { count = state.count + 1, lastAt = now }
	end
	return { count = 1, lastAt = now }
end

-- The count at time `now`: 0 when the window since the last piece has passed.
function Combo.current(state: State?, now: number, windowSeconds: number): number
	if state == nil or not isFinite(now) or not isFinite(windowSeconds) then
		return 0
	end
	if now - state.lastAt > windowSeconds then
		return 0
	end
	return state.count
end

return Combo
