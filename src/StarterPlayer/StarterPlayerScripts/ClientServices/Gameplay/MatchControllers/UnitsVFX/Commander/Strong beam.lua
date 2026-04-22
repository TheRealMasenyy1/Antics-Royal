local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RocksModule = require(ReplicatedStorage.Shared.Utility.RocksModule)

local Commander = {}

local PirateKingAssets = ReplicatedStorage.Assets.VFX.Commander
local UnitService

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

local CurveTime = 0

function Commander.Gun(Unit,UnitInfo : UnitInformation)
	local redbeam = PirateKingAssets.RedBeamBase:Clone()
	redbeam.Parent = Unit.HumanoidRootPart
	redbeam.Anchored = true
	redbeam.CanCollide = false
	
	local redbeamCharge = PirateKingAssets.RedBeamChargeUp:Clone()
	redbeamCharge.Parent = Unit.HumanoidRootPart
	redbeamCharge.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,0,-2)
	redbeamCharge.Anchored = true
	redbeamCharge.CanCollide = false
	
	local redBullet = PirateKingAssets.Smash:Clone()
	redBullet.Parent = Unit.HumanoidRootPart
	redBullet.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,0,-2)
	redBullet.Anchored = true
	redBullet.CanCollide = false

	local shootAnim = Unit.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Commander.Gun1_anim)
	shootAnim:Play()
	Toggle(redbeamCharge,true)

	task.wait(2.225)
	redbeam.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,0,-2)
	Toggle(redbeamCharge,false)
	for i, v in pairs(redBullet:GetDescendants()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
    UnitService:RequestDamage(Unit)
	task.wait(1)
	Toggle(redbeam,false)
	DebrisService:AddItem(redBullet,1.5)
	DebrisService:AddItem(redbeam,1.5)
end

function Commander.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	Commander.Gun(Unit,UnitInfo)
end

return Commander