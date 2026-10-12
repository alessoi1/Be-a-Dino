--!strict
-- Pure rules for the paid offers: which product is what, granting a purchase once (a repeated
-- receipt changes nothing), saved revives and bounties, and the running time of potions. The
-- functions change the profile table they are given. No Roblox services, no logging.

export type Config = {
	products: { [string]: number },
	potions: {
		[string]: { product: string, durationSeconds: number, effect: string, factor: number?, bonusSeconds: number? },
	},
	maxPotionSeconds: number,
	maxCredits: number,
	receiptMemory: number,
}

export type State = {
	-- Seconds left per potion id (counted down in the arena only).
	potionSeconds: { [string]: number },
	-- Saved revives and bounties per kind: "revive", "bounty".
	credits: { [string]: number },
	-- The most recent purchase ids, oldest first.
	receipts: { string },
}

-- What a product is: "revive", "bounty" or a potion (with its id).
export type Product = { kind: string, potionId: string? }

export type Outcome = "granted" | "duplicate" | "unknown_product"

local Offers = {}

Offers.CREDIT_KINDS = { revive = true, bounty = true }

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Which offer a Developer Product id belongs to, or nil when it is none of ours.
function Offers.productFor(config: Config, productId: number): Product?
	if not isFinite(productId) or productId <= 0 then
		return nil
	end
	if config.products.revive == productId then
		return { kind = "revive", potionId = nil }
	end
	if config.products.bounty == productId then
		return { kind = "bounty", potionId = nil }
	end
	for potionId, potion in config.potions do
		if config.products[potion.product] == productId then
			return { kind = "potion", potionId = potionId }
		end
	end
	return nil
end

function Offers.hasReceipt(state: State, purchaseId: string): boolean
	return table.find(state.receipts, purchaseId) ~= nil
end

-- Remembers a purchase id; the oldest ones are forgotten beyond `limit`.
function Offers.recordReceipt(state: State, purchaseId: string, limit: number)
	table.insert(state.receipts, purchaseId)
	while #state.receipts > limit do
		table.remove(state.receipts, 1)
	end
end

function Offers.credits(state: State, kind: string): number
	return state.credits[kind] or 0
end

-- Adds one saved revive or bounty (never above `maxCredits`). Returns whether it was added.
function Offers.addCredit(state: State, kind: string, maxCredits: number): boolean
	if Offers.CREDIT_KINDS[kind] ~= true then
		return false
	end
	local have = Offers.credits(state, kind)
	if have >= maxCredits then
		return false
	end
	state.credits[kind] = have + 1
	return true
end

-- Uses one saved credit. Returns false when there is none.
function Offers.takeCredit(state: State, kind: string): boolean
	local have = Offers.credits(state, kind)
	if have <= 0 then
		return false
	end
	if have == 1 then
		state.credits[kind] = nil
	else
		state.credits[kind] = have - 1
	end
	return true
end

-- Adds the time of one potion (never above `maxSeconds`). Returns the seconds now stored.
function Offers.addPotion(state: State, potionId: string, seconds: number, maxSeconds: number): number
	if not isFinite(seconds) or seconds <= 0 then
		return state.potionSeconds[potionId] or 0
	end
	local total = math.min((state.potionSeconds[potionId] or 0) + seconds, maxSeconds)
	state.potionSeconds[potionId] = total
	return total
end

function Offers.potionSeconds(state: State, potionId: string): number
	return state.potionSeconds[potionId] or 0
end

function Offers.potionActive(state: State, potionId: string): boolean
	return Offers.potionSeconds(state, potionId) > 0
end

-- Counts every potion down by `dt` seconds (time spent in the arena). Returns the ids that ran
-- out, in alphabetical order.
function Offers.tickPotions(state: State, dt: number): { string }
	local ended: { string } = {}
	if not isFinite(dt) or dt <= 0 then
		return ended
	end
	for potionId, left in state.potionSeconds do
		if left - dt <= 0 then
			table.insert(ended, potionId)
		else
			state.potionSeconds[potionId] = left - dt
		end
	end
	table.sort(ended)
	for _, potionId in ended do
		state.potionSeconds[potionId] = nil
	end
	return ended
end

-- The factor of a potion effect ("growth", "coin" or "speed"): the configured factor while a
-- potion with that effect runs, otherwise 1. Several potions of one effect do not stack.
function Offers.factor(state: State, config: Config, effect: string): number
	local best = 1
	for potionId, potion in config.potions do
		if potion.effect == effect and Offers.potionActive(state, potionId) then
			local factor = potion.factor
			if factor ~= nil and isFinite(factor) and factor > best then
				best = factor
			end
		end
	end
	return best
end

-- Extra seconds of spawn protection while a shield potion runs, otherwise 0.
function Offers.shieldBonus(state: State, config: Config): number
	local best = 0
	for potionId, potion in config.potions do
		if potion.effect == "shield" and Offers.potionActive(state, potionId) then
			local bonus = potion.bonusSeconds
			if bonus ~= nil and isFinite(bonus) and bonus > best then
				best = bonus
			end
		end
	end
	return best
end

-- Grants a purchase: remembers the purchase id and gives a credit (revive, bounty) or potion
-- time. A purchase id seen before is "duplicate" and changes nothing, so a repeated receipt never
-- gives twice. A revive or bounty above the saved limit still counts as granted (it is not lost
-- silently: the credit stays at the limit and the caller logs it).
function Offers.grant(state: State, config: Config, productId: number, purchaseId: string): (Outcome, Product?)
	local product = Offers.productFor(config, productId)
	if product == nil then
		return "unknown_product", nil
	end
	if type(purchaseId) ~= "string" or purchaseId == "" then
		return "unknown_product", nil
	end
	if Offers.hasReceipt(state, purchaseId) then
		return "duplicate", product
	end
	if product.kind == "potion" and product.potionId ~= nil then
		local potion = config.potions[product.potionId]
		Offers.addPotion(state, product.potionId, potion.durationSeconds, config.maxPotionSeconds)
	else
		Offers.addCredit(state, product.kind, config.maxCredits)
	end
	Offers.recordReceipt(state, purchaseId, config.receiptMemory)
	return "granted", product
end

-- "growth=540,coin=120": the seconds left (rounded up) of the running potions, in the given
-- order. The server publishes it as an attribute for the display.
function Offers.encodePotions(state: State, order: { string }): string
	local parts: { string } = {}
	for _, potionId in order do
		local left = Offers.potionSeconds(state, potionId)
		if left > 0 then
			table.insert(parts, potionId .. "=" .. string.format("%d", math.ceil(left)))
		end
	end
	return table.concat(parts, ",")
end

-- The reverse of encodePotions: potion id -> seconds left. Junk entries are skipped.
function Offers.decodePotions(text: string): { [string]: number }
	local result: { [string]: number } = {}
	if type(text) ~= "string" then
		return result
	end
	for potionId, seconds in string.gmatch(text, "([a-z0-9]+)=(%d+)") do
		local value = tonumber(seconds)
		if value ~= nil and value > 0 then
			result[potionId] = value
		end
	end
	return result
end

-- Returns a list of problems (empty when the config is usable).
function Offers.validate(config: Config): { string }
	local errors: { string } = {}
	local seen: { [number]: string } = {}
	for key, id in config.products do
		if not isFinite(id) or id <= 0 or id % 1 ~= 0 then
			table.insert(errors, "product " .. key .. " needs a whole product id above 0")
		elseif seen[id] ~= nil then
			table.insert(errors, "product " .. key .. " has the same id as " .. seen[id])
		else
			seen[id] = key
		end
	end
	for _, key in { "revive", "bounty" } do
		if config.products[key] == nil then
			table.insert(errors, "missing product " .. key)
		end
	end
	for potionId, potion in config.potions do
		if config.products[potion.product] == nil then
			table.insert(errors, "potion " .. potionId .. " has no product " .. potion.product)
		end
		if not isFinite(potion.durationSeconds) or potion.durationSeconds <= 0 then
			table.insert(errors, "potion " .. potionId .. " needs a duration above 0")
		end
		if potion.effect == "shield" then
			if potion.bonusSeconds == nil or not isFinite(potion.bonusSeconds) or potion.bonusSeconds <= 0 then
				table.insert(errors, "potion " .. potionId .. " needs bonusSeconds above 0")
			end
		elseif potion.effect == "growth" or potion.effect == "coin" or potion.effect == "speed" then
			if potion.factor == nil or not isFinite(potion.factor) or potion.factor <= 1 then
				table.insert(errors, "potion " .. potionId .. " needs a factor above 1")
			end
		else
			table.insert(errors, "potion " .. potionId .. " has an unknown effect")
		end
	end
	if not isFinite(config.maxPotionSeconds) or config.maxPotionSeconds <= 0 then
		table.insert(errors, "maxPotionSeconds must be above 0")
	end
	if not isFinite(config.maxCredits) or config.maxCredits < 1 then
		table.insert(errors, "maxCredits must be at least 1")
	end
	if not isFinite(config.receiptMemory) or config.receiptMemory < 1 then
		table.insert(errors, "receiptMemory must be at least 1")
	end
	return errors
end

return Offers
