local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UnitModule = require(ReplicatedStorage.Shared.UnitInfo)
local UnitsInfoModule = require(ReplicatedStorage.SharedPackage.Units)
local CameraShake = require(ReplicatedStorage.Shared.Utility.CameraShaker)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local _maid = MaidManager.new()

local SummonModule = {}

local VFX = ReplicatedStorage.Assets.VFX
local Units = ReplicatedStorage.Units
local Animations = ReplicatedStorage.Assets.Animations

local Camera = workspace.CurrentCamera
local player = game:GetService("Players").LocalPlayer

local Rarity = {
    [1] = "Rare",
    [2] = "Epic",
    [3] = "Legendary",
    [4] = "Mythical",
    [5] = "Secret",
}

function SummonModule:SetScriptable(Value : boolean)
    if Value then
        Camera.CameraType = Enum.CameraType.Scriptable
    else
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function quadraticBezier(p0, p1, p2, t)
    local q0 = lerp(p0, p1, t)
    local q1 = lerp(p1, p2, t)

    local pointOnCurve = lerp(q0, q1, t)
    return pointOnCurve
end


function SummonModule:CameraGetCFrame()
    return Camera.CFrame, Camera
end

function SummonModule:ShowUnit(Unit)
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    local Content = Core:WaitForChild("Content")
    local InspectFrame = Core:WaitForChild("InspectContent")
    local Continue = InspectFrame:WaitForChild("Continue")
    local UnitRarity = InspectFrame:WaitForChild("Rarity")

    local CameraCFrame,Camera = SummonModule:CameraGetCFrame()
    local SummonedUnit = SummonModule:GetUnit(Unit.Unit,CameraCFrame * CFrame.new(0,2,-3) * CFrame.Angles(0,math.rad(180),0))--createTracePart(player,CameraCFrame * CFrame.new(0,0,-3))
    local relativeCFrame = CameraCFrame * CFrame.new(0,0,-3) * CFrame.Angles(0,math.rad(180),0)
    local Particle = SummonModule:GetParticle("Summon")
    -- local backGroundParticle = SummonModule:GetParticle("BackVFX")
    local Animation = Animations:FindFirstChild(Unit.Unit .."Idle", true)
    local maid = Maid.new()

    SummonedUnit.Parent = Camera
    AnimationIsDone = false

    SummonModule:SetDepthOfField(true, 2.36, true)
    
    Particle.upgrade.Parent = SummonedUnit.PrimaryPart
    
    if Animation then
        local AnimationController = SummonedUnit:FindFirstChild("Humanoid") or SummonedUnit:FindFirstChild("AnimationController") 
        if AnimationController then
            local Anim = AnimationController.Animator:LoadAnimation(Animation)
            Anim:Play()
        end
    end

    local unitData = UnitModule[Unit.Unit]
    local unitRarity = Rarity[UnitsInfoModule[Unit.Unit].Rarity]
    local TypeSynon = {
        ["Ground"] = "GRND",
        ["Hill"] = "Hill",
        ["Hybrid"] = "Hybrid"
    }

    UnitRarity.Text = unitRarity
    InspectFrame.InfoFrame.Rarity.Text = unitRarity
    InspectFrame.InfoFrame.UnitType.Type.Text = TypeSynon[UnitsInfoModule[Unit.Unit].UnitType] 

    local TweenInf = TweenService:Create(SummonedUnit.PrimaryPart,TweenInfo.new(.25),{CFrame = relativeCFrame})
    TweenInf:Play()

    Content.Visible = false
    InspectFrame.Visible = true
    InspectFrame.UnitName.Text = Unit.Unit
    InspectFrame.InfoFrame.UnitName.Text = Unit.Unit

    local RarityText = UIManager:AddEffectToText(InspectFrame.InfoFrame.Rarity, unitRarity,0,0)
    local RarityV2Text = UIManager:AddEffectToText(InspectFrame.Rarity, unitRarity,0,0)
    local InfoStroke = UIManager:AddEffectToText(InspectFrame.InfoFrame.UIStroke, unitRarity,0,2)
    -- InspectFrame.Rarity.Text = Rarity[unitData.Rarity]
    -- InspectFrame.InfoFrame.Rarity.Text = Rarity[unitData.Rarity] .. " - " .. unitData.UnitType

    -- ChangeColor(attachment, RarityColor[unitRarity])
    _maid:AddMaid(InspectFrame,"Visible",InspectFrame.Changed:Connect(function()
        if not InspectFrame.Visible then
            RarityText:Destroy()
            RarityV2Text:Destroy()
            InfoStroke:Destroy()
        end
    end))

    local DIF = {
        ["Cooldown"] = "CD",
        ["Damage"] = "DMG",
        ["Range"] = "RANGE",
    }

    for name, Stat in Unit.Stats do
        local Label = InspectFrame.InfoFrame:FindFirstChild(name)
        if Label then
            local gradeValue, grade, Value = UnitManager:ConvertGrade(Unit, name)
            Label.Text.Text = DIF[name] .. "("..Stat..") " ..": " .. Value
        end
    end

    TweenInf.Completed:Connect(function(playbackState)
        AnimationIsDone = true
        SummonModule:Emit(SummonedUnit, 5)
    end)

    maid:GiveTask(Continue.Activated:Connect(function()
        maid:Destroy()
        -- Content.Visible = true
        InspectFrame.Visible = false
        SummonModule:SetDepthOfField(false)
    end))
end


function SummonModule:PlayDragonBalls()
    local CameraCFrame,Camera = SummonModule:CameraGetCFrame()
    local DragonballPos = ReplicatedStorage.DragonballPos
    local Dragonball = ReplicatedStorage.dragonballs
    local relativeCFrame = CameraCFrame * CFrame.new(0,0,-10) * CFrame.Angles(0,math.rad(180),0)
    local p1Table = {
        [1] = CameraCFrame.Position - Vector3.new(0,5,0),
        [2] = CameraCFrame.Position + Vector3.new(0,0,5),
        [3] = CameraCFrame.Position + Vector3.new(10,0,0),
        [4] = CameraCFrame.Position - Vector3.new(0,5,0),
        [5] = CameraCFrame.Position + Vector3.new(0,5,0),
        [6] = CameraCFrame.Position + Vector3.new(0,5,0),
        [7] = CameraCFrame.Position - Vector3.new(0,5,0),
    }

    SummonModule:SetScriptable(true)

    local function ShakeCamera(shakeCFrame)
        Camera.CFrame = Camera.CFrame * shakeCFrame
    end
    local camshake = CameraShake.new(Enum.RenderPriority.Camera.Value, ShakeCamera)

    local newPos = DragonballPos:Clone()
    newPos:PivotTo(relativeCFrame)
    newPos.Parent = Camera

    local newDragonball : Model = Dragonball:Clone()
    newDragonball:PivotTo(newPos:GetPivot())
    -- newDragonball:PivotTo(CameraCFrame * CFrame.new(0,0,4) * CFrame.Angles(0,math.rad(90),math.rad(90)))
    newDragonball.Parent = Camera

    -- camshake:Start()
    -- camshake:ShakeOnce(1.5,.1, .1)
    -- camshake:Shake(CameraShake.Presets.Summon)

    for i = 1,#newDragonball:GetChildren() do
        local isDone = false
        local SummonParticle = SummonModule:GetParticle("Summon")
        local PrimaryPart = newDragonball["dragonball "..i].PrimaryPart
        TweenService:Create(Camera,TweenInfo.new(.25,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0),{ FieldOfView = 90}):Play()

        SummonParticle.upgrade.Parent = PrimaryPart
        for t = 0, 1, .01 do
            -- TweenService:Create(PrimaryPart,TweenInfo.new(1),{ CFrame = quadraticBezier(PrimaryPart.CFrame.Position,p1Table[i],newPos[i].Position,t)})
            PrimaryPart.CFrame = CFrame.new(quadraticBezier(PrimaryPart.CFrame.Position,p1Table[i],newPos[i].Position,t))
            RunService.Heartbeat:Wait()
        end

        local TweenBack = TweenService:Create(Camera,TweenInfo.new(.2,Enum.EasingStyle.Bounce,Enum.EasingDirection.InOut,0),{ FieldOfView = 70})
        TweenBack:Play()

        TweenBack.Completed:Connect(function(playbackState)
            SummonModule:Emit(PrimaryPart, 8)
            PrimaryPart.CFrame = CFrame.new(PrimaryPart.CFrame.Position, Camera.CFrame.Position)
            isDone = true
        end)

        repeat task.wait() until isDone
    end
    local Spin = 0
    local MaxSpin = 360 

    local function Enable(Attachment,Value)
        for _, particle in Attachment:GetDescendants() do
            if not particle:IsA("Attachment") then
                particle.Enabled = Value 
            end
        end
    end

    for i = 1,#newDragonball:GetChildren() do
        -- task.spawn(function()
        local SummonGlow = SummonModule:GetParticle("DragonballVFX")
        SummonGlow.Attachment.Parent = newDragonball["dragonball " .. i].PrimaryPart

        for _, parts in newDragonball["dragonball " .. i]:GetDescendants() do
            if parts:IsA("BasePart") and parts.Name ~= "Star" then
                TweenService:Create(parts,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0),{ Color = Color3.fromRGB(51, 210, 250) }):Play()
            end       
        end

        Enable(newDragonball["dragonball " .. 1].PrimaryPart.Attachment, true)
            -- end)
    end

    task.wait(1)
    while Spin < MaxSpin do
        Spin += 1
        newDragonball:PivotTo(newDragonball:GetPivot() * CFrame.Angles(0,0,math.rad(Spin)))
        task.wait()
    end
    -- local isActive = true

    -- repeat
    --     task.wait()
    -- until not isActive
    return newDragonball, newPos
end

function SummonModule:GetUnit(UnitName : string, CFRAME, Scale)
    Scale = Scale or .35
    local unit = Units:FindFirstChild(UnitName)
    if unit then
        local newUnit : Model = unit:Clone()
        newUnit.PrimaryPart.PivotOffset = CFrame.new(0,0,0)
        newUnit:ScaleTo(Scale)
        newUnit:PivotTo(CFRAME)

        for _,parts : BasePart in pairs(newUnit:GetDescendants()) do
            if parts:IsA("BasePart") then
                parts.CollisionGroup = "Summon"
            end
        end

        return newUnit
    end
end

function SummonModule:Emit(Part,count)
    for _,Object in ipairs(Part:GetDescendants()) do
        if Object:IsA("ParticleEmitter") then
            Object:Emit(count)
        end
    end
end

function SummonModule:GetParticle(Name : string)
    for _, particle in ipairs(VFX:GetDescendants()) do
        if particle:IsA("BasePart") and particle.Name == Name then
            local newParticle = particle:Clone()
            return newParticle
        end
    end

    return nil
end

function SummonModule:SetDepthOfField(Value : boolean, Distance : number, IgnoreSummonFrame : boolean)
    Distance = Distance or 9.64
    local OpenUIDepth = Lighting:FindFirstChild("OpenUIDepth")
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    local SummonFrame = Core:WaitForChild("SummonContent")
    local Content = Core:WaitForChild("Content")
    
    if OpenUIDepth then
        if Value then
            Lighting.DepthOfField.Enabled = false
            OpenUIDepth.Enabled = true
            if not IgnoreSummonFrame then
                SummonFrame.Visible = true
            end
            Content.Visible = false
            SummonModule:SetScriptable(true)

            TweenService:Create(OpenUIDepth,TweenInfo.new(.25), {FarIntensity = 1, FocusDistance = Distance, InFocusRadius = 0}):Play()
        else
            local OpenUIDepth = Lighting:FindFirstChild("OpenUIDepth")
            if OpenUIDepth then
                Camera:ClearAllChildren()

                if not IgnoreSummonFrame then
                    SummonFrame.Visible = false
                end

                Content.Visible = true
                TweenService:Create(OpenUIDepth,TweenInfo.new(.25), {FocusDistance = 0.05, FarIntensity = 0.103, InFocusRadius = 23.005, NearIntensity = 0.546}):Play()
                OpenUIDepth.Enabled = false
                Lighting.DepthOfField.Enabled = true

                SummonModule:SetScriptable(false)
            end
        end
    end
end

return SummonModule