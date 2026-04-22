local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Cold = {}

local VFX = ReplicatedStorage.Assets.VFX
local ColdAssets = ReplicatedStorage.Assets.VFX.Cold
local Animations = ReplicatedStorage.Assets.Animations.Cold
local UnitService; 

type UnitInformation = {
	Unit : any, -- This is the unit model
	Name : string, -- Name
	UnitId : number, -- This is an attribute on model
	Owner : string, -- Who placed the unit
	Ability : string, -- Which Ability to use
	Target : any, -- This is a model
	Args : any,
}

function Emit(Part)
	for i, v in pairs(Part:GetChildren()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function Toggle(Part,Value)
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "Beam" or v.ClassName == "ParticleEmitter" or v.ClassName == "PointLight" then
			v.Enabled = Value
		end
	end
end

function Move(TheTarget,Unit,Ball,step : number, Speed : number)
	local Distance = (Ball.Position - TheTarget.Position).Magnitude
	local Direction = (TheTarget.Position - Ball.Position).Unit

	Ball.CFrame = Ball.CFrame + Direction * .25

	return Distance
end

function Cold.Supernova(Unit,UnitInfo : UnitInformation)
    local AttackAnimation = Unit.Humanoid.Animator:LoadAnimation(Animations.DeathSlice)
	local BeamEmitters = ColdAssets.DeathSlice:Clone()
	local Particles = {}

	for _,Particle in pairs(BeamEmitters.Main) do
		table.insert(Particles, Particle)
	end

	BeamEmitters:destroy()

    AttackAnimation:Play()
    AttackAnimation:AdjustSpeed(1)

	AttackAnimation:GetMarkerReachedSignal("Start"):Connect(function()
		for _,Particle in pairs(Particles) do
			Particle.Parent = Unit["Left Arm"].LeftGripAttachment
			Particle.Enabled = true

			UnitService:RequestDamage(Unit)
		end
	end)

	AttackAnimation:GetMarkerReachedSignal("Hit"):Connect(function()
		local Model = ColdAssets.DeathSlice:Clone()
		local Explode = ColdAssets.ExplosionDeathSlicer
		local MoveTween = TweenService:Create(Model,TweenInfo.new(.5),{CFrame = UnitInfo.Target.CFrame})

		for _,Particle in pairs(Particles) do
			Particle:destroy()
		end

		Model.CFrame = Unit["Left Arm"].LeftGripAttachment.WorldCFrame
		Model.Parent = Unit

		MoveTween:Play()

		MoveTween.Completed:Wait()

		Explode.CFrame = UnitInfo.Target.CFrame

		Emit(Explode.Emit)

		task.wait(.35)

		Emit(Explode.Second)

		DebrisService:AddItem(Explode,2)
		DebrisService:AddItem(Model,2)

	end)
	
end

function Cold.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Cold.Supernova(Unit,UnitInfo)
end

return Cold