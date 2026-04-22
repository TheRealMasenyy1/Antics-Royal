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

function Invisible(Model, Value)
    for _, part in Model:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= ("Detector") and part.Name ~= ("Upgrade") then
           -- if Value == 0 and part.Transparency == 1 then continue end
            part.Transparency = Value 
        end
    end
end

function EmitAll(Attachment,Value)
	-- Value = Value or 1
	for _, particle in Attachment:GetDescendants() do
	 if not particle:IsA("ParticleEmitter") then continue end
	 if not Value then
		
		 if particle:GetAttribute("EmitCount")  then
			 Value = particle:GetAttribute("EmitCount")
		 else
			 Value = 10
		 end
	 end

	 local Delay = particle:GetAttribute("EmitDelay")

	 if Delay then
		task.delay(Delay,function()
			particle:Emit(Value) 
		end)
	else
		particle:Emit(Value) 
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
	local Explosion = ColdAssets.FlashingStrikes:Clone()

	local Track : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(Animations.Move1)

	Track:Play()

    Track:GetMarkerReachedSignal("Hit"):Connect(function()
		Invisible(Unit,1)
		Track:AdjustSpeed(.5)
		Explosion.Parent = Unit
		Explosion:PivotTo(Unit.HumanoidRootPart.CFrame)
	
		EmitAll(Explosion)
	
		UnitService:RequestDamage(Unit)
	
		DebrisService:AddItem(Explosion,7)
	end)

	task.delay(3,function()
		Invisible(Unit,0)
	end)
end

function Cold.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Cold.EclipseStrike(Unit,UnitInfo)
end

return Cold