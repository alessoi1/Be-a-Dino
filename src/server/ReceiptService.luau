--!strict
-- The one ProcessReceipt callback of the game. Roblox allows only one, so every Developer
-- Product owner registers a handler here. A handler says whether the product is its own;
-- the first one that claims it processes the receipt. A receipt is confirmed only after the
-- profile was saved, and a repeated receipt never grants twice (the handlers are
-- idempotent). If anything is not ready, the receipt stays open and Roblox delivers it again.
-- Only checkable in Roblox Studio.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Log"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local log = Log.new("Receipts")

export type Outcome = "granted" | "duplicate" | "unknown_product" | "not_a_product"

export type Info = { userId: number, purchaseId: string, productId: number }

export type Handler = {
	name: string,
	-- Processes the receipt in the profile data. Returns nil when the product is not this
	-- handler's, otherwise the outcome.
	handle: (player: Player, data: any, info: Info) -> Outcome?,
	-- Runs after the receipt was confirmed as granted (tell the player).
	onGranted: (player: Player, data: any, info: Info) -> (),
}

local ReceiptService = {}

local handlers: { Handler } = {}
local started = false

function ReceiptService.register(handler: Handler)
	table.insert(handlers, handler)
	log.info("handler registered", { name = handler.name })
end

-- Never errors out: an error would count as not processed anyway, but this way the reason
-- is logged.
local function processReceipt(receipt: any): Enum.ProductPurchaseDecision
	local notYet = Enum.ProductPurchaseDecision.NotProcessedYet
	local info: Info = {
		userId = receipt.PlayerId,
		purchaseId = receipt.PurchaseId,
		productId = receipt.ProductId,
	}
	local player = if type(info.userId) == "number" then Players:GetPlayerByUserId(info.userId) else nil
	if player == nil then
		-- The player left; Roblox asks again when they come back.
		log.info("receipt for an absent player", { userId = info.userId, productId = info.productId })
		return notYet
	end
	local data = DataService.getData(player)
	if data == nil then
		-- No live profile (loading, guest): nothing can be saved, so nothing is granted.
		log.warn("receipt without a live profile", { userId = info.userId, productId = info.productId })
		return notYet
	end

	local owner: Handler? = nil
	local outcome: Outcome? = nil
	for _, handler in handlers do
		local ok, result = pcall(handler.handle, player, data, info)
		if not ok then
			log.error("receipt handler failed", { name = handler.name, userId = info.userId, error = tostring(result) })
			return notYet
		end
		if result ~= nil then
			owner = handler
			outcome = result
			break
		end
	end
	if owner == nil or outcome == nil or outcome == "unknown_product" or outcome == "not_a_product" then
		log.error(
			"receipt cannot be processed",
			{ userId = info.userId, productId = info.productId, outcome = outcome }
		)
		return notYet
	end
	log.info("receipt processed", {
		userId = info.userId,
		productId = info.productId,
		purchaseId = info.purchaseId,
		handler = owner.name,
		outcome = outcome,
	})

	-- Confirm only when the grant is on disk. A repeated receipt saves again, so a failed
	-- first save is retried by Roblox's next call.
	if not DataService.saveNow(player) then
		log.error("receipt not confirmed, save failed", { userId = info.userId, purchaseId = info.purchaseId })
		return notYet
	end
	if outcome == "granted" and player.Parent == Players then
		local ok, err = pcall(owner.onGranted, player, data, info)
		if not ok then
			log.error("receipt notification failed", { name = owner.name, userId = info.userId, error = tostring(err) })
		end
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ReceiptService.start()
	if started then
		log.warn("start called twice")
		return
	end
	started = true
	MarketplaceService.ProcessReceipt = processReceipt
	log.info("started")
end

return ReceiptService
