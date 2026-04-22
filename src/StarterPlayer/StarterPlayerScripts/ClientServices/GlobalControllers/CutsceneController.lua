local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Cutscene = require(ReplicatedStorage.Shared.Cutscene)
local Signal = require(ReplicatedStorage.Packages.Signal)
local CutsceneController = Knit.CreateController {
    Name = "CutsceneController"
}

local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
CutsceneController.SummonEvent = Signal.new()
CutsceneController.SummonCompleted = Signal.new()

local function followCamera(RenderName,CameraPart)
    Cutscene:Enabled(true)

    RunService:BindToRenderStep(RenderName, 1,function()
        Camera.CFrame = CameraPart.CFrame
    end)
end

function Emit(Attachment,Value)
    Value = Value or 10

    for _, particle in Attachment:GetDescendants() do
        task.spawn(function()
            if particle:IsA("ParticleEmitter") then
                if not Value then
                    Value = particle:GetAttribute("EmitCount") 
                end
                particle:Emit(Value) 
            end
        end)
    end
end

function Enable(Attachment,Value)
    for _, particle in Attachment:GetDescendants() do
        task.spawn(function()
            if not particle:IsA("Attachment") and particle:IsA("ParticleEmitter") then
                particle.Enabled = Value 
            end
        end)
    end
end

function ChangeVisiblity(Model, Value : number)
    for _, Parts in Model:GetDescendants() do
        task.spawn(function()
            if Parts:IsA("MeshPart") then
               TweenService:Create(Parts,TweenInfo.new(.25),{Transparency = Value }):Play() 
            end
        end)
    end
end

function EnableLight(Model,Value : number)
    for _, Light in Model:GetDescendants() do
        task.spawn(function()
            if Light:IsA("PointLight") then
               TweenService:Create(Light,TweenInfo.new(.5),{Range = Value }):Play() 
            end
        end)
    end
end

local BigShenronAnimationPlaying = false

function CutsceneController.Summon(Skip : boolean)
    local MovieGui = Cutscene.DisableUI(player,"MovieMode", true)
    Cutscene.DisableUI(player,"Content", false)
    local Transition = MovieGui.Transition
    local SummoningFolder = workspace.Summoning
    local ParticlePart = SummoningFolder.ParticlePart
    local Dragonballs = SummoningFolder.Dragonballs
    local BigShenron = SummoningFolder.BigShenron
    local EntranceDragon = SummoningFolder.ShenronEntranceShadow
    local AnimationDragon = SummoningFolder.ShenronEntrance
    local Completed = false

    local Entrance : AnimationTrack = EntranceDragon.AnimationController.Animator:LoadAnimation(SummoningFolder.EntranceAnimation)
    local ActualEntrance = AnimationDragon.AnimationController.Animator:LoadAnimation(SummoningFolder.EntranceAnimation)
    local Idle = BigShenron.AnimationController.Animator:LoadAnimation(SummoningFolder.IdleAnimation)
    local OpenUIDepth = Lighting:FindFirstChild("OpenUIDepth")

    if OpenUIDepth then
        OpenUIDepth.NearIntensity = 0.018
        OpenUIDepth.FocusDistance = 32.72
        OpenUIDepth.FarIntensity = 0.773
    end

    local function TransitionFunc(WaitTime : number,Speed : number)
        Speed = Speed or .5
        WaitTime = WaitTime or 1

        Cutscene:Enabled(true)

        for _, Frames in pairs(Transition:GetChildren()) do
            Cutscene:Resize(Frames,UDim2.new(1,0,.5,0),Speed,nil)
        end
        task.wait(WaitTime)

        for _, Frames in pairs(Transition:GetChildren()) do
            Cutscene:Resize(Frames,UDim2.new(1, 0,0.107, 0),Speed,nil)
        end

        Completed = true
    end

   local function LastStage()
        task.spawn(TransitionFunc,1,.35)

        task.spawn(Enable,SummoningFolder.TopFog, true)
        task.wait(.5)
        Lighting.ScarySky.Parent = ReplicatedStorage
        BigShenron:PivotTo(SummoningFolder.Spawn.CFrame * CFrame.new(0,-28.5,0)) -- Camera.CFrame * CFrame.new(0,-20,-60) * CFrame.Angles(0,math.random(180 * 2),0)

        if not BigShenronAnimationPlaying then
            Idle:Play()
            Idle:AdjustSpeed(.2)
            BigShenronAnimationPlaying = true
        end

        RunService:UnbindFromRenderStep("FollowCamera")
        Camera.CFrame = SummoningFolder.Camera3.CFrame

        task.delay(1.5,function()
            CutsceneController.SummonCompleted:Fire()
            ChangeVisiblity(AnimationDragon, 1)
        end)
    end

    if not Skip then
        TransitionFunc(1.5,.5)
        Camera.CFrame = SummoningFolder.Camera1.CFrame
        
        task.wait(1)
        EnableLight(Dragonballs, 8)
        task.delay(1.5,Enable,Dragonballs.PrimaryPart, true)
        task.wait(2.5)
        Cutscene:TravelTo(SummoningFolder.Camera2.CFrame,.5,function()
            if OpenUIDepth then
                OpenUIDepth.NearIntensity = 0.327
                OpenUIDepth.FocusDistance = 32.72
                OpenUIDepth.FarIntensity = 0.273
            end
            --- Play Dragon Animation
            AnimationDragon:PivotTo(EntranceDragon:GetPivot())
            
            EntranceDragon.CameraRig.Anchored = false
            
            Entrance:Play()
            ActualEntrance:Play()
            
            Emit(ParticlePart.Attachment)
            task.spawn(ChangeVisiblity,EntranceDragon, 0)
            task.wait(.15)
            Emit(ParticlePart.Wind)
    
            Entrance:GetMarkerReachedSignal("Switch"):Connect(function()
                ChangeVisiblity(EntranceDragon, 1)
                ChangeVisiblity(AnimationDragon, 0)
            end)
    
            Entrance:GetMarkerReachedSignal("NewDragon"):Connect(function()
                --- Finale Stage ---
                LastStage()
            end)
    
            followCamera("FollowCamera",EntranceDragon.CameraRig)
        end)
    else
        LastStage()  
    end
end

function CutsceneController:KnitInit()

end

function CutsceneController:KnitStart()
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.KeyCode == Enum.KeyCode.C then
            print("Pressed to start cutscene!")
            -- CutsceneController.Summon()
        end
    end)

    CutsceneController.SummonEvent:Connect(CutsceneController.Summon)
end

return CutsceneController