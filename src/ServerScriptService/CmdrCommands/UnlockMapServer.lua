local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

return function (context, forPlayer,  Map : any, chapter : number)
    local PlayerService = Knit.GetService("PlayerService")

    if forPlayer.Character and forPlayer.Character:FindFirstChild("HumanoidRootPart") then
        chapter = chapter or 1
        PlayerService:UnlockMap(forPlayer, Map.Name, chapter)
        return "Map unlocked: " .. Map.Name .. " chapter: " .. chapter
    elseif not forPlayer then
        return "Invalid player"
    end

    return "Could not get the exp"
end 
