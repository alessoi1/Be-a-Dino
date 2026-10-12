--!strict
-- The dino egg in the shop: bought with coins, it gives one variant (glowing, gold, shadow or
-- rainbow) for a random dino the player has already reached. Coins are earned by playing and are
-- never bought with Robux. All chances are shown to the player as percentages. Starting values.

return {
	-- Coins one egg costs.
	price = 200,
	-- Relative chance of each variant by id (see Config/Variants). They are shown as percentages.
	weights = { glowing = 70, gold = 22, shadow = 6, rainbow = 2 },
	-- A variant the player already has gives back this share of the price (0.5 = half).
	duplicateRefundShare = 0.5,
	-- Minimum seconds between two eggs of one player.
	cooldownSeconds = 1,
}
