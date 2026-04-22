local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

return function (context, forPlayer, expAmount : number)
    local PlayerService = Knit.GetService("PlayerService")
    
    if forPlayer.Character and forPlayer.Character:FindFirstChild("HumanoidRootPart") then
        print("Giving exp amount: ", expAmount, " -> ", forPlayer.Name)
        PlayerService:GiveBattlepassExp(forPlayer, expAmount)
        return forPlayer.Name.." was given "..expAmount
    elseif not forPlayer then
        return "Invalid player"
    end

    return "Could not get the exp"
end 
