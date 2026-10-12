--!strict
-- Pure rules for the global leaderboards: the number of a player for a list, whether it needs to
-- be written, and how the raw entries of a sorted DataStore become the rows of a board.
-- No Roblox services, no logging.

export type Raw = { key: string, value: number }

export type Row = { rank: number, userId: number, value: number }

-- What the profile holds (a structural copy, so this module needs no requires).
type Data = { kills: number, bestPoints: number, playSeconds: number }

local GlobalBoard = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- The whole number of a player for the list `categoryId` ("kills", "size" = the best size ever,
-- "time" = seconds in the arena), between 0 and `max`. Unknown lists and bad data give 0.
function GlobalBoard.valueFor(categoryId: string, data: Data, max: number): number
	local raw: any = nil
	if categoryId == "kills" then
		raw = data.kills
	elseif categoryId == "size" then
		raw = data.bestPoints
	elseif categoryId == "time" then
		raw = data.playSeconds
	end
	if not isFinite(raw) or raw <= 0 then
		return 0
	end
	return math.min(max, math.floor(raw))
end

-- Only write a number that is above 0 and different from the one written last. (The numbers
-- only grow, so a different one is a higher one.)
function GlobalBoard.shouldWrite(lastWritten: number?, current: number): boolean
	if not isFinite(current) or current <= 0 then
		return false
	end
	return lastWritten == nil or current ~= lastWritten
end

-- The best `limit` rows of the raw entries (key = user id as text). Entries with an invalid
-- key or a value that is not above 0 are dropped, a user appears once (with the higher value),
-- and a tie is decided by the smaller user id.
function GlobalBoard.rows(raw: { Raw }, limit: number): { Row }
	local best: { [number]: number } = {}
	for _, entry in raw do
		local userId = tonumber(entry.key)
		if
			userId ~= nil
			and isFinite(userId)
			and userId >= 1
			and userId % 1 == 0
			and isFinite(entry.value)
			and entry.value > 0
		then
			local value = math.floor(entry.value)
			if best[userId] == nil or value > best[userId] then
				best[userId] = value
			end
		end
	end

	local rows: { Row } = {}
	for userId, value in best do
		table.insert(rows, { rank = 0, userId = userId, value = value })
	end
	table.sort(rows, function(a: Row, b: Row): boolean
		if a.value ~= b.value then
			return a.value > b.value
		end
		return a.userId < b.userId
	end)

	local limited: { Row } = {}
	for index, row in rows do
		if index > limit then
			break
		end
		row.rank = index
		table.insert(limited, row)
	end
	return limited
end

return GlobalBoard
