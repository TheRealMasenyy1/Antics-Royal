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
	for i, v in pairs(Part:GetDescendants()) do
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

function Invisible(Model, Value)
    for _, part in Model:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= ("HumanoidRootPart") and part.Name ~= ("Detector") and part.Name ~= ("Upgrade") and not part:GetAttribute("HitboxPart") then
            part.Transparency = Value 
        end
    end
end

function lerp(a, b, c)
	return a + (b - a) * c
end

function quadBezier(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)

	local l2 = lerp(p1, p2, t)

	local quad = lerp(l1, l2, t)

	return quad
end

-- 113546220006755
function Cold.EclipseStrike(Unit,UnitInfo : UnitInformation)
	local Explosion = ColdAssets.Explosion:Clone()
	-- Keyreached = Activated
	Explosion.Parent = Unit
	Explosion.Transparency = 1
	Explosion.CFrame = UnitInfo.Target.CFrame * CFrame.new(0,1.5,0)

    local clonedUnit = Unit:Clone()
    clonedUnit.Parent = workspace.Debris
	clonedUnit.PrimaryPart.Anchored = true
    clonedUnit:PivotTo(Unit.HumanoidRootPart.CFrame)

    Invisible(Unit,1)

	local DistanceToTarget = (Unit.HumanoidRootPart.CFrame.Position - UnitInfo.Target.CFrame.Position).Magnitude 
    local AttackAnimation : AnimationTrack = clonedUnit.Humanoid.Animator:LoadAnimation(Animations.RavensDescent)
	AttackAnimation:Play()

	task.spawn(function()
		for i = 0, 1, .01 do
			local Position = quadBezier(i,Unit.HumanoidRootPart.CFrame.Position,Unit.HumanoidRootPart.CFrame.Position + Vector3.new(0,10,0),Explosion.CFrame.Position)
			clonedUnit:PivotTo(CFrame.new(Position))
			RunService.Heartbeat:Wait()
		end
	end)

	AttackAnimation:GetMarkerReachedSignal("Activated"):Connect(function()
		Emit(Explosion.Attachment)
		UnitService:RequestDamage(Unit)

		task.delay(.5,function()
			local AppearEffect = ColdAssets.Appear:Clone()
			AppearEffect.CFrame = Unit.PrimaryPart.CFrame
			AppearEffect.Parent = workspace.Debris

			Emit(AppearEffect)
			Invisible(Unit,0)
			clonedUnit:Destroy()
			task.delay(1,game.Destroy,AppearEffect)
		end)	
	end)


	DebrisService:AddItem(Explosion,2)
end

function Cold.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Cold.EclipseStrike(Unit,UnitInfo)
end

return Cold