--!strict
-- Pure bounty rules. The state is a table from the id of a marked player to the server time at
-- which the bounty ends. The functions change that table. No Roblox services, no logging.

export type State = { [number]: number }

local Bounty = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Puts a bounty on a player for `duration` seconds. A second one renews the time instead of
-- stacking. Returns true when the player was not marked before, false when it was renewed or
-- the input is invalid.
function Bounty.place(state: State, targetId: number, now: number, duration: number): boolean
	if not isFinite(targetId) or not isFinite(now) or not isFinite(duration) or duration <= 0 then
		return false
	end
	local wasMarked = state[targetId] ~= nil and state[targetId] > now
	state[targetId] = now + duration
	return not wasMarked
end

function Bounty.isActive(state: State, targetId: number, now: number): boolean
	local endsAt = state[targetId]
	return endsAt ~= nil and now < endsAt
end

-- The multiplier for eating this player: `multiplier` while a bounty is active, otherwise 1.
function Bounty.multiplierFor(state: State, targetId: number, now: number, multiplier: number): number
	if Bounty.isActive(state, targetId, now) and isFinite(multiplier) and multiplier > 1 then
		return multiplier
	end
	return 1
end

-- Takes the bounty away because the player was eaten. Returns whether it was active.
function Bounty.claim(state: State, targetId: number, now: number): boolean
	local active = Bounty.isActive(state, targetId, now)
	state[targetId] = nil
	return active
end

function Bounty.clear(state: State, targetId: number)
	state[targetId] = nil
end

-- Removes the bounties that ended and returns their player ids.
function Bounty.sweep(state: State, now: number): { number }
	local ended: { number } = {}
	for targetId, endsAt in state do
		if now >= endsAt then
			table.insert(ended, targetId)
		end
	end
	for _, targetId in ended do
		state[targetId] = nil
	end
	return ended
end

return Bounty
