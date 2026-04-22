local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Bezier = require(ReplicatedStorage.Shared.Utility.Bezier)

local MeteorShower = {}

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

function Emit(Attachment,Value)
   -- Value = Value or 1
    for _, particle in Attachment:GetChildren() do
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
        if part:IsA("BasePart") and (part.Name ~= ("HumanoidRootPart") or part.Name ~= ("RootPart")) and part.Name ~= ("Detector") and part.Name ~= ("Upgrade") and not part:GetAttribute("Hitbox") then
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

function MeteorShower:Activate(Unit,UnitInfo)
    local HumanoidRootPart = Unit.HumanoidRootPart
    local MeteorShower = UnitAssets.MeteorShower:Clone()
    local clonedUnit = Unit:Clone()
    local SoundController = Knit.GetController("SoundController")

    MeteorShower.Parent = workspace.Debris

    MeteorShower:PivotTo(Unit:GetPivot())

    clonedUnit.Parent = workspace.Debris
    clonedUnit:PivotTo(Unit.HumanoidRootPart.CFrame)
   -- clonedUnit.HumanoidRootPart.Anchored = true

    Invisible(Unit,1)

    --task.wait(1000)
    local Track = clonedUnit.Humanoid.Animator:LoadAnimation(Animations.Nova)
    local relativeVector = (clonedUnit.HumanoidRootPart.Position - MeteorShower.fireball.Position)
    local distance = relativeVector.Magnitude

    local FloatUpTween = TweenService:Create(clonedUnit.HumanoidRootPart,TweenInfo.new(2),{CFrame = clonedUnit.HumanoidRootPart.CFrame * CFrame.new(0,distance - 7 ,0)})
    local FloatDownTween = TweenService:Create(clonedUnit.HumanoidRootPart,TweenInfo.new(2),{CFrame = Unit.HumanoidRootPart.CFrame})

    Track:Play()

    Track:GetMarkerReachedSignal("Float"):Connect(function()
        Track:AdjustSpeed(.25)
        SoundController:Play("MeteorStart",{Parent = HumanoidRootPart})
        FloatUpTween:Play()
    end)

    Track:GetMarkerReachedSignal("FloatFinished"):Connect(function()
        Track:AdjustSpeed(1)
        warn("FINISHED")
    end)

    Track:GetMarkerReachedSignal("Explosion"):Connect(function()
        Track:AdjustSpeed(0)

        Enable(MeteorShower.fireball.Orb,true)

        TweenService:Create(MeteorShower.fireball.Orb,TweenInfo.new(.5),{Transparency = 0}):Play()
        TweenService:Create(MeteorShower.fireball,TweenInfo.new(.5),{Transparency = 0}):Play()

        Enable(MeteorShower.fireball,true)

        task.wait(1)

        Enable(MeteorShower.Lightbarrage,true)

        UnitService:RequestDamage(Unit)

        task.wait(4)

        Enable(MeteorShower.Lightbarrage,false)
        EmitAll(MeteorShower.Lightbarrage)

        task.wait(.5)

        Track:AdjustSpeed(1)

        Enable(MeteorShower.fireball,false)
        EmitAll(MeteorShower.fireball)
        
        TweenService:Create(MeteorShower.fireball,TweenInfo.new(.15),{Transparency = 1}):Play()
        TweenService:Create(MeteorShower.fireball.Orb,TweenInfo.new(.15),{Transparency = 1}):Play()

        FloatDownTween:Play()

        FloatDownTween.Completed:Wait()

        Invisible(clonedUnit,1)
        Invisible(Unit,0)
    
        Debris:AddItem(MeteorShower,2)
        Debris:AddItem(clonedUnit,2)
    end)

   -- TweenService:Create(MeteorShower.fireball,TweenInfo.new(.5),{Transparency = 0}):Play()
end

function MeteorShower.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    MeteorShower:Activate(Unit,UnitInfo)
end

return MeteorShower