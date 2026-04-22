local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local Signal = require(Knit.Util.Signal)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)

local QuestController = Knit.CreateController {
    Name = "QuestController"
}

QuestController.OpenRequestQuest = Signal.new()

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local QuestService;
local Content
local _maid = MaidManager.new()

local targetDayOfWeek = 2 -- 1 = Sunday, 2 = Monday, etc.
local targetHour = 0 -- 0 = Midnight, 12 = Noon, etc.

local ProfileService;

function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function formatWeek(seconds)
    local days = math.floor(seconds / (24 * 3600)) -- Calculate full days
    seconds = seconds % (24 * 3600) -- Remaining seconds after days
    local hours = math.floor(seconds / 3600) -- Calculate full hours
    seconds = seconds % 3600 -- Remaining seconds after hours
    local minutes = math.floor(seconds / 60) -- Calculate full minutes

    return string.format("%dD:%02dH:%02dM", days, hours, minutes)
end

function getTimeUntilNextDay()
    local currentTime = os.time()
    local currentDate = os.date("*t", currentTime)

    -- Set the target to midnight of the next day
    currentDate.hour = 0
    currentDate.min = 0
    currentDate.sec = 0
    local dstAdjustment = 0

    if currentDate.isdst then
        -- If the player is currently in DST, adjust accordingly
        dstAdjustment = 3600 -- 1 hour in seconds
    end

    local targetTime = os.time(currentDate) + 24 * 60 * 60
    local timeUntilNextDay = (targetTime - currentTime) - dstAdjustment
    return timeUntilNextDay
end

function getTimeUntilNextWeek()
    local currentTime = os.time()
    local currentDate = os.date("*t", currentTime)

    -- Calculate how many days until the target day
    local daysUntilTarget = (targetDayOfWeek - currentDate.wday + 7) % 7
    if daysUntilTarget == 0 and currentDate.hour >= targetHour then
        daysUntilTarget = 7 -- if it's already the target day, but past the target hour
    end

    -- Calculate the time of the next target day
    local targetDate = os.date("*t", currentTime + daysUntilTarget * 24 * 60 * 60)    targetDate.hour = targetHour
    targetDate.min = 0
    targetDate.sec = 0
    local dstAdjustment = 0

    if currentDate.isdst then
        -- If the player is currently in DST, adjust accordingly
        dstAdjustment = 3600 -- 1 hour in seconds
    end

    local timeUntilNextWeek = os.time(targetDate) - currentTime - dstAdjustment
    return timeUntilNextWeek
end

function QuestController:TrackPlaytime(SinceFirstJoined, func : any) -- This function is to put in a Textlabel and show
    local LastOnline
    local TimeConnection : RBXScriptConnection;
    if not SinceFirstJoined then
        ProfileService:Get("Quests"):andThen(function(QuestData)
            LastOnline = QuestData.DailyStartedAt
        end)

        TimeConnection = RunService.Heartbeat:Connect(function(delta)
            local currentTime = os.time()
            local timeSinceLastOnline = currentTime - LastOnline

            func(timeSinceLastOnline)
        end)
    end
    
    return TimeConnection
end

function QuestController:TrackQuestData(QuestFrame, QuestData, CurrentlyOpen)
    local tableOfConnection = {}
    if QuestData.Type == "PlayTime" then
        tableOfConnection[math.random(-100,100)] = QuestController:TrackPlaytime(false,function(timePassing)

        end)
    end
end

local SelectedUI;
local SelectedSection;

function QuestController:DisplayQuests(QuestFrame, QuestData, CurrentlyOpen)
    local Content = QuestFrame:WaitForChild("Content")
    local UIListLayout : UIListLayout = Content:WaitForChild("UIListLayout")
    local TempFolder = Content.TempFolder
    local ClaimButton = QuestFrame:WaitForChild("ClaimButton")
    local ClaimCleaner = Maid.new();
    
    local function OnQuestSelected(newQuestFrame)
        local Descendents = newQuestFrame:GetDescendants()

        if SelectedUI then
            local OldDescendents = SelectedUI:GetDescendants()

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

    local function checkIfCompleted(Quests, QuestUI : TextButton)
        if Quests.Amount >= Quests.MaxAmount then
            local Descendents = ClaimButton:GetDescendants()

            for _, Elements in ipairs(Descendents) do
                if Elements.Name == "UIGradient" then
                    Elements.Enabled = false
                elseif Elements.Name == "GradientComplete" then
                    Elements.Enabled = true
                end
            end

            if Quests.Collected then
                for _, Elements in ipairs(Descendents) do
                    if Elements.Name == "UIGradient" then
                        Elements.Enabled = true
                    elseif Elements.Name == "GradientComplete" then
                        Elements.Enabled = false
                    end
                end

                ClaimButton.Btn.Text = "Reward Claimed"
                QuestUI.Completed.Visible = true
                QuestUI.Name = "Z "..Quests.Name
                UIListLayout.SortOrder = Enum.SortOrder.Name

                task.delay(.5,function()
                    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                end)

                QuestUI:SetAttribute("Completed", true)
                return true
            end
        end
        -- QuestUI.Progress.Text = Quests.Amount .. "/" .. Quests.MaxAmount
        return false
    end

    local function DisplayQuestInfo(QuestData, newQuests)
        local Descendents = ClaimButton:GetDescendants()
        ClaimCleaner = Maid.new();
        QuestFrame.Title.Text = QuestData.Name
        QuestFrame.QuestType.Text = QuestData.Type
        QuestFrame.Desc.Text = QuestData.Description
        QuestFrame.Progress.Text = QuestData.Amount .. "/" .. QuestData.MaxAmount

        UIManager:ClearFrame("TextButton", QuestFrame.Rewards)

        OnQuestSelected(newQuests)

        for Name,reward in pairs(QuestData.Reward) do
            if Name ~= "Exp" then
                local newItem = UnitCreator.CreateItemIconForChallenge(Name,{Amount = reward}) --Item:Clone()
                newItem.Size = UDim2.new(0.292, 0,0.784, 0)
                newItem.UnitName.Visible = false
                newItem.Parent = QuestFrame.Rewards
                newItem.Visible = true
            end
        end

        for _, Elements in ipairs(Descendents) do
            if Elements.Name == "UIGradient" then
                Elements.Enabled = true
            elseif Elements.Name == "GradientComplete" then
                Elements.Enabled = false
            end
        end

        if QuestData.Amount >= QuestData.MaxAmount then
            for _, Elements in ipairs(Descendents) do
                if Elements.Name == "UIGradient" then
                    Elements.Enabled = false
                elseif Elements.Name == "GradientComplete" then
                    Elements.Enabled = true
                end
            end

            if QuestData.Collected then
                for _, Elements in ipairs(Descendents) do
                    if Elements.Name == "UIGradient" then
                        Elements.Enabled = true
                    elseif Elements.Name == "GradientComplete" then
                        Elements.Enabled = false
                    end
                end
            end
        end

        ClaimCleaner:GiveTask(ClaimButton.Btn.Activated:Connect(function()
            local RewardGiven = QuestService:RequestReward(CurrentlyOpen, QuestData) --! Change the daily to something more dynamic
            RewardGiven:andThen(function(value,newQuestData)
                print("The Reward Has Been given", value)
                if value then
                    Shortcut:PlaySound("Claim",true)
                    local isCompleted = checkIfCompleted(newQuestData,newQuests)
                    if isCompleted then
                        -- newQuests.Accept.Interactable = false
                    end
                end
            end)
        end))
    end

    UIManager:ClearFrame("Frame",Content)

    local TweenInformation = TweenInfo.new(.1,Enum.EasingStyle.Linear, Enum.EasingDirection.InOut,0, true, .1)

    for _, Quests in QuestData do
        task.spawn(function()
            local QuestUI = Content:FindFirstChild(Quests.Name) or Content:FindFirstChild("Z " ..Quests.Name)

            if not QuestUI then
                if Quests.Amount > Quests.MaxAmount then Quests.Amount = Quests.MaxAmount end

                local newQuests = TempFolder.temp:Clone()
                local Section = newQuests.Section --? This is where all the elements are.
                local OriginalSize = newQuests.Size
                Section.Progress.Text = Quests.Type .. " (" .. Quests.Amount .. "/" .. Quests.MaxAmount ..")"
                Section.Title.Text = Quests.Name
                newQuests.Parent = Content
                newQuests.Name = Quests.Name
                newQuests.Visible = true
    
                -- UIManager:OnMouseChangedWithCondition(newQuests,UDim2.new(1, 0, .115, 0), OriginalSize,"TextButton")
                _maid:AddMaid(newQuests.Select,"Activated",newQuests.Select.Activated:Connect(function()
                    ClaimButton.Btn.Text = "Claim Reward"
                    if ClaimCleaner then ClaimCleaner:Destroy() end

                    if not newQuests:GetAttribute("Completed") then
                        DisplayQuestInfo(Quests, newQuests)
                        SelectedUI = newQuests

                        UIManager:TravelToSpringy(newQuests,.1,2,{Size = UDim2.fromScale(1, .1)})
                        task.delay(2, function()
                            UIManager:TravelToSpringy(newQuests,.15,2,{Size = OriginalSize})
                        end)
                        -- UIManager:OnActionWithInfo(newQuests,UDim2.new(1, 0, .1, 0), TweenInformation)
                        --! Collect Quest
                    end
                end))
                checkIfCompleted(Quests,newQuests)
            else
                checkIfCompleted(Quests,QuestUI)
            end
        end)
    end
end

local SelectedButton;

function QuestController.OpenQuest()
    local Quests = Content:WaitForChild("Quests")
    local QuestData = QuestService:GetQuests("Daily")
    local currentOpen = "Daily"

    local function OnQuestSelected(newQuestFrame)
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

    QuestData:andThen(function(Data)
        QuestController:DisplayQuests(Quests,Data,currentOpen)
    end):await()

    SelectedButton = Quests.Daily

    for _,btns in pairs(Quests.Buttons:GetChildren()) do
        if btns.Name ~= "Close" and (btns.Name == "Daily" or btns.Name == "Weekly") then
            local OriginalSize = btns.Size
            UIManager:OnMouseChangedWithCondition(btns,UDim2.new(0.25, 0,0.85, 0), OriginalSize,"TextButton", 2)

            btns.Btns.Activated:Connect(function() --!  Add a maid cleaner here 
                local btnQuestData = QuestService:GetQuests(btns.Name)
                currentOpen = btns.Name

                OnQuestSelected(btns)
                SelectedButton = btns

                btnQuestData:andThen(function(Data)
                    QuestController:DisplayQuests(Quests,Data,currentOpen)
                end):await()
            end)
        end
    end

    UIManager:UIOpened(Quests)

    task.spawn(function()
        while Quests.Visible do
            local TimeUntilNextDay = getTimeUntilNextDay()
            local TimeUntilNextWeek = getTimeUntilNextWeek()
            local UntilNextDay = formatTime(TimeUntilNextDay)
            local UntilNextWeek = formatWeek(TimeUntilNextWeek)
            
            if currentOpen == "Daily" then
                Quests.TimeLabel.Text = UntilNextDay --UntilNextDay
            else
                Quests.TimeLabel.Text = UntilNextWeek --UntilNextDay
            end
            task.wait()
        end
    end)
end

function QuestController:KnitInit()

end

function QuestController:KnitStart()
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    Content = Core:WaitForChild("Content")
    QuestService = Knit.GetService("QuestsService")
    ProfileService = Knit.GetService("ProfileService")

    QuestController.OpenRequestQuest:Connect(QuestController.OpenQuest)
end

return QuestController