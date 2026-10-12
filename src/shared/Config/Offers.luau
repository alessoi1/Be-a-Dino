--!strict
-- The paid offers (Developer Products). The ids come from the Creator Hub (Monetization,
-- Developer Products); they are no secrets. The prices are set there, not here. Everything here
-- is a starting value. Potions only run while the player is in the arena.

export type Potion = {
	-- Key of the product in `products`.
	product: string,
	-- Seconds in the arena one potion gives (more potions add up).
	durationSeconds: number,
	-- "growth": food points times `factor`; "coin": coins times `factor`; "speed": walk speed
	-- times `factor`; "shield": `bonusSeconds` more spawn protection after a start.
	effect: string,
	factor: number?,
	bonusSeconds: number?,
}

return {
	products = {
		revive = 3718119522,
		bounty = 3718119654,
		growthPotion = 3718119706,
		coinPotion = 3718119751,
		speedPotion = 3718119799,
		shieldPotion = 3718119863,
	},
	potions = {
		growth = { product = "growthPotion", durationSeconds = 600, effect = "growth", factor = 2 },
		coin = { product = "coinPotion", durationSeconds = 600, effect = "coin", factor = 2 },
		speed = { product = "speedPotion", durationSeconds = 600, effect = "speed", factor = 1.15 },
		shield = { product = "shieldPotion", durationSeconds = 600, effect = "shield", bonusSeconds = 5 },
	} :: { [string]: Potion },
	-- Order of the potions in the window.
	potionOrder = { "growth", "coin", "speed", "shield" },
	-- Most seconds of one potion a player can store.
	maxPotionSeconds = 3600,
	-- Most saved revives (and saved bounties) a player can hold when they could not be used at once.
	maxCredits = 3,
	-- How many purchase ids the profile remembers (a repeated receipt is then not granted again).
	receiptMemory = 100,
	-- Minimum seconds between two purchase prompts of one player.
	promptCooldownSeconds = 3,
}
