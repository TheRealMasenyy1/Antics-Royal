local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local QuestsModule = require(ReplicatedStorage.Shared.QuestsModule)
local PurchaseIds = require(ReplicatedStorage.SharedPackage.PurchaseIds)
local QuestsService = Knit.CreateService{
    Name = "QuestsService",
    Client = {}
}

local ProfileService;
local PlayerService;
local GlobalDatastoreService;
local ProductService;

QuestsService.Client.UpdateBattleLevel = Knit.CreateSignal();

local LevelMilestone = ReplicatedStorage.LevelMilestone

local function deepSearch(t, key_to_find)
    local tableKey;
    for key, value in pairs(t) do
        if value == key_to_find then -- value == key_to_find or
            return key, t, tableKey
        end
        if typeof(value) == "table" then -- Original function always returned results of deepSearch here, but we should not return unless it is not nil.
            local a, b = deepSearch(value, key_to_find)
            if a then return a, b end
        end	
    end
    return nil
end

local function GetQuestPosition(FullTable, keytofind)
    for key, Table in FullTable do
        print("Key: ", key, " Table: ", Table)
        if Table.Name == keytofind then
            return key, Table
        end
    end
    return nil, nil
end

function CheckTableFor(Table, Name)
    for pos, tably in Table do
        if tably.Type == Name then
            return true,tably
        end
    end

    return false
end

local BattlepassFolder = ReplicatedStorage.Battlepass

local function CheckClaimableLevel(Level, LevelMilestone) -- If already claimed it will not show in the table
    local Claimable = {}
    --[[
        0 - Can't collect
        1 - Can collect
        2 - Already collected
    ]]--
    for _, Folder in pairs(ReplicatedStorage.LevelMilestone:GetChildren()) do
        local checkpoint = tonumber(Folder.Name)

        if Level >= checkpoint and (not LevelMilestone[tostring(checkpoint)]) then
            Claimable[tostring(checkpoint)] = true 
        else
            Claimable[tostring(checkpoint)] = false 
        end
    end

    return Claimable -- If checkpoint is false then it's already claimed else you can claim
end

local function CheckClaimable(Level,Battlepass, OwnsBattlepass) -- If already claimed it will not show in the table
    local Claimable = {
        ["Free"] = {},
        ["Premium"] = {}
    }
    --[[
        0 - Can't collect
        1 - Can collect
        2 - Already collected
    ]]--

    local Types = {
        "Free",
        "Premium"
    }

    for Tier = 1,#BattlepassFolder["Season"..Battlepass.Season]:GetChildren() do
        -- for i = 1, Amount do
        for _,Type in ipairs(Types) do
            if (Level >= Tier and Type == "Free" and not Battlepass.Rewards[Type][tostring(Tier)]) or (Type == "Premium" and Level >= Tier and OwnsBattlepass and not Battlepass.Rewards[Type][tostring(Tier)]) then
                Claimable[Type][tostring(Tier)] = true 
            else
                Claimable[Type][tostring(Tier)] = false 
            end
        end
        -- end
    end

    return Claimable 
end

function QuestsService.Client:CheckLevelMilestone(player) -- Returned which ones are claimed
    local LevelMilestone = ProfileService:Get(player,"LevelMilestone")
    local Level = ProfileService:Get(player,"Level")
    local Claimed = CheckClaimableLevel(Level,LevelMilestone)

    return Claimed
end

function QuestsService.Client:CheckBattlepass(player) -- Returned which ones are claimed
    local Battlepass = ProfileService:Get(player,"Battlepass")
    local OwnsBattlepass = ProductService:GetPlayerPurchase(player,PurchaseIds.Gamepasses.BattlePassSeasonOne)
    warn("THE BATTLEPASS DATA: ", Battlepass)
    local Level = Battlepass.Level
    local Claimed = CheckClaimable(Level,Battlepass, OwnsBattlepass)

    return Claimed
end

local function returnMultipleChildren(Folder : Folder)
    local Child = {};
    for _, child in pairs(Folder:GetChildren()) do
        table.insert(Child, child)
    end
    return Child
end

function QuestsService.Client:ClaimLevelMilestone(player,LevelClaim)
    local levelMilestone = ProfileService:Get(player,"LevelMilestone")
    local Level = ProfileService:Get(player,"Level")
    local Claimable = CheckClaimableLevel(Level,levelMilestone)
    local Folder = LevelMilestone:FindFirstChild(tostring(LevelClaim))
    local PassedCheck = false
    
    if Folder and Level >= LevelClaim then
        local checkpoint = tonumber(Folder.Name)

        if Claimable[Folder.Name] and (not levelMilestone[checkpoint]) then
            local Rewards = returnMultipleChildren(Folder)
    
            for _, Reward in Rewards do
                -- print("Claimed: Level " .. Folder.Name .. " : " .. Reward.Name, " -- " , Reward.Value )
                if Reward.Name == "Gems" then
                    PlayerService:GiveGems(player, Reward.Value)
                elseif Reward.Name == "Unit" then
                    local UnitData = GlobalDatastoreService:CreateUnit(Reward.Value)
                    ProfileService:Update(player,"Inventory", function(Inventory)
                        table.insert(Inventory.Units, UnitData)
                        -- warn("Unit has been given from battlepass")
                        return Inventory
                    end)
                else
                    warn("THE REWARD TYPE: ", Reward:GetAttribute("Type") or "Items")
                    PlayerService:GiveItem(player,Reward:GetAttribute("Type") or "Items", Reward.Name, Reward.Value)
                end
            end
            levelMilestone[Folder.Name] = true
            PassedCheck = true
        else
            warn("Level ".. Folder.Name.. " is already claimed: ", Claimable)
        end
    else
        warn(`Folder {tostring(Level)} could not be founded `)
    end

    ProfileService:Update(player,"LevelMilestone", function()
        return levelMilestone
    end)

    return PassedCheck, levelMilestone
end

function QuestsService.Client:ClaimBattlePass(player)
    local Battlepass = ProfileService:Get(player,"Battlepass")
    local OwnsBattlepass = ProductService:GetPlayerPurchase(player,PurchaseIds.Gamepasses.BattlePassSeasonOne)
    local Level = Battlepass.Level
    local Claimable = CheckClaimable(Level,Battlepass, OwnsBattlepass)
    local pass = BattlepassFolder["Season"..Battlepass.Season]
    local Amount = #BattlepassFolder["Season"..Battlepass.Season]:GetChildren()
    local Collected = false
    local Types = {
        "Free",
        "Premium"
    }

    local function returnChildren(Folder : Folder)
        local Child;
        for _, child in pairs(Folder:GetChildren()) do
            Child = child
        end
        return Child
    end

    for i = 1, Amount do
        local Tier = pass[tostring(i)] -- Actual Tier Folder
        for x = 1, #Types do
            local Type = Types[x] -- This is the type(Free or Premium)
            if Type == "Free" or (Type == "Premium" and OwnsBattlepass) then
                -- warn("We're here and trying to claim: ", Claimable)
                if Claimable[Type][tostring(i)] and (not Battlepass.Rewards[Type][tostring(i)]) then
                    local Reward = returnChildren(Tier[Type])
                    -- print("Claimed: Level " .. Tier.Name .. ": " .. Type .. " : " .. Reward.Name, " -- " , Reward.Value )
                    if Reward.Name == "Gems" then
                        PlayerService:GiveGems(player, Reward.Value)
                    elseif Reward.Name == "Unit" then
                        local UnitData = GlobalDatastoreService:CreateUnit(Reward.Value)
                        ProfileService:Update(player,"Inventory", function(Inventory)
                            table.insert(Inventory.Units, UnitData)
                            -- warn("Unit has been given from battlepass")
                            return Inventory
                        end)
                    else
                        PlayerService:GiveItem(player,"Items", Reward.Name, Reward.Value)
                    end
                    Collected = true
                    Battlepass.Rewards[Type][Tier.Name] = true
                end
            end
        end
    end

    ProfileService:Update(player,"Battlepass", function()
        -- warn("The battlepass has been updated: ", Battlepass.Rewards)
        return Battlepass
    end)

    return Collected, Battlepass
end

function QuestsService:GenerateQuest(QuestType)
    local QuestRewards = QuestsModule[QuestType]
    local MaxQuests = 3
    local CurrentAmount = 0
    local Quests = {}
    local AlreadyAdded = {}

    while CurrentAmount < MaxQuests do
        for _, _ in QuestRewards do
            local AmountInList = #QuestRewards
            local RandomQuest = QuestRewards[math.random(1,AmountInList)]

            if CurrentAmount < MaxQuests and not AlreadyAdded[RandomQuest.Name] then
                AlreadyAdded[RandomQuest.Name] = true
                table.insert(Quests, RandomQuest)
                CurrentAmount = CurrentAmount + 1
            end
        end
        task.wait()
    end

    for _, Quest in Quests do
        if Quest.Type == "DailyQuests" then
            Quest.MaxAmount = (#Quests - 1)
        elseif Quest.Type == "WeeklyQuests" then
            Quest.MaxAmount = (#Quests - 1)
        end
    end

    return Quests
end

function QuestsService:TimeHasPassed(player,lastJoinTime)
    local currentTime = os.time()
    local currentDate = os.date("*t", currentTime)
    
    -- Set the daily reset time (e.g., midnight)
    currentDate.hour = 0
    currentDate.min = 0
    currentDate.sec = 0
    local dstAdjustment = 0
    
    -- Calculate the time for the start of today
    local todayStartTime = os.time(currentDate)

    if currentDate.isdst then
        -- If the player is currently in DST, adjust accordingly
        dstAdjustment = 3600 -- 1 hour in seconds
    end

    if lastJoinTime then
        -- If the last join time was before the start of today, a day has passed
        if lastJoinTime < todayStartTime then
            print("A new day has passed since the player last joined.")
            
            ProfileService:Update(player,"Quests", function(QuestsData)
                QuestsData.DailyStartedAt = os.time()
                return QuestsData
            end)
            return true
        else
            warn("Player joined on the same day.")
            return false
        end
    end
end

function QuestsService:CheckPlaytime(player, QuestType, Quests)
    local lastTimeJoined = Quests[QuestType.."StartedAt"]
    local currentTime = os.time()
    local newQuestData = Quests;
    local TimeTable = {}

    local _, DailyQuestTable, _ = deepSearch(Quests.DailyList, "Playtime")
    local _, WeeklyQuestTable, _ = deepSearch(Quests.WeeklyList, "Playtime")

    if DailyQuestTable then
        local timePassed = currentTime - lastTimeJoined
        DailyQuestTable.Amount = timePassed
        table.insert(TimeTable, DailyQuestTable)
    end

    if WeeklyQuestTable then
        local timePassed = currentTime - lastTimeJoined
        WeeklyQuestTable.Amount = timePassed
        table.insert(TimeTable, WeeklyQuestTable)
    end

    if #TimeTable > 0 then
        ProfileService:Update(player,"Quests", function(QuestsData)
            local Pos,actualQuest = CheckTableFor(QuestsData[QuestType.."List"], "Playtime")--table.find(oldQuestsData[QuestType .. "List"], QuestTable) -- deepSearch(oldQuestsData[QuestType.."List"])

            if Pos then
                actualQuest.Amount = TimeTable[1].Amount
            end

            newQuestData = QuestsData

            return QuestsData
        end)
    end

    return newQuestData
end

function QuestsService:CheckAmountQuests(Quests)
    local amount = 0
    for _, Quest in Quests do
        if Quest.Collected or Quest.Amount >= Quest.MaxAmount then
            amount += 1
        end
    end
    return amount
end

function QuestsService:CheckDailyQuest(player, QuestType, Quests)
    local newQuestData = Quests;
    local TimeTable = {}

    local _, DailyQuestTable, _ = deepSearch(Quests.DailyList, "DailyQuests")
    local _, WeeklyQuestTable, _ = deepSearch(Quests.WeeklyList, "WeeklyQuests")

    if DailyQuestTable then
        local amountCompleted = QuestsService:CheckAmountQuests(Quests.DailyList)
        DailyQuestTable.Amount = amountCompleted
        TimeTable["Daily"] = DailyQuestTable
    end

    if WeeklyQuestTable then
        local QuestCompleted = QuestsService:CheckAmountQuests(Quests.WeeklyList)
        WeeklyQuestTable.Amount = QuestCompleted
        TimeTable["Weekly"] = WeeklyQuestTable
    end

    if next(TimeTable) ~= nil then
        print("VI ÄR HÄR INNE NU ", TimeTable)
        ProfileService:Update(player,"Quests", function(QuestsData)
            local Pos,actualQuest = CheckTableFor(QuestsData[QuestType.."List"], QuestType.."Quests")--table.find(oldQuestsData[QuestType .. "List"], QuestTable) -- deepSearch(oldQuestsData[QuestType.."List"])

            if Pos and QuestType == "Daily" then
                actualQuest.Amount = TimeTable["Daily"].Amount
            elseif Pos and QuestType == "Weekly" then
                actualQuest.Amount = TimeTable["Weekly"].Amount
            end

            newQuestData = QuestsData

            return QuestsData
        end)
    end

    return newQuestData
end

function QuestsService:GetQuests(player, QuestType : string)
    local Quests = ProfileService:Get(player, "Quests")
    local QuestList = Quests[QuestType .. "List"]
    local lastTimeJoined = Quests.DailyStartedAt
    local HasPassed = QuestsService:TimeHasPassed(player,lastTimeJoined)
    local newQuestData

    if (#QuestList <= 0 or HasPassed) then
        local GenerateQuests = QuestsService:GenerateQuest(QuestType);

        ProfileService:Update(player,"Quests", function(QuestsData)
            QuestsData[QuestType.."List"] = GenerateQuests 
            QuestsData[QuestType.."StartedAt"] = os.time()

            -- print("Here to save: ", QuestsData)
            return QuestsData
        end)

        print("time has passed and new quests here: ",newQuestData)
        return GenerateQuests
    else
        -- Checks playtime -- Start
        newQuestData = QuestsService:CheckPlaytime(player, QuestType, Quests)
        newQuestData = QuestsService:CheckDailyQuest(player, QuestType, Quests)
        -- Ends playtime -- End

        print("QuestData here: ",newQuestData)
        return newQuestData[QuestType.."List"]
    end
end

function QuestsService.Client:RequestReward(player, QuestType, QuestData)
    local Quests = ProfileService:Get(player, "Quests")
    local QuestList = Quests[QuestType .. "List"]


    local _, QuestTable, _ = deepSearch(QuestList, QuestData.Name)

    if QuestTable and next(QuestTable) ~= nil then
        local Quest = QuestTable
        local Rewards = Quest.Reward

        if Quest.Amount >= Quest.MaxAmount then
            local newQuestData;
            ProfileService:Update(player, "Quests", function(oldQuestsData)
                local Pos,actualQuest = GetQuestPosition(oldQuestsData[QuestType.."List"], Quest.Name)--table.find(oldQuestsData[QuestType .. "List"], QuestTable) -- deepSearch(oldQuestsData[QuestType.."List"])

                if Pos and not actualQuest.Collected then
                    print("FOUND POSITION: ", actualQuest, Rewards, Quests , Pos)
                    actualQuest.Collected = true
                    newQuestData = actualQuest

                    for RewardType, Data in pairs(Rewards) do
                        if RewardType == "Coins" then
                            PlayerService:GiveCoin(player,Data)                           
                        elseif RewardType == "Gems" then
                            PlayerService:GiveGems(player,Data)                           
                        elseif RewardType == "Exp" then
                            PlayerService:GivePlayerExp(player,Data)
                        elseif RewardType == "Battlepass" then
                            PlayerService:GiveBattlepassExp(player,Data)
                        end
                    end
                end

                return oldQuestsData
            end)

            -- Give rewards -- 
            
            return true,newQuestData
        end
    end

    return false
end

function QuestsService.Client:GetQuests(player,QuestType)
    return QuestsService:GetQuests(player,QuestType) or nil
end

function QuestsService:GiveQuest(player,QuestType)

end

function QuestsService:KnitInit()
    
end

function QuestsService:KnitStart()
    ProfileService = Knit.GetService("ProfileService")
    PlayerService = Knit.GetService("PlayerService")
    ProductService = Knit.GetService("ProductService")
    GlobalDatastoreService = Knit.GetService("GlobalDatastoreService")

    Players.PlayerAdded:Connect(function(player)
        repeat task.wait() until ProfileService:IsProfileReady(player)
        warn("THE DAILY&WEEKLY QUEST HAS BEEN LOADED")
        QuestsService:GetQuests(player,"Daily")
        QuestsService:GetQuests(player,"Weekly")
    end)
end

return QuestsService