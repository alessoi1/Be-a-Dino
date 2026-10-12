--!strict
-- The one place that opens the Roblox purchase dialog for a Developer Product. The dialog only
-- opens after a deliberate tap, never by itself. It asks nothing of the server: the server grants
-- the item only when Roblox sends the receipt (see ReceiptService), so a wrong or faked prompt
-- cannot give anything. Guests and players whose profile is still loading cannot buy (nothing
-- could be saved). Only checkable in Roblox Studio.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared:WaitForChild("Log"))
local OfferConfig = require(Shared:WaitForChild("Config"):WaitForChild("Offers"))

local log = Log.new("PurchasePrompt")

local lastPrompt = 0

local PurchasePrompt = {}

-- Whether the player can buy now: the profile is loaded and it is not a guest session.
function PurchasePrompt.canBuy(): boolean
	local player = Players.LocalPlayer
	return player:GetAttribute("DataReady") == true and player:GetAttribute("DataGuest") ~= true
end

-- Opens the purchase dialog of a product. Returns whether it was opened.
function PurchasePrompt.request(productId: number): boolean
	if typeof(productId) ~= "number" or productId <= 0 then
		log.warn("bad product id")
		return false
	end
	if not PurchasePrompt.canBuy() then
		log.info("purchase refused, progress is not saved", { productId = productId })
		return false
	end
	local now = os.clock()
	if now - lastPrompt < OfferConfig.promptCooldownSeconds then
		return false
	end
	lastPrompt = now

	local ok, err = pcall(function()
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
	end)
	if not ok then
		log.error("purchase dialog failed", { productId = productId, error = tostring(err) })
		return false
	end
	log.info("purchase dialog opened", { productId = productId })
	return true
end

return PurchasePrompt
