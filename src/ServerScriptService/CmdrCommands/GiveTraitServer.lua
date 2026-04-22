local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

return function (context, forPlayer, traitAmount : number)
    local ProfileService = Knit.GetService("ProfileService")

    if forPlayer.Character and forPlayer.Character:FindFirstChild("HumanoidRootPart") then
        print("Giving trait amount: ", traitAmount, " -> ", forPlayer.Name)
        ProfileService:Update(forPlayer,"TraitGems", function(Amount)
            return Amount + traitAmount
        end)

        return forPlayer.Name.. " was given " .. traitAmount
    elseif not forPlayer then
        return "Invalid player"
    end

    return "Could not get the exp"
end 
