local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AfkService = Knit.CreateService{
    Name = "AfkService"
}

local PlayerService;
local ProfileService;
local Minute = 60
local Defualt_TimeUntilPayout = 4 * Minute 
local Defualt_Gems = 10
local PlayerTable : {[string] : {CurrentTime : number, JoinTime : number, Gems : number, Increment : number}} = {}

function AfkService:KnitInit()

end

function AfkService.Client:GetClientTime(player)
    if PlayerTable[player.Name] then
        return PlayerTable[player.Name]
    end 

    return nil
end

function AfkService.Client:UpdatePayout(player)
    if PlayerTable[player.Name] and (os.clock() - PlayerTable[player.Name].JoinTime) > Defualt_TimeUntilPayout then
        local reward = Defualt_Gems * PlayerTable[player.Name].Increment
        PlayerService:GiveGems(player, reward)

        PlayerTable[player.Name].CurrentTime = Defualt_TimeUntilPayout
        PlayerTable[player.Name].Gems += reward
        PlayerTable[player.Name].JoinTime = os.clock()
    else
        warn("Enough time hasn't passed for you to collect reward: ", (os.clock() - PlayerTable[player.Name].JoinTime))
    end 

    return PlayerTable[player.Name]
end

function AfkService:KnitStart()
    PlayerService = Knit.GetService("PlayerService")
    ProfileService = Knit.GetService("ProfileService")   

    local function IncreaseIncrement(player)
        local IsVip = PlayerService:GetFlag(player,"IsVip")
        local IsPremium = PlayerService:GetFlag(player,"IsPremium") 
        local Increment = 1

        if IsVip then
            Increment += 1
        end

        if IsPremium then
            Increment += .5
        end

        return Increment
    end

    game.Players.PlayerAdded:Connect(function(player)
        repeat task.wait() until ProfileService:IsProfileReady(player)
        PlayerTable[player.Name] = {
            CurrentTime = Defualt_TimeUntilPayout,
            JoinTime = os.clock(), 
            Gems = 0,
            Increment = IncreaseIncrement(player),
        } --! Logs players join time and adds him to the Player table
        warn("player added to the table")
    end)
end

return AfkService