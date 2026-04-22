local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Cutscene = require(ReplicatedStorage.Shared.Cutscene)
local Pain = {}

local function getAffectedUnitsByExplosion(Object, distance) -- Id is of the unit that killed the mob that will explode
    local units = {}
    local parentFolder = workspace.GameAssets.Units:GetChildren()

    for _, unit in pairs(parentFolder) do
        if unit:GetAttribute("Stun") == true then continue end
        if not unit:FindFirstChild("HumanoidRootPart") then continue end
        local currentDistance = (unit.HumanoidRootPart.Position - Object.Position).Magnitude

        if currentDistance <= distance then
            table.insert(units, unit)
        end
    end

    return units
end

function Emit(Attachment,Value)
    -- Value = Value or 10
 
     for _, particle in Attachment:GetDescendants() do
        if not particle:IsA("ParticleEmitter") then continue end
         if not Value then
             Value = particle:GetAttribute("EmitCount") 
         end
         particle:Emit(Value) 
     end
 end

 function Invisible(Model, Value)
    for _, part in Model:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= ("Detector") and part.Name ~= ("Upgrade") and part.Name ~= "HumanoidRootPart" then
           -- if Value == 0 and part.Transparency == 1 then continue end
            part.Transparency = Value 
        end
    end
end

local function Visible(Unit : Model,Value : boolean)
    for _, object : BasePart in pairs(Unit:GetDescendants()) do
        local HeadUI = Unit.Head:FindFirstChild("MobStatusUI")
        local Face : Decal = Unit.Head:FindFirstChildWhichIsA("Decal")
        if object:IsA("BasePart") then
            object.Transparency = if Value then 0 else 1
        end

        if HeadUI then
            HeadUI.Enabled = Value
        end

        if Face then
            Face.Transparency = if Value then 0 else 1
        end
    end
end

function Pain:Intro(entityModel)
    local MobService = Knit.GetService("MobService")
    local UnitService = Knit.GetService("UnitService")
    --local UIController = Knit.GetController("UIController")
    local fakeModel = entityModel:Clone()
    local cutsceneFinished = false

    local Animations = ReplicatedStorage.Assets.Animations.BossIntros.Pain
    local CameraModel = Animations.CameraRig:Clone()

    local mobs = {}

    local UnitInfo = {
        Unit = fakeModel,
        IsBoss = true,
        Ability = "AlmightyPush",
        NoAnimation = true
    }
    

    fakeModel.Parent = workspace.Debris
    fakeModel:PivotTo(CFrame.new(90.5270157, 41.9644012, -323.775787, 1, 0, 0, 0, 1, 0, 0, 0, 1))

    CameraModel.Parent = workspace.Debris
    CameraModel:PivotTo(fakeModel.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4.5, -1, 0, 0, 0, 1, 0, 0, 0, -1))

    local cameraAnimationTrack = CameraModel.Humanoid.Animator:LoadAnimation(Animations.Camera)
    local bossTrack = fakeModel.Humanoid.Animator:LoadAnimation(Animations.Boss)

    UnitService.Client.BossTransition:FireAll(1)
    UnitService.Client.MovieMode:FireAll(true)
    
    task.wait(.9)

    bossTrack:Play()
    cameraAnimationTrack:Play()

    bossTrack:GetMarkerReachedSignal("Push"):Connect(function()
        UnitService.Client.AttackVFX:FireAll(UnitInfo)
    end)

    cameraAnimationTrack:GetMarkerReachedSignal("End"):Connect(function()
        cutsceneFinished = true

        Debris:AddItem(CameraModel,1)

        fakeModel:Destroy()
    end)

    MobService.Client.BossIntro:FireAll(CameraModel)

    for _,Mob in pairs(workspace.Gameplay.Mobs:GetChildren()) do
        table.insert(mobs,Mob)
        Visible(Mob,false)
    end

    repeat task.wait() until cutsceneFinished

    UnitService.Client.MovieMode:FireAll(false)

    for _,mob in mobs do
        Visible(mob,true)
    end
end

function Pain:Activate(entityModel) -- Boss init thing
    local looping = true
    local attack_cooldown = 10
    local UnitService = Knit.GetService("UnitService")
    local oldSpeed = entityModel:GetAttribute("Speed")

    local UnitService = Knit.GetService("UnitService")

    local UnitInfo = {
        Unit = entityModel,
        IsBoss = true,
        Ability = "AlmightyPush"
    }

    while looping do
        task.wait(attack_cooldown)

        if entityModel:GetAttribute("Health") <= 0 then looping = false; break end
        if entityModel.Parent == nil then looping = false; break end

        local AffectedUnits = getAffectedUnitsByExplosion(entityModel.HumanoidRootPart,200)

        if #AffectedUnits ~= 0 then
            print("not 0")
            UnitService:StunUnits(AffectedUnits,5, os.clock())
        end

        UnitService.Client.AttackVFX:FireAll(UnitInfo)
    
        entityModel:SetAttribute("Speed",0)
    
        task.wait(2)
        
        entityModel:SetAttribute("Speed",oldSpeed)
        
    end
end

return Pain