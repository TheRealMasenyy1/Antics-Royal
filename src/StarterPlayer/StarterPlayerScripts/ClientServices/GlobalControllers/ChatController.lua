local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local ChatController = Knit.CreateController {
    Name = "ChatController",
}

local titles = {
    {level = 1, title = "V.I.P"},
    {level = 3, title = "Supporter"},
    {level = 5, title = "Follower"},
    {level = 7, title = "Hype Master"},
    {level = 9, title = "Backstage Pass Holder"},
    {level = 11, title = "VIP"},
    {level = 13, title = "Superfan"},
    {level = 15, title = "Influencer"},
    {level = 17, title = "Headliner"},
    {level = 19, title = "Celebrity"}
}

local titlesColor = {
    {level = 1, title = "#FFE000"},
    {level = 3, title = "#FFFFFF"},
    {level = 5, title = "#58F9D2"},
    {level = 7, title = "#5AC8FF"},
    {level = 9, title = "#01A0F0"},
    {level = 11, title = "#FFF000"},
    {level = 13, title = "#FFB200A"},
    {level = 15, title = "#9300FF"},
    {level = 17, title = "#1BFF00"},
    {level = 19, title = "#FF00BDA"}
}

local function generateChatTag(Text : string, colour : Color3)
    return '<font color="' .. colour .. '" size="17" face="FredokaOne">' .. Text .. '</font>'
end

local function getTitleForLevel(level)
    -- Iterate through the titles table
    for i = #titles, 1, -1 do
        if level >= titles[i].level then
            return titles[i].title
        end
    end
    return "Fan" -- Default title if level doesn't match any criteria
end

local function getColorForLevel(level)
    -- Iterate through the titles table
    for i = #titlesColor, 1, -1 do
        if level >= titlesColor[i].level then
            return titlesColor[i].title
        end
    end
    return titlesColor[1].title -- Default title if level doesn't match any criteria
end

-- local function onPlayerPurchase(playerName, itemName)
--     -- Define the message that will be broadcasted to chat
--     local Channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem")
--     local message = "<u>" .. generateChatTag(playerName, "#3DFF69") .. "</u> just bought <u>" .. generateChatTag(itemName, "#3DFF69") .. "</u>!"
    
--     -- Broadcast the system message to all players
--     Channel:DisplaySystemMessage(message) 
--     -- TextChatService:BroadcastSystemMessage(message)
-- end

function ChatController:KnitInit()
end

function ChatController:KnitStart()
    TextChatService.OnIncomingMessage = function(message : TextChatMessage)
        local Properties = Instance.new("TextChatMessageProperties")
        Properties.Text = "<font size='17' face='FredokaOne'>" .. message.Text .. "</font>"

        if message.TextSource then
            local Player = Players:GetPlayerByUserId(message.TextSource.UserId)
            local IsVIP = Player:FindFirstChild("IsVIP")

            if IsVIP then
                local Title = getTitleForLevel(1)
                local Color = getColorForLevel(1)

                Properties.PrefixText = generateChatTag("[ ".. Title .." ] ".. Player.Name .. ": ", Color)
            else
                Properties.PrefixText = generateChatTag(Player.Name .. ": ", "#1AE7A5")
            end
        end
        return Properties
    end
end

return ChatController