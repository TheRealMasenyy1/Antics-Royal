local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Entity = require(ReplicatedStorage.Shared.Entity)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)

local InventoryService = Knit.CreateService {
    Name = "InventoryService",
    Client = {
        UnitEquipped = Knit.CreateSignal(),
        PlayAnimation = Knit.CreateSignal(),
        StopAnimation = Knit.CreateSignal()
    }
}

local ProfileService;
local PlayerService;
local InventoryController;

local SpaceBetweenPets = 2.5

local function GetUnit(UnitsData, UnitHash : string)
    for pos,UnitData in UnitsData do
        if UnitData.Hash == UnitHash then
            return UnitData,pos
        end
    end

    return nil
end

local function GetUnitByName(UnitsData, UnitName : string)
    for pos,UnitData in UnitsData do
        if UnitData.Unit == UnitName then
            return UnitData,pos
        end
    end

    return nil
end

local function AddToCollisionGroup(Model : Model, GroupName)
    for _,part : BasePart in pairs(Model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = GroupName
            part.Massless = true
        end
    end
end

local Debug = false
local DefualtSpeed = 20
local SpawnCFrame = {
    [1] = CFrame.new(0,0,4.5),
    [2] = CFrame.new((SpaceBetweenPets/2) * 2,0,3.5),
    [3] = CFrame.new(-(SpaceBetweenPets/2) * 2,0,3.5),
    [4] = CFrame.new((SpaceBetweenPets/2) * 3.5,0,0),
    [5] = CFrame.new(-(SpaceBetweenPets/2) * 3.5,0,0),
    [6] = CFrame.new(0,0,-2.5),
}

function NecessaryForUnit(player,Unit, Pos)
    -- local HumanoidRootPart = Unit:FindFirstChild("HumanoidRootPart") or Unit:FindFirstChild("RootPart") 
    local playerToUnitAttachment = Instance.new("Attachment")
    playerToUnitAttachment.Name = "playerToUnitAttachment" .. Pos
    playerToUnitAttachment.CFrame = SpawnCFrame[Pos]--CFrame.new(SpawnCFrame[Pos].Position.X,1,5)
    playerToUnitAttachment.Parent = player.Character.HumanoidRootPart
    playerToUnitAttachment.Visible = Debug 

    local UnitToGround = Instance.new("Attachment")
    UnitToGround.Name = "UnitToGround" .. Pos
    UnitToGround.WorldCFrame = Unit.PrimaryPart.CFrame * CFrame.new(0,1.75,0) -- Unit.PrimaryPart.CFrame *
    UnitToGround.Parent =  player.Character.HumanoidRootPart --Unit.PrimaryPart
    UnitToGround.Visible = Debug 

    local UnitAttachment = Instance.new("Attachment")
    UnitAttachment.Name = "UnitAttachment" .. Pos
    UnitAttachment.CFrame = CFrame.new(0,-1.95,0)
    UnitAttachment.Parent = Unit.PrimaryPart
    UnitAttachment.Visible = Debug

    local AlignPosition = Instance.new("AlignPosition")
    AlignPosition.Name = "AlignPosition"
    AlignPosition.Responsiveness = 25
    AlignPosition.MaxVelocity = math.huge
    AlignPosition.MaxForce = math.huge
    AlignPosition.Attachment0 = UnitAttachment
    AlignPosition.Attachment1 = playerToUnitAttachment
    AlignPosition.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    AlignPosition.MaxAxesForce = Vector3.new(math.huge,0,math.huge)
    AlignPosition.Parent = Unit.PrimaryPart

    task.delay(2,function()
        AlignPosition.ReactionForceEnabled = true
    end)

    local GroundPosition = Instance.new("AlignPosition")
    GroundPosition.Name = "GroundPosition"
    GroundPosition.Attachment0 = UnitAttachment
    GroundPosition.Attachment1 = UnitToGround
    GroundPosition.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    GroundPosition.MaxAxesForce = Vector3.new(0,math.huge,0)
    GroundPosition.Responsiveness = 150
    GroundPosition.Parent = Unit.PrimaryPart

    local AlignOrientation = Instance.new("AlignOrientation")
    -- AlignOrientation.MaxAngularVelocity = 35
    AlignOrientation.Name = "AlignOrientation"
    AlignOrientation.Responsiveness = 50
    AlignOrientation.MaxTorque = 25_000
    AlignOrientation.Attachment0 = UnitAttachment
    AlignOrientation.Attachment1 =  player.Character.HumanoidRootPart.RootAttachment
    AlignOrientation.Parent = Unit.PrimaryPart

    return UnitToGround, playerToUnitAttachment, AlignPosition, {AlignOrientation, AlignPosition, GroundPosition, UnitAttachment,playerToUnitAttachment}
end

local function CheckIfPlaying(character, Name)
    local AnimationController = character:FindFirstChild("Humanoid") or character:FindFirstChild("AnimationController")
    local Animator = AnimationController.Animator

    for _,animation in Animator:GetPlayingAnimationTracks() do
        if animation.Name == Name then
            return true
        end
    end 

    return false
end

function PlayAnimation(character, Name : string, AdjustSpeed : number)
    local findAnimation = ReplicatedStorage.Assets.Animations:FindFirstChild(character.Name..Name, true) or ReplicatedStorage.Assets.Animations:FindFirstChild(Name, true) 
    local IsPlaying = CheckIfPlaying(character, findAnimation.Name)
    AdjustSpeed = AdjustSpeed or 1

    if findAnimation and not IsPlaying then
        local AnimationController = character:FindFirstChild("Humanoid") or character:FindFirstChild("AnimationController")
        local Animation : AnimationTrack = AnimationController.Animator:LoadAnimation(findAnimation)
        Animation:Play()
        Animation:AdjustSpeed(AdjustSpeed)
    end
end

function StopAnimation(character, Name : string)
    local AnimationController = character:FindFirstChild("Humanoid") or character:FindFirstChild("AnimationController")
    local Animator = AnimationController.Animator

    if Animator then
        for _,animation in Animator:GetPlayingAnimationTracks() do
            if (animation.Name == Name) or (animation.Name == character.Name..Name)  then
                animation:Stop()
            end
        end 
    end
end

function TrackOwnerMovementChange(player, Unit) -- Might need to change
    local playerHumanoid : Humanoid = player.Character.Humanoid
    local WalkAnimation = "Walk"

    if playerHumanoid.MoveDirection.Magnitude <= 0 then
        task.delay(.1, function()
            StopAnimation(Unit,"Run")
            StopAnimation(Unit,WalkAnimation)
            PlayAnimation(Unit,Unit.Name.."Idle")
        end)
    elseif playerHumanoid.WalkSpeed <= DefualtSpeed and playerHumanoid.MoveDirection.Magnitude > 0 then
        StopAnimation(Unit,"Run")
        PlayAnimation(Unit,WalkAnimation)
    elseif playerHumanoid.WalkSpeed > DefualtSpeed and playerHumanoid.MoveDirection.Magnitude > 0 then
        StopAnimation(Unit,WalkAnimation)
        PlayAnimation(Unit,"Run")
    end
end


function createTracePart(player, CFRAME)
    local part = Instance.new("Part")
    part.CFrame = CFRAME
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(1,1,1)
    part.Parent = player.Character

    return part
end

function SpawnPetUnit(player, UnitData, Pos)
    local Unit = ReplicatedStorage.Units:FindFirstChild(UnitData.Unit)

    local SpawnCFrameToHumanoid = {
        [1] = CFrame.new(0,0,6.5),
        [2] = CFrame.new((SpaceBetweenPets/2) * 2,0,6.5),
        [3] = CFrame.new(-(SpaceBetweenPets/2) * 3,0,6.5),
        [4] = CFrame.new((SpaceBetweenPets/2) * 4,0,6.5),
        [5] = CFrame.new(-(SpaceBetweenPets/2) * 5,0,6.5),
        [6] = CFrame.new(0,0,-6.5),
    }

    if Unit then
        warn(UnitData.Unit, Pos)
        local Unitmaid = Maid.new()
        local newUnit : Model = Unit:Clone()
        newUnit.Name = UnitData.Unit
        newUnit:PivotTo(player.Character.HumanoidRootPart.CFrame * SpawnCFrame[Pos])
        newUnit.PrimaryPart.Anchored = false
        newUnit:ScaleTo(.65)

        local UnitToGround : Attachment, playerToUnitAttachment : AlignPosition, AlignPosition, FullAttachmentTable = NecessaryForUnit(player, newUnit, Pos)
        local tracepart = createTracePart(player,player.Character.HumanoidRootPart.CFrame * SpawnCFrame[Pos])
        local tracepartForPlayer = createTracePart(player,player.Character.HumanoidRootPart.CFrame * SpawnCFrame[Pos])
        newUnit.Parent = player.Character
        
        -- tracepartForPlayer.Transparency = 0
        AddToCollisionGroup(newUnit, "PetUnits")
        
        InventoryService.Client.PlayAnimation:FireAll(newUnit,newUnit.Name.."Idle")
        
        UnitToGround.Parent = tracepart
        UnitToGround.WorldCFrame = newUnit.PrimaryPart.CFrame

        task.spawn(function()
            local playerHumanoid : Humanoid = player.Character.Humanoid

            Unitmaid:GiveTask(playerHumanoid.Changed:Connect(function(name)
                TrackOwnerMovementChange(player, newUnit)
            end))
            
            local raycastParams  = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Include
            raycastParams.FilterDescendantsInstances = { workspace.Map }
            raycastParams.IgnoreWater = true
            
            Unitmaid:GiveTask(RunService.Heartbeat:Connect(function()
                if player.Character == nil or #newUnit:GetChildren() <= 0 then tracepart:Destroy() Unitmaid:Destroy() end

                local Position : Vector3 = Entity.KeepGroundLevel(newUnit.PrimaryPart.CFrame * CFrame.new(0,5,0), Vector3.new(0,-150,0), raycastParams)

                if not player then
                    tracepart:Destroy()
                    Unitmaid:Destroy()
                end

                if player.Character ~= nil and (not player.Character:FindFirstChild(UnitData.Unit)) then
                    for _,Object in ipairs(FullAttachmentTable) do
                        Object:Destroy()
                    end
                    tracepart:Destroy()
                    Unitmaid:Destroy()
                end

                if Position and Position.Magnitude > 0 then
                    local UnitPos = Unit.PrimaryPart.CFrame.Position
                    -- playerToUnitAttachment.WorldCFrame = CFrame.new(playerToUnitAttachment.WorldCFrame.Position.X,UnitToGround.WorldCFrame.Position.Y,playerToUnitAttachment.WorldCFrame.Position.Z) --playerToUnitAttachment.WorldCFrame:Lerp(player.Character.HumanoidRootPart.CFrame * relativecframe, speed)
                    UnitToGround.WorldCFrame = CFrame.new(Position, player.Character.HumanoidRootPart.CFrame.Position) --.Position = Vector3.new(0,Position.Y,0)
                end
            end))          
        end)

        -- tracepartForPlayer:SetNetworkOwner(nil)
        newUnit.PrimaryPart:SetNetworkOwner(nil)
    end
end

local function deepSearch(t, key_to_find)
    for key, value in pairs(t) do
        if value == key_to_find then -- value == key_to_find or
            return key, t, value
        end
        if typeof(value) == "table" then -- Original function always returned results of deepSearch here, but we should not return unless it is not nil.
            local a, b, c = deepSearch(value, key_to_find)
            if a then return a, b, c end
        end	
    end
    return nil
end

function InventoryService.Client:FeedUnit(player, UnitHash, FoodForUnit)
    local PlayerItems = PlayerService:GetItem(player,"Items")
    local UnitWasFeed = false

    local function CheckExpAmount()
        local AmountExpGiven= 0
        local AmountInInventory = #PlayerItems

        print(FoodForUnit, PlayerItems)
        for pos,Items in pairs(FoodForUnit) do
            local _,ActualItem = deepSearch(PlayerItems, Items.Name)
            if ActualItem.Name == Items.Name and ActualItem.Amount >= Items.Amount then
                AmountExpGiven += (Items.Exp * Items.Amount)
                ActualItem.Amount -= Items.Amount

                if ActualItem.Amount <= 0 then
                    PlayerService:GiveItem(player,"Items",Items.Name, 0)
                end
                UnitWasFeed = true
            end
        end

        return AmountExpGiven
    end

    local ExpToUnit = CheckExpAmount()
    PlayerService:GiveUnitExp(player,UnitHash, ExpToUnit)

    ProfileService:Update(player,"Inventory",function(Inventory)
        Inventory.Items = PlayerItems       
        warn("The new items saved: ", PlayerItems)
        return Inventory
    end)

    return UnitWasFeed
end

function InventoryService.Client:UnequipUnit(player, UnitName : string) -- UnitName is actually the units Hash
    local Equipped = ProfileService:Get(player,"Equipped")
    local AmountEquipped = #Equipped
    local IsUnitEquipped,Pos = GetUnit(Equipped,UnitName)

    if IsUnitEquipped then
        local UnitInsideCharacter = player.Character:FindFirstChild(IsUnitEquipped.Unit)

        --- Just Unequip
        if UnitInsideCharacter then
            UnitInsideCharacter:Destroy()
        end

        ProfileService:Update(player,"Equipped",function(EquipTable)
            table.remove(EquipTable,Pos)
            InventoryService.Client.UnitEquipped:Fire(player, EquipTable)
            return EquipTable
        end)

        return true
    else
        print("Unit is not Equipped: ", UnitName)
    end
end

function InventoryService.Client:SavePreset(player, Slot)
    local Equipped = ProfileService:Get(player,"Equipped")
    local Presets = ProfileService:Get(player,"Presets")

    if Presets[Slot] then
        local newEquipped = table.clone(Equipped)
        Presets[Slot].Units = newEquipped

        ProfileService:Update(player,"Presets",function()
            print("Preset Save: ", newEquipped)
            return Presets
        end)

        return Presets[Slot] 
    end
end

function InventoryService.Client:EquipPreset(player, Slot)
    local Presets = ProfileService:Get(player,"Presets")

    if Presets[Slot] then
        for i = 1,#Presets[Slot].Units do
            InventoryService.Client:EquipUnit(player, Presets[Slot].Units[i].Hash)
            task.wait()
        end

        print("The  new  Equipped: ", Presets[Slot])
        -- return Presets[Slot] 
    end
end

function InventoryService.Client:ClearPreset(player, Slot)
    local Equipped = ProfileService:Get(player,"Equipped")
    local Presets = ProfileService:Get(player,"Presets")

    if Presets[Slot] then
        Presets[Slot].Units = {}

        ProfileService:Update(player,"Presets",function()
            return Presets
        end)

        return Presets[Slot] 
    end
end

function InventoryService.Client:EquipUnit(player, UnitHash : string)
    local Inventory = ProfileService:Get(player,"Inventory")
    local Equipped = ProfileService:Get(player,"Equipped")
    local Level = ProfileService:Get(player,"Level")
    local UnitsData = Inventory.Units
    local Unit, Position = GetUnit(UnitsData, UnitHash)
    local LevelRequirement = {
        [1] = 1;
        [2] = 1;
        [3] = 10;
        [4] = 15;
        [5] = 20;
        [6] = 25;
    }

    if Unit then
        local AmountEquipped = #Equipped
        local IsUnitEquipped = GetUnitByName(Equipped, Unit.Unit)
        if AmountEquipped < 6 and Level >= LevelRequirement[AmountEquipped + 1] and not IsUnitEquipped then
            --- Just equip
            ProfileService:Update(player,"Equipped",function(EquipTable)
                table.insert(EquipTable, Unit)
                InventoryService.Client.UnitEquipped:Fire(player, EquipTable)
                return EquipTable
            end)

            SpawnPetUnit(player, Unit, AmountEquipped + 1)
            return true
        elseif IsUnitEquipped then
            return false, "Similar Unit equipped", "You cannot equip an identical unit"
        elseif Level < LevelRequirement[AmountEquipped + 1] then
            print("You don't have extra slot")

            return false, "NoSlotAvailable","Slot unavailable! Unequip a unit."
        else
            print("Unit is already Equipped: ", UnitHash)
            --- Tell player to unequip one 
        end
    end
end

local function LoadEquippedUnits(player)
    repeat task.wait() until ProfileService:IsProfileReady(player)
    task.wait(3)
    local Equipped = ProfileService:Get(player,"Equipped")

    print("Equipped: ", Equipped)

    for Pos,UnitData in Equipped do
        SpawnPetUnit(player,UnitData, Pos)
    end
end 

function InventoryService:KnitInit()

end

function InventoryService:KnitStart()
    ProfileService = Knit.GetService("ProfileService")
    PlayerService = Knit.GetService("PlayerService")

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            LoadEquippedUnits(player)
        end)
    end)
end

return InventoryService 