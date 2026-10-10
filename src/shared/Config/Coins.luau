--!strict
-- Coins are earned by growing: every newly reached stage gives `perStageFactor * stage number`.
-- They are never bought with Robux. The upper limit is `maxCoins` in Config/Profile.

return {
	perStageFactor = 5,
}
