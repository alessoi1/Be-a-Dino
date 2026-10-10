--!strict
-- Pure data structure for the food on the arena floor (positions on the ground
-- plane). The server asks it which pieces are within reach of a player.
-- No Roblox services, no logging.

export type Item = { id: number, x: number, z: number, kind: number }

export type Field = {
	items: { [number]: Item },
	count: number,
}

export type Config = {
	pickupBase: number,
	pickupPerScale: number,
}

local FoodField = {}

function FoodField.new(): Field
	return { items = {}, count = 0 }
end

function FoodField.count(field: Field): number
	return field.count
end

-- Returns false when the id is already in use.
function FoodField.place(field: Field, id: number, x: number, z: number, kind: number): boolean
	if field.items[id] ~= nil then
		return false
	end
	field.items[id] = { id = id, x = x, z = z, kind = kind }
	field.count += 1
	return true
end

-- Returns the removed item, or nil when there was none.
function FoodField.remove(field: Field, id: number): Item?
	local item = field.items[id]
	if item == nil then
		return nil
	end
	field.items[id] = nil
	field.count -= 1
	return item
end

-- All pieces within `radius` (border included), nearest first, ties by id.
function FoodField.inRange(field: Field, x: number, z: number, radius: number): { Item }
	local found: { Item } = {}
	if radius ~= radius or radius < 0 then
		return found
	end
	local radiusSquared = radius * radius
	local distances: { [number]: number } = {}
	for _, item in field.items do
		local dx = item.x - x
		local dz = item.z - z
		local distanceSquared = dx * dx + dz * dz
		if distanceSquared <= radiusSquared then
			table.insert(found, item)
			distances[item.id] = distanceSquared
		end
	end
	table.sort(found, function(a: Item, b: Item): boolean
		local da = distances[a.id]
		local db = distances[b.id]
		if da ~= db then
			return da < db
		end
		return a.id < b.id
	end)
	return found
end

-- Pickup radius for a dino of the given scale. An invalid scale gives the base radius.
function FoodField.pickupRadius(config: Config, scale: number): number
	if scale ~= scale or scale < 0 then
		return config.pickupBase
	end
	return config.pickupBase + config.pickupPerScale * scale
end

return FoodField
