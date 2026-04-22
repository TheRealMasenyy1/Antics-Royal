local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local afkController = Knit.CreateController{
    Name = "afkController",
}

local player = Players.LocalPlayer
--! TIME UNTIL PAYOUT: xxxs

function afkController:KnitInit()

end

function afkController:KnitStart() 
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    local afkFrame = Core:WaitForChild("AfkFrame")
    local TimeUntilPayout = afkFrame:WaitForChild("TimeUntilPayout")
    local ToLobby = afkFrame:WaitForChild("ToLobby")

    local AfkService = Knit.GetService("AfkService")
    local ProfileService = Knit.GetService("ProfileService")
    local PlayerService = Knit.GetService("PlayerService")

    repeat task.wait() until ProfileService:IsProfileReady(player):expect()

    local playerJoinData = AfkService:GetClientTime():expect()
    local TimeUntilPayoutNr = playerJoinData.CurrentTime

    afkFrame.Increment.Text = "Gain +" ..(10 * playerJoinData.Increment) .. ' ('.. playerJoinData.Increment..'x)'
    afkFrame.StartedWith.Text = 'Gems started with: ' .. ProfileService:Get("Gems"):expect()

    local function format(num)
        local formatted = string.format("%.2f", math.floor(num*100)/100)
        if string.find(formatted, ".00") then
            return string.sub(formatted, 1, -4)
        end
        return formatted
    end

    ToLobby.Text.Activated:Connect(function()
        PlayerService:TeleportPlayerToLobby()
    end)

    RunService.Heartbeat:Connect(function(deltaTime)
        if TimeUntilPayoutNr > 0 then
            TimeUntilPayoutNr -= RunService.Heartbeat:Wait()
            TimeUntilPayout.Text = "TIME UNTIL PAYOUT: ".. format(TimeUntilPayoutNr).."s" 
    
            if (TimeUntilPayoutNr) <= 0 then
                local AfkData = AfkService:UpdatePayout()
    
                AfkData:andThen(function(playerData)
                    TimeUntilPayoutNr = playerData.CurrentTime
                    afkFrame.Earned.Text = 'Gems earned: ' .. playerData.Gems
                end)
            end
        end
    end)
end

return afkController