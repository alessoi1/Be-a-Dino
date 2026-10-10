--!strict
-- Pure leaderboard ranking. The client builds the entries from the points the server
-- publishes (display only). No Roblox services, no logging.

export type Entry = { id: number, name: string, points: number, stageId: string }

export type Row = { rank: number, id: number, name: string, points: number, stageId: string, isOwn: boolean }

local Leaderboard = {}

local function cleanPoints(points: number): number
	if points ~= points or points < 0 or points == math.huge then
		return 0
	end
	return points
end

-- The top `limit` entries by points (ties by id). When the player `ownId` is not among
-- them, their own row follows with the real rank.
function Leaderboard.rank(entries: { Entry }, limit: number, ownId: number?): { Row }
	local sorted: { Entry } = {}
	for _, entry in entries do
		table.insert(sorted, {
			id = entry.id,
			name = entry.name,
			points = cleanPoints(entry.points),
			stageId = entry.stageId,
		})
	end
	table.sort(sorted, function(a: Entry, b: Entry): boolean
		if a.points ~= b.points then
			return a.points > b.points
		end
		return a.id < b.id
	end)

	local rows: { Row } = {}
	local ownInTop = false
	for index, entry in sorted do
		local isOwn = entry.id == ownId
		if index <= limit then
			table.insert(rows, {
				rank = index,
				id = entry.id,
				name = entry.name,
				points = entry.points,
				stageId = entry.stageId,
				isOwn = isOwn,
			})
			ownInTop = ownInTop or isOwn
		elseif isOwn and not ownInTop then
			table.insert(rows, {
				rank = index,
				id = entry.id,
				name = entry.name,
				points = entry.points,
				stageId = entry.stageId,
				isOwn = true,
			})
		end
	end
	return rows
end

return Leaderboard
