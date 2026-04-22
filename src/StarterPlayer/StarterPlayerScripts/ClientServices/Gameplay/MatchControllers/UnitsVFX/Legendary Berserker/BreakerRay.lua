local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Voxel = require(ReplicatedStorage.Shared.Utility.VoxelizeHandler)

local BreakerRay = {}

local VFX = ReplicatedStorage.Assets.VFX
local UnitAssets = VFX.LegendaryBerserker
local Animations = ReplicatedStorage.Assets.Animations.LegendaryBerserker

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

function Emit(Attachment, Descendants_,Value)
   -- Value = Value or 1

    local children = if Descendants_ then Attachment:GetDescendants() else Attachment:GetChildren()

    for _, particle in children do
        if not particle:IsA("ParticleEmitter") then continue end
        if not Value then
            if particle:GetAttribute("EmitCount")  then
                Value = particle:GetAttribute("EmitCount")
            else
                Value = 10
            end
        end
        particle:Emit(Value) 
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

function BreakerRay:Activate(Unit,UnitInfo)
    local HumanoidRootPart = Unit.HumanoidRootPart
    local BreakerRay = UnitAssets.BreakerRay:Clone()
    local Beam2 = BreakerRay.beam2
    local Attachment2 = BreakerRay.Attachment2
    local Track = Unit.Humanoid.Animator:LoadAnimation(Animations.Laser)
    local Attachments = {}
    local SoundController = Knit.GetController("SoundController")

    Track:Play()

    Track:GetMarkerReachedSignal("Charge"):Connect(function()
        for i,v in pairs(BreakerRay.LeftGrip:GetChildren()) do
            v.Parent = Unit["Left Arm"].LeftGripAttachment

            table.insert(Attachments,v)
        end
    end)


    Track:GetMarkerReachedSignal("Fire"):Connect(function()
        Track:AdjustSpeed(.75)
        
        SoundController:Play("BrolyBeam", {
            Parent = HumanoidRootPart
        })
        BreakerRay.Parent = Unit
        BreakerRay.CFrame = HumanoidRootPart.CFrame * CFrame.new(-1.02518845, 0.0813522339, -2.56592102, -1, 0, 0, 0, 1, 0, 0, 0, -1)
        
        TweenService:Create(Attachment2,TweenInfo.new(.1),{WorldCFrame = Attachment2.WorldCFrame * CFrame.new(0,0,UnitInfo.Range)}):Play()
        TweenService:Create(Beam2,TweenInfo.new(.1),{WorldCFrame = Beam2.WorldCFrame * CFrame.new(0,0,UnitInfo.Range)}):Play()
    
        UnitService:RequestDamage(Unit)
    
        task.wait(.1)
    
        Enable(Beam2,true)
    
        task.wait(.75)
    
        Emit(BreakerRay,true)
        Enable(BreakerRay,false)

        for _,particle in pairs(Attachments) do
            particle:Destroy()
        end
    
        Debris:AddItem(BreakerRay,3)
    end)
end

function BreakerRay.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    BreakerRay:Activate(Unit,UnitInfo)
end

return BreakerRay