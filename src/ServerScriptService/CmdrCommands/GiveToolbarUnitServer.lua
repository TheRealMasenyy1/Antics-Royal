local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

return function (context, forPlayer, Unit : any, UnitLevel : number, Position : number)
    local PlayerService = Knit.GetService("PlayerService")

    if forPlayer.Character then
        local UnitName = Unit.Name
        Position = Position or nil
        PlayerService:GiveUnitToolbarUnit(forPlayer, UnitName, UnitLevel, nil, Position)
        return  forPlayer.Name .. " Unit given " .. UnitName
    elseif not forPlayer then
        return "Invalid player"
    end

    return "Could not find the unit"
end 
