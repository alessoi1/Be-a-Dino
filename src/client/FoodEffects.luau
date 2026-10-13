--!strict
-- The feedback when food is eaten: a small burst of particles in the color of the piece (and an
-- optional munch sound) where it was, for every piece that disappears near the camera. Pieces
-- leave the "Food" folder only when somebody eats them. The effects are made on this device only,
-- are limited per second and reuse a few emitters. Display only. Only checkable in Roblox Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FoodEffect = require(Shared:WaitForChild("FoodEffect"))
local Log = require(Shared:WaitForChild("Log"))
local EffectConfig = require(Shared:WaitForChild("Config"):WaitForChild("FoodEffects"))

local DinoAnimator = require(script.Parent:WaitForChild("DinoAnimator"))

local FOLDER_NAME = "Food"
-- Seconds to wait for the food folder to appear.
local FOLDER_WAIT = 30
-- Particles fly in all directions, from the middle of the piece.
local SPREAD_ANGLE = 180

local log = Log.new("FoodEffects")

type Emitter = { part: Part, emitter: ParticleEmitter, freeAt: number }

local FoodEffects = {}

local function newEmitter(folder: Instance): Emitter
	local part = Instance.new("Part")
	part.Name = "EatEffect"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.Parent = folder

	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(EffectConfig.particleLifetime * 0.6, EffectConfig.particleLifetime)
	emitter.Speed = NumberRange.new(EffectConfig.particleSpeed * 0.5, EffectConfig.particleSpeed)
	emitter.SpreadAngle = Vector2.new(SPREAD_ANGLE, SPREAD_ANGLE)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, EffectConfig.particleSize),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.LightEmission = 0.4
	emitter.Parent = part
	return { part = part, emitter = emitter, freeAt = 0 }
end

function FoodEffects.start()
	local effectFolder = Instance.new("Folder")
	effectFolder.Name = "EatEffects"
	effectFolder.Parent = workspace

	local pool: { Emitter } = {}
	for _ = 1, EffectConfig.emitterPool do
		table.insert(pool, newEmitter(effectFolder))
	end
	local window = FoodEffect.newWindow()
	local random = Random.new()

	local sound: Sound? = nil
	if EffectConfig.soundId ~= "" then
		local made = Instance.new("Sound")
		made.Name = "EatSound"
		made.SoundId = EffectConfig.soundId
		made.Volume = EffectConfig.soundVolume
		made.Parent = SoundService
		sound = made
	end

	local function burst(position: Vector3, color: Color3, value: number)
		local now = os.clock()
		if not FoodEffect.allow(window, now, EffectConfig.maxPerSecond) then
			return
		end
		for _, entry in pool do
			if now >= entry.freeAt then
				entry.freeAt = now + EffectConfig.emitterHold
				entry.part.Position = position
				entry.emitter.Color = ColorSequence.new(color)
				entry.emitter:Emit(FoodEffect.emitCount(EffectConfig, value))
				if sound ~= nil then
					sound.PlaybackSpeed = random:NextNumber(EffectConfig.pitchMin, EffectConfig.pitchMax)
					sound:Play()
				end
				return
			end
		end
		-- All emitters busy: skip the effect, the game goes on.
	end

	task.spawn(function()
		local folder = workspace:WaitForChild(FOLDER_NAME, FOLDER_WAIT)
		if folder == nil then
			log.warn("food folder not found, no eating effects")
			return
		end
		folder.ChildRemoved:Connect(function(child: Instance)
			if not child:IsA("BasePart") then
				return
			end
			-- The dino that ate it munches (a nod), wherever the camera is.
			DinoAnimator.notifyEat(child.Position)
			local camera = workspace.CurrentCamera
			if camera == nil or (child.Position - camera.CFrame.Position).Magnitude > EffectConfig.effectRange then
				return
			end
			local value = child:GetAttribute("Value")
			burst(child.Position, child.Color, if typeof(value) == "number" then value else 1)
		end)
		log.info("started")
	end)
end

return FoodEffects
