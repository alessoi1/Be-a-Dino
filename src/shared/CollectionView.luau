--!strict
-- Pure helpers for the collection menu: the reached dinos as a short text (the server
-- publishes it as a player attribute) and the cards the menu shows. Display only.
-- No Roblox services, no logging.

type Stage = { id: string, minPoints: number }

export type Card = { index: number, id: string, reached: boolean, minPoints: number }

local CollectionView = {}

-- Most entries decodeReached keeps (guards against junk text).
CollectionView.MAX_ENTRIES = 64

-- Known stages the player has reached, in stage order, separated by commas.
function CollectionView.encodeReached(reached: { [string]: boolean }, stages: { Stage }): string
	local ids: { string } = {}
	for _, stage in stages do
		if reached[stage.id] == true then
			table.insert(ids, stage.id)
		end
	end
	return table.concat(ids, ",")
end

-- Reads the text again. Only ids made of lowercase letters, digits and underscores count.
function CollectionView.decodeReached(text: string): { [string]: boolean }
	local set: { [string]: boolean } = {}
	if type(text) ~= "string" then
		return set
	end
	local count = 0
	for part in string.gmatch(text, "[^,]+") do
		if string.match(part, "^[a-z0-9_]+$") ~= nil and not set[part] then
			set[part] = true
			count += 1
			if count >= CollectionView.MAX_ENTRIES then
				break
			end
		end
	end
	return set
end

-- One card per stage, in stage order.
function CollectionView.cards(stages: { Stage }, reached: { [string]: boolean }): { Card }
	local cards: { Card } = {}
	for index, stage in stages do
		table.insert(cards, {
			index = index,
			id = stage.id,
			reached = reached[stage.id] == true,
			minPoints = stage.minPoints,
		})
	end
	return cards
end

-- Number of reached cards and the number of all cards.
function CollectionView.summary(cards: { Card }): (number, number)
	local reached = 0
	for _, card in cards do
		if card.reached then
			reached += 1
		end
	end
	return reached, #cards
end

return CollectionView
