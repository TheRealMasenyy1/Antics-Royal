local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local PlaceIds = require(ReplicatedStorage.Shared.PlaceIds)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))

local function GetPlaceId(placeId)
    local Table = PlaceIds[1]

    for id, folder in pairs(Table) do
        if id == placeId then
            return folder, id
        end
    end

    return nil, nil
end

Cmdr:SetActivationKeys({ Enum.KeyCode.Backquote }) -- Enum.KeyCode.Delete

local FolderToLoad = PlaceIds[game.PlaceId] or GetPlaceId(game.PlaceId)

Knit.AddControllersDeep(script.Parent.ClientServices.GlobalControllers)
Knit.AddControllersDeep(script.Parent.ClientServices[FolderToLoad])
Knit.Start()