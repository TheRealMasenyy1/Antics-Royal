local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Bezier = require(ReplicatedStorage.Shared.Utility.Bezier)

local GaleForce = {}

local VFX = ReplicatedStorage.Assets.VFX
local UnitAssets = VFX.Nami
local Animations = ReplicatedStorage.Assets.Animations.Nami

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
   -- Value = Value or 1

    local childrenTable

    if typeof(Attachment) == "table" then
        childrenTable = Attachment
    else
        childrenTable = Attachment:GetChildren()
    end

    for _, particle in childrenTable do
        if not particle:IsA("ParticleEmitter") then print("continuing") continue end
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

function lerp(a, b, c)
	return a + (b - a) * c
end

function quadBezier(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)

	local l2 = lerp(p1, p2, t)

	local quad = lerp(l1, l2, t)

	return quad
end

function GaleForce:Activate(Unit,UnitInfo)
    local HumanoidRootPart = Unit.HumanoidRootPart
    local GaleForce = UnitAssets.GaleForce:Clone()

    GaleForce.Parent = Unit
    GaleForce.CFrame = HumanoidRootPart.CFrame * CFrame.new(0.24590683, 2.5019989, -13.7420502, -1, 0, 0, 0, 0, -1, 0, -1, 0)

    Enable(GaleForce,true)

    UnitService:RequestDamage(Unit)

    task.wait(1)

    Enable(GaleForce,false)

    Debris:AddItem(GaleForce,1)
end

function GaleForce.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    GaleForce:Activate(Unit,UnitInfo)
end

return GaleForce