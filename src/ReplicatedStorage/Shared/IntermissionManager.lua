local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local IntermissionManager = {}

export type MapInfo = {
    Map : string,
    FriendsOnly : boolean,
    Chapter : number;
    Difficulty : number,
    Challenge : number;
}

function IntermissionManager:IsFriends(player : Player , Host) -- Checks if the player is friend in Friends Only
    return player:IsFriendsWith(Host.UserId)
end

function IntermissionManager:GetHostSpawn(Host)
    local PlayParts : Folder = workspace.PlayParts
    local Descendant = PlayParts:GetDescendants()

    for _, Spawn in pairs(Descendant) do
        if Spawn:IsA("BasePart") then
            local SpawnHost = Spawn:GetAttribute("Host")
            if SpawnHost == Host.Name then
                return Spawn
            end
        end
    end

    return nil
end

function IntermissionManager:Visible(Spawn, Value : boolean)
    for _,SurfaceGui : SurfaceGui in pairs(Spawn) do
        if SurfaceGui:IsA("ScreenGui") then
            local Frame = SurfaceGui.Frame

            if Value then
                Frame.Occupied.Core.Visible = true
            else
                Frame.Occupied.Core.Visible = Value
                Frame.Unoccupied.Text.Visible = not Value
            end
        end
    end
end

function IntermissionManager:CreateLobby(Leader : Player, Spawn : Part, MapData : MapInfo)
    local playerTable = {}
    local SurfaceGui = Spawn.SurfaceGui
    local Frame = SurfaceGui.Frame


    if MapData.Challenge == 0 then
        local Unoccupied = Frame.Unoccupied
        local Occupied = Frame.Occupied
    
        local Core = Occupied.Core 
        local Convert = {
            [1] = "Normal",
            [2] = "Hard",
        }
        local DifficultyColor = {
            [1] = Color3.fromRGB(34, 255, 0),
            [2] = Color3.fromRGB(255),
        }

        Spawn:SetAttribute("FriendsOnly", MapData.FriendsOnly)
    
        Unoccupied.Text.Visible = false
        Core.Visible = true
    
        Core.Host.Text = "Host: " .. Leader.Name
        Core.Map.Text = "Map: " .. MapData.Map
        Core.Difficulty.Text = "Difficulty: " .. Convert[MapData.Difficulty]
        Core.Difficulty.TextColor3 = DifficultyColor[MapData.Difficulty]
        Core.Chapter.Text = "Chapter: " .. MapData.Chapter
    end

    return Leader
end

function IntermissionManager:ResetSpawn(Spawn)
    local SurfaceGui = Spawn.SurfaceGui

    if not Spawn:GetAttribute("Challenge") then
        local Frame = SurfaceGui.Frame
        local Unoccupied = Frame.Unoccupied
        local Occupied = Frame.Occupied
        
        Unoccupied.Text.Visible = true
        Occupied.Core.Visible = false
    end

    Spawn:SetAttribute("FriendsOnly", false)
    Spawn:SetAttribute("Host","")
    Spawn:SetAttribute("MapSelected","")
end

function IntermissionManager:EnterSpawn(player, Spawn, HasHost)
    local IntermissionService = Knit.GetService("IntermissionService")
    local HumanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local SpawnLocation = Spawn.SpawnLocation

    if not HasHost then
        --- Send Client Request to show matchFrame
        if HumanoidRootPart then
            local LobbyType = Spawn.Parent.Name
            local ChallengeId = Spawn:GetAttribute("Challenge")
            IntermissionService.Client.CreateLobby:Fire(player, LobbyType, ChallengeId)

            HumanoidRootPart.CFrame = SpawnLocation.CFrame * CFrame.new(math.random(-SpawnLocation.Size.X/2,SpawnLocation.Size.X/2),1,math.random(-SpawnLocation.Size.Z/2,SpawnLocation.Size.Z/2))       
            Spawn:SetAttribute("Host", player.Name)
        end
    else
        IntermissionService.Client.JoinedLobby:Fire(player) 
        HumanoidRootPart.CFrame = SpawnLocation.CFrame * CFrame.new(math.random(-SpawnLocation.Size.X/2,SpawnLocation.Size.X/2),1,math.random(-SpawnLocation.Size.Z/2,SpawnLocation.Size.Z/2))       
    end
end

return IntermissionManager