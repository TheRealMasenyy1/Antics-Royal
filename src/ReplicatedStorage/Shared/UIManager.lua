local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local UIManager = {}

local EzVisuals = require(ReplicatedStorage.Shared.EasyVisuals)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local Cutscene = require(ReplicatedStorage.Shared.Cutscene)
local Spring = require(ReplicatedStorage.Shared.Utility.UISpring)
local _maid = MaidManager.new()

local player = Players.LocalPlayer

local function Grow(Frame, Goal : UDim2, Speed : number) : Tween
    Goal = Goal or UDim2.new(1,0,1,0)
    Speed = Speed or .5
    local Prop = {
        Size = Goal
    }

    local Tween = TweenService:Create(Frame, TweenInfo.new(Speed), Prop)
    Tween:Play()

    return Tween
end

local function GrowWithInfo(Frame, Goal : UDim2, Info : TweenInfo)
    if not Info then return error("You need to input Info") end

    Goal = Goal or UDim2.new(1,0,1,0)
    local Prop = {
        Size = Goal
    }

    local Tween = TweenService:Create(Frame, Info, Prop):Play()

    return Tween
end

local function GrowThickness(Stroke, Goal : number, Speed : number)
    Goal = Goal or 1
    Speed = Speed or .5
    local Prop = {
        Thickness = Goal
    }

    local Tween = TweenService:Create(Stroke, TweenInfo.new(Speed), Prop):Play()

    return Tween
end

local FirstStrokeColor = Color3.fromRGB(10, 30, 56)
local SecondStrokeColor = Color3.fromRGB(15, 44, 81)
local ThirdStrokeColor = Color3.fromRGB(36, 114, 197)
local LastOpenUI
local MiniOpenUI

function UIManager:GrowThickness(Stroke, Goal : number, Speed)
    Goal = Goal or 1
    Speed = Speed or .5
    local Prop = {
        Thickness = Goal
    }

    local Tween = TweenService:Create(Stroke, TweenInfo.new(Speed), Prop):Play()

    return Tween
end

function UIManager:HideItemInfo()
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core") or playerGui:WaitForChild("Main")
    local InfoFrame = Core.Content.InfoFrame

    InfoFrame.Visible = false
end

function UIManager:AddEffectToUI(UI, Color : ColorSequence, Transparency)
    local effect = EzVisuals.Gradient.new(UI, Color, Transparency)

    effect:SetOffsetSpeed(.35,.1)
    effect:SetRotation(45,.1)
    effect:SetTransparencyOffset(.7,.1)

    if UI:FindFirstChild("UIStroke") then
        local StrokeGradient = EzVisuals.Gradient.new(UI.UIStroke, Color, 0)
        
        StrokeGradient:SetOffsetSpeed(.35,.1)
        StrokeGradient:SetRotation(60,.1)
    end

    -- effectStroke.Size = 4

    return effect
end

function UIManager:AddEffectToText(UI, Rarity, Transparency, Thickness)
    Transparency = Transparency or .7
    Thickness = Thickness or 4
    local Colors = {
        ["Defualt"] = Color3.fromRGB(255, 255, 255),
        ["Rare"] = Color3.fromRGB(15, 91, 255),
        ["Epic"] = Color3.fromRGB(217, 2, 255),
        ["Legendary"] = Color3.fromRGB(255, 251, 0),
        ["Mythical"] = Color3.fromRGB(236, 0, 0),
        ["Secret"] = Color3.fromRGB(255, 0, 0),
    }

    local RarityColor = Colors[Rarity]

    local c = ColorSequence.new({
        ColorSequenceKeypoint.new(0,RarityColor),
        ColorSequenceKeypoint.new(.5,Color3.fromRGB(255, 145, 0)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,51,0))
    })

    if Rarity == "Legendary" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255, 145, 0)),
            ColorSequenceKeypoint.new(0.4,RarityColor),
            ColorSequenceKeypoint.new(0.6,Color3.fromRGB(255, 145, 0)),
            ColorSequenceKeypoint.new(0.8,RarityColor),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(255, 145, 0)),
        })
    elseif Rarity == "Secret" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB()),
            ColorSequenceKeypoint.new(0.4,RarityColor),
            ColorSequenceKeypoint.new(0.6,Color3.fromRGB()),
            ColorSequenceKeypoint.new(0.8,RarityColor),
            ColorSequenceKeypoint.new(1,Color3.fromRGB()),
        })
    elseif Rarity == "Mythical" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(.15, Color3.fromRGB(255, 218, 53)),
            ColorSequenceKeypoint.new(.25, Color3.fromRGB(87, 255, 53)),
            ColorSequenceKeypoint.new(.45, Color3.fromRGB(53, 248, 255)),
            ColorSequenceKeypoint.new(.55, Color3.fromRGB(53, 73, 255)),
            ColorSequenceKeypoint.new(.65, Color3.fromRGB(157, 53, 255)),
            ColorSequenceKeypoint.new(.75, Color3.fromRGB(225, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })

        -- local textEffect = EzVisuals.new(UI, "RainbowStroke", 0.5, 6, true);
    elseif Rarity == "Epic" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB()),
            ColorSequenceKeypoint.new(0.4,RarityColor),
            ColorSequenceKeypoint.new(0.6,Color3.fromRGB()),
            ColorSequenceKeypoint.new(0.8,RarityColor),
            ColorSequenceKeypoint.new(1,Color3.fromRGB()),
        })

    elseif Rarity == "Rare" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(4, 34, 204)),
            ColorSequenceKeypoint.new(0.4,RarityColor),
            ColorSequenceKeypoint.new(0.6,Color3.fromRGB(4, 34, 204)),
            ColorSequenceKeypoint.new(0.8,RarityColor),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(4, 34, 204)),
        })
    end

    local effect = EzVisuals.Gradient.new(UI, c, Transparency)
    -- local effectStroke = EzVisuals.Stroke.new(UI, Thickness)
    -- local StrokeGradient = EzVisuals.Gradient.new(effectStroke.Instance, c, 0)

    effect:SetOffsetSpeed(.35,.1)
    effect:SetRotation(45,.1)
    
    return effect --, StrokeGradient
end

function UIManager:Resize(Element : UIBase, Damping : number, Speed : number, Property, WaitUntiCompletion : boolean)
    Spring.target(Element, Damping, Speed, Property)
end

function UIManager:AddEffect(UI, Rarity, Transparency, Thickness)
    Transparency = Transparency or .7
    Thickness = Thickness or 4
    local Colors = {
        ["Defualt"] = Color3.fromRGB(255, 255, 255),
        ["Rare"] = Color3.fromRGB(15, 91, 255),
        ["Epic"] = Color3.fromRGB(217, 2, 255),
        ["Legendary"] = Color3.fromRGB(255, 251, 0),
        ["Mythical"] = Color3.fromRGB(236, 0, 0),
        ["Secret"] = Color3.fromRGB(255, 0, 0),
    }

    local RarityColor = Colors[Rarity]
    -- warn("Rarity: ", RarityColor, Rarity)
    local c = ColorSequence.new({
        ColorSequenceKeypoint.new(0,RarityColor),
        ColorSequenceKeypoint.new(.5,Color3.fromRGB(255, 145, 0)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,51,0))
    })

    if Rarity == "Legendary" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255, 145, 0)),
            ColorSequenceKeypoint.new(0.4,RarityColor),
            ColorSequenceKeypoint.new(0.6,Color3.fromRGB(255, 145, 0)),
            ColorSequenceKeypoint.new(0.8,RarityColor),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(255, 145, 0)),
        })
    elseif Rarity == "Secret" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB()),
            ColorSequenceKeypoint.new(0.4,RarityColor),
            ColorSequenceKeypoint.new(0.6,Color3.fromRGB()),
            ColorSequenceKeypoint.new(0.8,RarityColor),
            ColorSequenceKeypoint.new(1,Color3.fromRGB()),
        })
    elseif Rarity == "Mythical" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(.15, Color3.fromRGB(255, 218, 53)),
            ColorSequenceKeypoint.new(.25, Color3.fromRGB(87, 255, 53)),
            ColorSequenceKeypoint.new(.45, Color3.fromRGB(53, 248, 255)),
            ColorSequenceKeypoint.new(.55, Color3.fromRGB(53, 73, 255)),
            ColorSequenceKeypoint.new(.65, Color3.fromRGB(157, 53, 255)),
            ColorSequenceKeypoint.new(.75, Color3.fromRGB(225, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })

        -- local textEffect = EzVisuals.new(UI, "RainbowStroke", 0.5, 6, true);
    elseif Rarity == "Epic" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB()),
            ColorSequenceKeypoint.new(0.4,RarityColor),
            ColorSequenceKeypoint.new(0.6,Color3.fromRGB()),
            ColorSequenceKeypoint.new(0.8,RarityColor),
            ColorSequenceKeypoint.new(1,Color3.fromRGB()),
        })

    elseif Rarity == "Rare" then
        c = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(4, 34, 204)),
            ColorSequenceKeypoint.new(0.4,RarityColor),
            ColorSequenceKeypoint.new(0.6,Color3.fromRGB(4, 34, 204)),
            ColorSequenceKeypoint.new(0.8,RarityColor),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(4, 34, 204)),
        })
    end

    local effect = EzVisuals.Gradient.new(UI, c, Transparency)
    local effectStroke = EzVisuals.Stroke.new(UI, Thickness)
    local StrokeGradient = EzVisuals.Gradient.new(effectStroke.Instance, c, 0)

    effect:SetOffsetSpeed(.35,.1)
    effect:SetRotation(45,.1)
    -- effect:SetTransparencyOffset(.7,.1)

    StrokeGradient:SetOffsetSpeed(.35,.1)
    StrokeGradient:SetRotation(60,.1)

    return effect, StrokeGradient
end

function UIManager:AddButton(Button : TextButton,DownSize,OriginalSize)
    local TimeLimit = 1
    local Holding;
    local ButtonSpring;

    _maid:AddMaid(Button,"Down",Button.MouseButton1Down:Connect(function()
        local t = 0

        Spring.stop(Button)
        TweenService:Create(Button,TweenInfo.new(.1,Enum.EasingStyle.Bounce,Enum.EasingDirection.In),{Size = DownSize}):Play()

        Holding = _maid:AddMaid(Button,"Up",UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Spring.target(Button,.15,2,{
                    Size = OriginalSize--UDim2.fromScale(0.5,0.5)
                })
            end
        end))
    end))
end

function UIManager:UIOpenedInsideAnother(MainFrame, Frame, OnClosefunc : any) -- Used to open Lobby Frames 
    local Close = Frame:FindFirstChild("Close") or Frame:FindFirstChild("LeaveButton")
    Shortcut:PlaySound("MouseClick", true)
    if MiniOpenUI then MiniOpenUI.Visible = false Shortcut:PlaySound("UIClose", true) end
    Frame.Position = UDim2.new(.5,0,.3,0)

    Shortcut:PlaySound("UIOpen", true)
    Lighting.DepthOfField.Enabled = false
    Frame.Visible = true

    if Close and not Close:GetAttribute("ConnectionSet") then
        Close.MouseEnter:Connect(function()
            if Close:GetAttribute("IgnoreTween") then return end
            Grow(Close,UDim2.new(0.063 + 0.005, 0,0.112 + 0.005, 0),.15)
        end)
        
        Close.MouseLeave:Connect(function()
            if Close:GetAttribute("IgnoreTween") then return end
            Grow(Close,UDim2.new(0.063, 0,0.112, 0),.15)
        end)

        Close.Activated:Connect(function()
            if OnClosefunc then
                OnClosefunc()
            end

            Lighting.DepthOfField.Enabled = true
            Frame.Visible = false
            -- UIManager:UIClose(Frame)
        end)

        Close:SetAttribute("ConnectionSet", true)
    end

    MiniOpenUI = Frame
    TweenService:Create(Frame,TweenInfo.new(.25), {Position = UDim2.new(.5,0,.5,0)}):Play()
end

function UIManager:EnableGamepad(Frame)
    for _, Buttons in pairs(Frame:GetDescendants()) do
        if Buttons.Name == "Controller" then
            Buttons.Visible = true
        end
    end
end

function UIManager:UIOpened(Frame, OnClosefunc : any) -- Used to open Lobby Frames 
    local OpenUIDepth = Lighting:FindFirstChild("OpenUIDepth")
    Shortcut:PlaySound("MouseClick", true)
    if OpenUIDepth then
        Shortcut:PlaySound("UIOpen", true)
        local Close = Frame:FindFirstChild("Close") or Frame:FindFirstChild("LeaveButton")
        if LastOpenUI then LastOpenUI.Visible = false end
        Frame.Position = UDim2.new(.5,0,.3,0)

        Lighting.DepthOfField.Enabled = false
        OpenUIDepth.Enabled = true
        Frame.Visible = true

        local OriginalSize = Frame.Size
        UIManager:EnableGamepad(Frame)

        UIManager:HideItemInfo()

        if Close then
            _maid:AddMaid(Close,"Hovered",Close.MouseEnter:Connect(function()
                if Close:GetAttribute("IgnoreTween") then return end
                Grow(Close,UDim2.new(0.063 + 0.005, 0,0.112 + 0.005, 0),.15)
            end))
            
            _maid:AddMaid(Close,"Close",Close.MouseLeave:Connect(function()
                if Close:GetAttribute("IgnoreTween") then return end
                Grow(Close,UDim2.new(0.063, 0,0.112, 0),.15)
            end))
    
            _maid:AddMaid(Close,"Activated",Close.Activated:Connect(function()
                if OnClosefunc then
                    OnClosefunc()
                    Cutscene.DisableUI(player, "HUD", true)
                    UIManager:HideHUD(false)
                end

                UIManager:UIClose(Frame)
            end))

            Close:SetAttribute("ConnectionSet", true)
        end

        LastOpenUI = Frame
        TweenService:Create(OpenUIDepth,TweenInfo.new(.25), {FarIntensity = 1, FocusDistance = 0, InFocusRadius = 0}):Play()
        Spring.target(Frame,.4,2,{
            Position = UDim2.fromScale(.5,.5)
        })
        -- TweenService:Create(Frame,TweenInfo.new(.25), {Position = UDim2.new(.5,0,.5,0)}):Play()
    end
end

function UIManager:CloseDialog(Frame)
    Frame.Position = UDim2.new(.5,0,1.5,0)

    Cutscene:Enabled(false)
    Shortcut:PlaySound("UIClose", true)
    Cutscene.DisableUI(player, "HUD", true)
    local Tween = TweenService:Create(Frame,TweenInfo.new(.25),{Position = UDim2.new(0.5,0,1.5,0)})
    Tween:Play()

    Frame.Visible = true

    UIManager:OpenToolbar()

    return Tween
end

function UIManager:Visibility(Frame, WhatType, Visibility : number)
    for _, Frames in pairs(Frame:GetChildren()) do
        if Frames:IsA(WhatType) then
            if not Frames.Transparency then
                Frames.Transparency = Visibility
            else
                Frames.Visible = if Visibility > 0 then false else true 
            end
        end
    end
end

function UIManager:OpenDialog(Frame, PromptParent : BasePart, func : any, OnClosefunc : any)
    local maid = Maid.new()
    local CharacterCFrame = CFrame.new(player.Character:GetPivot().Position, PromptParent.CFrame.Position)
    local CameraCFrame = CharacterCFrame * CFrame.new(5,2.5, 4.5) -- or set the Y = 2.5
    local CameraCFrameRelativeToNpc = CFrame.new(CameraCFrame.Position, PromptParent.CFrame.Position)
    Frame.Position = UDim2.new(.5,0,1.5,0)

    Cutscene:Enabled(true)
    Shortcut:PlaySound("UIOpen", true)
    local Tween = TweenService:Create(Frame,TweenInfo.new(.25),{Position = UDim2.new(0.5, 0,0.95, 0)})
    Tween:Play()

    Frame.Visible = true

    Cutscene:TravelToSpringy(CameraCFrameRelativeToNpc,.5)
    
    UIManager:EnableGamepad(Frame)

    maid:GiveTask(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.KeyCode == Enum.KeyCode.ButtonX then
            func()
            maid:Destroy()
        elseif input.KeyCode == Enum.KeyCode.ButtonB then
            local Tween = TweenService:Create(Frame,TweenInfo.new(.25),{Position = UDim2.new(0.5, 0,0.95, 0)})
            Shortcut:PlaySound("UIClose", true)
            UIManager:CloseDialog(Frame)
            print("maid has been cleaned")
            maid:Destroy()
        end
    end))

    maid:GiveTask(Frame.Accept.Activated:Connect(func))

    maid:GiveTask(Frame.Close.Activated:Connect(function()
        local Tween = TweenService:Create(Frame,TweenInfo.new(.25),{Position = UDim2.new(0.5, 0,0.95, 0)})
        -- Shortcut:PlaySound("UIClose", true)
        UIManager:CloseDialog(Frame)
        UIManager:HideHUD(false)
        print("maid has been cleaned")
        if OnClosefunc then
            OnClosefunc()
        end
        maid:Destroy()
    end))

    return Tween, maid
end

function UIManager:OpenToolbar()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    local Content = Core:WaitForChild("Content")
    local Toolbar = Content:WaitForChild("Toolbar")

    local Tween = TweenService:Create(Toolbar,TweenInfo.new(.25), {Position = UDim2.new(0.5, 0, 0.89, 0)})
    Tween:Play()

    return Tween
end

function UIManager:CloseToolbar()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    local Content = Core:WaitForChild("Content")
    local Toolbar = Content:WaitForChild("Toolbar")

    local Tween = TweenService:Create(Toolbar,TweenInfo.new(.25), {Position = UDim2.new(0.5, 0,1.5, 0)})
    Tween:Play()

    return Tween
end

function UIManager:ClearFrame(WhatToClear , Parent, DeepSearch : boolean)
    local Cleanup = false
    for _, Object in pairs(Parent:GetChildren()) do
        if Object:IsA(WhatToClear) then
            Object:Destroy()
            Cleanup = true
        end
    end

    -- if Cleanup then print("UI has been cleaned") return true end
    if DeepSearch then
        for _, Object in pairs(Parent:GetChildren()) do
            if Object:FindFirstChildWhichIsA(WhatToClear) then
                Object:Destroy()
                Cleanup = true
            end
        end
    end
end

function UIManager:UIClose(Frame)
    local OpenUIDepth = Lighting:FindFirstChild("OpenUIDepth")
    if OpenUIDepth then
        Shortcut:PlaySound("UIClose", true)
        TweenService:Create(OpenUIDepth,TweenInfo.new(.25), {FocusDistance = 0.05, FarIntensity = 0.103, InFocusRadius = 23.005, NearIntensity = 0.546}):Play()
        OpenUIDepth.Enabled = false
        Lighting.DepthOfField.Enabled = true
        Frame.Visible = false
        UIManager:HideItemInfo()
    end
end

function UIManager.OnLobbyButtonHover(Btn, MouseOnUI)
    if MouseOnUI then
        Btn.FirstStroke.Thickness = 0
        Btn.FirstStroke.Color =Color3.fromRGB(133, 133, 133) ---

        Btn.TextButton.SecondStroke.Thickness = 0
        Btn.TextButton.SecondStroke.Color = Color3.fromRGB(202, 202, 202)

        Btn.TextButton.TextButton.ThirdStroke.Thickness = 0
        Btn.TextButton.TextButton.ThirdStroke.Color = Color3.fromRGB(255, 255, 255)
        
        TweenService:Create(Btn.TextButton.ImageLabel,TweenInfo.new(.15), {Rotation = -30}):Play()

        GrowThickness(Btn.FirstStroke,5, .15)
        GrowThickness(Btn.TextButton.SecondStroke,5, .15)
        GrowThickness(Btn.TextButton.TextButton.ThirdStroke,3, .15)

        Grow(Btn, UDim2.new(0.331 + 0.005, 0,0.234 + 0.005, 0), .15)
    else
        Btn.FirstStroke.Thickness = 5
        Btn.FirstStroke.Color = FirstStrokeColor

        Btn.TextButton.SecondStroke.Thickness = 5
        Btn.TextButton.SecondStroke.Color = SecondStrokeColor

        TweenService:Create(Btn.TextButton.ImageLabel,TweenInfo.new(.15), {Rotation = 0}):Play()

        Btn.TextButton.TextButton.ThirdStroke.Thickness = 3
        Btn.TextButton.TextButton.ThirdStroke.Color = ThirdStrokeColor 

        Grow(Btn, UDim2.new(0.331, 0,0.234, 0), .15)
    end
end

function UIManager.Visible(Frame, Visible : boolean, Size : UDim2)
    Size = Size or UDim2.new(0.691, 0,0.677, 0)

    if Visible then
        Frame.Size = UDim2.new(0,0,0,0)

        Shortcut:PlaySound("UIOpen",true)
        Frame.Visible = true
        Spring.target(Frame,.35,2,{
            Size = Size
        })
        -- Grow(Frame, Size)       
    else
        local UITween : Tween = Grow(Frame, UDim2.new(0.0, 0,0.0, 0))

        -- local _,err = pcall(function()
        Shortcut:PlaySound("UIClose",true)
        UITween.Completed:Connect(function()
            Frame.Visible = false
        end)
        -- end)

        -- if err then 
            -- warn(err)
            -- Frame.Visible = false
        -- end
    end
end

function UIManager:TweenMultipleUI(Elements, Speed, _callback)
    local Amount = #Elements
    local RequiredForCallBack = 0

    for _, InfoTable in ipairs(Elements) do
        local Tween = TweenService:Create(InfoTable.Element,TweenInfo.new(Speed),InfoTable.Tween)
        Tween:Play()

        Tween.Completed:Connect(function()
            RequiredForCallBack += 1
        end)
    end

    repeat
        task.wait()
    until RequiredForCallBack >= Amount

    if _callback then
        _callback()
    end
end

function UIManager:HoverOver(Btn : GuiButton, HoverColor : Color3) -- This will change the color of the Parent GuiObject
    local Frame : Frame = Btn.Parent
    local OriginalColor = Frame.BackgroundColor3
    HoverColor = HoverColor or Color3.fromRGB(171,171,171)
    
    _maid:AddMaid(Frame,"OnHover",Btn.MouseEnter:Connect(function()
        Shortcut:PlaySound("MouseHover", true)
        print("Tweening the hover effect")
        TweenService:Create(Frame,TweenInfo.new(.25),{BackgroundColor3 = HoverColor}):Play()
    end))

    _maid:AddMaid(Frame,"HoverLeft",Btn.MouseLeave:Connect(function()
        TweenService:Create(Frame,TweenInfo.new(.25),{BackgroundColor3 = OriginalColor}):Play()
    end))
end

function UIManager:SpringyMultipleUI(Elements,Damping, Speed,_callback)
    local Amount = #Elements
    local RequiredForCallBack = 0

    for _, InfoTable in ipairs(Elements) do
        Spring.target(InfoTable.Element,Damping,Speed,InfoTable.Tween)
        Spring.completed(InfoTable.Element,function()
            RequiredForCallBack += 1
        end)
    end

    repeat
        task.wait()
    until RequiredForCallBack >= Amount

    if _callback then
        _callback()
    end
end

function UIManager:TravelToSpringy(Element,Damping, Speed, InfoTable)
    Spring.target(Element,Damping,Speed,InfoTable)
end

function UIManager:OnMouseChangedWithCondition(UI : ImageButton | TextButton, OnEnterSize : UDim2, OnExitSize : UDim2, MustHave : string, DefualtStroke : number, Speed : number)
    Speed = Speed or .15
    local UIStroke = UI:FindFirstChild("UIStroke")
    UI.MouseEnter:Connect(function(x, y)
        if UI:FindFirstChildWhichIsA(MustHave) then
            -- Grow(UI, OnEnterSize, Speed)

            Spring.target(UI,.25,2,{
                Size = OnEnterSize --UDim2.fromScale(0.5,0.5)
            })

            Shortcut:PlaySound("MouseHover",true)
            if UIStroke then
                UIStroke.Enabled = true
                UIStroke.Thickness = 0
                GrowThickness(UIStroke,5.7, Speed)
            end
        end
    end)

    UI.MouseLeave:Connect(function()
        if UI:FindFirstChildWhichIsA(MustHave) then
            Spring.target(UI,.25,2,{
                Size = OnExitSize --UDim2.fromScale(0.5,0.5)
            })
            -- Grow(UI, OnExitSize, Speed)
            if UIStroke then
                GrowThickness(UIStroke,(DefualtStroke  or 0), Speed)
            end
        end
    end)
end

function UIManager:HideHUD(Value : boolean)
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    local Content = Core.Content
    local Hud = Content.HUD

    if Value then
        Spring.target(Hud,.2,2,{
            Size = UDim2.fromScale(1.5,1.5)
        })
    else
        Spring.target(Hud,.5,5,{
            Size = UDim2.fromScale(1,1)
        })
    end
end

function UIManager:OnMouseChanged(UI : ImageButton | TextButton, OnEnterSize : UDim2, OnExitSize : UDim2, UIOnHover : Frame, OnHover : any, OnHoverExit : any, Attribute : string, DefualtStroke : number)
    local UIStroke = UI:FindFirstChild("UIStroke")
    local Damping;
    local Stiffness;
    _maid:AddMaid(UI,"MousEnter",UI.MouseEnter:Connect(function(x, y)
        Spring.target(UI,.25,2,{
            Size = OnEnterSize --UDim2.fromScale(0.5,0.5)
        })

        if Attribute and not UI:GetAttribute(Attribute) then return end
        Shortcut:PlaySound("MouseHover",true)

        if UIOnHover then
            UIOnHover.Position = UI.Position -- + UDim2.new(-0.05,0,0.25,0)        
            -- UIOnHover.Visible = true
        end
        if UIStroke then
            UIStroke.Enabled = true
            UIStroke.Thickness = (DefualtStroke or 0)
            GrowThickness(UIStroke,2.7,.15)
        end
    end))

    _maid:AddMaid(UI,"MouseLeave",UI.MouseLeave:Connect(function()
        -- Grow(UI, OnExitSize, .15)

        Spring.target(UI,.25,2,{
            Size = OnExitSize --UDim2.fromScale(0.5,0.5)
        })

        if OnHoverExit then
            OnHoverExit()
        end

        if UIStroke then
            GrowThickness(UIStroke,(DefualtStroke or 0),.15)
        end
    end))
end

function UIManager:OnActionWithInfo(Button, Goal, Info)
    GrowWithInfo(Button, Goal, Info)
end

function UIManager:OnAction(Button, Goal, Speed)
    Grow(Button, Goal, Speed)
end

return UIManager
