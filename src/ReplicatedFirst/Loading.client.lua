local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ContentProvider = game:GetService("ContentProvider")
local TeleportService = game:GetService("TeleportService")
local LoadGui = ReplicatedFirst:WaitForChild("LoadGui")
local PlaceIds = {
    --- Lobby ---
    [114746697858159] = "Lobby",

    --- Leaf Village ---
    [1] = { 
        [70814776537237] = "Gameplay",
        [72076408034151] = "70814776537237",
        [108829333865646] = "Gameplay",
        [80904234996369] = "Gameplay",
    },
}

local function GetPlaceId(placeId)
    local Table = PlaceIds[1]

    for id, folder in pairs(Table) do
        if id == placeId then
            return folder, id
        end
    end

    return nil, nil
end

warn("LOADING", game.PlaceId)

local PlaceId = GetPlaceId(game.PlaceId)
LoadGui.Parent = Players.LocalPlayer.PlayerGui

LoadGui[PlaceId].Visible = true
--TeleportService:SetTeleportGui(ReplicatedStorage.LoadGui)

ReplicatedFirst:RemoveDefaultLoadingScreen()

local children = 0

repeat task.wait(2) children = #ReplicatedStorage:GetChildren() until children > 0

repeat task.wait() until #ReplicatedStorage.Assets.Viewports:GetChildren() > 0

local Animations = ReplicatedStorage.Assets.Animations:GetDescendants()

ContentProvider:PreloadAsync(Animations)

LoadGui[PlaceId].Visible = false