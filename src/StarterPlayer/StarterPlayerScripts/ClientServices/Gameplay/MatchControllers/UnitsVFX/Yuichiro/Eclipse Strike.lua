local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Cold = {}

local VFX = ReplicatedStorage.Assets.VFX
local ColdAssets = ReplicatedStorage.Assets.VFX.Yuichiro
local Animations = ReplicatedStorage.Assets.Animations.Yuichiro
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
	local slash = ColdAssets.Dark_Slash:Clone()
	local oldPos; 
    local AttackAnimation : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(Animations.EclipseStrike)
	AttackAnimation:Play()

	AttackAnimation:GetMarkerReachedSignal("Hit"):Connect(function()
		slash.Parent = workspace.Debris

		slash:PivotTo(Unit.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(90),0,math.rad(-90))); 
	
		Toggle(slash,true)
	
		task.wait(.15)
	
		for _,part in slash:GetChildren() do 
			TweenService:Create(part,TweenInfo.new(.3,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,false),{CFrame = part.CFrame * CFrame.new(0,0,-7)}):Play()  
		end
	
		UnitService:RequestDamage(Unit)
	
		task.delay(1.5,function()
			Toggle(slash,false)
		end)
	
		DebrisService:AddItem(slash,3)
	end)

end

function Cold.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Cold.EclipseStrike(Unit,UnitInfo)
end

return Cold