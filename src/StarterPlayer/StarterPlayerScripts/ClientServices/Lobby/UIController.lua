local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local maidManager = MaidManager.new()
-- local easyVisuals = require(ReplicatedStorage.Shared.Utility.EasyVisuals)

local UIController = Knit.CreateController {
    Name = "UIController",
    Server = {}
}

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Content

local ProfileService;
local SystemController;
local CurrentLevel;
local EffectService;

function UIController:KnitInit()

end

function UIController:GetUI(Parent, Name : string)
    for _,UI in pairs(Parent:GetDescendants()) do
        if UI.Name == Name then
            return UI
        end
    end
end

local HudSizeIncrease = UDim2.new(0.0625, 0,0.075, 0) 
local HudSizeDecrease = UDim2.new(0.050, 0, 0.060, 0) 
local LevelRequirement = {
    [1] = 1;
    [2] = 1;
    [3] = 10;
    [4] = 15;
    [5] = 20;
}

function UIController.UnlockSlot(Level)
    local Toolbar = Content:WaitForChild("Toolbar")

    for lvlSlot,levelrequire in LevelRequirement do
        local Slot = Toolbar:FindFirstChild(lvlSlot)        

        if Slot and Level >= levelrequire then
            Slot.Lock.Visible = false
            Slot.Lvl.Visible = false
        end
    end 

end

function UIController.Transition(TransitionTime)
    local playerGui = player.PlayerGui
    local Transition = playerGui.Transition
    local Frame = Transition.Black
    local UIGradient = Frame.UIGradient
    
    TweenService:Create(Frame,TweenInfo.new(.15),{BackgroundTransparency = 0}):Play()

    task.wait(TransitionTime)
    TweenService:Create(Frame,TweenInfo.new(.15),{BackgroundTransparency = 1}):Stop()
end

function UIController.UpdateGems(NewAmount : number)
    local Toolbar = Content:WaitForChild("Toolbar")
    local GemsLabel = UIController:GetUI(Toolbar,"Gems")

    GemsLabel.TextLabel.Text = NewAmount
end

function UIController.UpdateCoins(NewAmount : number)
    local Toolbar = Content:WaitForChild("Toolbar")
    local MoneyLabel = UIController:GetUI(Toolbar,"Money")

    MoneyLabel.TextLabel.Text = NewAmount
end

function UIController.UpdateExp(newValue,MaxExp, Level)
    local Toolbar = Content:WaitForChild("Toolbar")
    local Exp_lb = UIController:GetUI(Toolbar,"Exp")
    local ExpBar = UIController:GetUI(Toolbar,"ExpBar")
    local Prop = {
        Size = UDim2.new(newValue / MaxExp,0,1,0)
    }

    local Tween = TweenService:Create(ExpBar,TweenInfo.new(1),Prop)
    Tween:Play()

    UIController.UnlockSlot(Level)
    Exp_lb.Text = "Level " .. Level .. " (" .. newValue .. "/" .. MaxExp ..")"
end

function UIController:UnitsTab(Units)
    local InventoryController = Knit.GetController("InventoryController")
    local OriginalSize = Units.Size
    local Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(142, 22, 221)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(225, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(142, 22, 221)),
    })

    UIManager:AddEffectToUI(Units.Icon,Color,0)
    UIManager:AddEffectToUI(Units.Empty,Color,0)
    -- UIManager:AddEffectToUI(Units.Border,Color,0)
    UIManager:OnMouseChanged(Units,HudSizeIncrease,OriginalSize, nil, function()
        TweenService:Create(Units.Icon,TweenInfo.new(.15), {Rotation = -30}):Play()
        -- UIManager:GrowThickness(Units.Border.UIStroke,3, .15)
    end, function() -- OnLeave
        -- UIManager:GrowThickness(Units.Border.UIStroke,0, .15)
        TweenService:Create(Units.Icon,TweenInfo.new(.15), {Rotation = 0}):Play()
    end)

    maidManager:AddMaid(Units,"Activated",Units.Activated:Connect(function()
        InventoryController.RequestOpenInventory:Fire()
    end))

    UIManager:AddButton(Units,HudSizeDecrease,OriginalSize)
end

function UIController:ItemsTab(Items)
    local InventoryController = Knit.GetController("InventoryController")
    local OriginalSize = Items.Size
    local Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 180, 0)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(150, 255, 29)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 180, 0)),
    })

    UIManager:AddEffectToUI(Items.Icon,Color,0)
    UIManager:AddEffectToUI(Items.Empty,Color,0)
    -- UIManager:AddEffectToUI(Items.Border,Color,0)
    UIManager:OnMouseChanged(Items,HudSizeIncrease,OriginalSize, nil, function()
        TweenService:Create(Items.Icon,TweenInfo.new(.15), {Rotation = -30}):Play()
        -- UIManager:GrowThickness(Items.Border.UIStroke,3, .15)
    end, function() -- OnLeave
        -- UIManager:GrowThickness(Items.Border.UIStroke,0, .15)
        TweenService:Create(Items.Icon,TweenInfo.new(.15), {Rotation = 0}):Play()
    end)

    maidManager:AddMaid(Items,"Activated",Items.Activated:Connect(function()
        InventoryController.RequestOpenItems:Fire()
    end))

    UIManager:AddButton(Items,HudSizeDecrease,OriginalSize)
end

function UIController:QuestsTab(Quests)
    local QuestController = Knit.GetController("QuestController")
    local OriginalSize = Quests.Size
    local Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(247, 189, 0)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(255, 234, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(247, 189, 0)),
    })

    UIManager:AddEffectToUI(Quests.Icon,Color,0)
    UIManager:AddEffectToUI(Quests.Empty,Color,0)
    -- UIManager:AddEffectToUI(Quests.Border,Color,0)
    UIManager:OnMouseChanged(Quests,HudSizeIncrease,OriginalSize, nil, function()
        TweenService:Create(Quests.Icon,TweenInfo.new(.15), {Rotation = -30}):Play()
        -- UIManager:GrowThickness(Quests.Border.UIStroke,3, .15)
    end, function() -- OnLeave
        -- UIManager:GrowThickness(Quests.Border.UIStroke,0, .15)
        TweenService:Create(Quests.Icon,TweenInfo.new(.15), {Rotation = 0}):Play()
    end)

    maidManager:AddMaid(Quests,"Activated",Quests.Activated:Connect(function()
        QuestController.OpenRequestQuest:Fire()
    end))

    UIManager:AddButton(Quests,HudSizeDecrease,OriginalSize)
end

function UIController:BattlepassTab(Battlepass)
    local LobbyController = Knit.GetController("LobbyController")
    local OriginalSize = Battlepass.Size
    local Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(206, 0, 0)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(206, 0, 0)),
    })

    UIManager:AddEffectToUI(Battlepass.Icon,Color,0)
    UIManager:AddEffectToUI(Battlepass.Empty,Color,0)
    -- UIManager:AddEffectToUI(Battlepass.Border,Color,0)
    UIManager:OnMouseChanged(Battlepass,HudSizeIncrease,OriginalSize, nil, function()
        TweenService:Create(Battlepass.Icon,TweenInfo.new(.15), {Rotation = -30}):Play()
        -- UIManager:GrowThickness(Battlepass.Border.UIStroke,3, .15)
    end, function() -- OnLeave
        -- UIManager:GrowThickness(Battlepass.Border.UIStroke,0, .15)
        TweenService:Create(Battlepass.Icon,TweenInfo.new(.15), {Rotation = 0}):Play()
    end)

    maidManager:AddMaid(Battlepass,"Activated",Battlepass.Activated:Connect(function()
        LobbyController.OpenBattlepass:Fire()
    end))

    UIManager:AddButton(Battlepass,HudSizeDecrease,OriginalSize)
end

function UIController:CodesTab(Code)
    -- local LobbyController = Knit.GetController("LobbyController")
    local OriginalSize = Code.Size
    local Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(2, 184, 175)),
        ColorSequenceKeypoint.new(.5, Color3.fromRGB(43, 255, 244)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 184, 175)),
    })

    UIManager:AddEffectToUI(Code.Icon,Color,0)
    UIManager:AddEffectToUI(Code.Empty,Color,0)
    
    UIManager:OnMouseChanged(Code,HudSizeIncrease,OriginalSize, nil, function()
        TweenService:Create(Code.Icon,TweenInfo.new(.15), {Rotation = -30}):Play()
    end, function() -- OnLeave
        TweenService:Create(Code.Icon,TweenInfo.new(.15), {Rotation = 0}):Play()
    end)

    maidManager:AddMaid(Code,"Activated",Code.Activated:Connect(function()
        SystemController.OpenRequestCodes:Fire()
    end))

    UIManager:AddButton(Code,HudSizeDecrease,OriginalSize)
end

function UIController:ShopsTab(Shop : TextButton | ImageButton)
    local OriginalSize = Shop.Size
    local LastSize : UDim2; 
    local Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(.15, Color3.fromRGB(255, 218, 53)),
        ColorSequenceKeypoint.new(.25, Color3.fromRGB(87, 255, 53)),
        ColorSequenceKeypoint.new(.45, Color3.fromRGB(53, 248, 255)),
        ColorSequenceKeypoint.new(.55, Color3.fromRGB(53, 73, 255)),
        ColorSequenceKeypoint.new(.65, Color3.fromRGB(157, 53, 255)),
        ColorSequenceKeypoint.new(.75, Color3.fromRGB(225, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })

    UIManager:AddEffectToUI(Shop.Icon,Color,0)
    UIManager:AddEffectToUI(Shop.Empty,Color,0)

    UIManager:OnMouseChanged(Shop,HudSizeIncrease,OriginalSize, nil, function()
        TweenService:Create(Shop.Icon,TweenInfo.new(.15), {Rotation = -30}):Play()
        LastSize = HudSizeIncrease
    end, function() -- OnLeave
        TweenService:Create(Shop.Icon,TweenInfo.new(.15), {Rotation = 0}):Play()
        LastSize = OriginalSize
    end)

    maidManager:AddMaid(Shop,"Activated",Shop.Activated:Connect(function()
        SystemController.OpenRequestStore:Fire()
    end))

    UIManager:AddButton(Shop,HudSizeDecrease, OriginalSize)
end

function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local ActiveEffects = {}

function UIController.ShowEffect(Effects)
    local EffectsFrame = Content.Effects
    local Folder = EffectsFrame.Folder

    for Effect, EffectData in pairs(Effects) do
        local Potion = Folder:FindFirstChild(Effect)
        local PotionInFrame = EffectsFrame:FindFirstChild(Effect)
        
        if Potion and not ActiveEffects[Effect] then
            local newEffect = Potion:Clone()
            newEffect.Timer.Text = formatTime(EffectData.Duration) 
            newEffect.Parent = EffectsFrame
            newEffect.Name = Effect
            newEffect.Visible = true
            ActiveEffects[Effect] = EffectData

            task.spawn(function()
                ActiveEffects[Effect].UI = newEffect
                ActiveEffects[Effect].Connection = RunService.Heartbeat:Connect(function()
                    ActiveEffects[Effect].Duration -= RunService.Heartbeat:Wait()
                    newEffect.Timer.Text = formatTime(ActiveEffects[Effect].Duration) 
                end)
            end)
        elseif ActiveEffects[Effect] then
            local newEffect = ActiveEffects[Effect].UI
            ActiveEffects[Effect].Connection:Disconnect()
            ActiveEffects[Effect].Duration = EffectData.Duration

            newEffect.Timer.Text = formatTime(ActiveEffects[Effect].Duration) 
            ActiveEffects[Effect].Connection = RunService.Heartbeat:Connect(function()
                ActiveEffects[Effect].Duration -= RunService.Heartbeat:Wait()
                newEffect.Timer.Text = formatTime(ActiveEffects[Effect].Duration) 
            end)
        end
    end
end

function UIController:KnitStart()
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    Content = Core:WaitForChild("Content")
    local HUD = Content:WaitForChild("HUD")
    local Units : TextButton = HUD:WaitForChild("Units")
    local Items : TextButton = HUD:WaitForChild("Items")
    local Quests : TextButton = HUD:WaitForChild("Quests")
    local Battlepass : TextButton = HUD:WaitForChild("Battlepass")
    local Shop : TextButton = HUD:WaitForChild("Shop")
    local Codes : TextButton = HUD:WaitForChild("Codes")
    local PlayerService = Knit.GetService("PlayerService")

    ProfileService = Knit.GetService("ProfileService")
    SystemController = Knit.GetController("SystemController")
    EffectService = Knit.GetService("EffectService")

    task.spawn(function()
        repeat
            task.wait()
        until ProfileService:IsProfileReady():expect()
        local PlayerData
        warn("THE PROFILE INFO: ", PlayerData)

        local nLevel = ProfileService:Get("Level")
        local nExp = ProfileService:Get("Exp")
        local nMaxExp = ProfileService:Get("MaxExp")
        local nCoins = ProfileService:Get("Coins")
        local nGems = ProfileService:Get("Gems")

        local Exp = 0
        local MaxExp = 0

        local Coins = 0
        local Gems = 0

        nLevel:andThen(function(current) CurrentLevel = current end):await()
        nExp:andThen(function(current) Exp = current end):await()
        nMaxExp:andThen(function(current) MaxExp= current end):await()

        nCoins:andThen(function(current) Coins = current end):await()
        nGems:andThen(function(current) Gems = current end):await()

        UIController.UpdateCoins(Coins)
        UIController.UpdateGems(Gems)
        UIController.UpdateExp(Exp, MaxExp, CurrentLevel)
    end)

    UIController:UnitsTab(Units)
    UIController:QuestsTab(Quests)
    UIController:ItemsTab(Items)
    UIController:CodesTab(Codes)
    UIController:ShopsTab(Shop)
    UIController:BattlepassTab(Battlepass)

    PlayerService.UpdateExp:Connect(UIController.UpdateExp)
    PlayerService.UpdateGems:Connect(UIController.UpdateGems)
    PlayerService.UpdateCoins:Connect(UIController.UpdateCoins)
    EffectService.Effects:Observe(function(newEffect)
        UIController.ShowEffect(newEffect)
    end)
end

return UIController