local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RocksModule = require(ReplicatedStorage.Shared.Utility.RocksModule)

local Cyborg = {}

local PirateKingAssets = ReplicatedStorage.Assets.VFX.PirateKing
local Animation = ReplicatedStorage.Assets.Animations
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

local CurveTime = 0

function Cyborg.BlitzShot(Unit,UnitInfo : UnitInformation)
	local Fired = false
    local FireAnimation : AnimationTrack = Unit.Humanoid:LoadAnimation(Animation.Cyborg.EnergyCanon)
    FireAnimation:Play()
    FireAnimation.Looped = false
	
	task.wait(1)

	local blitzshotCharge = PirateKingAssets.GenosBlitzShotChargeUp:Clone()
	blitzshotCharge.Parent = Unit.HumanoidRootPart
	blitzshotCharge.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,0,-1.5) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
	
	local blitzshotBase = PirateKingAssets.GenosBlitzShotBase:Clone()
	blitzshotBase.Parent = Unit.HumanoidRootPart
	blitzshotBase.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,-50,-1.5) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
	
	local blitzshotExplosion = PirateKingAssets.GenosBlitzShotExplosion:Clone()
	blitzshotBase.Parent = Unit.HumanoidRootPart
	
	Toggle(blitzshotCharge,true)
	
	FireAnimation:GetMarkerReachedSignal("Activate"):Connect(function()
		Fired = true
	end)

	repeat task.wait() until Fired

	task.delay(.5,function()
		Toggle(blitzshotCharge,false)
		DebrisService:AddItem(blitzshotCharge,2)
		blitzshotBase.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,0,-1.5) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
		
		local Tween = TweenService:Create(blitzshotBase,TweenInfo.new(.5),{CFrame = blitzshotBase.CFrame * CFrame.new(0,0,-20)})
		--Tween:Play()
		
		local MoveConnection : RBXScriptConnection;
		local HasExploded = false
		local DistanceToTarget;
		local newShuriken = blitzshotBase:Clone()
		newShuriken.Anchored = true
		newShuriken.Parent = workspace
		blitzshotBase:Destroy()

		MoveConnection = RunService.Stepped:Connect(function(time,step)
			CurveTime = 0
			DistanceToTarget = Move(UnitInfo.Target,Unit,newShuriken,step,100)

			if DistanceToTarget <= 1 and not HasExploded then
				HasExploded = true
				MoveConnection:Disconnect()
				blitzshotExplosion.CFrame = newShuriken.CFrame
				blitzshotExplosion.Parent = workspace.Debris
				
				Toggle(newShuriken,false)
				Emit(blitzshotExplosion.Attachment)
				UnitService:RequestDamage(Unit)
				RocksModule.Ground(blitzshotExplosion.CFrame.Position,5,Vector3.new(1,1,1),{UnitInfo.Target,blitzshotExplosion,newShuriken},10,false,3)
				
				DebrisService:AddItem(newShuriken,3)
				DebrisService:AddItem(blitzshotExplosion,3)
				
			end
		end)
	end)
end

function Cyborg.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
	UnitService = Knit.GetService("UnitService")
	Cyborg.BlitzShot(Unit,UnitInfo)
end

return Cyborg