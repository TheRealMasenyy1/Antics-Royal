local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Difficulties = require(ReplicatedStorage.Difficulties)
local Signals = require(ReplicatedStorage.Packages.Signal)

local MatchData = {}

local WorldService = Knit.CreateService {
    Name = "WorldService",
    MatchInfo = Signals.new(),
    PauseWave = Signals.new(),
    MultiplySpeed = Signals.new(),
    GiveMoney = Signals.new(),
    RequestSpeedIncrease = Signals.new(),
    AutoSkip = Signals.new(),

    Client = {
        AdminCommands = Knit.CreateSignal(),
    },
    Admins = {
        92260968
    }
}

local Gameplay = workspace.Gameplay

local PlayersHasLoaded = false

function WorldService:GetPathNodes()
    local Nodes = Gameplay.Path
    local PathNodes = {}

    table.insert(PathNodes,Gameplay.Start.CFrame)

    for i = 1, #Nodes:GetChildren() do
        table.insert(PathNodes, Nodes[i].CFrame)   
    end

    table.insert(PathNodes,Gameplay.End.CFrame)
    return PathNodes
end

function WorldService.Client:AdminCommands(player, Action : string, ...)
    -- --print(`Admin: {player.Name}, wishes to {Action}`)
    if table.find(WorldService.Admins,player.UserId) then
        if Action == "PauseWave" then
            WorldService.PauseWave:Fire(...)
        elseif Action == "ClearWave" then
            Gameplay.Mobs:ClearAllChildren()
        elseif Action == "MultiplySpeed" then
            WorldService.MultiplySpeed:Fire(...)
        elseif Action == "GiveMoney" then
            WorldService.GiveMoney:Fire(player,...)
        elseif Action == "AutoSkip" then
            WorldService.AutoSkip:Fire(player,...)
        end
    end
end

function WorldService:NextChapter()
    MatchData.Chapter += 1
end

function WorldService.Client:RequestTeleportToStart(player) 
    local SpawnLocation = workspace:FindFirstChild("SpawnLocation")

    if SpawnLocation then
        player.Character:PivotTo(SpawnLocation.CFrame * CFrame.new(0,5,0))
    end
end

function WorldService:RestoreWorld()
    local IngameMap = workspace:FindFirstChild("Map")
    local playerData = {
        Level = 12,
        IsLobbyLeader = true,
        Equipped = {
            --- Units
        },

        CurrentMatchInfo = {
            Name = "Leaf Village",
            Difficulty = "Normal",
            Challenges = 0,
            Chapter = 5
        }
    }
    if IngameMap then
        -- local StoredMap = ReplicatedStorage:FindFirstChild("Map")

        -- if StoredMap then
            -- IngameMap:Destroy()

            -- local newMap = StoredMap:Clone()
            -- newMap.Parent = workspace

            workspace.Values:ClearAllChildren()
            workspace.Gameplay.Mobs:ClearAllChildren()
            workspace.GameAssets.Units.Detectors:ClearAllChildren()

            for _,object in workspace.GameAssets.Units:GetChildren() do
                if not object:IsA("Folder") then
                    object:Destroy()
                end
            end

            print("starting bro")
            print(MatchData)

            WorldService:StartMatch(MatchData)
        -- else
        --     for _,players in game.Players do
        --         players:Kick("Could not find map to restore") -- actually just send to lobby
        --     end
        -- end

    end
end

function WorldService:GetLobbyLeader()
    -- Get Everyones data and check for the lobby leader
end

function WorldService:StartMatch(playerData)
    local Path = self:GetPathNodes()

    playerData.Path = Path
    WorldService.MatchInfo:Fire(playerData)
end

function WorldService:KnitInit()
end

function WorldService:KnitStart()
    local reservedServer = MemoryStoreService:GetHashMap("ReservedServers")
    local MatchStarted = false
    local data = {}

    local playerData = {
        Level = 12,
        IsLobbyLeader = true,
        Equipped = {
            --- Units
        },

        CurrentMatchInfo = {
            Name = "Leaf Village",
            Difficulty = "Normal",
            Chapter = 1,
            Challenges = 0
        }
    }

    local DifficultyConverter = {
        [1] = "Normal",
        [2] = "Hard",
        [3] = "Infinite"
    }

    --local MatchData = {}

	local function playerAdded(player)
		local joinData = player:GetJoinData()

		if joinData and not RunService:IsStudio() then
			local TeleportData = joinData.TeleportData
			local reservedCode = TeleportData.reservedCode
			local message = TeleportData.message
			
			data = reservedServer:GetAsync(reservedCode) or {}
			
			MatchData = {
				Name = data.Map,
				Difficulty = DifficultyConverter[data.Difficulty],
				Chapter = data.Chapter,
				Challenges = data.Challenge or 0
			}
		elseif RunService:IsStudio() then
			MatchData = playerData.CurrentMatchInfo
		end
        
        --! Changes the units transparency
        --[[
            local selection = game:GetService("Selection"):Get()[1]

            for _,Part in pairs (Selection:GetDescendants()) do
                if Part:IsA("Part") then
                    Part:SetAttribute("Destroyable", true)
                end
            end
        ]] 


        -- local function Visible(Unit : Model,Value : boolean)
        --     for _, object : BasePart in pairs(Unit:GetDescendants()) do
        --         local HeadUI = Unit.Head:FindFirstChild("MobStatusUI")
        --         local Face : Decal = Unit.Head:FindFirstChildWhichIsA("Decal")
        --         if object:IsA("BasePart") then
        --             object.Transparency = if Value then 0 else 1
        --         end

        --         if HeadUI then
        --             HeadUI.Enabled = Value
        --         end

        --         if Face then
        --             Face.Transparency = if Value then 0 else 1
        --         end
        --     end
        -- end
		
        -- Visible(selection, false)

        local leaderstats = Instance.new("IntValue")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player

        local Cash = Instance.new("IntValue")
        Cash.Name = "Cash"
        Cash.Parent = leaderstats
        Cash.Value = 0

        local PlacementAmount = Instance.new("IntValue")
        PlacementAmount.Name = "PlacementAmount"
        PlacementAmount.Parent = player
        PlacementAmount.Value = 0 

        local Damage = Instance.new("IntValue")
        Damage.Name = "Damage"
        Damage.Parent = leaderstats
        Damage.Value = 0

        -- Wait until player data has been loaded
        player.CharacterAdded:Connect(function()

        end)
    end

    for _,player in Players:GetChildren() do
        playerAdded(player)
    end

    Players.PlayerAdded:Connect(playerAdded)

	repeat task.wait() until next(MatchData) ~= nil 
	
	--for n,v in MatchData do
	--	print(n,v)
	--end
	
    task.delay(2, function()
        if RunService:IsStudio() then
                WorldService:StartMatch(playerData.CurrentMatchInfo)
        else
            WorldService:StartMatch(MatchData)
        end
    end)

    --print("We got the server working....")
end

return WorldService