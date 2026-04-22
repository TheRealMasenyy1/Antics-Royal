local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Cutscene = {}
local Camera = workspace.CurrentCamera
local UISpring = require(ReplicatedStorage.Shared.Utility.UISpring)
local Spring = require(ReplicatedStorage.Shared.Utility.Spring)

local player = game.Players.LocalPlayer

function Cutscene.DisableUI(player, UI : string, Value : boolean)
    local playerGui = player:WaitForChild("PlayerGui")
    local TheUI = playerGui:FindFirstChild(UI,true) or playerGui.Core:FindFirstChild(UI,true)
    Value = Value or false

    if TheUI and TheUI:IsA("ScreenGui") then
        TheUI.Enabled = Value

        return TheUI
    elseif TheUI and TheUI:IsA("Frame") then
        TheUI.Visible = Value

        return TheUI
    end
end

function Cutscene:Enabled(Value : boolean)
    local Character = player.Character

    Camera.CameraType = if Value then Enum.CameraType.Scriptable else Enum.CameraType.Custom
end

function Cutscene:Resize(UI : UIBase,GoalSize, Speed, _callback)
    Speed = Speed or 1

    local TweenProp = {
        Size = GoalSize,
        Position = UI.Position
    }

    local Tween = TweenService:Create(UI, TweenInfo.new(Speed), TweenProp)
    Tween:Play()

    if _callback then
        Tween.Completed:Connect(_callback)
    end

    return Tween
end

-- function Cutscene.DisableUI(player, UI : string, Value : boolean)
function Cutscene:DisableHud(player, Value : boolean)
    local playerGui = player:WaitForChild("PlayerGui")
    local Frame = playerGui:WaitForChild("HUD")
    local HUDPOS = {
        ["Quests"] = UDim2.new(-0.25, 0,0.213, 0),
        ["Items"] = UDim2.new(-0.25, 0,0.213, 0),
        ["Units"] = UDim2.new(-0.25, 0,0.442, 0),
        ["Shop"] = UDim2.new(-0.25, 0,0.442, 0),
    }
    if Frame and Value == true then
        for _, HudBtn in pairs(Frame:GetChildren()) do
            if not HudBtn:IsA("TextButton") then continue end
            HudBtn:SetAttibute("OriginalPos", HudBtn.Position)
        end
        -- Cutscene.DisableUI(player,"HUD", false) -- 
    end
end

function Cutscene:TravelToSpringy(GoalCFrame : CFrame, Speed, _callback)
    UISpring.target(Camera,.5,2,{
        CFrame = GoalCFrame,
    })
end

function Cutscene:TravelTo(GoalCFrame : CFrame, Speed, _callback)
    Speed = Speed or 1

    local TweenProp = {
        CFrame = GoalCFrame,
    }

    local Tween = TweenService:Create(Camera, TweenInfo.new(Speed), TweenProp)
    Tween:Play()

    if _callback then
        Tween.Completed:Connect(_callback)
    end

    return Tween
end

return Cutscene