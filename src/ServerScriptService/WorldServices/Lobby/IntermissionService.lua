local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local IntermissionManager = require(ReplicatedStorage.Shared.IntermissionManager)
local TimerModule = require(ReplicatedStorage.Shared.TimeModule)
local Challenges = require(ReplicatedStorage.Shared.Challenges)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local Items = require(ReplicatedStorage.Shared.Items)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)
local BannerNotify = require(ReplicatedStorage.Shared.Utility.BannerNotificationModule)

local IntermissionService = Knit.CreateService {
    Name = "IntermissionService",
    Client = {
        CreateLobby = Knit.CreateSignal();
        CloseLobbyUI = Knit.CreateSignal();
        JoinedLobby = Knit.CreateSignal();
        ShowLoadingScreen = Knit.CreateSignal(),
    }
}

local ProfileService;

local PlayParts = workspace.PlayParts
local LobbyStorage = {}
local MapsInQueue = {}

local MapIds = { -- Should have two different versions
    [102414288850842] = {
        ["Leaf Village"] = 72076408034151;
        ["Demon District"] = 91010504416412;
        ["Royal Village"] = 114106678219778;
        ["Inferno Gate"] = 99444175922477;
    };

    [114746697858159] = {
        ["Leaf Village"] = 70814776537237;
        ["Demon District"] = 83479094164979;
        ["Royal Village"] = 137172673188156;
        ["Inferno Gate"] = 84343808797112;
    };
}

local MapsConverted = {
    ["Leaf Village"] = 1;
    ["Demon District"] = 2;
    ["Royal Village"] = 3;
    ["Inferno Gate"] = 4;
}

local LastChallenge : number = 1;

local function deepSearch(t, key_to_find)
	for key, value in pairs(t) do
		if value == key_to_find then -- value == key_to_find or
			return key, t, value
		end
		if typeof(value) == "table" then -- Original function always returned results of deepSearch here, but we should not return unless it is not nil.
			local a, b, c = deepSearch(value, key_to_find)
			if a then return a, b, c end
		end	
	end
	return nil
end

function IntermissionService.Client:GetSpawn(player)
    local Exists,LobbyTable = deepSearch(LobbyStorage, player)

    warn("Trying to get the spawn", Exists, LobbyTable, LobbyStorage)

    if Exists then
        local Host = LobbyTable[1]
        local Spawn = IntermissionManager:GetHostSpawn(Host)

        if Spawn then
            return Spawn, Spawn.Name, Spawn.Parent.Name
        end
    end

    return nil
end

function IntermissionService.JoinSpawn(player, Spawn)
    local Host = Spawn:GetAttribute("Host")
    local EquippedUnits = ProfileService:Get(player,"Equipped")
    --- Checks if it already has a leader or if it's friends only
    if #EquippedUnits <= 0 then
        BannerNotify:Notify("No Unit","You don't have a unit equipped","",5,nil,player)
        return
    end

    if Host == "" then
        IntermissionManager:EnterSpawn(player, Spawn, false)
    elseif Host ~= "" and Host ~= player.Name then
        local Spawn = IntermissionManager:GetHostSpawn({Name = Host})
        local _,HostMapInQueue = deepSearch(MapsInQueue, Host)
        local MapIntoBinary = MapsConverted[HostMapInQueue.Map]
        local playerWorlds = ProfileService:Get(player, "Worlds")
        local WorldData = playerWorlds[MapIntoBinary]

        --- Join lobby show timer and info
        --- Also check if the player has the Map and or Chapter
        if Spawn and WorldData.Unlocked and WorldData.Chapter >= HostMapInQueue.Chapter then
            local Host = Players:FindFirstChild(Host)

            if Host then
                local FindPos,LobbyTable = deepSearch(LobbyStorage, Host)--table.find(LobbyStorage, player)
                local playerAlreadyIn = table.find(LobbyTable, player)
                local FriendsOnly = Spawn:GetAttribute("FriendsOnly")
                local IsFriends = IntermissionManager:IsFriends(player,Host)
                
                if (not playerAlreadyIn) and not FriendsOnly then
                    IntermissionManager:EnterSpawn(player, Spawn, true)
                    table.insert(LobbyTable, player) -- Added to the table
                elseif not playerAlreadyIn and FriendsOnly and IsFriends then
                    table.insert(LobbyTable, player) -- Added to the table
                    IntermissionManager:EnterSpawn(player, Spawn, true)
                end
            end
        end
    end
end

function IntermissionService.Client:LeaveLobby(player)
    local FindPos,LobbyTable = deepSearch(LobbyStorage, player)

    print("Request Recieved",FindPos)

    if FindPos then
        local Host = LobbyTable[1]
        local Spawn = IntermissionManager:GetHostSpawn(LobbyTable[1])

        --- Teleport outside the Spawn
        if Spawn then
            local playerPosInLobby = deepSearch(LobbyTable, player)

            table.remove(LobbyTable, playerPosInLobby)
            IntermissionService.Client.CloseLobbyUI:Fire(player,Spawn.Parent.Name)

            if Host.Name == player.Name then -- If the host leaves then kick everyone
                local _, HostInMapQueue = deepSearch(MapsInQueue, Host.Name)
                local Pos = table.find(MapsInQueue, HostInMapQueue)

                table.remove(LobbyStorage, FindPos) -- Removes the Host lobby in the LobbyStorage
                table.remove(MapsInQueue, Pos) -- Removes the map info in MapsInQueue

                IntermissionManager:ResetSpawn(Spawn)

                for _, playerInLobby in ipairs(LobbyTable) do
                    playerInLobby.Character.HumanoidRootPart.CFrame = Spawn.ExitLocation.CFrame
                end

                if Spawn:GetAttribute("MaxTime") then
                    Spawn:SetAttribute("TimeUntilStart", Spawn:GetAttribute("MaxTime"))
                end

                Spawn:SetAttribute("Host","")
                print("After Host removal Lobby: ", LobbyStorage, MapsInQueue)
            end

            player.Character.HumanoidRootPart.CFrame = Spawn.ExitLocation.CFrame
        end
    else
        local Spawn = IntermissionManager:GetHostSpawn(player)

        if Spawn then
            IntermissionService.Client.CloseLobbyUI:Fire(player,Spawn.Parent.Name)

            Spawn:SetAttribute("Host","")
            player.Character.HumanoidRootPart.CFrame = Spawn.ExitLocation.CFrame
        end
    end
end


function IntermissionService.Client:StartLobby(player)
    local _,HostTable, Host = deepSearch(MapsInQueue,player.Name)

    if Host == player.Name then
        HostTable.Start = true
    end
end

function IntermissionService.Client:ConfirmLobby(Host, LobbyInfo : IntermissionManager.MapInfo)
    local Spawn = IntermissionManager:GetHostSpawn(Host)

    if Spawn then
        warn("THE LOBBY BEFORE THE SENT: ", LobbyInfo)
        local newLobbyInfo = table.clone(LobbyInfo)
        local _, HostInMapQueue = deepSearch(MapsInQueue, Host.Name)
        local TimeUntilStart = 15 -- if this reaches Zero

        --- Check LobbyInfo, to make sure the client hasn't change the data locally
        if LobbyInfo.Challenge ~= 0 and LobbyInfo.Challenge ~= Spawn:GetAttribute("Challenge") then
            IntermissionService.Client:LeaveLobby(Host)
            return;
        elseif Spawn:GetAttribute("Challenge") then
            LobbyInfo.Map = Spawn:GetAttribute("Map")
            LobbyInfo.Challenge = Spawn:GetAttribute("Challenge")
            LobbyInfo.Difficulty = Spawn:GetAttribute("Difficulty")
        end
        print("LobbyInfo: ", LobbyInfo)

        Spawn:SetAttribute("MaxTime", TimeUntilStart)
        Spawn:SetAttribute("TimeUntilStart", TimeUntilStart)

        --- If one exists then remove it --- 
        if HostInMapQueue then
            local FindTableInQueue = table.find(MapsInQueue, HostInMapQueue)

            if FindTableInQueue then
                IntermissionService.Client:LeaveLobby(Host)
                warn("Host left the party!")
                -- table.remove(MapsInQueue, FindTableInQueue)
            end
        end

        local Hostist = IntermissionManager:CreateLobby(Host, Spawn, LobbyInfo)
        table.insert(LobbyStorage, { Hostist })
        
        newLobbyInfo["Host"] = Host.Name
        newLobbyInfo.Start = false
        table.insert(MapsInQueue, newLobbyInfo)

        local _, HostTable = deepSearch(MapsInQueue, Host.Name)
        --- Start timer wait for people to join

        if not Spawn:GetAttribute("Challenge") then
            while TimeUntilStart > 0 and Spawn:GetAttribute("Host") ~= "" and not HostTable.Start do
                _, HostTable = deepSearch(MapsInQueue, Host.Name)
                Spawn:SetAttribute("TimeUntilStart", TimeUntilStart)
                TimeUntilStart -= RunService.Heartbeat:Wait()
            end

            if HostTable.Start then --? If player press Confirm
                TimeUntilStart = 0
            end
        else
            TimeUntilStart = 0
        end
        
        if TimeUntilStart <= 0 then
            local _,EntireParty = deepSearch(LobbyStorage, Host)
            local placeId = MapIds[game.PlaceId][LobbyInfo.Map]

            local serverCode 

            local _,Reservererr = pcall(function()
                warn("The place Id: ", tonumber(placeId))
                serverCode = TeleportService:ReserveServer(tonumber(placeId))
            end)

            local reservedServer = MemoryStoreService:GetHashMap("ReservedServers")

            if Reservererr then
                warn(Reservererr)
            end

            local succ,err = pcall(function()
                reservedServer:SetAsync(tostring(serverCode), LobbyInfo, 120)
            end)

            if succ then
                warn("We have reserved a server with data") 
            else 
                warn(err) 
            end
            
            local succ,result = pcall(function()
                local teleportOption = Instance.new("TeleportOptions")
                teleportOption.ReservedServerAccessCode = serverCode

                teleportOption:SetTeleportData({
                    reservedCode = serverCode;
                    message = "Welcome to the new server!"
                })
                warn("Before teleport: ", placeId, EntireParty , teleportOption, serverCode)

                return TeleportService:TeleportAsync(placeId, EntireParty , teleportOption) -- ,  LobbyInfo
            end)
            
            if succ then
                local jobId = result 
                --* Reset the spawn frame

                for _,player in ipairs(EntireParty) do
                    local FindPos,LobbyTable = deepSearch(LobbyStorage, player)
                    print("Request Recieved",FindPos)

                    IntermissionService.Client.ShowLoadingScreen:Fire(player, placeId, LobbyInfo.Chapter)

                    if FindPos then
                        local Host = LobbyTable[1]
                        local Spawn = IntermissionManager:GetHostSpawn(LobbyTable[1])

                        --- Teleport outside the Spawn
                        if Spawn then
                            local playerPosInLobby = deepSearch(LobbyTable, player)

                            table.remove(LobbyTable, playerPosInLobby)
                            IntermissionService.Client.CloseLobbyUI:Fire(player,Spawn.Parent.Name)

                            if Host.Name == player.Name then -- If the host leaves then kick everyone
                                local _, HostInMapQueue = deepSearch(MapsInQueue, Host.Name)
                                local Pos = table.find(MapsInQueue, HostInMapQueue)

                                table.remove(LobbyStorage, FindPos) -- Removes the Host lobby in the LobbyStorage
                                table.remove(MapsInQueue, Pos) -- Removes the map info in MapsInQueue
                            end
                        end
                    end
                    
                end
                
                IntermissionManager:ResetSpawn(Spawn)
                print("Players teleported to", jobId, serverCode)
            else
                for _,player in EntireParty do
                    local FindPos,LobbyTable = deepSearch(LobbyStorage, player)

                    IntermissionService.Client.CloseLobbyUI:Fire(player,Spawn.Parent.Name)
                    IntermissionService.Client:LeaveLobby(player)
                end
                warn("TELEPORTING ALL IN -> ", LobbyStorage, MapsInQueue)
                warn(result)
            end
        end
    end
end

function IntermissionService:GetNewChallenge(Spawn)
    local AllChallenge = #Challenges
    local SurfaceGui = Spawn.SurfaceGui
    local Frame = SurfaceGui.Frame
    local Core = Frame.Core
    local RewardsFrame = Core.Rewards
    local RewardsContent = RewardsFrame.Content
    local TempFolder = RewardsContent.Temp
    local tempImage = TempFolder.tempUI

    local newChallenge = math.random(1,AllChallenge);
    local MapsConvertedToNumber = {
        [1] = "Leaf Village";
        [2] = "Ruined City";
    }
    local newMap = MapsConvertedToNumber[math.random(1,2)]

    while LastChallenge == newChallenge do
        newChallenge = math.random(1,AllChallenge);
        task.wait()
    end

    Spawn:SetAttribute("Map",newMap)
    Spawn:SetAttribute("Difficulty",math.random(1,2))
    Spawn:SetAttribute("Challenge", newChallenge)

    local _,ChallengeName,Rewards,Desc = Challenges[newChallenge]()
    local function ShowRewards()
        UIManager:ClearFrame("ImageLabel",RewardsContent)

        --! Doesn't show gems
        -- local Gems = tempImage:Clone()
        -- Gems.Amount.Text = Rewards.Gems .. "x"
        -- Gems.Parent = RewardsContent
        -- Gems.Percentage.Visible = false
        -- Gems.Visible = true

        for name, RewardsTable in Rewards.PossibleRewards do
            if RewardsTable.Name ~= "Nothing" then
                -- warn(RewardsTable.Name)
                local Image = Items.Items[RewardsTable.Name] or Items.Materials[RewardsTable.Name]
                local PossibleReward, ImageLabel = UnitCreator.CreateItemIconForChallenge(RewardsTable.Name, RewardsTable)
                PossibleReward.UnitName.Text = RewardsTable.Percentage .. "%"
                PossibleReward.UnitName.Position = UDim2.new(.5,0,.1,0)
                PossibleReward.Size = UDim2.new(0.225, 0,0.77, 0)
                ImageLabel.Size = UDim2.new(1.5, 0,1.15, 0)
    
                PossibleReward.UnitName.Visible = true
                PossibleReward.Parent = RewardsContent
            end
        end
        
        Core.Visible = true
    end

    Core.Challenge.Text = ChallengeName
    Core.Map.Text = "Map: " .. newMap
    Core.Desc.Text = Desc

    ShowRewards()
end

function IntermissionService:KnitInit()

end

function IntermissionService:KnitStart()
    local PlayFolder = PlayParts.Play:GetChildren()
    local ChallengeFolder = PlayParts.Challenges:GetChildren()
    local playAreas = {PlayFolder, ChallengeFolder}
    ProfileService = Knit.GetService("ProfileService")

    for _, PlayTable in playAreas do
        for _,Spawn : Part in pairs(PlayTable) do
            Spawn.Touched:Connect(function(otherPart)
                local Humanoid = otherPart.Parent:FindFirstChild("Humanoid")
    
                if Humanoid then
                    local player = Players:GetPlayerFromCharacter(Humanoid.Parent)
                    if player then
                        IntermissionService.JoinSpawn(player, Spawn)
                    end
                end
            end)

            if Spawn.Parent.Name == "Challenges" then
                task.spawn(function()
                    IntermissionService:GetNewChallenge(Spawn)
                end)
            end
        end
    end
    
    local MaxChallengeDuration = 60 * 30
    local ChallengeDuration = MaxChallengeDuration

    --- Add MessangerService
    RunService.Heartbeat:Connect(function(deltaTime)
        for _, Spawns in pairs(ChallengeFolder) do
            local SurfaceGui = Spawns.SurfaceGui
            local Frame = SurfaceGui.Frame
            local Core = Frame.Core

            if ChallengeDuration <= 0 then
                IntermissionService:GetNewChallenge(Spawns)
                ChallengeDuration = MaxChallengeDuration
            end

            TimerModule:SetTimerInHeartbeat("Challenges", MaxChallengeDuration, ChallengeDuration, function(FormttedTime, Duration)
                Core.TimeLabel.Text = FormttedTime
            end, true)

            ChallengeDuration -= RunService.Heartbeat:Wait()
        end
    end)
end

return IntermissionService