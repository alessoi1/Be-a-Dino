--!strict
-- Pure purchase rules: which skin a bought product belongs to and how it is granted.
-- Granting is idempotent: the same receipt twice changes nothing the second time.
-- No Roblox services, no logging; the ReceiptService logs the outcome.

export type Skin = {
	id: string,
	dinoId: string,
	unlock: { kind: string, stageId: string?, points: number?, productId: number? },
}

export type Outcome = "granted" | "duplicate" | "unknown_product" | "not_a_product"

local Purchases = {}

-- The skin sold under `productId`. A product id of 0 means "not for sale", so it never matches.
function Purchases.skinForProduct(skins: { Skin }, productId: number): Skin?
	if type(productId) ~= "number" or productId ~= productId or productId <= 0 or productId % 1 ~= 0 then
		return nil
	end
	for _, skin in skins do
		if skin.unlock.kind == "product" and skin.unlock.productId == productId then
			return skin
		end
	end
	return nil
end

-- Marks the skin as bought in `owned` (the ownedSkins of the profile).
function Purchases.grant(owned: { [string]: boolean }, skin: Skin): Outcome
	if skin.unlock.kind ~= "product" then
		return "not_a_product"
	end
	if owned[skin.id] == true then
		return "duplicate"
	end
	owned[skin.id] = true
	return "granted"
end

-- Resolves the product and grants its skin. Returns the outcome and the skin (if known).
function Purchases.apply(skins: { Skin }, owned: { [string]: boolean }, productId: number): (Outcome, Skin?)
	local skin = Purchases.skinForProduct(skins, productId)
	if skin == nil then
		return "unknown_product", nil
	end
	return Purchases.grant(owned, skin), skin
end

return Purchases
