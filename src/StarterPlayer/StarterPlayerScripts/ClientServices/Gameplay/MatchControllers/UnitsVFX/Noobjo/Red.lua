local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Voxel = require(ReplicatedStorage.Shared.Utility.VoxelizeHandler)

local Red = {}

local VFX = ReplicatedStorage.Assets.VFX
local Animations = ReplicatedStorage.Assets.Animations
local NoobjoAnimation = Animations.Noobjo
local UnitAssets = VFX.Noobjo

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
   Value = Value or 10

    for _, particle in Attachment:GetDescendants() do
        if particle:IsA("ParticleEmitter") then
            -- Value = particle:GetAttribute("EmitCount") 
            particle:Emit(Value) 
        end
    end
end

function Enable(Attachment,Value)
    for _, particle in Attachment:GetDescendants() do
        if (particle:IsA("ParticleEmitter") or particle:IsA("Beam")) then
            particle.Enabled = Value 
        end
    end
end

function SetAttachments(Part : BasePart, Character)
    local attachmentsTable = {}
    for _,Attachment in pairs(Part:GetChildren()) do
        if Attachment:IsA("Attachment") then
            local clonedAttachment = Attachment:Clone()
            clonedAttachment.Parent = Character[clonedAttachment:GetAttribute("Place")]

            table.insert(attachmentsTable,clonedAttachment)
        end
    end

    return attachmentsTable
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
        if part:IsA("BasePart") and part.Name ~= ("Detector") and part.Name ~= ("Upgrade") then
           -- if Value == 0 and part.Transparency == 1 then continue end
            part.Transparency = Value 
        end
    end
end

function Red:Activate(Unit,UnitInfo)
    local HumanoidRootPart = Unit.HumanoidRootPart
    local Red = UnitAssets.Red:Clone()
    local RedExplosion = UnitAssets.RedExplosion:Clone()
     
    local RedAn : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(NoobjoAnimation.Red)
    RedAn:Play()
    RedAn.Looped = false
     
    Red.Parent = Unit
    Red.CFrame = Unit.LeftPart.CFrame --* CFrame.new(1.25,0,0)
     
    local newWeld = Instance.new("WeldConstraint")
    newWeld.Part0 = Red
    newWeld.Part1 = Unit.LeftPart
    newWeld.Parent = Red
     
    Emit(Red.ChargeUp, 10)
    task.delay(.25,Enable,Red.ChargeUp, true)
    
    RedExplosion.Parent = Unit
    RedExplosion.Anchored = true
    RedExplosion.CFrame = Unit.PrimaryPart.CFrame * CFrame.new(1.25,0,0) 

    RedAn:GetMarkerReachedSignal("RedFire"):Connect(function()
        Emit(RedExplosion, 10)
        UnitService:RequestDamage()

        Red:Destroy()
        task.delay(2, game.Destroy, RedExplosion)
    end)
end

function Red.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    Red:Activate(Unit,UnitInfo)
end

return Red