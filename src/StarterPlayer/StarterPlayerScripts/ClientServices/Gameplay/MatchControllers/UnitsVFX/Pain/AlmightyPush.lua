local AlmightyPush = {}

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage.Assets.VFX.Pain
local Animations = ReplicatedStorage.Assets.Animations.Pain

function Emit(Attachment,Value)
     for _, particle in Attachment:GetDescendants() do
        if not particle:IsA("ParticleEmitter") then continue end
         if not Value then
             Value = particle:GetAttribute("EmitCount") 
         end
         particle:Emit(Value) 
     end
end

 function StopAnimsExeptIdle(Unit)
    local Animator = Unit.Humanoid:FindFirstChild("Animator")
    if Animator then
        for _,Animation in pairs(Animator:GetPlayingAnimationTracks()) do
            print(Animation.Name,Animation.Animation.Name)
            if Animation.Name ~= "Idle" then
                Animation:Stop()
            end
        end
    end
end

function AlmightyPush:Activate(Unit,UnitInfo)
    if UnitInfo.NoAnimation then
        warn("naur")
        local AlmightyPush = Assets.Almightypush:Clone()
        AlmightyPush.Parent = Unit
        AlmightyPush.CFrame = Unit.Torso.CFrame * CFrame.Angles(math.rad(-90),0,0)
        
        Debris:AddItem(AlmightyPush,3)
        
        Emit(AlmightyPush)
        return
    end

    local Track = Unit.Humanoid.Animator:LoadAnimation(Animations.AlmightyPush)

    Track:Play()

    Track:GetMarkerReachedSignal("Hit"):Connect(function()
        local AlmightyPush = Assets.Almightypush:Clone()
        AlmightyPush.Parent = Unit
        AlmightyPush.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(-90),0,0)
        
        Debris:AddItem(AlmightyPush,3)
        
        Emit(AlmightyPush)
    end)
end

function AlmightyPush.Attack(Unit,UnitInfo)
    AlmightyPush:Activate(Unit,UnitInfo)
end


return AlmightyPush