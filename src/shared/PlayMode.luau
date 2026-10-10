--!strict
-- Pure rules for the two modes of a player: in the lobby (safe) or playing in the arena.
-- No Roblox services, no logging.

export type Mode = "lobby" | "playing"

export type Reason = "full" | "invalid"

local PlayMode = {}

-- Whether another player may enter the arena. `playingCount` is how many are in it now.
function PlayMode.canEnter(playingCount: number, maxPlaying: number): (boolean, Reason?)
	if
		type(playingCount) ~= "number"
		or playingCount ~= playingCount
		or playingCount < 0
		or type(maxPlaying) ~= "number"
		or maxPlaying ~= maxPlaying
	then
		return false, "invalid"
	end
	if playingCount >= maxPlaying then
		return false, "full"
	end
	return true, nil
end

-- Lobby to playing and back are allowed; staying in the same mode is not a change.
function PlayMode.canTransition(from: Mode, to: Mode): boolean
	return (from == "lobby" and to == "playing") or (from == "playing" and to == "lobby")
end

-- How many entries of a mode table are playing.
function PlayMode.countPlaying(modes: { [any]: Mode }): number
	local count = 0
	for _, mode in modes do
		if mode == "playing" then
			count += 1
		end
	end
	return count
end

return PlayMode
