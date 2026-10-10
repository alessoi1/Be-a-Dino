--!strict
-- Pure movement plausibility check (horizontal plane only). The server compares
-- two position samples against the speed it allows. No Roblox services, no logging.

export type Config = {
	speedTolerance: number,
	moveSlack: number,
}

export type Point = { x: number, z: number }

export type Result = "ok" | "rubberband"

local MoveCheck = {}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

-- `maxSpeed` is the speed the server currently allows (studs per second, with sprint).
-- Without a previous position there is nothing to compare, so the result is "ok".
function MoveCheck.check(config: Config, last: Point?, current: Point, dt: number, maxSpeed: number): Result
	if not isFinite(current.x) or not isFinite(current.z) or not isFinite(dt) or dt < 0 then
		return "rubberband"
	end
	if last == nil then
		return "ok"
	end
	local dx = current.x - last.x
	local dz = current.z - last.z
	local distance = math.sqrt(dx * dx + dz * dz)
	local allowed = maxSpeed * dt * config.speedTolerance + config.moveSlack
	if distance > allowed then
		return "rubberband"
	end
	return "ok"
end

return MoveCheck
