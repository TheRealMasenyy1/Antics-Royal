local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local Difficulties = require(ReplicatedStorage.Difficulties)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local ChallengeModule = require(ReplicatedStorage.Shared.Challenges)
local IntermissionManager = require(ReplicatedStorage.Shared.IntermissionManager)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)

local IntermissionController = Knit.CreateController {
    Name = "IntermissionController",
}

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Assets = ReplicatedStorage.Assets

local IntermissionService;
local ProfileService;
local Content

local newWorldInfo = {} -- Holds the worlds in order 1 -> 2 -> 3 -> 4 -> 5
local HoverSpeed = .15
local start = 15
local maid;

local MapInfo : IntermissionManager.MapInfo =  { --! Reset this everytime he enteres map 
    Map = "Leaf Village",
    Difficulty = 1, -- 1: Normal, 2: Hard
    Chapter = 1;
    Challenge = 0,
    FriendsOnly = false;
}

local MapImages = {
    ["Leaf Village"] = "rbxassetid://109034391336878",
    ["Demon District"] = "rbxassetid://138282693165989",
    ["Inferno Gate"] = "rbxassetid://133452766701329",
    ["Royal Village"] = "rbxassetid://132791042699471",
}

local function GetDifficulty(Number) -- Convert number to Text
    return if Number == 1 then "Normal" else "Hard" 
end

function IntermissionController:ApplyChallengeInfo(Spawn, StartingMatch, ChallengeId)
    local _,ChallengeName,Rewards,Desc = ChallengeModule[ChallengeId]()

    local Confirm = StartingMatch:WaitForChild("Confirm")
    local Leave = StartingMatch:WaitForChild("Leave")
    local MapInfoFrame = StartingMatch:WaitForChild("MapInfo")
    local RewardHub = StartingMatch:WaitForChild("RewardHub")
    local Host = StartingMatch:WaitForChild("Host")
    -- local Timebar = StartingMatch:WaitForChild("TimeBar")

    local Difficulty = GetDifficulty(MapInfo.Difficulty)
    local WorldInfo = Difficulties[MapInfo.Map][Difficulty]
    local CompletionReward = WorldInfo.CompletionRewards

    local ConfirmOriginalSize = Confirm.Size
    local LeaveOriginalSize = Leave.Size

    MapInfoFrame.MapName.Text = MapInfo.Map
    MapInfoFrame.ChapterName.Text = if MapInfo.Chapter ~= "" then "Chapter: " .. MapInfo.Chapter else MapInfo.Challenge

    Confirm.Visible = true

    UIManager:OnMouseChangedWithCondition(Leave,UDim2.new(0.18, 0,0.084, 0), LeaveOriginalSize,"UIStroke")
    UIManager:OnMouseChangedWithCondition(Confirm, UDim2.new(0.1, 0,0.086, 0), ConfirmOriginalSize,"UIStroke")

    maid:GiveTask(Confirm.Btns.Activated:Connect(function()
        print("PRESSED THE STARTT")
        IntermissionService:ConfirmLobby(MapInfo)
    end))

    maid:GiveTask(Leave.Btns.Activated:Connect(function()
        UIManager.Visible(StartingMatch, false)
        IntermissionService:LeaveLobby()
    end))

    UIManager:ClearFrame("TextButton", RewardHub.Rewards)

    local function ShowRewards(RewardFrame, Rewards, RewardSize)
        local Items = Assets.Items
        local ItemsTable = Rewards.PossibleRewards

        ClearFrame("TextButton", RewardFrame)
    
        for Name,RewardInfo in pairs(Rewards) do
            local Item = Items:FindFirstChild(Name)
            if Item then
                local newItem = UnitCreator.CreateItemIconForChallenge(Name,{Amount =  RewardInfo}) --Item:Clone()
                newItem.Size = UDim2.new(0.225, 0,0.77, 0)
                newItem.UnitName.Visible = false
                newItem.Parent = RewardFrame
                newItem.Visible = true
            end
        end
    
        for i = 1,#ItemsTable do
            local ItemsInfo = ItemsTable[i]
            local Name = ItemsInfo.Name
            local Amount = ItemsInfo.Amount
            local Item = Items:FindFirstChild(Name,true)
    
            if Item then
                local newItem, ImageLabel = UnitCreator.CreateItemIconForChallenge(Name,{Amount = Amount}) --Item:Clone()
                -- newItem.Amount.Text = RewardInfo .. "x"
                newItem.UnitName.Text = ItemsInfo.Percentage .. "%"
                newItem.UnitName.Position = UDim2.new(.5,0,.1,0)
                newItem.Size = UDim2.new(0.225, 0,0.77, 0)
                ImageLabel.Size = UDim2.new(1.5, 0,1.15, 0)
    
                newItem.UnitName.Visible = true
                newItem.Parent = RewardFrame
            end
        end
    end

    if ChallengeName then
        -- StartingMatch.MapInfo.Text = ChallengeName
        StartingMatch.MapInfo.MapName.Text = Spawn:GetAttribute("Map")
        StartingMatch.MapInfo.ChapterName.Text = Desc

        ShowRewards(RewardHub.Rewards, Rewards, UDim2.new(0.292, 0,0.784, 0))
    end
end

local function ShowMiniFrameInfo()
    local StartingMatch = Content:WaitForChild("StartingMatch")
    local Confirm = StartingMatch:WaitForChild("Confirm")
    local Leave = StartingMatch:WaitForChild("Leave")
    local MapInfoFrame = StartingMatch:WaitForChild("MapInfo")
    local RewardHub = StartingMatch:WaitForChild("RewardHub")
    local Host = StartingMatch:WaitForChild("Host")
    local TimeBar = StartingMatch:WaitForChild("TimerBar")

    local Difficulty = GetDifficulty(MapInfo.Difficulty)
    local WorldInfo = Difficulties[MapInfo.Map][Difficulty]
    local CompletionReward = WorldInfo.CompletionRewards

    local ConfirmOriginalSize = Confirm.Size
    local LeaveOriginalSize = Leave.Size

    maid = Maid.new()

    UIManager.Visible(StartingMatch, true, UDim2.new(0.272, 0,0.492, 0))

    MapInfoFrame.MapName.Text = MapInfo.Map
    MapInfoFrame.ChapterName.Text = if MapInfo.Chapter ~= "" then "Chapter: " .. MapInfo.Chapter else MapInfo.Challenge
    MapInfoFrame[Difficulty].Visible = true

    print("The mapInfo: ", MapInfo)

    Confirm.Visible = false
    UIManager:OnMouseChangedWithCondition(Leave,UDim2.new(0.341, 0,0.112, 0), LeaveOriginalSize,"UIStroke")

    maid:GiveTask(Leave.Btns.Activated:Connect(function()
        MapInfoFrame[Difficulty].Visible = false

        UIManager.Visible(StartingMatch, false)
        IntermissionService:LeaveLobby()
    end))

    UIManager:ClearFrame("TextButton", RewardHub.Rewards)

    GetRewards(RewardHub.Rewards, CompletionReward, UDim2.new(0.292, 0,0.784, 0))

    task.spawn(function()
        local Bar = TimeBar:WaitForChild("Bar")
        local Spawn = IntermissionService:GetSpawn():expect()
        start = Spawn:GetAttribute("TimeUntilStart")

        while start >= 0 and Spawn:GetAttribute("Host") ~= "" do
            Bar.Size = UDim2.new((start / 15), 0, 1, 0)
            start -= RunService.Heartbeat:Wait()
        end
    end)
end

function IntermissionController.CreateLobby(LobbyType)
    local MatchPanel = Content:WaitForChild("MatchPanel")
    local ChallengePanel = Content:WaitForChild("ChallengePanel")
    local StartingMatch = Content:WaitForChild("StartingMatch")
    local TimeBar = StartingMatch:WaitForChild("TimerBar")

    maid = Maid.new()

    local function ShowMiniFrameInfo(IsChallenge : boolean, ChallengeMode : number)
        local Confirm = StartingMatch:WaitForChild("Confirm")
        local Leave = StartingMatch:WaitForChild("Leave")
        local MapInfoFrame = StartingMatch:WaitForChild("MapInfo")
        local RewardHub = StartingMatch:WaitForChild("RewardHub")
        local Host = StartingMatch:WaitForChild("Host")

        local Difficulty = GetDifficulty(MapInfo.Difficulty)
        local WorldInfo = Difficulties[MapInfo.Map][Difficulty]
        local CompletionReward = WorldInfo.CompletionRewards

        local ConfirmOriginalSize = Confirm.Size
        local LeaveOriginalSize = Leave.Size

        MapInfoFrame.MapName.Text = MapInfo.Map
        MapInfoFrame.ChapterName.Text = if MapInfo.Chapter ~= "" then "Chapter: " .. MapInfo.Chapter else MapInfo.Challenge

        Confirm.Visible = true
        MapInfoFrame[Difficulty].Visible = true

        local _, err = pcall(function()
            MapInfoFrame.Image = MapImages[MapInfo.Map]
        end)

        UIManager:OnMouseChangedWithCondition(Leave,UDim2.new(0.341, 0,0.112, 0), LeaveOriginalSize,"UIStroke")
        UIManager:OnMouseChangedWithCondition(Confirm, UDim2.new(0.55, 0,0.112, 0), ConfirmOriginalSize,"UIStroke")

        maid:GiveTask(Confirm.Btns.Activated:Connect(function()
            IntermissionService:StartLobby()
        end))

        maid:GiveTask(Leave.Btns.Activated:Connect(function()
            MapInfoFrame[Difficulty].Visible = false
            UIManager.Visible(StartingMatch, false)
            IntermissionService:LeaveLobby()
        end))

        UIManager:ClearFrame("TextButton", RewardHub.Rewards)

        GetRewards(RewardHub.Rewards, CompletionReward, UDim2.new(0.292, 0,0.784, 0))

        task.spawn(function()
            local Bar = TimeBar:WaitForChild("Bar")
            local Spawn = IntermissionService:GetSpawn():expect()

            while start >= 0 and Spawn:GetAttribute("Host") ~= "" do
                Bar.Size = UDim2.new((start / 15), 0, 1, 0)
                start -= RunService.Heartbeat:Wait()
            end
        end)
    end
    
    if LobbyType == "Play" then
        local ConfirmBtn = MatchPanel:WaitForChild("ConfirmButton")
        local LeaveBtn = MatchPanel:WaitForChild("LeaveButton")
        local Bar = TimeBar:WaitForChild("Bar")

        local LeaveOriginalSize = LeaveBtn.Size
        local ConfirmOriginalSize = ConfirmBtn.Size

        TimeBar.Visible = true

        IntermissionController:LoadMatchPanel()

        maid:GiveTask(ConfirmBtn.Btns.Activated:Connect(function()
            UIManager:UIClose(MatchPanel) -- Should be behind the UIManager System
            UIManager.Visible(StartingMatch, true, UDim2.new(0.272, 0,0.492, 0))

            start = 15 --! Shouldn't be hard coded like this ngl
            IntermissionService:ConfirmLobby(MapInfo) --- This should start a count down
            ShowMiniFrameInfo()
        end))
    
        maid:GiveTask(LeaveBtn.Btns.Activated:Connect(function()
            UIManager:HideItemInfo()
            IntermissionService:LeaveLobby()
        end))
    
        UIManager:OnMouseChangedWithCondition(LeaveBtn,UDim2.new(0.18, 0,0.084, 0), LeaveOriginalSize,"UIStroke")
        UIManager:OnMouseChangedWithCondition(ConfirmBtn, UDim2.new(0.18, 0,0.086, 0), ConfirmOriginalSize,"UIStroke")
    
        UIManager.Visible(MatchPanel, true)
    elseif LobbyType == "Challenges" then
        -- task.delay(.5,function()
        --     IntermissionService:LeaveLobby()
        -- end)

        local IsHost = IntermissionManager:GetHostSpawn(player)
        local ChallengeId = IsHost:GetAttribute("Challenge")

        TimeBar.Visible = false
        IntermissionController:ApplyChallengeInfo(IsHost, StartingMatch, ChallengeId)

        MapInfo.Challenge = ChallengeId
        UIManager.Visible(StartingMatch, true, UDim2.new(0.272, 0,0.492, 0))
    end
end

function IntermissionController.LeaveLobby(Area)
    local MatchPanel = Content:WaitForChild("MatchPanel")
    local StartingMatch = Content:WaitForChild("StartingMatch")
    local ChallengePanel = Content:WaitForChild("ChallengePanel")

    maid:Destroy()

    if StartingMatch.Visible then
        UIManager.Visible(StartingMatch, false)
    end

    if Area == "Challenges" then
        UIManager.Visible(ChallengePanel, false)
    else
        UIManager.Visible(MatchPanel, false)
    end
end

local function deepSearch(t, key_to_find)
	for key, value in pairs(t) do
		if key == key_to_find then -- value == key_to_find or
            -- warn("THE VALUE TYPE ", typeof(value), value)
			return value, t, key
		end
		if typeof(value) == "table" then -- Original function always returned results of deepSearch here, but we should not return unless it is not nil.
			local a, b = deepSearch(value, key_to_find)
			if a then return a, b end
		end	
	end
	return nil
end

function ClearFrame(WhatToClear , Parent)
    for _, Object in pairs(Parent:GetChildren()) do
        if Object:IsA(WhatToClear) then
            Object:Destroy()
        end
    end
end

function GetRewards(RewardFrame, Rewards, RewardSize)
    local Items = Assets.Items
    local ItemsTable = Rewards.Items

    ClearFrame("ImageButton", RewardFrame)

    for Name,RewardInfo in pairs(Rewards) do
        local Item = Items:FindFirstChild(Name)
        if Item then
            local newItem = UnitCreator.CreateItemIconForChallenge(Name,{Amount =  RewardInfo}) --Item:Clone()
            newItem.Size = UDim2.new(0.225, 0,0.77, 0)
            newItem.UnitName.Visible = false
            newItem.Parent = RewardFrame
            newItem.Visible = true
        end
    end

    warn("THE ITEMTABLE: ", ItemsTable)
    for i = 1,#ItemsTable do
        local ItemsInfo = ItemsTable[i]
        local Name = ItemsInfo.Name
        local Amount = ItemsInfo.Amount
        local Item = Items:FindFirstChild(Name,true)

        if Item then
            local newItem, ImageLabel = UnitCreator.CreateItemIconForChallenge(Name,{Amount = Amount}) --Item:Clone()
            -- newItem.Amount.Text = RewardInfo .. "x"
            newItem.Size = UDim2.new(0.225, 0,0.77, 0)
            ImageLabel.Size = UDim2.new(1.5, 0,1.15, 0)

            newItem.UnitName.Visible = false
            newItem.Parent = RewardFrame
        end
    end
end

function LoadWorldInfo(MatchPanel, WorldInfoFrame, World : string, Difficulty : string)
    local WorldInfo = Difficulties[World][Difficulty]
    local CompletionReward = WorldInfo.CompletionRewards
    local RewardsFrame = MatchPanel:WaitForChild("Rewards")
    local RewardSize = UDim2.new(0.237, 0,0.824, 0)

    UIManager:ClearFrame("TextButton", RewardsFrame)
    GetRewards(RewardsFrame, CompletionReward, RewardSize)
end

function LoadWorlds(WorldContent)
    local MatchPanel = Content:WaitForChild("MatchPanel")
    local ChapterFrame = MatchPanel:WaitForChild("ChapterFrame")
    local WorldInfoFrame = MatchPanel:WaitForChild("WorldFrame")
    local Temp = WorldContent.Temp.temp

    local Worlds = ReplicatedStorage.Difficulties:GetChildren()
    local WorldData = ProfileService:Get("Worlds")
    local LastButton;
    local playerWorldData;

    ClearFrame("Frame", WorldContent)

    WorldData:andThen(function(Value)
        playerWorldData = Value
    end):await()

    -- Set the order of the worlds ---
    for _, worlds in pairs(Worlds) do
        local Order = worlds:GetAttribute("Order")
        if Order then
            newWorldInfo[Order] = worlds.Name
        end
    end

    --- Load the worlds in order ---
    for i = 1,#newWorldInfo do
        local World = playerWorldData[i]
        local newTemp : ImageButton = Temp:Clone()
        local OriginalSize = newTemp.Size

        newTemp.Name = newWorldInfo[i]
        newTemp.Visible = true
        newTemp.Parent = WorldContent

        newTemp.ImageButton.MapName.Text = newWorldInfo[i]

        local _, err = pcall(function()
            newTemp.ImageButton.Image = MapImages[newWorldInfo[i]]
        end)

        if err then
            warn("Failed to load image for world: ", newWorldInfo[i], err)
        end

        if World and World.Unlocked then
            if i == 1 then
                -- newTemp.UIStroke.Color =Color3.fromRGB(255,255,255)
                -- newTemp.UIStroke.Thickness = 2
                LastButton = newTemp
            end

            UIManager:OnMouseChangedWithCondition(newTemp,UDim2.new(.95, 0,0.1, 0), OriginalSize,"ImageButton")

            newTemp.ImageButton.Activated:Connect(function()
                if LastButton then 
                    LastButton:SetAttribute("Selected", false) 
                end 

                MapInfo.Map = newWorldInfo[i]
                MatchPanel.Hub.MapName.Text = newWorldInfo[i]

                local _, err = pcall(function()
                    MatchPanel.Hub.Image = MapImages[newWorldInfo[i]]
                end)

                if err then
                    warn("Failed to load image for world: ", newWorldInfo[i], err)
                end

                --- Load Chapters & World Info ---
                warn("CLICKED THE WORLD: ", newWorldInfo[i])
                LoadChapters(ChapterFrame, playerWorldData, newTemp.Name)

                --- End ---
                LastButton = newTemp
                newTemp:SetAttribute("Selected", true)
            end)
        end
    end

    return playerWorldData
end

local ChapterCleaner

function resetChapters(Content)
    for _, ChapterBtn : ImageButton in pairs(Content:GetChildren()) do
        if ChapterBtn:IsA("UIGradient") then
            if ChapterBtn.Name == "GradientComplete" then
                ChapterBtn.Enabled = false
            elseif ChapterBtn.Name == "UIGradient" then 
                ChapterBtn.Enabled = true
            end
        end

        if ChapterBtn:IsA("Frame") and ChapterBtn:GetAttribute("Selected") then
            ChapterBtn:SetAttribute("Selected", false)
            ChapterBtn:SetAttribute("Locked", true)
        end
    end
end

function resetDifficulty(Folder)
    local Normal = Folder.Normal 
    local Hard = Folder.Hard

    Hard.UIStroke.Selected.Enabled = false
    Hard.UIStroke.UIGradient.Enabled = true
    Hard.UIStroke.Thickness = 2
    Hard:SetAttribute("Selected", false)

    Normal.UIStroke.Selected.Enabled = true
    Normal.UIStroke.UIGradient.Enabled = false
    Normal.UIStroke.Thickness = 4
    Normal:SetAttribute("Selected", true)
end

function Difficulty(Hub)
    local LastButton = Hub.Normal
    local DifficultyMap = {
        ["Normal"] = 1;
        ["Hard"] = 2;
    }

    resetDifficulty(Hub)

    for _, Btns : ImageButton in pairs(Hub:GetChildren()) do
        if Btns:IsA("TextButton") then 
            local OriginalSize = Btns.Size

            maid:GiveTask(Btns.Activated:Connect(function()
                if LastButton then
                    LastButton.UIStroke.Selected.Enabled = false
                    LastButton.UIStroke.UIGradient.Enabled = true
                    LastButton.UIStroke.Thickness = 2
                    LastButton:SetAttribute("Selected", false)
                end

                MapInfo.Difficulty = DifficultyMap[Btns.Name]

                Btns.UIStroke.Selected.Enabled = true
                Btns.UIStroke.UIGradient.Enabled = false
                Btns.UIStroke.Thickness = 4

                LastButton = Btns
                Btns:SetAttribute("Selected", true)
            end))

            UIManager:OnMouseChangedWithCondition(Btns,UDim2.new(0.17, 0,0.276, 0), OriginalSize,"TextLabel",if Btns:GetAttribute("Selected") then 4 else 2)
        end
    end
end

local SelectedButton;

local function OnSelected(newQuestFrame)
    local Descendents = newQuestFrame:GetDescendants()
    if SelectedButton then
        local OldDescendents = SelectedButton:GetDescendants()
        for _, Elements in ipairs(OldDescendents) do
            if Elements.Name == "UIGradient" then
                Elements.Enabled = true
            elseif Elements.Name == "GradientComplete" then
                Elements.Enabled = false
            end
        end
    end

    for _, Elements in ipairs(Descendents) do
        if Elements.Name == "UIGradient" then
            Elements.Enabled = false
        elseif Elements.Name == "GradientComplete" then
            Elements.Enabled = true
        end
    end
end

local function Unlocked(newQuestFrame, Value : boolean)
    local Descendents = newQuestFrame:GetDescendants()

    if Value then
        for _, Elements in ipairs(Descendents) do
            if Elements.Name == "GradientComplete" then
                Elements.Enabled = false
            end

            if Elements.Name == "UIGradient" then
                Elements.Enabled = true
                newQuestFrame.Btns.TextColor3 = Color3.fromRGB(255, 255, 255)
            elseif Elements.Name == "LockedGradient" then
                Elements.Enabled = false
            end
        end
    else
        for _, Elements in ipairs(Descendents) do
            if Elements:IsA("UIGradient") then
                if Elements.Name == "UIGradient" then
                    Elements.Enabled = false
                elseif Elements.Name == "LockedGradient" then
                    Elements.Enabled = true
                end
            end
        end

        newQuestFrame.Btns.TextColor3 = Color3.fromRGB(81, 81, 81)
    end

end

function LoadChapters(ChapterFrame, WorldInfo, WorldName : string)
    local MatchPanel = ChapterFrame.Parent
    local Hub = MatchPanel:WaitForChild("Hub")
    local LastButton;

    local FindWorld = table.find(newWorldInfo, WorldName)

    if ChapterCleaner then ChapterCleaner:Destroy() end
    ChapterCleaner = Maid.new()
    -- resetChapters(ChapterFrame) -- resets the chapter if player selects new world

    -- resetChapters(ChapterFrame)
    Difficulty(Content.MatchPanel.Hub)

    warn("CHAPTER DATA: ", WorldInfo)

    if FindWorld then
        local World = WorldInfo[FindWorld]
        for _, ChapterBtn : Frame in pairs(ChapterFrame:GetChildren()) do
            if ChapterBtn:IsA("Frame") then
                -- local ChapterFrame = ChapterBt.Parent
                -- print("Checking the chapter: ", ChapterBtn.Name, World.Chapter)
                if ChapterBtn.Name == "Infinite" and World.Chapter >= 5 then
                    print("Infinite unlocked")
                    ChapterBtn:SetAttribute("Locked", false)
                    Unlocked(ChapterBtn, true)
                elseif ChapterBtn.Name == "Infinite" and World.Chapter < 5 then
                    print("Infinite locked")
                    ChapterBtn:SetAttribute("Locked", true)
                    Unlocked(ChapterBtn, false)
                end

                if ChapterBtn.Name ~= "Infinite" then
                    if World.Chapter >= tonumber(ChapterBtn.Name) then
                        ChapterBtn:SetAttribute("Locked", false)
                        Unlocked(ChapterBtn, true)
                    else
                        ChapterBtn:SetAttribute("Locked", true)
                        Unlocked(ChapterBtn, false)
                    end
                end
            end  
        end
    end

    for _, ChapterBtnFrame : Frame in pairs(ChapterFrame:GetChildren()) do
        if ChapterBtnFrame:IsA("Frame") and not ChapterBtnFrame:GetAttribute("Locked") then
            local ChapterBtn = ChapterBtnFrame.Btns
            local OriginalSize = ChapterBtnFrame.Size
            local Chapter = tonumber(ChapterBtnFrame.Name)

            UIManager:OnMouseChangedWithCondition(ChapterBtnFrame,UDim2.new(0.95, 0,0.14, 0), OriginalSize,"TextButton",3)

            ChapterCleaner:GiveTask(ChapterBtn.Activated:Connect(function()
                if LastButton then LastButton:SetAttribute("Selected", false) end
                OnSelected(ChapterBtnFrame)
                SelectedButton = ChapterBtnFrame

                ChapterBtn:SetAttribute("Selected", true) 
                MapInfo.Chapter = Chapter or ChapterBtnFrame.Name

                LastButton = ChapterBtn
            end))
        end
    end
end

function IntermissionController:LoadMatchPanel()
    local MatchPanel = Content:WaitForChild("MatchPanel")
    local ChapterFrame = MatchPanel:WaitForChild("ChapterFrame")
    -- local SelectFrame = MatchPanel:WaitForChild("SelectFrame")
    local FriendsOnly = MatchPanel:WaitForChild("FriendsOnly")
    local WorldContent = MatchPanel:WaitForChild("WorldFrame")
    local Temp = WorldContent.Temp.temp

    -- local HoverSpeed = .25
    maid:GiveTask(FriendsOnly.Activated:Connect(function()
        FriendsOnly.Check.Visible = not FriendsOnly.Check.Visible       
        MapInfo.FriendsOnly = FriendsOnly.Check.Visible 
    end))

    local WorldInfo = LoadWorlds(WorldContent)
    LoadChapters(ChapterFrame,WorldInfo,"Leaf Village")
    LoadWorldInfo(MatchPanel, WorldContent, "Leaf Village", "Normal")
end

function IntermissionController:KnitInit()

end

function IntermissionController:KnitStart()
    local PlayerGui = player:WaitForChild("PlayerGui")
    local LoadGui = player.PlayerGui:WaitForChild("LoadGui")
    local Core = PlayerGui:WaitForChild("Core")
    Content = Core:WaitForChild("Content")
    
    IntermissionService = Knit.GetService("IntermissionService")
    ProfileService = Knit.GetService("ProfileService")

    IntermissionService.JoinedLobby:Connect(ShowMiniFrameInfo)
    IntermissionService.CreateLobby:Connect(IntermissionController.CreateLobby)
    IntermissionService.CloseLobbyUI:Connect(IntermissionController.LeaveLobby)
    IntermissionService.ShowLoadingScreen:Connect(function(placeId, Chapter)
        local Frame
        local succ, err = pcall(function()
            LoadGui = player.PlayerGui:WaitForChild("LoadGui")
            Frame = LoadGui:WaitForChild(placeId)
        end)

        if succ then
            Frame.Visible = true

            Frame.Chapter.Text = "Chapter " .. Chapter
            Frame.ChapterShadow.Text = "Chapter " .. Chapter

            local Logo = Frame.Logo
            local Tween = TweenService:Create(Logo,TweenInfo.new(2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,math.huge,true),{Position = UDim2.new(0.819, 0,0.81, 0)})
            Tween:Play()

            TeleportService:SetTeleportGui(ReplicatedStorage.LoadGui)
            game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
        else
            warn("Failed to load teleport GUI: ", placeId)
        end
    end)
end

return IntermissionController