--!strict
-- Pure rule for the way back to the lobby: the player has to stand still for a number of
-- seconds. The position at the start is the anchor; moving farther than the radius from it
-- (also up or down) cancels the wait. No Roblox services, no logging.

export type Position = { x: number, y: number, z: number }
export type State = { anchor: Position, startedAt: number }
export type Status = "waiting" | "done" | "moved"

local LeaveWait = {}

function LeaveWait.start(position: Position, now: number): State
	return { anchor = { x = position.x, y = position.y, z = position.z }, startedAt = now }
end

-- Seconds still to wait (never below zero).
function LeaveWait.remaining(state: State, now: number, seconds: number): number
	return math.max(0, state.startedAt + seconds - now)
end

-- Checks one moment. Returns the state to keep (nil when the wait is over) and what happened:
-- "waiting" (keep the state), "done" (stood still long enough) or "moved" (cancelled).
function LeaveWait.step(
	state: State,
	position: Position,
	now: number,
	radius: number,
	seconds: number
): (State?, Status)
	local dx = position.x - state.anchor.x
	local dy = position.y - state.anchor.y
	local dz = position.z - state.anchor.z
	local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
	-- NaN fails this comparison too, so bad positions cancel.
	if not (distance <= radius) then
		return nil, "moved"
	end
	if LeaveWait.remaining(state, now, seconds) <= 0 then
		return nil, "done"
	end
	return state, "waiting"
end

return LeaveWait
