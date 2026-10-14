--!strict
-- Pure rules of the daily quests: which quests are active on a day, how progress is recorded and
-- when a quest can be claimed. The state is saved in the profile. No Roblox services.

local Quests = {}

export type Quest = { id: string, kind: string, target: number, coins: number }
export type State = { day: number, progress: { [string]: number }, claimed: { [string]: boolean } }
export type View = { id: string, progress: number, target: number, coins: number, claimed: boolean }

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Quests.new(day: number): State
	return { day = day, progress = {}, claimed = {} }
end

-- The quests of a day: `count` entries of the pool, moving on by `count` each day so that every
-- quest comes up. The same day always gives the same quests (the pool order is the rotation).
function Quests.pick(day: number, pool: { Quest }, count: number): { Quest }
	local picked: { Quest } = {}
	local size = #pool
	if size == 0 or not isFinite(day) or not isFinite(count) or count < 1 then
		return picked
	end
	local amount = math.min(math.floor(count), size)
	local start = (math.max(0, math.floor(day)) * amount) % size
	for offset = 0, amount - 1 do
		table.insert(picked, pool[(start + offset) % size + 1])
	end
	return picked
end

-- The state for `day`: the given one when it is from the same day, otherwise a fresh one.
function Quests.sync(state: State?, day: number): State
	if state ~= nil and state.day == day then
		return state
	end
	return Quests.new(day)
end

-- Records `amount` for all quests of this kind. The "combo" kind keeps the best value instead of
-- adding. Progress never goes above the target. Returns true when something changed.
function Quests.record(state: State, quests: { Quest }, kind: string, amount: number): boolean
	if not isFinite(amount) or amount <= 0 then
		return false
	end
	local changed = false
	for _, quest in quests do
		if quest.kind == kind and state.claimed[quest.id] ~= true then
			local current = state.progress[quest.id] or 0
			local updated = if kind == "combo" then math.max(current, amount) else current + amount
			updated = math.min(updated, quest.target)
			if updated ~= current then
				state.progress[quest.id] = updated
				changed = true
			end
		end
	end
	return changed
end

function Quests.isDone(state: State, quest: Quest): boolean
	return (state.progress[quest.id] or 0) >= quest.target
end

-- True when the goal is reached and the coins were not taken yet.
function Quests.canClaim(state: State, quest: Quest): boolean
	return Quests.isDone(state, quest) and state.claimed[quest.id] ~= true
end

-- Marks the quest as claimed and returns its coins (0 when it cannot be claimed).
function Quests.claim(state: State, quest: Quest): number
	if not Quests.canClaim(state, quest) then
		return 0
	end
	state.claimed[quest.id] = true
	return quest.coins
end

-- Text for the client: one entry "id,progress,target,coins,claimed" per quest, joined by ";".
function Quests.encode(state: State, quests: { Quest }): string
	local parts: { string } = {}
	for _, quest in quests do
		table.insert(
			parts,
			string.format(
				"%s,%d,%d,%d,%d",
				quest.id,
				state.progress[quest.id] or 0,
				quest.target,
				quest.coins,
				if state.claimed[quest.id] == true then 1 else 0
			)
		)
	end
	return table.concat(parts, ";")
end

-- The reverse of encode. Junk entries are skipped.
function Quests.decode(text: string): { View }
	local views: { View } = {}
	for entry in string.gmatch(text, "[^;]+") do
		local id, progress, target, coins, claimed = string.match(entry, "^([%w_]+),(%d+),(%d+),(%d+),([01])$")
		if id ~= nil then
			table.insert(views, {
				id = id,
				progress = tonumber(progress) :: number,
				target = tonumber(target) :: number,
				coins = tonumber(coins) :: number,
				claimed = claimed == "1",
			})
		end
	end
	return views
end

-- Problems of the pool (empty when fine).
function Quests.validate(pool: { Quest }, perDay: number): { string }
	local errors: { string } = {}
	local seen: { [string]: boolean } = {}
	local kinds = { food = true, kill = true, grow = true, combo = true, play = true }
	for _, quest in pool do
		if string.match(quest.id, "^[%w_]+$") == nil then
			table.insert(errors, "quest id must be letters, digits or underscore: " .. quest.id)
		end
		if seen[quest.id] then
			table.insert(errors, "duplicate quest id " .. quest.id)
		end
		seen[quest.id] = true
		if not kinds[quest.kind] then
			table.insert(errors, "unknown kind for " .. quest.id)
		end
		if not isFinite(quest.target) or quest.target < 1 or quest.target % 1 ~= 0 then
			table.insert(errors, "target must be a whole number above 0 for " .. quest.id)
		end
		if not isFinite(quest.coins) or quest.coins < 1 or quest.coins % 1 ~= 0 then
			table.insert(errors, "coins must be a whole number above 0 for " .. quest.id)
		end
	end
	if perDay < 1 or perDay > #pool then
		table.insert(errors, "perDay must be between 1 and the pool size")
	end
	return errors
end

return Quests
