local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Voxel = require(ReplicatedStorage.Shared.Utility.VoxelizeHandler)

local ShurikenThrow = {}

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
    Value = Value or 10

    for _, particle in Attachment:GetChildren() do
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

function ShurikenThrow:Activate(Unit,UnitInfo)
    local HumanoidRootPart = Unit.HumanoidRootPart
    local ObjectList = {}
    local Speed = 2

    for i = 1, 3 do
        local Shuriken = LeafNinjaAssets.Shuriken:Clone()
        Shuriken.Parent = Unit
        Shuriken.CFrame = HumanoidRootPart.CFrame * CFrame.new((-2) + i,0,2) * CFrame.Angles(math.rad(-90),0,0)
        Shuriken.Anchored = true

        TweenService:Create(Shuriken,TweenInfo.new(.25),{Transparency = 0}):Play()
        table.insert(ObjectList,Shuriken)
        task.wait()
    end

    for _, Shuriken in ipairs(ObjectList) do
        local Tween = TweenService:Create(Shuriken,TweenInfo.new(1/Speed),{Position = CFrame.new(UnitInfo.Target.Position).Position + HumanoidRootPart.CFrame.LookVector * 10})
        Tween:Play()
        SoundController:Play("ShurikenThrow",{Parent = Shuriken}) 
        Tween.Completed:Wait()
        Shuriken:Destroy()
        UnitService:RequestDamage(Unit)
    end
end

function ShurikenThrow.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    SoundController = Knit.GetController("SoundController")
    -- SoundController
    ShurikenThrow:Activate(Unit,UnitInfo)
end

return ShurikenThrow