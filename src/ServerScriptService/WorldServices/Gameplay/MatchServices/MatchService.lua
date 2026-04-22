local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Difficulties = require(ReplicatedStorage.Difficulties)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local EntityModule = require(ReplicatedStorage.Shared.Entity)
local Signals = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Challenges = require(ReplicatedStorage.Shared.Challenges)
local BannerNotify = require(ReplicatedStorage.Shared.Utility.BannerNotificationModule)
local ItemsModule = require(ReplicatedStorage.SharedPackage.Items)

local MatchService = Knit.CreateService {
    Name = "MatchService",

    InsertEntityTable = Signals.new(),
    RemoveEntityTable = Signals.new(),

    Client = {
        SkipWave = Knit.CreateSignal(),
        WaveEnd = Knit.CreateSignal(),
        RemoveSkipWave = Knit.CreateSignal(),
        WaveUpdate = Knit.CreateSignal(),
        StartTimer = Knit.CreateSignal(),
        Vote = Knit.CreateSignal(),
        RequestToStart = Knit.CreateSignal(),
        Sprint = Knit.CreateSignal(),
        MatchStart = Knit.CreateSignal(),
        MatchEnd = Knit.CreateSignal(),
        PlayUnitAnimations = Knit.CreateSignal(),
        EnemiesSpawned = Knit.CreateProperty(0),
        NextChapter = Knit.CreateSignal(),
    }
}

MatchService.GameIsActive = false

local ValueFolder = workspace.Values
local Gameplay = workspace.Gameplay
local Mobs = Gameplay.Mobs

local WorldService
local PlayerService
local MobService
local ProfileService
local UnitService
local GameInfo = {}
local EntityWaveTable = {}
local InfiniteRewards = {}

local bannerConfig = {
    .2,                             -- Background Transparency
    Color3.fromRGB(61, 255, 77),         -- Background Color

    0,                                 -- Content Transparency
    Color3.fromRGB(244, 244, 244), -- Content Color
}

type EntityType = {
    Amount : number,
    Direction : string?,
    Enemy : string,
    HP : number,
	Speed : number;
	Priority : number?;
	IsBoss : boolean?;
}

local DefaultWaitUntilNextWave = 30 -- seconds
local PauseWave = false

function MatchService.Client:SendToLobby(player)
    local succ, result = pcall(function()
        return TeleportService:Teleport(114746697858159,player)
    end)

    if result then
        -- Teleport Screen
    end
end

function MatchService.AutoSkip(player)
    local Exists = ValueFolder:FindFirstChild("AutoSkip: ".. player.Name)

    if not Exists then
        local AutoSkip = Instance.new("BoolValue")
        AutoSkip.Name = "AutoSkip: ".. player.Name
        AutoSkip.Value = true
        AutoSkip.Parent = ValueFolder
    else
        Exists:Destroy()
    end
end

function MatchService:SelectItemByPercentage(items)
    local totalPercentage = 0
    for _, item in pairs(items) do
        totalPercentage = totalPercentage + item.Percentage
    end
    
	local randomPercentage = math.random() * 100 
    local accumulatedPercentage = 0
    
    for _, item in pairs(items) do
        accumulatedPercentage = accumulatedPercentage + item.Percentage
        if randomPercentage <= accumulatedPercentage then
            return item
        end
    end
    
    return nil
end

function MatchService:OrderByPriority(CurrentWaveTable)
	local waitTable = {}
	local AmountForWave = 0

	table.sort(CurrentWaveTable,function(a,b)
		return a["Priority"] < b["Priority"]
	end)

	for i = 1,#CurrentWaveTable do
		local Entity = CurrentWaveTable[i]
		local fraction = tonumber(Entity["Priority"]) % 1
		AmountForWave += Entity["Amount"]
		if fraction ~= 0 then
			waitTable[i] = fraction * 100 -- Gets the fraction and turns it into seconds
		else
			waitTable[i] = DefaultWaitUntilNextWave
		end
	end

	return CurrentWaveTable,waitTable,AmountForWave
end


function MatchService.Cooldown(Time : number)
    local dt : number = 0

    local SkipCooldown = Instance.new("BoolValue")
    SkipCooldown.Value = false
    SkipCooldown.Parent = workspace.Values
    SkipCooldown.Name = "SkipCooldown"


    while dt < Time and not SkipCooldown.Value do
        if #EntityWaveTable <= 0 then
            break
        end
        if #workspace.Gameplay.Mobs:GetChildren() <= 0 then
            break
        end

        dt += RunService.Heartbeat:Wait()
    end
end

function MatchService.CreateValues(ExtraInfo) : IntValue
    local DefualtHealth = ExtraInfo.Health or 150

    local Health = Instance.new("IntValue")
    Health.Name = "Health"
    Health.Value = DefualtHealth
    Health.Parent = ValueFolder

    local GameSpeed = Instance.new("IntValue")
    GameSpeed.Name = "GameSpeed"
    GameSpeed.Value = 1
    GameSpeed.Parent = ValueFolder

    local TimeIsActive = Instance.new("BoolValue")
    TimeIsActive.Name = "TimeIsActive"
    TimeIsActive.Value = true
    TimeIsActive.Parent = ValueFolder

    local DestructionLevel = Instance.new("IntValue")
    DestructionLevel.Name = "Destruction"
    DestructionLevel.Value = 3 -- 1 = Off, 2 = Medium, 3 = High
    DestructionLevel.Parent = ValueFolder

    Health:SetAttribute("MaxHealth", DefualtHealth)
    return Health,TimeIsActive
end

function MatchService:MakeRewardTable(player, MatchInfo)
    local newTable = {}
    local completionRewards = table.clone(MatchInfo.MatchInfo.CompletionRewards)
    local recievedItemTable = self:SelectItemByPercentage(completionRewards.ChanceToGet)

    completionRewards.ChanceToGet = nil

    newTable = completionRewards
    newTable.Items = {} -- Can be items, materials and stuff

    newTable.Items[recievedItemTable.Name] = recievedItemTable.Amount

   -- Rewards[player.Name].Items

    if MatchInfo.MatchInfo.Challenges ~= nil then
        local challengeRewards = MatchInfo.MatchInfo.Challenges.Rewards
        local recievedItemTable = self:SelectItemByPercentage(challengeRewards.PossibleRewards)

        challengeRewards.PossibleRewards = nil

        for thing,amount in pairs(challengeRewards) do
            if newTable[thing] ~= nil then
                newTable[thing] = newTable[thing] + amount
            else
                newTable[thing] = amount
            end
        end

        if newTable.Items[recievedItemTable.Name] ~= nil then
            newTable.Items[recievedItemTable.Name] += recievedItemTable.Amount 
        else
            newTable.Items[recievedItemTable.Name] = recievedItemTable.Amount
        end

    end

    -- Gives items to players

    for ItemName,Amount in pairs(newTable.Items) do
        local ItemType,ItemRarity = ItemsModule:GetItem(ItemName)

        if ItemType then -- else its like gems or coins and dsoen't have an itemtype
            PlayerService:GiveItem(player,ItemType,ItemName,Amount)
        end
    end

    PlayerService:MapCompleted(player, MatchInfo.MapInfo)

    return newTable
end

function MatchService:EndMatch(MatchInfo) --! Matchen slutar här
    local TimeIsActive = ValueFolder.TimeIsActive
    local Rewards = {}

    local function GiveUnitExp(player, exp)
        local Units = ProfileService:Get(player,"Equipped")

        for _,unitData in Units do
            --task.spawn(function()
                PlayerService:GiveUnitExp(player, unitData.Hash, exp)
            --end)
        end

        -- Go igemon workspace, kolla alla units, lägg dem och + damage i table
        
    end

    TimeIsActive.Value = false
    MatchService.GameIsActive = false
    MobService.ClearEntities()

    MatchService:StartVote(#Players:GetChildren(),nil, 999, function()
        WorldService:RestoreWorld()
    end)

    for _,player in pairs(Players:GetChildren()) do
        if MatchInfo.Result == "Win" then
            local rewards = self:MakeRewardTable(player, MatchInfo)
            Rewards[player.Name] = rewards
            local coins = rewards.Coins
            local gems = rewards.Gems

            if coins then
                PlayerService:GiveCoin(player,coins)
            end

            if gems then
                PlayerService:GiveGems(player,gems)
            end    

            if rewards.UnitExp then
                GiveUnitExp(player, rewards.UnitExp)
            end
            
            PlayerService:GivePlayerExp(player,rewards.Exp)
            PlayerService:GiveBattlepassExp(player,rewards.Exp)
         end -- Give exp to units

         player.leaderstats.Cash.Value = 0

         if InfiniteRewards[player.Name] then
            Rewards[player.Name] = InfiniteRewards[player.Name]
         end

        -- Give rewards for completing the map
    end

    InfiniteRewards = {}

    MatchService.Client.MatchEnd:FireAll({VoteName = "Try again", Matchresult = MatchInfo, Rewards = Rewards})
end

function MatchService:StartVote(RequiredToProcced : number, ReasonToVote : string, TimeToVote : number, _callback : any)
    TimeToVote = TimeToVote or 10
    RequiredToProcced = RequiredToProcced or 1
    ReasonToVote = ReasonToVote or "Try again"
    
    local AlreadyInVoting = ValueFolder:FindFirstChild(ReasonToVote)
    if AlreadyInVoting then return end
    
    local Voted = {}
    local AlreadyCleaned = false
    local maid = Maid.new()

    local Folder = Instance.new("Folder")
    Folder.Name = ReasonToVote
    Folder.Parent = ValueFolder

    local Votes = Instance.new("IntValue")
    Votes.Name = "Votes"
    Votes.Value = 0
    Votes.Parent = Folder

    local RequiredVotes = Instance.new("IntValue")
    RequiredVotes.Name = "RequiredVotes"
    RequiredVotes.Value = RequiredToProcced
    RequiredVotes.Parent = Folder

    local function Clean()
        AlreadyCleaned = true
        Voted = {}
        Folder:Destroy()
        maid:Destroy()
        _callback = nil
    end

    task.delay(TimeToVote, function()
        if not AlreadyCleaned then
            Clean()
        end
    end)

    maid:GiveTask(Players.PlayerRemoving:Connect(function(player) -- if player leaves during vote, then lower the vote required to procced
        local playerIntable = table.find(Voted,player.Name)

        if playerIntable then
            table.remove(Voted,playerIntable)
        end

        RequiredToProcced = #Players:GetChildren()
        RequiredVotes.Value = RequiredToProcced
    end))

    maid:GiveTask(MatchService.Client.NextChapter:Connect(function(player)
        -- increase chapter count bro
        WorldService:NextChapter()
        task.spawn(_callback)
        Clean()
    end))

    MatchService.Client.Vote:Connect(function(player)
        local playerIntable = table.find(Voted,player.Name)

        if playerIntable then
            table.remove(Voted,playerIntable)
        else
            table.insert(Voted,player.Name)
        end

        Votes.Value = #Voted

        if Votes.Value >= RequiredToProcced and _callback then
            --warn(`[ {ReasonToVote} the callback that was going to activate ] `)
            task.spawn(_callback)
            Clean()
        end
    end)

    --- Remove all values when the votes has gone through
    -- MatchService.Client.Vote:FireAll()
end

function MatchService:SkipWave()
    local TimeToVote = DefaultWaitUntilNextWave
    local AlreadyRemoved = false
    local OldSkipCooldown = workspace.Values:FindFirstChild("SkipCooldown")

    if OldSkipCooldown then
        OldSkipCooldown:Destroy()
    end

    MatchService.Client.SkipWave:FireAll({VoteName = "SkipWave",TimetoVote = TimeToVote})

    task.delay(TimeToVote,function()
        if not AlreadyRemoved then
        local SkipCooldown = workspace.Values:FindFirstChild("SkipCooldown")
        local SkipWaveFolder = workspace.Values:FindFirstChild("SkipWave")

        if SkipWaveFolder then
            SkipWaveFolder:Destroy()
        end

        if SkipCooldown then
            -- warn("THE SKIP HAS FINISHED")
            SkipCooldown:Destroy()
        end
            MatchService.Client.RemoveSkipWave:FireAll()
        end
    end)

    MatchService:StartVote(#Players:GetChildren(),"SkipWave", TimeToVote, function()
        local SkipCooldown = workspace.Values:FindFirstChild("SkipCooldown")

        if SkipCooldown then
            -- warn("THE SKIP HAS FINISHED")
            SkipCooldown.Value = true
            SkipCooldown:Destroy()
        end

        MatchService.Client.RemoveSkipWave:FireAll()
        AlreadyRemoved = true
    end)
end

function toHMS(s)
	return string.format("%02i:%02i", s/60%60, s%60)
end

function MatchService:GivePlayerMoney(Amount : number)
    for _,player in pairs(Players:GetChildren()) do
        local leaderstats = player:FindFirstChild("leaderstats")

        if leaderstats then
            local Cash = leaderstats:FindFirstChild("Cash")
            if Cash then
                Cash.Value += Amount
            end
        end
    end
end

function MatchService:SkipCooldown()
    local SkipValue = workspace.Values:FindFirstChild("SkipCooldown")

    if SkipValue then
        SkipValue.Value = true
    end
end

local BossHealth = 100
local StartingHealth = 15

function MatchService:GenerateWave(MatchInfo : {CurrentWave : number }, EntityList, Room_Difficulty, Spawns : number)

	local function Variety(MaxVariety : number)
		local VarietyAmount = math.random(1,MaxVariety)
		local totalAmount = #EntityList
		local List = {}
        local newEntityList = {}

        for _,Entity in pairs(EntityList) do
            if not Entity:GetAttribute("IsBoss") then
                table.insert(newEntityList, Entity)
            end
        end

        totalAmount = #newEntityList
        
		-- add could down for each Entity

		for Priority = 1, VarietyAmount do
			List[newEntityList[math.random(1,totalAmount)].Name] = Priority
		end

		return List,VarietyAmount
	end

	local WaveList,MaxVarieties = Variety(Room_Difficulty.MaxVariety) -- the number should be a value from the Map Data
	local Wave = {}
	local Locations = {
		[1] = "Start",
		[2] = "Start1",
		[3] = "Start2",
	}

	-- Add boss every 10 round
	if MatchInfo.CurrentWave % 10 == 0 then
		table.insert(Wave,{
			Amount = 1,
			Direction = "",
			Enemy = "Pain",
			HP = (BossHealth * 2),
			Priority = 1.05, -- Boss should always be last
			Speed = math.random(1,3),
			IsBoss = true,
		})

		BossHealth = math.floor(BossHealth * 1.25)
	end
	
	if MatchInfo.CurrentWave < 200 then
		StartingHealth = StartingHealth * 1.048 -- Save health
	else
		StartingHealth += 5000
	end
	--warn("[ GENERATED WAVE ]:", CurrentWave.Value ," HEALTH --> ", StartingHealth)
	
	for Entity,Priority in pairs(WaveList) do
		local Preset : EntityType = {
			Amount = math.ceil((5 + Room_Difficulty.IncrementPerWave) / MaxVarieties);
			Enemy = Entity;
			HP = math.floor(StartingHealth); -- Should be a value from the Map Data
			Speed = math.random(1,2); -- Should be a value from the Map Data
            MobType = "Ground";
			Priority = Priority;
			SpawnLocation = "Start"
		};
		table.insert(Wave,Preset)
	end
	
	return Wave
end

function MatchService:SetChallenge(Waves, Challenge)

    return Waves
end

function MatchService:StartMatch(MapInfo)
    if MatchService.GameIsActive then return end

    MobService = Knit.GetService("MobService")
    UnitService:ResetTable()
    
    local ExtraInfo = table.clone(Difficulties[MapInfo.Name][MapInfo.Difficulty])
    local GameTime = ExtraInfo.MaxTime
    local MaxTime = ExtraInfo.MaxTime
    local Chapter = MapInfo.Chapter -- This increase health or changes Wave completely?, Inreases health and amount
    local PlayerCount = #Players:GetChildren()
    local Waves = ExtraInfo.Waves
    local MatchEndTime
    local ResultShown = false
    local WaitPerWave = 15 -- seconds
    local EntityTable = {}
    local ChallengeRewards
    local ChallengeName

    if MapInfo.Challenges ~= 0 then 
        -- There is a challenge active
        Waves, ChallengeName, ChallengeRewards = Challenges[MapInfo.Challenges](Waves)

        ExtraInfo.Challenges = {
            Name = ChallengeName,
            Rewards = ChallengeRewards
        }
    end

    if Chapter > 1 then
        local amountMult = 1.25
        local healthMult = 1.35

        local function getEnemyHealth(baseHealth,chapter)
            return baseHealth * (healthMult ^ (chapter - 1))
        end

        for _,waveInfo in pairs(Waves) do
            for i = 1,#waveInfo do
                local unitInfo = waveInfo[i]
                local newHealth = getEnemyHealth(unitInfo.HP,Chapter); newHealth = math.round(newHealth)
                
                if unitInfo.HP then
                    unitInfo.HP = newHealth
                end

                if unitInfo.Amount and not unitInfo.IsBoss then
                    local newAmount = unitInfo.Amount * (amountMult ^ (Chapter - 1))
                    newAmount = math.round(newAmount)
                    unitInfo.Amount = newAmount
                end
                
            end
        end
    end

    if PlayerCount > 1 then
        for _,waveInfo in pairs(Waves) do
            for i = 1,#waveInfo do
                local unitInfo = waveInfo[i]
                local newHealth = unitInfo.HP * (1.5 * (PlayerCount-1))

                unitInfo.HP = newHealth
            end
        end
    end

    local Health,TimeIsActive = MatchService.CreateValues(ExtraInfo)

    MatchService.GameIsActive = true -- Allows the game to starts

    local Overlaps = OverlapParams.new()
    Overlaps.FilterType = Enum.RaycastFilterType.Include
    Overlaps.FilterDescendantsInstances = { Gameplay.Mobs }

    MatchService:GivePlayerMoney(ExtraInfo.StartingCash) -- ExtraInfo.StartingCash

    MatchService.Client.StartTimer:FireAll(MaxTime) -- Fires to client to render time countdown

    task.spawn(function()
        while MatchService.GameIsActive do -- Used to take health and check Mobs location in detector
            local Parts = workspace:GetPartsInPart(Gameplay.End,Overlaps)

            for _,parts in ipairs(Parts) do
                if parts.Parent then   
                    local HumanoidRootPart = parts.Parent:FindFirstChild("HumanoidRootPart")

                    if HumanoidRootPart then
                        local Id = HumanoidRootPart.Parent:GetAttribute("Id")
                        local Model = HumanoidRootPart.Parent

                        if Id then
                            local Amount_Deducted = if Model:GetAttribute("IsBoss") then 900 else 15
                            Health.Value -= Amount_Deducted
                            MobService.Remove:Fire(Id)
                            MatchService.RemoveEntityFromTable(Model)
                        end
                    end
                end
            end

            if ((MaxTime <= 0) or (Health.Value <= 0)) and not ResultShown then
                MatchService:SkipCooldown()
                MatchEndTime = toHMS(GameTime - MaxTime)
                MatchService:EndMatch({Result = "Lose", MatchInfo = table.clone(ExtraInfo),MapInfo = table.clone(MapInfo), Time = MatchEndTime}) -- Match ends
                ResultShown = true
                MatchService.GameIsActive = false               
            end

            MaxTime -= RunService.Heartbeat:Wait()
        end
    end)

    local CurrentWaveNr = {}

    if MapInfo.Difficulty ~= "Infinite" then
        for Current = 1, #Waves do
            CurrentWaveNr = Current
            local CurrentWave = self:OrderByPriority(Waves[Current])
            CurrentWave = CurrentWave

            MatchService.Client.PlayUnitAnimations:FireAll()
            MatchService.Client.RemoveSkipWave:FireAll()

            if not MatchService.GameIsActive then
                break;
            end

            self.Client.WaveUpdate:FireAll(Current,#Waves)

            for Entity = 1,#CurrentWave do
                local EntityTable = CurrentWave[Entity]
                CurrentWave[Entity].Path = MapInfo.Path
                for _ = 1, EntityTable.Amount do
                    if MatchService.GameIsActive and not PauseWave then
                        MobService.Create:Fire(CurrentWave[Entity])
                        task.wait(EntityTable.Priority)
                    else
                        break;
                    end
                end
            end 

            if not MatchService.GameIsActive then
                break;
            end

            if PauseWave then -- Mostly for Admins but could be used for revive later
                repeat
                    task.wait()
                until not PauseWave 
            end
            --- Should add somekind of wait until the loops continue

            if Current ~= #Waves  then
                MatchService:SkipWave()

                self.Cooldown(DefaultWaitUntilNextWave)
    
                MatchService:GivePlayerMoney(ExtraInfo.CashPerWave)
                
                --BannerNotify:Notify("WAVE ENDED","next wave starting","rbxassetid://11326670020",2.5,bannerConfig)
                MatchService.Client.WaveEnd:FireAll()
            end

            for _,player in Players:GetChildren() do
                PlayerService:GiveWaves(player.Name,1)
            end

        end
    else
        local Current : number = 0
        while MatchService.GameIsActive do
            Current += 1

            local Wave = MatchService:GenerateWave({CurrentWave = Current},ServerStorage.Mobs:GetChildren(),ExtraInfo)
            local CurrentWave = self:OrderByPriority(Wave)
            CurrentWave = CurrentWave

            if not MatchService.GameIsActive then
                break;
            end
            
            self.Client.WaveUpdate:FireAll(Current,"--")

            for Entity = 1,#CurrentWave do
                local EntityTable = CurrentWave[Entity]
                CurrentWave[Entity].Path = MapInfo.Path
                for _ = 1, EntityTable.Amount do
                    if MatchService.GameIsActive and not PauseWave then
                        MobService.Create:Fire(CurrentWave[Entity])
                        task.wait(EntityTable.Priority)
                    else
                        break;
                    end
                end
            end 

            if not MatchService.GameIsActive then
                break;
            end

            if PauseWave then -- Mostly for Admins but could be used for revive later
                repeat
                    task.wait()
                until not PauseWave 
            end
            --- Should add somekind of wait until the loops continue

            MatchService:SkipWave()

            self.Cooldown(DefaultWaitUntilNextWave)

            MatchService:GivePlayerMoney(ExtraInfo.CashPerWave)

            --if matchin


            BannerNotify:Notify("WAVE ENDED","next wave starting","rbxassetid://11326670020",2.5,bannerConfig)

            for _,player in Players:GetChildren() do
                PlayerService:GiveWaves(player.Name,1)
                if InfiniteRewards[player] == nil then
                    InfiniteRewards[player] = self:MakeRewardTable(player, ExtraInfo)
                else
                    for thing,amount in pairs(self:MakeRewardTable(player, ExtraInfo)) do
                        if not typeof(thing) == "table" then
                            if InfiniteRewards[player][thing] then
                                InfiniteRewards[player][thing] += amount
                            else
                                InfiniteRewards[player][thing] = amount
                            end
                        else
                            -- Its item table
                            local items = thing
                            for item, amount in pairs(items) do
                                if InfiniteRewards[player].Items[item] then
                                    InfiniteRewards[player].Items[item] += amount
                                else
                                    InfiniteRewards[player].Items[item] = amount
                                end
                            end
                        end
                    end

                end
            end


        end
    end

    repeat
        local MobCount = #Mobs:GetChildren()

        if MobCount <= 0 and CurrentWaveNr >= #Waves then
            MatchService.GameIsActive = false
        end

        task.wait()
    until not MatchService.GameIsActive

    if not ResultShown then
        MatchEndTime = toHMS(GameTime - MaxTime)
        MatchService.GameIsActive = false
        -- TimeIsActive.Value = false 
        MatchService:EndMatch({Result = "Win", MatchInfo = table.clone(ExtraInfo), MapInfo = table.clone(MapInfo), Time = MatchEndTime}) -- Match ends
    end
end

local StoredEntity = {}
local MobAdded_Connection : RBXScriptConnection;

function MatchService.SetSpeed(Value, Multiply : boolean)
    local GameSpeed = workspace.Values:FindFirstChild("GameSpeed")
    GameSpeed.Value = Value or 1 

    if Value and GameSpeed then

        workspace.Gameplay.Mobs.ChildAdded:Connect(function(mob)
            if not table.find(StoredEntity,mob) then
                StoredEntity[mob] = {Speed = mob:GetAttribute("OriginalSpeed")}
            end
        end)

        -- if #StoredEntity <= 0 then
        for _,mob in Mobs:GetChildren() do
            local speed = mob:GetAttribute("Speed")
            local OriginalSpeed = mob:GetAttribute("OriginalSpeed")

            if not StoredEntity[mob] then
                OriginalSpeed = mob:SetAttribute("OriginalSpeed", speed)
                mob:SetAttribute("OriginalSpeed", speed)
                StoredEntity[mob] = {Speed = speed}
            end

            if not Multiply then
                mob:SetAttribute("Speed", Value)
            else
                mob:SetAttribute("Speed", (OriginalSpeed or speed) * GameSpeed.Value)
            end
        end
    else
        for mob,mobTable in StoredEntity do
            if mob then
                mob:SetAttribute("Speed", mob:GetAttribute("OriginalSpeed") or mobTable.Speed)
            end
        end
        -- MobAdded_Connection:Disconnect()
        StoredEntity = {}
    end
end

local Requests = {}

function MatchService.RequestSpeedIncrease(player,Value, Multiply : boolean)
    if (not Requests[player] or Requests[player] ~= Value) then
        Requests[player] = Value
        MatchService.SetSpeed(Value, Multiply)
    -- else
    --     table.remove(Requests, table.find(Requests, player))
    end
end

function MatchService.GiveMoney(player, ...)
    local Cash = player.leaderstats:FindFirstChild("Cash")

    if Cash then
        Cash.Value += 999999
    end
end

function MatchService.CurrentPauseWave(value)
    -- warn("Requested to pause is ", value)
    PauseWave = value
    if value then
        MatchService.SetSpeed(0)
    else
        MatchService.SetSpeed()
    end
end

function MatchService.RemoveEntityFromTable(EntityModel)
    table.remove(EntityWaveTable,table.find(EntityWaveTable,EntityModel.Name))

    MatchService.Client.EnemiesSpawned:Set(#EntityWaveTable)
end

function MatchService.AddEntityToTable(EntityModel)
    table.insert(EntityWaveTable,EntityModel.Name)
    MatchService.Client.EnemiesSpawned:Set(#EntityWaveTable)

end

function MatchService:RequestStartGame(Info)
    local TimeToStart = 20
    local AlreadyStarted = false
    
    EntityWaveTable = {}

    MatchService.Client.RequestToStart:FireAll({VoteName = "StartGame",StartTime = TimeToStart})

    MatchService:StartVote(#Players:GetChildren(), "StartGame", TimeToStart,function()
        AlreadyStarted = true
        MatchService.Client.MatchStart:FireAll() -- Starts everything in the client
        self:StartMatch(Info)
    end)

    task.delay(TimeToStart,function()
        if not AlreadyStarted then
            AlreadyStarted = true
            MatchService.Client.MatchStart:FireAll() -- Starts everything in the client
            self:StartMatch(Info)
        end
    end)
end

function MatchService:KnitStart()
    WorldService = Knit.GetService("WorldService")
    PlayerService = Knit.GetService("PlayerService")
    ProfileService = Knit.GetService("ProfileService")
    UnitService = Knit.GetService("UnitService")

    WorldService.MultiplySpeed:Connect(MatchService.SetSpeed)
    WorldService.PauseWave:Connect(MatchService.CurrentPauseWave)
    WorldService.GiveMoney:Connect(MatchService.GiveMoney)
    WorldService.RequestSpeedIncrease:Connect(MatchService.RequestSpeedIncrease)
    WorldService.AutoSkip:Connect(MatchService.AutoSkip)

    -- WorldService.MatchInfo:Connect(function(Info)
    --     -- Confirms that all players are in the game
    --     if not MatchService.GameIsActive then
    --         MatchService:RequestStartGame(Info)
    --     end
    -- end)

    MatchService.InsertEntityTable:Connect(MatchService.AddEntityToTable)
    MatchService.RemoveEntityTable:Connect(MatchService.RemoveEntityFromTable)

    
end

return MatchService
