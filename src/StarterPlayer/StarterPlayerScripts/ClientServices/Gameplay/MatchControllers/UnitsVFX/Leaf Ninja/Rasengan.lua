local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Voxel = require(ReplicatedStorage.Shared.Utility.VoxelizeHandler)

local Rasengan = {}

local VFX = ReplicatedStorage.Assets.VFX
local LeafNinjaAssets = VFX.LeafNinja

type UnitInformation = {
    Unit : any, -- This is the unit model
    Name : string, -- Name
    UnitId : number, -- This is an attribute on model
    Owner : string, -- Who placed the unit
    Ability : string, -- Which Ability to use
    Target : any, -- This is a model
    Args : any,
}

local CurveTime = 0
local UnitService;
local SoundController;

function Emit(Attachment,Value)
   -- Value = Value or 10

    for _, particle in Attachment:GetChildren() do
        if not Value then
            Value = particle:GetAttribute("EmitCount") 
        end
        particle:Emit(Value) 
    end
end

function Enable(Attachment,Value)
    for _, particle in Attachment:GetDescendants() do
        if not particle:IsA("Attachment") then
            particle.Enabled = Value 
        end
    end
end

function Move(TheTarget,Unit,Ball,step : number, Speed : number)
	local Distance = (Ball.Position - TheTarget.Position).Magnitude
	-- local Direction = (Ball.Position - TheTarget.Position).Unit
	local Direction = (TheTarget.Position - Ball.Position).Unit

    -- Ball.CFrame = CFrame.lookAt(Ball.CFrame.Position, TheTarget.Position)
    Ball.CFrame = Ball.CFrame + Direction * .25

    return Distance
end

function Invisible(Model, Value)
    for _, part in Model:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= ("Detector") and part.Name ~= ("Upgrade") and part.Name ~= "HumanoidRootPart" then
           -- if Value == 0 and part.Transparency == 1 then continue end
            part.Transparency = Value 
        end
    end
end

function Rasengan:Activate(Unit,UnitInfo)
    local HumanoidRootPart = Unit.HumanoidRootPart
    local rasengan = LeafNinjaAssets.Rasengan:Clone()
    local ball = rasengan.Ball
    local effect = rasengan.Part
    local clonedUnit = Unit:Clone()
    local SoundController = Knit.GetController("SoundController")

    rasengan.Parent = clonedUnit
    
    clonedUnit.Parent = workspace.Debris
    clonedUnit:PivotTo(Unit.HumanoidRootPart.CFrame)
    clonedUnit.HumanoidRootPart.Anchored = true
    
    effect.Parent = clonedUnit
    
    local runAnimation : AnimationTrack = clonedUnit.Humanoid.Animator:LoadAnimation(LeafNinjaAssets.Run)
    
    Invisible(Unit,1)
    
    runAnimation:Play()
    
    runAnimation:AdjustSpeed(1.35)
    
	SoundController:Play("Rasengan", {
		Parent = Unit.HumanoidRootPart
	})

    local part = Instance.new("Part")
    part.Size = Vector3.new(0.5,0.5,0.5)
    part.Parent = workspace.Debris
    part.Anchored = true
    part.CanCollide = false
    part.CFrame = clonedUnit.HumanoidRootPart.CFrame
    part.Position = UnitInfo.Target.Position

    --part.CFrame = CFrame.lookAt(part.CFrame,UnitInfo.Target.CFrame)

    local runTween = TweenService:Create(clonedUnit.HumanoidRootPart,TweenInfo.new( (125/60) * 0.65 ),{CFrame = part.CFrame})
    ball.CFrame = clonedUnit["Right Arm"].CFrame * CFrame.Angles(0,math.rad(90),0) * CFrame.new(0,-.5,-.75)
    ball.WeldConstraint.Part1 = clonedUnit["Right Arm"]

   -- ball.Parent = clonedUnit

    runTween:Play()

    runAnimation:GetMarkerReachedSignal("Jump"):Connect(function()
        runAnimation:AdjustSpeed(1.35)

        --effect.CFrame = ball.CFrame
        --effect.particles.CFrame = ball.CFrame

        runTween:Pause()

        task.wait(.8)

        effect.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(0,math.rad(90),0); effect.Position = ball.Position;
        effect.particles.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(0,math.rad(90),0); effect.particles.Position = ball.Position;

        Enable(ball.Attachment,false)

        Emit(effect.Rasengan)
        Emit(effect.particles.Attachment)

        UnitService:RequestDamage(Unit)

        runTween:Cancel()

        Debris:AddItem(clonedUnit,2)-- clonedUnit:Destroy()

        Invisible(clonedUnit,1)
        Invisible(Unit,0)
    end)

    runTween.Completed:Wait()

    Debris:AddItem(rasengan,3)
    part:Destroy()
end

function Rasengan.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    Rasengan:Activate(Unit,UnitInfo)
end

return Rasengan