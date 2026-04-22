local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Cold = {}

local VFX = ReplicatedStorage.Assets.VFX
local ColdAssets = ReplicatedStorage.Assets.VFX.Thorfinn
local Animations = ReplicatedStorage.Assets.Animations.Thorfinn
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

function Cold.EclipseStrike(Unit,UnitInfo : UnitInformation)
	local slash = ColdAssets.Slash360:Clone()
	local Track : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(Animations.Move1)

	Track:Play()

    Track:GetMarkerReachedSignal("Hit"):Connect(function()
		slash.Parent = Unit

		slash:PivotTo(Unit.HumanoidRootPart.CFrame);
	
	
		--for _,part in slash:GetChildren() do
			--part:PivotTo(Unit.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(90),math.rad(180),math.rad(90)) * CFrame.new(-5,0,0));
			--part.Size = part.Size - Vector3.new(23,0,4);
			--TweenService:Create(part,TweenInfo.new(.35,Enum.EasingStyle.Cubic,Enum.EasingDirection.In,0,false,0),{Size = Vector3.new(24.809, 0.009, 4.752), CFrame = part.CFrame * CFrame.new(-11,0,0)}):Play()
		--end
	
		Emit(slash.Attachment)
	
		UnitService:RequestDamage(Unit)
	
		DebrisService:AddItem(slash,1.5)
	end)
end

function Cold.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Cold.EclipseStrike(Unit,UnitInfo)
end

return Cold