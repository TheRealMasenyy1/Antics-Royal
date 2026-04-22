local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ServerBuildManager = require(script.Parent.ServerBuildManager)
local TestsFolder = script.Parent.tests
local TestEz = require(ReplicatedStorage.Shared.Utility.TestEz)
local PlaceIds = require(ReplicatedStorage.Shared.PlaceIds)
local CmdrModule = ReplicatedStorage.Shared.Utility.Cmdr
local Cmdr = require(CmdrModule)

local function GetPlaceId(placeId)
    local Table = PlaceIds[1]

    for id, folder in pairs(Table) do
        if id == placeId then
            return folder, id
        end
    end

    return nil, nil
end

local FolderToLoad = PlaceIds[game.PlaceId] or GetPlaceId(game.PlaceId)


Cmdr:RegisterDefaultCommands() -- Sets command line
Cmdr:RegisterCommandsIn(ServerScriptService.CmdrCommands)
Cmdr:RegisterHooksIn(CmdrModule.CustomHooks)

task.spawn(function()
    TestEz.TestBootstrap:run({TestsFolder})
end)

if FolderToLoad == "Gameplay" then
    ServerBuildManager:Init()
end

print(`Loading {FolderToLoad} for this place: {game.PlaceId}`)

Knit.AddServicesDeep(script.Parent.WorldServices.GlobalServices)
Knit.AddServicesDeep(script.Parent.WorldServices[FolderToLoad])
Knit.Start()