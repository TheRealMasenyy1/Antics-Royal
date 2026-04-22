local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Voxel = require(ReplicatedStorage.Shared.Utility.VoxelizeHandler)

local FlameThrower = {}

local VFX = ReplicatedStorage.Assets.VFX
local LostNinjaAssets = VFX.LostNinja

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

function FlameThrower:Activate(Unit,UnitInfo)
    warn("lol")
    local Head = Unit.Head
    local HumanoidRootPart = Unit.HumanoidRootPart
    local Flamethrower = LostNinjaAssets.Flamethrower:Clone()
    local SoundController = Knit.GetController("SoundController")

    local attachments : table = SetAttachments(LostNinjaAssets.Attachments, Unit)
    local distance = (UnitInfo.Target.Position - HumanoidRootPart.Position).Magnitude
    if distance <= 4 then
        distance = 5
    end
    local vector = HumanoidRootPart.CFrame.lookVector * distance
    
    Flamethrower.Parent = Unit
    Flamethrower:PivotTo(Head.CFrame * CFrame.new(0,0,-distance))
    
    UnitService:RequestDamage(Unit)
    
    SoundController:Play("LostNinjaFlamethrower", {
        Parent = Unit.HumanoidRootPart
    })

    task.wait(3.22)
    
    -- Move ending fading out vfx 

    -- ON TARGET INFRONT OF HEAD W (DONE)
    -- MAKE PARTICLE OUT OF HEAD SMALLER LOWKEY IF TOO CLOSE

    Enable(Flamethrower,false)

    -- Clean up

    for _,item in attachments do
        Enable(item, false)
        Debris:AddItem(item,2)
    end

    Debris:AddItem(Flamethrower,2)

end

function FlameThrower.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    FlameThrower:Activate(Unit,UnitInfo)
end

return FlameThrower