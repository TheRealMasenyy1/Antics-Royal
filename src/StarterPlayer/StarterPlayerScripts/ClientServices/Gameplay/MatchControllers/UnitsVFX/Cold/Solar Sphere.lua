local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PirateKing = {}

local VFX = ReplicatedStorage.Assets.VFX
local PirateKingAssets = ReplicatedStorage.Assets.VFX.PirateKing
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

function PirateKing.Supernova(Unit,UnitInfo : UnitInformation)
    local AttackAnimation = Unit.Humanoid.Animator:LoadAnimation(VFX.Cold.Attack)
	local SupernovaBase = PirateKingAssets.SupernovaBase:Clone()
	SupernovaBase.Parent = Unit.HumanoidRootPart
	
	local Explosion = PirateKingAssets.DistructoDiskExplosion:Clone()
	Explosion.Parent = Unit.HumanoidRootPart
	Explosion.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,-50,0)
	
	SupernovaBase.Sound:Play()
	--local ThrowAnimation : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(LeafNinjaAssets.Throw)
	--local ChargingAnimation = Unit.Humanoid.Animator:LoadAnimation(LeafNinjaAssets.Charging)

	--ChargingAnimation:Play()

	--local con
	--con = RunService.RenderStepped:Connect(function(dt)
		SupernovaBase.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,10,0)
	--end)

    AttackAnimation:Play()
    AttackAnimation:AdjustSpeed(.8)

	task.delay(1,function()
		--con:Disconnect()
		local tween = TweenService:Create(SupernovaBase,TweenInfo.new(.5),{CFrame = UnitInfo.Target.CFrame})
		tween:Play()
		
		tween.Completed:Wait()
		
		SupernovaBase:Destroy()
		Explosion.CFrame = SupernovaBase.CFrame
		Emit(Explosion.EndExplosionEMIT)
		Explosion.Sound:Play()
		UnitService:RequestDamage(Unit)
		
		task.delay(.5,function()
			Toggle(Explosion,false)
			TweenService:Create(Explosion,TweenInfo.new(.35),{Size = Explosion.Size - Vector3.new(20,20,20)}):Play()
			DebrisService:AddItem(Explosion,.5)
		end)
		
	end)
	
end

function PirateKing.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	PirateKing.Supernova(Unit,UnitInfo)
end

return PirateKing