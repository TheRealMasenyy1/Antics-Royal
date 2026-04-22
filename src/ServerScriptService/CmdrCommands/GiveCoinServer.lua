local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

return function (context, forPlayer, Amount : number)
    local PlayerService = Knit.GetService("PlayerService")

    if forPlayer.Character and forPlayer.Character:FindFirstChild("HumanoidRootPart") then
        PlayerService:GiveCoin(forPlayer, Amount)
        return  forPlayer.Name .. " coin given " .. Amount
    elseif not forPlayer then
        return "Invalid player"
    end

    return "Could not get the exp"
end 
