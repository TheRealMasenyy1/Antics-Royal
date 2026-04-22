local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Cold = {}

local VFX = ReplicatedStorage.Assets.VFX
local ColdAssets = ReplicatedStorage.Assets.VFX.Yuichiro
local Animations = ReplicatedStorage.Assets.Animations.Mikaela
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
	local Track : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(Animations.Attack1)
	local Ripple = ColdAssets.Ripple:Clone()

	Track:Play()



	Track:GetMarkerReachedSignal("Hit"):Connect(function()
		local HeightOffset = UnitInfo.Target.Parent:GetAttribute("HeightOffset")
		local goalPosition = Vector3.new(
			UnitInfo.Target.Position.X,
			UnitInfo.Target.Position.Y - (UnitInfo.Target.Size.Y),
			--(UnitInfo.Target.Size.Y / 2) + HeightOffset, --- Keeps the attacker on the ground and not hovering
			UnitInfo.Target.Position.Z
		)

		Ripple.Parent = workspace.Debris

		Ripple:PivotTo(CFrame.new(goalPosition))
	
		UnitService:RequestDamage(Unit)
	
		Emit(Ripple.Attachment)
	end)

	DebrisService:AddItem(Ripple,4)
end

function Cold.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Cold.EclipseStrike(Unit,UnitInfo)
end

return Cold