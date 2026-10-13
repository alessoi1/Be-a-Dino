--!strict
-- Pure layout checks of the lobby decoration: the circles the decoration takes up on the floor (nobody
-- spawns in them) and a check that everything lies inside the visible platform and clear of the glowing
-- circles. No Roblox services, no logging.

export type Spot = { x: number, z: number }
export type Circle = { id: string, x: number, z: number, radius: number, dwell: number }

export type Decor = {
	pillars: { Spot },
	pillarRadius: number,
	benches: { Spot },
	benchRadius: number,
	planters: { Spot },
	planterRadius: number,
	skeleton: { x: number, z: number, radius: number },
	zoneGap: number,
	edgeGap: number,
}

export type Zone = { id: string, x: number, z: number, radius: number }

local LobbyLayout = {}

-- All the circles the decoration takes up (relative to the middle of the platform).
function LobbyLayout.circles(decor: Decor): { Circle }
	local list: { Circle } = {}
	for index, spot in decor.pillars do
		table.insert(list, { id = "pillar" .. index, x = spot.x, z = spot.z, radius = decor.pillarRadius, dwell = 0 })
	end
	for index, spot in decor.benches do
		table.insert(list, { id = "bench" .. index, x = spot.x, z = spot.z, radius = decor.benchRadius, dwell = 0 })
	end
	for index, spot in decor.planters do
		table.insert(list, { id = "planter" .. index, x = spot.x, z = spot.z, radius = decor.planterRadius, dwell = 0 })
	end
	table.insert(
		list,
		{ id = "skeleton", x = decor.skeleton.x, z = decor.skeleton.z, radius = decor.skeleton.radius, dwell = 0 }
	)
	return list
end

-- Problems of the layout (empty when fine): every circle must lie inside the visible platform (half
-- `size` from the middle, but the north `northInset` studs lie under the wall) and keep `zoneGap` from
-- every circle of `zones` (relative coordinates as well).
function LobbyLayout.validate(decor: Decor, size: number, northInset: number, zones: { Zone }): { string }
	local errors: { string } = {}
	local half = size / 2 - decor.edgeGap
	local north = -size / 2 + northInset
	for _, circle in LobbyLayout.circles(decor) do
		if math.abs(circle.x) + circle.radius > half then
			table.insert(errors, circle.id .. " leaves the platform at the side")
		end
		if circle.z + circle.radius > half then
			table.insert(errors, circle.id .. " leaves the platform at the back")
		end
		if circle.z - circle.radius < north then
			table.insert(errors, circle.id .. " lies under the wall of the dome")
		end
		for _, zone in zones do
			local dx, dz = circle.x - zone.x, circle.z - zone.z
			if math.sqrt(dx * dx + dz * dz) < circle.radius + zone.radius + decor.zoneGap then
				table.insert(errors, circle.id .. " is too close to the circle " .. zone.id)
			end
		end
	end
	return errors
end

return LobbyLayout
