--!strict
-- Coins are earned by growing (every newly reached stage gives `perStageFactor * stage number`)
-- and by eating other players (`perKillFactor * stage number of the one who was eaten`, more
-- with a bounty, see Config/Bounty). They are never bought with Robux. The upper limit is
-- `maxCoins` in Config/Profile.

return {
	perStageFactor = 5,
	perKillFactor = 1,
}
