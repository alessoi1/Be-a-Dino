--!strict
-- Logs rejected remote calls on warn, but at most once per interval, remote and
-- reason per user, so a held button or a flooding client cannot flood the log.
-- The clock is injected so the limiter is testable without Roblox.

-- Structural subset of Log.Logger (no requires, so this module runs under Lune).
export type WarnLogger = { warn: (message: string, context: { [string]: any }?) -> () }

export type Limiter = {
	reject: (userId: number, remote: string, reason: string) -> (),
	forget: (userId: number) -> (),
}

local RejectLimiter = {}

function RejectLimiter.new(log: WarnLogger, interval: number, clock: () -> number): Limiter
	local lastAt: { [number]: { [string]: number } } = {}

	local function reject(userId: number, remote: string, reason: string)
		local now = clock()
		local byKey = lastAt[userId]
		if byKey == nil then
			byKey = {}
			lastAt[userId] = byKey
		end
		local key = remote .. ":" .. reason
		local previous = byKey[key]
		if previous ~= nil and now - previous < interval then
			return
		end
		byKey[key] = now
		log.warn("remote call rejected", { remote = remote, userId = userId, reason = reason })
	end

	return {
		reject = reject,
		forget = function(userId: number)
			lastAt[userId] = nil
		end,
	}
end

return RejectLimiter
