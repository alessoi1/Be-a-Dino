--!strict
-- The feedback when food is eaten (particles, sound, hint), to be tuned by eye and ear in Studio.
-- Only the client uses it; nothing here changes a game value.

return {
	-- Only pieces eaten this close to the camera (studs) get an effect.
	effectRange = 80,
	-- At most this many effects per second on this device (against slowdowns in a crowd).
	maxPerSecond = 20,
	-- Particles per eaten piece: from `emitBase` for the smallest up to `emitMax`; each doubling of
	-- the value adds `emitPerDoubling`.
	emitBase = 4,
	emitPerDoubling = 2,
	emitMax = 14,
	-- Look of the particles (seconds, studs per second, studs).
	particleLifetime = 0.55,
	particleSpeed = 14,
	particleSize = 0.7,
	-- Emitters that are reused (a burst needs one for a moment).
	emitterPool = 10,
	-- Seconds an emitter is held until it is used again.
	emitterHold = 0.8,
	-- The "munch" sound: a Roblox sound id ("rbxassetid://..."), or "" for no sound. Roblox sounds
	-- need a real asset id, so none is set yet (see docs/MODELLE.md).
	soundId = "",
	soundVolume = 0.35,
	-- Random pitch of the sound (1 = unchanged), so it does not sound the same every time.
	pitchMin = 0.9,
	pitchMax = 1.3,
	-- The hint "Eat the food to grow!" at the start of a round: for at most this many seconds, and
	-- not any more once the first piece was eaten.
	hintSeconds = 8,
}
