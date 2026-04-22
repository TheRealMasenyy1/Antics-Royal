local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Zones = require(ReplicatedStorage.Shared.Zone)

local LobbyService = Knit.CreateService {
    Name = "LobbyService",
    Client = {
        FirstTimeJoined = Knit.CreateSignal()
    }
}

local GlobalDataStoreService;
local PlayerService;
local InventoryService;
local ProfileService;

LobbyService.Client.BoostEffect = Knit.CreateSignal()

function LobbyService:TeleportToPrivateServer(players, PLACE)
    PLACE = tonumber(PLACE)
    
    if not PLACE then
        warn("Invalid PLACE ID:", PLACE)
        return
    end

    if type(players) ~= "table" or #players == 0 then
        warn("Invalid players table:", players)
        return
    end
    
    local success, privateServerCode = pcall(function()
        return TeleportService:ReserveServer(PLACE)
    end)
    
    if success and privateServerCode then
        local successTeleport, err = pcall(function()
            TeleportService:TeleportToPrivateServer(PLACE, privateServerCode, players)
        end)

        if not successTeleport then
            warn("Teleport failed:", err)
        end
    else
        warn("Failed to reserve private server.", "Success:", success, "Code:", privateServerCode, "Place:", PLACE)
    end
end

function LobbyService.Client:DialogMode(player, Value : boolean,  Target)
    local Humanoid = player.Character.Humanoid

    if Value == true then
        Humanoid.WalkSpeed = 0
        if Target then
            local CharacterPivot = player.Character:GetPivot()
            player.Character:PivotTo(CFrame.new(CharacterPivot.Position, Target))
        end
    else
        Humanoid.WalkSpeed = 20
    end
end

function LobbyService.Client:PickFirstUnit(player, Unit)
    local Tutorial = PlayerService:GetFlag(player, "Tutorial")

    if Tutorial then --! exploitable
        local newUnit = GlobalDataStoreService:CreateUnit(Unit, false)

        ProfileService:Update(player,"Inventory", function(Inventory)
            table.insert(Inventory.Units,newUnit)
            return Inventory
        end)

        ProfileService:Update(player,"Flags", function(Flags)
            Flags.Tutorial = false
            return Flags
        end)

        InventoryService.Client:EquipUnit(player, newUnit.Hash)
    end
end

function LobbyService:KnitInit()
    
end

function LobbyService:KnitStart()
    local newZone = Zones.new(workspace.SpeedBooster)
    local Storage = {}
    local Duration = 4

    GlobalDataStoreService = Knit.GetService("GlobalDatastoreService")
    PlayerService = Knit.GetService("PlayerService")
    InventoryService = Knit.GetService("InventoryService")
    ProfileService = Knit.GetService("ProfileService")
    
    newZone.playerEntered:Connect(function(player)
        local findPos = table.find(Storage, player)
        if not findPos then
            table.insert(Storage, player)
            player.Character.Humanoid.WalkSpeed = 45
            player.Character:SetAttribute("IsBoosted", true)
            LobbyService.Client.BoostEffect:Fire(player, true)
        end
        
    end)

    newZone.playerExited:Connect(function(player)
        local newPos = table.find(Storage, player)
        if newPos then
            table.remove(Storage, newPos)
            player.Character.Humanoid.WalkSpeed = 20
            player.Character:SetAttribute("IsBoosted", false)
            LobbyService.Client.BoostEffect:Fire(player, false)
        end
    end)
end

return LobbyService