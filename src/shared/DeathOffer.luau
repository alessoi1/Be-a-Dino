--!strict
-- Pure rules for the window after a player was eaten: who ate them, until when they can choose,
-- and which choices are allowed. No Roblox services, no logging.

-- `points` are the points the player had when they were eaten (a revive gives them back).
export type Offer = { killerId: number, killerName: string, expiresAt: number, used: boolean, points: number }

export type Reason = "no_offer" | "expired" | "used" | "bad_choice" | "unavailable"

local DeathOffer = {}

DeathOffer.CHOICES = { revive = true, bounty = true, lobby = true }

function DeathOffer.open(now: number, seconds: number, killerId: number, killerName: string, points: number): Offer
	return {
		killerId = killerId,
		killerName = killerName,
		expiresAt = now + seconds,
		used = false,
		points = if points == points and points > 0 and points ~= math.huge then points else 0,
	}
end

-- Seconds left to choose (0 when there is no offer, it is used up or over).
function DeathOffer.remaining(offer: Offer?, now: number): number
	if offer == nil or offer.used then
		return 0
	end
	return math.max(0, offer.expiresAt - now)
end

function DeathOffer.isOpen(offer: Offer?, now: number): boolean
	return DeathOffer.remaining(offer, now) > 0
end

-- Whether the player may take this choice now. `available` says which choices exist at all
-- (for example nothing paid while the player has no profile to save it in). Returns true, or false with the reason.
function DeathOffer.check(offer: Offer?, choice: any, now: number, available: { [string]: boolean }): (boolean, Reason?)
	if type(choice) ~= "string" or DeathOffer.CHOICES[choice] ~= true then
		return false, "bad_choice"
	end
	if offer == nil then
		return false, "no_offer"
	end
	if offer.used then
		return false, "used"
	end
	if now >= offer.expiresAt then
		return false, "expired"
	end
	if available[choice] ~= true then
		return false, "unavailable"
	end
	return true, nil
end

-- A copy of the offer that is used up (it can be used only once).
function DeathOffer.use(offer: Offer): Offer
	return {
		killerId = offer.killerId,
		killerName = offer.killerName,
		expiresAt = offer.expiresAt,
		used = true,
		points = offer.points,
	}
end

return DeathOffer
