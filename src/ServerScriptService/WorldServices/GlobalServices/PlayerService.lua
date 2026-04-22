local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Codes = require(ServerStorage.GameInfo.Codes)

local Assets = ReplicatedStorage.Assets

--[[ 

    This will handle player stuff
    Like equipping the units clothes
    or sprinting and dashing...

]]--

local PlayerService = Knit.CreateService {
    Name = "PlayerService",
    Client = {
        UpdateExp = Knit.CreateSignal()
    }
}

PlayerService.UpdateBillboard = Signal.new()
PlayerService.Client.UpdateEquipped = Knit.CreateSignal()
PlayerService.Client.UpdateGems = Knit.CreateSignal()
PlayerService.Client.UpdateCoins = Knit.CreateSignal()
PlayerService.Client.UpdateGivenUnit = Knit.CreateSignal()
PlayerService.Client.UpdateInventory = Knit.CreateSignal()

local ProfileService;
local QuestsService;
local InventoryService;

-- function PlayerService.

local function GetUnit(UnitsData, UnitHash : string)
    for pos,UnitData in UnitsData do
        if UnitData.Hash == UnitHash then
            return UnitData,pos
        end
    end

    return nil
end

function PlayerService:GiveUnitToolbarUnit(player, UnitName, UnitLevel : number, newStats, Position : number)
    local newUnit = {Level = UnitLevel or 1; Unit = UnitName, Stats = newStats or {Damage = "F", Cooldown = "F", Speed = "F"}};	
    PlayerService.Client.UpdateGivenUnit:Fire(player, newUnit, Position)
end

function PlayerService.Client:TeleportPlayerToLobby(player)
    local CurrentServerId = game.JobId
    local succ,result, ErrorIthink = pcall(function()
        return TeleportService:TeleportAsync(114746697858159, {player})
    end)

    if result then
        print(player.Name .." was sent to the afk world")
    elseif ErrorIthink then
        warn("Failed to teleport player to the afk world:", ErrorIthink, succ, result)
    end
end

function PlayerService.Client:TeleportPlayerToAFK(player)
    local CurrentServerId = game.JobId
    local success, errorMessage, _currentInstance, currentPlaceId , nextServerId = pcall(function()
        return TeleportService:GetPlayerPlaceInstanceAsync(player.UserId)
    end)

    if success and game.PlaceId == 80904234996369 then
        if nextServerId == CurrentServerId then
            local serverCode;
            local _,Reservererr = pcall(function()
                serverCode = TeleportService:ReserveServer(tonumber(currentPlaceId))
            end)

            local teleportOption = Instance.new("TeleportOptions")
            teleportOption.ReservedServerAccessCode = serverCode

            teleportOption:SetTeleportData({
                reservedCode = serverCode;
                message = "Welcome to the new server!"
            })
            return TeleportService:TeleportAsync(132834609518011, {player}, teleportOption) -- ,  LobbyInfo
        end

        -- Force teleport to another public server in the same place
        local succ,result = pcall(function()
            return TeleportService:TeleportAsync(132834609518011, {player})
        end)

        if result then
            print(player.Name .." was sent to the afk world")
        end
    elseif game.PlaceId ~= 80904234996369 then
        local succ,result, ErrorIthink = pcall(function()
            return TeleportService:TeleportAsync(132834609518011, {player})
        end)

        if result then
            print(player.Name .." was sent to the afk world")
        elseif ErrorIthink then
            warn("Failed to teleport player to the afk world:", ErrorIthink, succ, result)
        end
    else
        warn("Failed to get player instance:", errorMessage, player, player.UserId)
    end
end

function PlayerService.Client:GetUnit(player, UnitHash)
    local Inventory = ProfileService:Get(player,"Inventory")
    local Unit = GetUnit(Inventory.Units, UnitHash)

    if Unit ~= nil then
        return Unit
    end
    
    return nil end

function PlayerService:GetItem(player, Catagory : string, Item : string)
    local Inventory = ProfileService:Get(player,"Inventory")
    local Items = Inventory[Catagory]

    --[[
        {
            Name = "2 Star",
            Amount = 5,
        }
    ]]--

    if not Item then
        warn("Item wasn't passed so returned the entire table")
        return Items   
    end

    for Pos, ItemData in Items do
        if ItemData.Name == Item then
            return ItemData, Pos
        end
    end

    return nil
end 

function PlayerService.Client:RedeemCodes(player, Code) 
    local UsedCodes = ProfileService:Get(player,"RedeemedCodes")
    local function hasCodeExpired(inputDate, endDate)
        if endDate == nil then return false end

        local endTime = os.time(endDate)
        local currentTime = os.time()

        warn("currentTime: ", os.date("%c",currentTime), " endTime: ", os.date("%c", endTime))
        return currentTime > endTime
    end

    if table.find(UsedCodes,Code) then
        return "Code has been used already!", false
    end

    for ActualCode,CodeData in pairs(Codes) do
        if ActualCode == Code and not hasCodeExpired(os.time,CodeData.Duration) then --! Check if he has used code before aswell
            local Rewards = CodeData.Reward
            --Give Rewards
            for RewardType, RewardValue in pairs(Rewards) do
                if RewardType == "Gems" then
                    PlayerService:GiveGems(player, RewardValue)
                elseif RewardType == "Coin" then
                    PlayerService:GiveCoin(player, RewardValue)
                elseif RewardType == "Exp" then
                    task.spawn(function()
                        PlayerService:GivePlayerExp(player, RewardValue)
                    end)
                elseif RewardType == "Items" then
                    for _, ItemInfo in pairs(RewardValue) do
                        PlayerService:GiveItem(player,ItemInfo.ItemType, ItemInfo.Name, ItemInfo.Amount)
                    end
                end
            end

            ProfileService:Update(player,"RedeemedCodes", function(SavedCodes)
                table.insert(SavedCodes,Code)
                return SavedCodes
            end)

            return "Code was redeem!", true
        elseif ActualCode == Code and hasCodeExpired(os.time,CodeData.Duration) then --! Check if he has used code before aswell
            return "Code has expired!", "expired"
        end
    end


    return "Code is invalid!", false
end

function PlayerService:AddAction(player, ActionName, reason)
    local AdminActions = ProfileService:Get(player,"AdminActions")

    if not AdminActions[ActionName] then
        AdminActions[ActionName] = {}
        table.insert(AdminActions[ActionName], {Time = os.date("%Y-%m-%d %H:%M:%S"),Reason = reason})
    else
        table.insert(AdminActions[ActionName], {Time = os.date("%Y-%m-%d %H:%M:%S"),Reason = reason})
    end

    ProfileService:Update(player,"AdminActions",function()
        return AdminActions
    end)
end

function PlayerService:GiveItem(player, Catagory : string, Item : string, Amount : number)
    local Inventory = ProfileService:Get(player,"Inventory")
    local Items = Inventory[Catagory]
    local Added = false
    assert(typeof(Amount) == "number", "Amount was given as a string")
    

    for Pos, ItemData in Items do
        if ItemData.Name == Item then
            Added = true
            ItemData.Amount += Amount
            -- warn("We're changing the item: ", ItemData.Amount, Amount)

            PlayerService.Client.UpdateInventory:Fire(player, ItemData)
            --? If the Item is being decreased then remove it completely from the inventory
            if ItemData.Amount <= 0 then
                table.remove(Items,Pos)
                warn("Item should have been removed completely: ", Items)
                Added = false
            end
        end
    end

    if not Added and Amount > 0 then
        table.insert(Items, {Name = Item, Amount = Amount})
    end

    ProfileService:Update(player,"Inventory",function()
        -- warn("New Inventory: ", Inventory)
        return Inventory
    end)
end 

function PlayerService.Client:GetItem(player, Catagory : string, Item : string)
    return PlayerService:GetItem(player, Catagory, Item)
end

function PlayerService.Client:GiveItemTest(player,Catagory : string, Item : string, Amount : number)
    PlayerService:GiveItem(player, Catagory, Item, Amount)
end

function PlayerService:ConvertItems( ItemName : string )
    local ItemsFolder = ReplicatedStorage.Recipes:GetChildren()
    local Items = {}

    local function ItemData(Item)
        local n = {}

        for _,t in pairs(Item:GetChildren()) do
            if t:IsA("IntValue") then
                -- table.insert(n,{Name = t.Name, Amount = t.Value})   
                n[t.Name] = t.Value
            else
                n["Icon"] = t:Clone()
            end
        end

        return n
    end

    for _,Item in pairs(ItemsFolder) do
        local Data = ItemData(Item)
        Items[Item.Name] = Data
    end

    if ItemName then
        return Items[ItemName]
    end

    return Items
end

function PlayerService:CheckTableFor(Table, Name)
    for pos, tably in Table do
        if tably.Type == Name then
            return true,tably
        end
    end

    return false
end

function PlayerService.Client:CraftItem(player, Item : string)
    local ItemData = PlayerService:ConvertItems(Item)
    local playerCoins = ProfileService:Get(player,"Coins")
    local MaxAmount = 0
    local RecipesAmount = 0
    local Cost = 0;

    if ItemData ~= nil then
        print("The Item we want to craft: ", ItemData)
        for Item, Amount in ItemData do
            if Item ~= "Icon" and Item ~= "Cost" then
                local ItemInInventory = PlayerService:GetItem(player,"Materials",Item) or { Amount = 0 } -- ProfileService:Get("Inventory")
                MaxAmount += 1
                if ItemInInventory.Amount >= Amount then
                    ItemInInventory.Amount -= Amount
                    RecipesAmount += 1
                end
            elseif Item == "Cost" then
                Cost = Amount
            end
        end

        print(`MaxAmount {MaxAmount} Amount {RecipesAmount}`)
        if RecipesAmount >= MaxAmount and playerCoins >= Cost then
            PlayerService:GiveItem(player,"Items",Item, 1)

            ProfileService:Update(player,"Coins",function(currentAmount)
                currentAmount -= Cost
                return currentAmount
            end)

            return true
        end

        return false
    end
end

function PlayerService.Client:Sprint(player, SetSprint : boolean)
    local character = player.Character
    local Humanoid = character:FindFirstChild("Humanoid")

    if Humanoid then
        if SetSprint then
            Humanoid.WalkSpeed = 25
        else
            Humanoid.WalkSpeed = 12
        end    
    end
end

local function BillboardUpdate(Character, Level, Title)
    local Billboard = Character:FindFistChild("playerGui")

    if Billboard then
        Billboard.UserName.Text = Character.Name .. " Lv. " .. Level       
    end
end

function PlayerService:GiveCoin(player,Amount)
    ProfileService:Update(player,"Coins",function(currentAmount)
        local TotalAmount = currentAmount + Amount
        PlayerService.Client.UpdateCoins:Fire(player, TotalAmount)
        return TotalAmount
    end)
end

function PlayerService:GetFlag(player, Flag)
    local Flags = ProfileService:Get(player,"Flags")
    if typeof(Flag) ~= "table" then
        return if Flags[Flag] ~= nil then Flags[Flag] else nil
    else
        local newTable = {}
        for _, flag in ipairs(Flag) do
            table.insert(newTable, if Flags[Flag] ~= nil then Flags[Flag] else nil)
        end
        return newTable
    end
end

function PlayerService:GiveGems(player,Amount)
    ProfileService:Update(player,"Gems",function(currentAmount)
        local TotalAmount = currentAmount + Amount
        PlayerService.Client.UpdateGems:Fire(player, TotalAmount)
        return TotalAmount
    end)
end

function PlayerService:GiveBattlepassExp(player, expAmount)
    local Battlepass = ProfileService:Get(player,"Battlepass")
    local leftoverExp = expAmount
    local increment = 1.5
    local Exp = Battlepass.Exp
    local MaxExp = Battlepass.MaxExp

    while leftoverExp > 0 do
        Exp = Battlepass.Exp
        MaxExp = Battlepass.MaxExp

        if Exp + leftoverExp >= MaxExp then
            leftoverExp = math.ceil((Exp + leftoverExp) - MaxExp)
            Battlepass.Exp = 0

            Battlepass.Level += 1
            Battlepass.MaxExp *= increment 
        else
            Battlepass.Exp += leftoverExp 
            leftoverExp = 0
        end
        task.wait()
    end

    ProfileService:Update(player,"Battlepass",function()
        Battlepass.MaxExp = math.round(Battlepass.MaxExp)
        return Battlepass
    end)

    local succ = pcall(function()
        QuestsService.Client.UpdateBattleLevel:Fire(player)
    end)

    if succ then
        print(`{player.Name} battlepass level has been updated`)
    end
end

function PlayerService:Skip10Levels(player)
    local Battlepass = ProfileService:Get(player,"Battlepass")
    local Exp = Battlepass.Exp
    local MaxExp = Battlepass.MaxExp
    local increment = 1.5
    -- local Level = Battlepass.Level

    local ExpNeeded = (MaxExp * (increment^(12)))

    print("ExpNeed to level 10: ", ExpNeeded)
    PlayerService:GiveBattlepassExp(player,Exp + math.round(ExpNeeded))
end

function PlayerService:GivePlayerExp(player,expAmount)
    local Level = ProfileService:Get(player,"Level")
    local Equipped = ProfileService:Get(player,"Equipped")
    local MaxExpIncrement = 1.25
    local CurrentExp = ProfileService:Get(player,"Exp")
    local CurrentMaxExp = ProfileService:Get(player,"MaxExp") 

    local Increment = expAmount/CurrentMaxExp
    local ExpLeft = expAmount
    local ExpInTank = expAmount

    if Increment > 1 then
        while Increment > 1 do
            Increment =  ExpLeft/CurrentMaxExp
            
            if (CurrentExp + ExpLeft) >= CurrentMaxExp then -- and Level.Value < MaxLevel
                ExpLeft -= (CurrentMaxExp - CurrentExp)
                ExpInTank -= (CurrentMaxExp - CurrentExp) 
                CurrentExp = 0 -- ExpLeft --(expAmount - CurrentMaxExp)

                Level += 1
                CurrentMaxExp *= MaxExpIncrement
            else
                CurrentExp += ExpLeft
            end
            task.wait()
        end

        CurrentExp = math.ceil(ExpLeft)
    else
        CurrentExp += ExpLeft

        if CurrentExp >= CurrentMaxExp then -- and Level.Value < MaxLevel
            ExpLeft -= (CurrentMaxExp - CurrentExp)
            ExpInTank -= (CurrentMaxExp - CurrentExp) 
            CurrentExp = 0 -- ExpLeft --(expAmount - CurrentMaxExp)

            Level += 1
            CurrentMaxExp *= MaxExpIncrement
        end
    end

    ProfileService:Update(player,"Exp",function()
        pcall(function()
            self.Client.UpdateExp:Fire(player, CurrentExp, math.ceil(CurrentMaxExp), Level)
        end)
        return math.ceil(CurrentExp)
    end)

    ProfileService:Update(player,"MaxExp",function()
        return math.ceil(CurrentMaxExp)
    end)

    ProfileService:Update(player,"Level",function()
        local Head = player.Character.Head
        local playerGui = Head:FindFirstChild("playerGui")

        if playerGui then
            local UserName = playerGui.UserName
            UserName.Text = player.Name .. " Lv. " .. Level
        end

        pcall(function()
            self.Client.UpdateExp:Fire(player, CurrentExp, math.ceil(CurrentMaxExp), Level)
        end)

        return Level
    end)

    print("CurrentExp: ", CurrentExp, " CurrentMaxExp: ", CurrentMaxExp, " CurrentLevel: ", Level, " ExpLeft: ", ExpLeft, " ExpInTank: ",ExpInTank)
end

function PlayerService:GiveUnitExp(player, UnitHash, Amount : number)

    local Inventory = ProfileService:Get(player,"Inventory")
    local Equipped = ProfileService:Get(player,"Equipped")
    local Units = Inventory.Units
    local Unit = GetUnit(Units, UnitHash)
    local EquippedUnit = GetUnit(Equipped, UnitHash)
    local OldLevel = Unit.Level
    print(`Before Giving Exp -> The Unit {Unit.Exp} x MaxExp: {Unit.MaxExp} x Level: {Unit.Level}`)

    if Unit then
        local MaxExp = Unit.MaxExp
        -- Check if player has double exp if so then double(expAmount * 2) exp amount

        local leftoverExp = Amount
        local maxExp = MaxExp

        while leftoverExp > 0 do
            local Exp = Unit.Exp
            if Exp + leftoverExp >= maxExp then
                -- Add exp to fill to MaxExp and level up
                leftoverExp = math.ceil((Exp + leftoverExp) - maxExp)

                Unit.Exp = 0
                Unit.Level += 1

                maxExp = maxExp * 1.25 -- Increase MaxExp by 25% for next level

                Unit.MaxExp = math.ceil(maxExp) 
            else
                -- Add remaining exp and break the loop
                local newValue = Unit.Exp + leftoverExp

                Unit.Exp = newValue
                leftoverExp = 0
            end
            task.wait()
        end

        if EquippedUnit then
            EquippedUnit.MaxExp = Unit.MaxExp
            EquippedUnit.Exp = Unit.Exp
            EquippedUnit.Level = Unit.Level
        end
        
        ProfileService:Update(player,"Equipped", function(equip)
            equip = Equipped
            return equip
        end)
        
        ProfileService:Update(player,"Inventory", function(inv)
            inv.Units = Units
            return inv
        end)

        if EquippedUnit and EquippedUnit.Level > OldLevel then
            PlayerService.Client.UpdateEquipped:Fire(player)
        end
    end
end

function PlayerService.Client:TestExp(player)
    -- PlayerService:GiveUnitExp(player,UnitHash,100)
    -- PlayerService:Skip10Levels(player)
    -- PlayerService:GiveBossKill(player.Name,2)
    -- PlayerService:GiveBattlepassExp(player,1000)
    -- PlayerService:GivePlayerExp(player,25)
    PlayerService:GiveItem(player,"Items","Meat",5)
    -- PlayerService:MapCompleted(player,{Name = "Leaf Village", Chapter = 1})
end

function PlayerService:GiveWaves(playerName, Amount)
    local player = Players:FindFirstChild(playerName)
    if not player then return false end

    local Statistics = ProfileService:Get(player,"Statistics")
    local Quests = ProfileService:Get(player,"Quests")
    local Daily = Quests.DailyList
    local Weekly = Quests.WeeklyList
    local GameInfo = Statistics.GameInfo
    local exists, WaveQuest = PlayerService:CheckTableFor(Daily,"WaveQuest")
    -- local Weeklyexists, WeeklyBossQuest = PlayerService:CheckTableFor(Weekly,"WaveQuest")
    -- local newGameInfo, TotalBossKilled = deepSearch(GameInfo, "TotalBossKilled")

    print(Statistics)

    GameInfo.TotalWaves += Amount

    if exists then
        WaveQuest.Amount += Amount
    end

    ProfileService:Update(player,"Quests",function()
        return Quests
    end)

    ProfileService:Update(player,"Statistics",function(statsInfo)
        statsInfo.GameInfo = GameInfo
        return statsInfo
    end)
end

function PlayerService:GiveMobKill(playerName, Amount)
    local player = Players:FindFirstChild(playerName)
    if not player then return false end

    local Statistics = ProfileService:Get(player,"Statistics")
    local Quests = ProfileService:Get(player,"Quests")

    local Daily = Quests.DailyList
    local Weekly = Quests.WeeklyList
    local GameInfo = Statistics.GameInfo
    local exists, MobQuest = PlayerService:CheckTableFor(Daily,"MobQuest")
    local Weeklyexists, WeeklyMobQuest = PlayerService:CheckTableFor(Weekly,"MobQuest")

    GameInfo.TotalKills += Amount

    if exists then
        MobQuest.Amount += Amount
    end

    if Weeklyexists then
        WeeklyMobQuest.Amount += Amount
    end

    ProfileService:Update(player,"Quests",function()
        return Quests
    end)

    ProfileService:Update(player,"Statistics",function(statsInfo)
        statsInfo.GameInfo = GameInfo
        return statsInfo
    end)
end

function PlayerService:GiveBossKill(playerName, Amount)
    local player = Players:FindFirstChild(playerName)
    if not player then return false end

    local Statistics = ProfileService:Get(player,"Statistics")
    local Quests = ProfileService:Get(player,"Quests")
    local Daily = Quests.DailyList
    local Weekly = Quests.WeeklyList
    local GameInfo = Statistics.GameInfo
    local exists, BossQuest = PlayerService:CheckTableFor(Daily,"BossQuest")
    local Weeklyexists, WeeklyBossQuest = PlayerService:CheckTableFor(Weekly,"BossQuest")

    GameInfo.TotalBossKilled += Amount

    if exists then
        BossQuest.Amount += Amount
    end

    if Weeklyexists then
        WeeklyBossQuest.Amount += Amount
    end

    ProfileService:Update(player,"Quests",function()
        return Quests
    end)

    ProfileService:Update(player,"Statistics",function(statsInfo)
        statsInfo.GameInfo = GameInfo
        return statsInfo
    end)
end

-- function PlayerService.Client:TestExp(player)
--     PlayerService:GiveMobKill(player.Name, 10)
--     PlayerService:GiveWaves(player.Name, 5)
--     -- PlayerService:GivePlayerExp(player,400)
-- end

local function GetMapOrdered()
    local Difficulties = ReplicatedStorage.Difficulties
    local Storage = {}

    for _,Maps in pairs(Difficulties:GetChildren()) do
        Storage[Maps:GetAttribute("Order")] = Maps.Name
    end

    return Storage
end

local function GetMap()
    local Difficulties = ReplicatedStorage.Difficulties
    local Storage = {}

    for _,Maps in pairs(Difficulties:GetChildren()) do
        Storage[Maps.Name] = Maps:GetAttribute("Order")
    end

    return Storage
end

function PlayerService:UnlockMap(player, MapName : string, Chapter : number)
    local Worlds = ProfileService:Get(player,"Worlds")
    local MapOrder = GetMap()[MapName]
    local currentMap = Worlds[MapOrder] --? Map Name

    if currentMap then
        currentMap.Chapter = Chapter
        currentMap.Unlocked = true
    end

    ProfileService:Update(player,"Worlds",function()
        warn("THE WORLD: ", Worlds, MapName, MapOrder, currentMap)
        return Worlds
    end)

    return currentMap
end

function PlayerService:MapCompleted(player, MatchData)
    local Worlds = ProfileService:Get(player,"Worlds")
    local MapOrder = GetMap()[MatchData.Name]
    local currentMap = Worlds[MapOrder] --? Map Name
    local CurrentChapter = MatchData.Chapter
    local CurrentChapters = currentMap.Chapter --? Chapter in datastore

     warn("THE CURRENTMAP: ", currentMap)
     print(CurrentChapter)
    --! This was the problem
    local Chapter = currentMap.Chapters[CurrentChapter]

    if CurrentChapters == CurrentChapter and CurrentChapters < currentMap.MaxChapters then
        Chapter.Cleared = true
        currentMap.Chapter += 1 --? Add one more chapter
    end

    if MatchData.BestTime then
        Chapter.BestTime = MatchData.BestTime
    end

    Chapter.TotalCleared += 1

    if currentMap.Chapter >= 5 then
        local NextChapter : number = tonumber(MapOrder + 1)
        -- CurrenMap

        if Worlds[NextChapter] and not Worlds[NextChapter].Unlocked then
            Worlds[NextChapter].Unlocked = true
        end
    end

    ProfileService:Update(player,"Worlds",function()
        -- warn("The new worlds: ", Worlds)
        return Worlds
    end)

    return currentMap
end

function PlayerService:KnitInit()

end

function PlayerService:KnitStart()
    ProfileService = Knit.GetService("ProfileService")

    local _,_ = pcall(function()
        InventoryService = Knit.GetService("InventoryService")
        QuestsService = Knit.GetService("QuestsService")
    end)
    
    local function Givebillboard(player,character)
        repeat task.wait() until ProfileService:IsProfileReady(player)
        local Level = ProfileService:Get(player,"Level")

        local Humanoid : Humanoid = character:FindFirstChild("Humanoid")
        local newBillboard = Assets.playerGui:Clone()
        newBillboard.UserName.Text = character.Name .. " Lv. " .. Level
        newBillboard.Parent = character.Head

        ProfileService:Update(player,"Statistics",function(Statistics)
            Statistics.LastLogin = os.time()
            return Statistics
        end)

        if Humanoid then
            Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
    end

    local function SetCollisionGroup(character)
        for _,part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Players"
			end
		end
    end

    for _, player in pairs(Players:GetChildren()) do
        Givebillboard(player.Character)
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            Givebillboard(player,character)
            SetCollisionGroup(character)
        end)
    end)

    -- ProfileService.UpdateBillboard:Connect()
end

return PlayerService
