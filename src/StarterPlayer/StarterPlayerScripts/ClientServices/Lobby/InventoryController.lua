
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local EzVisuals = require(ReplicatedStorage.Shared.EasyVisuals)
local UnitDataModule = require(ReplicatedStorage.SharedPackage.Units)
local Prices = require(ReplicatedStorage.Shared.Prices)
local Signal = require(Knit.Util.Signal)
local ItemsModule = require(ReplicatedStorage.Shared.Items)
local SummonModule = require(ReplicatedStorage.Shared.SummonModule)
local BannerNotify = require(ReplicatedStorage.Shared.Utility.BannerNotificationModule)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local _maid = MaidManager.new()

local InventoryController = Knit.CreateController {
    Name = "InventoryController",
}

InventoryController.RequestOpenInventory = Signal.new()
InventoryController.RequestOpenItems = Signal.new()
InventoryController.RequestOpenFeed = Signal.new()

local ProfileService;
local SummonService;
local PlayerService;
local SystemController;
local PromptController;
local EffectService;

local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Assets = ReplicatedStorage.Assets

local Rarity = {
    [1] = "Rare",
    [2] = "Epic",
    [3] = "Legendary",
    [4] = "Mythical",
    [5] = "Secret",
}

local Colors = {
    ["Defualt"] = Color3.fromRGB(255, 255, 255),
    ["Rare"] = Color3.fromRGB(0, 208, 255),
    ["Epic"] = Color3.fromRGB(217, 2, 255),
    ["Legendary"] = Color3.fromRGB(255, 226, 7),
    ["Mythical"] = Color3.fromRGB(255, 255, 255),
    ["Secret"] = Color3.fromRGB(255, 255, 255),
}

local InventoryService
local Content
local ExtraInfoFrame
local LastRarityActivated;
local LastViewport;

function format(num)
    local formatted = string.format("%.2f", math.floor(num*100)/100)
    if string.find(formatted, ".00") then
        return string.sub(formatted, 1, -4)
    end
    return formatted
end

local function LoadEquippedUnits()
    local OnProfileReady = ProfileService:OnProfileReady()

    OnProfileReady:andThen(function()
        local Equipped = ProfileService:Get("Equipped")
    
        Equipped:andThen(function(UnitsData)
            EquipUnit(UnitsData)
        end)
    end)
end 

local LevelRequirement = {
    [1] = 1;
    [2] = 1;
    [3] = 10;
    [4] = 15;
    [5] = 20;
    [6] = 25;
}

function EquipUnit(UnitsData)
    local InventoryFrame = Content:WaitForChild("Inventory")
    local Toolbar = Content:WaitForChild("Toolbar")
    local EquipBtn = InventoryFrame.InfoFrame:WaitForChild("Equip")
    local PlayerLevel = ProfileService:Get("Level"):expect()
    local UnitAmount = #UnitsData
    local OnHoverIncrease = 1.1

    repeat task.wait() until #Assets.Viewports:GetChildren() > 0

    warn("The units table:  ", UnitsData)

    for Pos = 1, 6 do
        local Slot : TextButton = Toolbar.Frame:FindFirstChild(Pos)

        UIManager:ClearFrame("TextButton",Slot)
        Slot.Txt.Visible = false

        if Slot and PlayerLevel >= LevelRequirement[Pos] then
            Slot.Locked.Visible = false
            Slot.Empty.Visible = true
        end

        if Slot and UnitsData[Pos] then
            local UnitData = UnitsData[Pos]
            local RarityInNumber = UnitDataModule[UnitData.Unit].Rarity
            local UnitRarity = Rarity[RarityInNumber]
            local RarityColor = Colors[UnitRarity]
            local Viewport = Assets.Viewports:WaitForChild(UnitData.Unit,10)
            local UnitDefualtStats = UnitDataModule[UnitData.Unit].Upgrades[0]

            if Viewport then

                Slot.Empty.Visible = false

                local UnitUI : TextButton = UnitCreator.CreateUnitIcon(UnitData.Unit, UnitData)
                local newUnitData = UnitDataModule[UnitData.Unit]
                local UnitRarity = Rarity[newUnitData.Rarity]
                UnitUI.Name = UnitData.Hash
                UnitUI.Parent = Slot
                UnitUI.Size = UDim2.new(1,0,1,0)
                local OriginalSize = Slot.Size
                UnitUI.Visible = true
                UnitUI.Interactable = false

                UnitUI.Level:Destroy()
                UnitUI.UnitName:Destroy()
                -- UnitUI.Coin:Destroy()
                -- UnitUI.Interactable = true
                UIManager:AddEffect(UnitUI, UnitRarity)
                
                UIManager:OnMouseChangedWithCondition(Slot,UDim2.new(Slot.Size.X.Scale * OnHoverIncrease, 0,Slot.Size.Y.Scale * OnHoverIncrease, 0), OriginalSize,"Frame",nil, .25)

                UnitUI.Coin.Position = UDim2.new(.95,0,.9,0)
                Slot.Coin.Visible = false
                -- Slot.Level.Visible = false

                Slot.Txt.Visible = true
                Slot.Txt.Text = "Lv. " .. UnitData.Level
                -- UnitCoin.Coin.Text = "¥" .. UnitDefualtStats.Cost 

            else
                warn("Could not find viewport --> ", UnitData.Unit)
            end
        end
        -- print(Pos .. ": " .. UnitData.Unit)
    end

    if UnitAmount < 6 then
        for Pos = UnitAmount + 1, 6 do
            local Slot = Toolbar:FindFirstChild(Pos)
    
            if Slot and Slot:FindFirstChildWhichIsA("TextButton") then
                UIManager:ClearFrame("TextButton",Slot)
                Slot.Empty.Visible = true
            end
        end
    end
     -- Request to equip Unit
end

local function GetUnit(UnitsData, Hash : string)
    for pos,UnitData in UnitsData do
        if UnitData.Hash == Hash then
            return UnitData,pos
        end
    end

    return nil
end

local InfoMaid;
local BackgroundEffects;
local StrokeEffect;

local function OpenInfoFrame(UnitData,InventoryContent)
    local InventoryFrame = Content:WaitForChild("Inventory")
    local InfoFrame : Frame = InventoryFrame:WaitForChild("InfoFrame")
    local EquipBtn = InfoFrame:WaitForChild("Equip")
    local RarityInNumber = UnitDataModule[UnitData.Unit].Rarity
    local UnitRarity = Rarity[RarityInNumber]
    local Viewport = Assets.Viewports:FindFirstChild(UnitData.Unit)

    local LevelBar = InfoFrame:WaitForChild("LevelBar")
    local bar = LevelBar:WaitForChild("bar")
    local Level = LevelBar:WaitForChild("Level") -- Lv. X
    local ExpAmount = LevelBar:WaitForChild("ExpAmount") -- 200/300
    local Inspect = InfoFrame:WaitForChild("Inspect")
    local ShinyLabel = InfoFrame:WaitForChild("ShinyLabel")
    local UnitTypeFrame = InfoFrame:WaitForChild("UnitType")

    local TypeSynon = {
        ["Ground"] = "GRND",
        ["Hill"] = "Hill",
        ["Hybrid"] = "Hybrid"
    }

    InfoFrame.Visible = true

    TweenService:Create(InfoFrame,TweenInfo.new(.25),{Position = UDim2.new(1.126, 0,0.537, 0)}):Play()
    TweenService:Create(InfoFrame.Parent,TweenInfo.new(.25),{Position = UDim2.new(0.46, 0,0.5, 0)}):Play()

    --[[
        If extra info is opened then 
        Move the main UI to -> {0.46, 0},{0.5, 0}
        set ExtraInfo to -> {1.126, 0},{0.537, 0}
        original set to -> {0.253, 0},{0.726, 0}
    ]]--

    if Viewport then
        if LastRarityActivated then LastRarityActivated.Visible = false end
        if LastViewport then LastViewport:Destroy() end
        if InfoMaid then InfoMaid:Destroy() end
        if BackgroundEffects then BackgroundEffects:Destroy() end
        if StrokeEffect then StrokeEffect:Destroy() end

        if UnitData.Shiny then 
            UIManager:AddEffect(ShinyLabel,"Mythical",0,.1)
            ShinyLabel.Visible = true
        else
            ShinyLabel.Visible = false
        end

        InfoMaid = Maid.new()
        InfoFrame.BackgroundColor3 = Colors[UnitRarity]

        BackgroundEffects, StrokeEffect = UIManager:AddEffect(InfoFrame, UnitRarity, .5)
        UnitTypeFrame.Type.Text = TypeSynon[UnitDataModule[UnitData.Unit].UnitType] 

        local Expbar = if UnitData.Exp >= 1 then (UnitData.Exp / UnitData.MaxExp) - .1 else (UnitData.Exp / UnitData.MaxExp)

        bar.Size = UDim2.new(Expbar,0, 0.29,0)
        ExpAmount.Text = UnitData.Exp .."/" .. UnitData.MaxExp
        Level.Text = "Lv.".. UnitData.Level

        local IsUnitEquipped = false
        local newViewport = Viewport:Clone()
        newViewport.Size = UDim2.new(1,0,1,0)
        newViewport.Parent = InfoFrame
        newViewport.WorldModel.Animate.Enabled = true
        newViewport.ZIndex = -10

        local _,_,ActualRange = UnitManager:ConvertGrade(UnitData,"Range")
        local _,_,ActualCooldown = UnitManager:ConvertGrade(UnitData,"Cooldown")
        local Equipped = ProfileService:Get("Equipped")
        local bannerConfig = {
            .2,                             -- Background Transparency
            Color3.fromRGB(168, 0, 0),         -- Background Color
            0,                                 -- Content Transparency
            Color3.fromRGB(255, 255, 255), -- Content Color
        }

        EquipBtn.Text.Text = "Equip"

        Equipped:andThen(function(Data)
            local UnitData,pos = GetUnit(Data, UnitData.Hash)
            if UnitData then
                IsUnitEquipped = true
                EquipBtn.Text.Text = "Unequip"
            end
        end):await()

        EquipBtn.Visible = true 

        InfoMaid:GiveTask(Inspect.Button.Activated:Connect(function()
            SummonModule:ShowUnit(UnitData)
            -- PlayerService:TestExp(UnitData.Hash)
        end))

        InfoMaid:GiveTask(EquipBtn.Text.Activated:Connect(function()
            --- Equip in server & Client
            if not IsUnitEquipped then
                local HasBeenEquipped = InventoryService:EquipUnit(UnitData.Hash)

                HasBeenEquipped:andThen(function(IsEquipped, ReturnString, Desc)
                    if IsEquipped then
                        local UnitInInventory = InventoryContent:FindFirstChild(UnitData.Hash)

                        if UnitInInventory then
                            UnitInInventory.Name = "A "..UnitInInventory.Name
                            UnitInInventory.Button.Visible = true
                        end
                        IsUnitEquipped = true
                        EquipBtn.Text.Text = "Unequip"
                    else
                        BannerNotify:Notify(ReturnString,Desc,"",5,bannerConfig)
                    end
                end)
            else
                local HasBeenUnequipped = InventoryService:UnequipUnit(UnitData.Hash)

                HasBeenUnequipped:andThen(function()
                    local UnitInInventory = InventoryContent:FindFirstChild("A "..UnitData.Hash)
                    if UnitInInventory then
                        UnitInInventory.Name = UnitData.Hash
                        UnitInInventory.Button.Visible = false
                    end
                    IsUnitEquipped = false
                    EquipBtn.Text.Text = "Equip"
                end)
            end
        end))
        local UnitType = if UnitData.UnitType == "Ground" then "GRND" elseif UnitData.UnitType == "Hill" then "Hill" elseif UnitData.UnitType == "Hybrid" then "Hybrid" else "GRND"
        -- Show trait as well(if unit has one ) -- 
        InfoFrame.UnitName.Text = UnitData.Unit
        InfoFrame.UnitType.Type.Text = UnitType
        InfoFrame.Damage.Text.Text = "DMG" .. "(" ..UnitData.Stats.Damage .. "): " .. UnitManager:GetDamageWithBenefits(UnitData, "Damage")
        InfoFrame.Range.Text.Text = "RNG" .. "(" ..UnitData.Stats.Range.. "): " .. ActualRange
        InfoFrame.Cooldown.Text.Text = "CD" .. "(" ..UnitData.Stats.Cooldown.. "): " .. ActualCooldown

        LastViewport = newViewport
        -- LastRarityActivated = BackgroundFrame
    end
end

local Rarity = {
    [1] = "Rare",
    [2] = "Epic",
    [3] = "Legendary",
    [4] = "Mythical",
    [5] = "Secret",
}

local InvMaid;

local function LoadPresets(PresetsFrame)
    local PresetsRequest = ProfileService:Get("Presets")
    local Equipped = ProfileService:Get("Equipped"):expect()
    local Content = PresetsFrame:WaitForChild("Content")
    local Frame = Content:WaitForChild("Frame")

    local function UnitViewport(UnitData,Parent)
        local UnitUI = UnitCreator.CreateUnitIcon(UnitData.Unit, UnitData)
        local newUnitData = UnitDataModule[UnitData.Unit]
        local UnitRarity = Rarity[newUnitData.Rarity]
        UnitUI.Name = UnitData.Hash
        UnitUI.Parent = Parent

        UnitUI.AnchorPoint = Vector2.new(.5,.5)
        UnitUI.Size = UDim2.new(1,0,1,0)
        UnitUI.Position = UDim2.new(.5,0,.5,0)
        UnitUI.Visible = true
        UnitUI.ZIndex = 5
    end

    local function LoadIntoPreset(Preset,Units)
        local Count = if #Units <= 0 then 6 else #Units
        for i = 1, Count do
            local Slot = Preset:FindFirstChild(tostring(i))
            local HasUnit = Slot:FindFirstChildWhichIsA("TextButton")

            if HasUnit then 
                HasUnit:Destroy()
            end

            if Slot and Units[i] ~= nil then
                UnitViewport(Units[i],Slot)
            end
        end
    end

    PresetsRequest:andThen(function(Presets)
        for i = 1, #Presets do
            local ActualFrame = Frame:FindFirstChild("Preset"..i)
            local Units = Presets[i].Units
            -- Equipped = ProfileService:Get("Equipped"):expect()
            if ActualFrame then
                if #Units > 0 then
                    ActualFrame.Equip.Text.Text = "Equip Team"
                    LoadIntoPreset(ActualFrame,Units)
                else
                    ActualFrame.Equip.Text.Text = "Save"
                end

                UIManager:HoverOver(ActualFrame.UnequipAll.Text)
                UIManager:HoverOver(ActualFrame.Equip.Text)

                _maid:AddMaid(ActualFrame.UnequipAll,"Activated",ActualFrame.UnequipAll.Text.Activated:Connect(function()
                    local newReset = InventoryService:ClearPreset(i)

                    newReset:andThen(function(newTeam)
                        LoadIntoPreset(ActualFrame,newTeam)
                        ActualFrame.Equip.Text.Text = "Save"
                    end)
                end))

                _maid:AddMaid(ActualFrame.Equip,"Activated",ActualFrame.Equip.Text.Activated:Connect(function()
                    if ActualFrame.Equip.Text.Text == "Save" then
                        LoadIntoPreset(ActualFrame,Equipped)
                        InventoryService:SavePreset(i)
    
                        ActualFrame.Equip.Text.Text = "Equip Team"
                    else
                        InventoryService:EquipPreset(i)
                    end
                end))
            end
        end
    end)
end

local function LoadInventory(Inventory, InventoryContent : Frame, InventoryData)
    local SearchFrame : Frame = Inventory:WaitForChild("SearchFrame")
    local RarityFrame : Frame = Inventory:WaitForChild("Rarity")
    local RaritiesFrame : Frame = Inventory:WaitForChild("Rarities")
    local UnequipAllFrame : Frame = Inventory:WaitForChild("UniquipAll")
    local SearchText : TextBox = SearchFrame:WaitForChild("Search")
    local InfoFrame : Frame = Inventory:WaitForChild("InfoFrame")
    local PresetsBtn : Frame = Inventory:WaitForChild("Presets")
    local Preset : Frame = Content:WaitForChild("Presets")
    local Equipped = ProfileService:Get("Equipped")
    local EquippedUnits = {}

    local SearchStorage = {}
    InvMaid = Maid.new()

    local function Search(Unit : string)
        for _, UI in pairs(InventoryContent:GetChildren()) do
            if UI:IsA("TextButton") and UI:GetAttribute("UnitName") then
                local UnitName : string = UI:GetAttribute("UnitName")
                if string.lower(UnitName):find(Unit) then
                    UI.Visible = true
                end

                if string.lower(UnitName) and not string.lower(UnitName):find(Unit) then
                    UI.Visible = false
                end

                if Unit == "" then
                    UI.Visible = true
                end
            end
        end
    end

    local function SortByRarity(Rarities: string)
        for _, UI in pairs(InventoryContent:GetChildren()) do
            if UI:IsA("TextButton") and UI:GetAttribute("UnitName") then
                local Rarity : string = UI:GetAttribute("Rarity")
                if Rarity:find(Rarities) then
                    UI.Visible = true
                end

                if Rarity and not Rarity:find(Rarities) then
                    UI.Visible = false
                end

                if Rarities == "" then
                    UI.Visible = true
                end
            end
        end
    end

    local LatestSelected;
    
    UIManager:HoverOver(PresetsBtn.Text)
    UIManager:HoverOver(RarityFrame.Text) 
    UIManager:HoverOver(UnequipAllFrame.Text)  

    _maid:AddMaid(PresetsBtn,"Activated",PresetsBtn.Text.Activated:Connect(function()
        LoadPresets(Preset)
        Shortcut:PlaySound("MouseClick",true)
        Inventory.Interactable = false

        UIManager:UIOpenedInsideAnother(Inventory, Preset,function()
            Inventory.Interactable = true
        end)
    end))

    for _,Frame in pairs(RaritiesFrame:GetChildren()) do
        local Button = Frame:FindFirstChild("Text") 

        if Button then
            local OriginalSize = UDim2.new(0.965, 0,0.195, 0)

            _maid:AddMaid(Button,"Activated",Button.Activated:Connect(function()
                Shortcut:PlaySound("MouseClick",true)

                if LatestSelected then
                    LatestSelected.SelectedGradient.Enabled = false
                    LatestSelected.UIStroke.SelectedGradient.Enabled = false

                    LatestSelected.UIGradient.Enabled = true
                    LatestSelected.UIStroke.UIGradient.Enabled = true
                end

                if not LatestSelected or (LatestSelected and LatestSelected.Name ~= Frame.Name) then
                    Frame.SelectedGradient.Enabled = true
                    Frame.UIStroke.SelectedGradient.Enabled = true
    
                    Frame.UIGradient.Enabled = false
                    Frame.UIStroke.UIGradient.Enabled = false

                    LatestSelected = Frame
                    SortByRarity(Frame.Name)     
                else
                    SortByRarity("")
                    LatestSelected = nil
                end
            end))

            -- UIManager:OnMouseChangedWithCondition(Frame,UDim2.new(0.97, 0, 0.2, 0), OriginalSize,"TextButton")
        end
    end

    _maid:AddMaid(RaritiesFrame,"Activated",RarityFrame.Text.Activated:Connect(function()
        --Position = {0.573, 0},{0.333, 0}, Size = {0.253, 0},{0.331, 0}
        --- Set to small = {0.253, 0},{0.047, 0}
        Shortcut:PlaySound("MouseClick",true)
        if not RaritiesFrame.Visible then
            RaritiesFrame.Visible = true
            TweenService:Create(RaritiesFrame,TweenInfo.new(.25),{Size = UDim2.new(0.253, 0,0.331, 0) }):Play()
        else
            RaritiesFrame.Visible = false
            RaritiesFrame.Size = UDim2.new(0.253, 0,0.047, 0)
        end
    end))

    _maid:AddMaid(SearchText,"Changed",SearchText.Changed:Connect(function(property)
        if property == "Text" then
            Search(string.lower(SearchText.Text))
        end
    end))

    
    Equipped:andThen(function(Data)
        EquippedUnits = Data
    end):await()
    --[[ w w
        If extra info is opened then 
        Move the main UI to -> {0.46, 0},{0.5, 0}
        set ExtraInfo to -> {1.126, 0},{0.537, 0}
        original set to -> {0.253, 0},{0.726, 0}
    ]]--
    local OnHoverScale = 1.05
    for _, UnitData in pairs(InventoryData) do
        local Exists = InventoryContent:FindFirstChild(UnitData.Hash) or InventoryContent:FindFirstChild("A "..UnitData.Hash)
        if UnitData.Unit and not Exists then
            local UnitUI = UnitCreator.CreateUnitIcon(UnitData.Unit, UnitData)
            local newUnitData = UnitDataModule[UnitData.Unit]
            local UnitRarity = Rarity[newUnitData.Rarity]
            UnitUI.Name = UnitData.Hash
            UnitUI.Parent = InventoryContent
            -- UnitUI.Size = UDim2.new(0, 170,0, 170)
            UnitUI.AnchorPoint = Vector2.new(.5,.5)
            UnitUI.Size = UDim2.new(0.128, 0,0.1, 0)
            UnitUI.Visible = true
            
            local OriginalSize = UnitUI.Size

            UIManager:AddEffect(UnitUI, UnitRarity)
            
            UnitUI:SetAttribute("Rarity", UnitRarity)
            UnitUI:SetAttribute("UnitName", UnitData.Unit)

            UIManager:OnMouseChangedWithCondition(UnitUI,UDim2.new(0.128 * OnHoverScale, 0,0.1 * OnHoverScale, 0), OriginalSize,"ViewportFrame",4,.25)

            local UnitDataS,pos = GetUnit(EquippedUnits, UnitData.Hash)

            if UnitDataS then
                UnitUI.Name = "A "..UnitUI.Name
                UnitUI.Button.Visible = true
            end

            _maid:AddMaid(UnitUI,"Activated",UnitUI.Activated:Connect(function()
                Shortcut:PlaySound("MouseClick",true)
                OpenInfoFrame(UnitData,InventoryContent)
            end))
        else
            Exists.Level.Text = "Lv. " .. UnitData.Level

            _maid:AddMaid(Exists,"Activated",Exists.Activated:Connect(function()
                Shortcut:PlaySound("MouseClick",true)
                OpenInfoFrame(UnitData,InventoryContent)
            end))
            -- UIManager:OnMouseChanged(UnitUI,UDim2.new(0.24, 0,0.0017, 0), OriginalSize, ExtraInfoFrame)
        end
    end

    InventoryContent.UIListLayout.SortOrder = Enum.SortOrder.Name
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

function InventoryController.PlayAnimation(character, Name : string, AdjustSpeed : number)
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

function InventoryController.StopAnimation(character, Name : string)
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

function InventoryController:EnterSellMode()
    local InventoryFrame = Content:WaitForChild("Inventory")
    local Content = InventoryFrame:WaitForChild("Content")
    local Frame = Content:WaitForChild("Frame")

    local SellFrame = InventoryFrame:WaitForChild("SellFrame")
    local Cancel_btn = SellFrame:WaitForChild("Cancel")
    local Sell_btn = SellFrame:WaitForChild("Sell")
    local Amount_lb = SellFrame:WaitForChild("Amount")
    local UnitAmount = InventoryFrame:WaitForChild("UnitAmount")

    local SelectedUnits : {string} = {}
    local Amount = 0

    local maid = Maid.new()
    local IsHolding = false
    local Started = false

    maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsHolding = true
        end
    end))

    maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsHolding = false
            print("The Hash: ", SelectedUnits, Amount)
        end
    end))

    local function Highlight(UI)
        local SellImage = UI:FindFirstChild("SellImage")

        if SellImage then -- Don't forget to revert it back
            if not SellImage.Visible then
                SellImage.Visible = true
            else
                SellImage.Visible = false               
            end 
        end
    end

    for _,Unit : ImageButton in pairs(Frame:GetChildren()) do
        if Unit:IsA("ImageButton") or Unit:IsA("TextButton") then
            _maid:AddMaid(Unit,"Activated",Unit.MouseEnter:Connect(function()
                local alreadyIn = table.find(SelectedUnits, Unit.Name)
                local IsEquipped = Unit.Button.Visible == true

                if not IsEquipped then
                    if IsHolding and not alreadyIn then
                        Highlight(Unit)
                        Amount += Prices[Unit:GetAttribute("Rarity")]

                        task.delay(.5,function()
                            table.insert(SelectedUnits, Unit.Name)
                        end)
                    elseif IsHolding and alreadyIn then
                        Highlight(Unit)
                        Amount -= Prices[Unit:GetAttribute("Rarity")]
                        table.remove(SelectedUnits, alreadyIn)
                    end
                end

                Amount_lb.Text = `Sell {#SelectedUnits} For {Amount} Gold?`
            end))
            
            _maid:AddMaid(Unit,"Activated",Unit.Activated:Connect(function()
                local alreadyIn = table.find(SelectedUnits, Unit.Name)
                local IsEquipped = Unit.Button.Visible == true

                if not IsEquipped then
                    if IsHolding and not alreadyIn then
                        Highlight(Unit)
                        Amount += Prices[Unit:GetAttribute("Rarity")]
                        table.insert(SelectedUnits, Unit.Name)
                    elseif IsHolding and alreadyIn then
                        Highlight(Unit)
                        Amount -= Prices[Unit:GetAttribute("Rarity")]
                        table.remove(SelectedUnits, alreadyIn)
                    end
                end

                Amount_lb.Text = `Sell {#SelectedUnits} For {Amount} Gold?`
            end))
        end
    end

    _maid:AddMaid(Cancel_btn,"Activated",Cancel_btn.Activated:Connect(function()
        SellFrame.Visible = false
        IsHolding = false
        for _, Hash in SelectedUnits do
            local UI = Frame:FindFirstChild(Hash)
            if UI and UI.SellImage.Visible then
                UI.SellImage.Visible = false
            end
        end

        SelectedUnits = {}
        maid:Destroy()
    end))

    _maid:AddMaid(Sell_btn,"Activated",Sell_btn.Activated:Connect(function()
        local Sold,Units = SummonService:SellUnits(SelectedUnits):expect()
        local MaxUnitsInventory = ProfileService:Get("MaxUnitsInventory"):expect() 

        if Sold then
            for _, Unit in SelectedUnits do
                local UnitBtn = Frame:FindFirstChild(Unit)
                if UnitBtn then
                    UnitBtn:Destroy()
                end
            end

            Amount = 0
            SelectedUnits = {}

            Amount_lb.Text = `Sell {#SelectedUnits} For {Amount} Gold?`
            UnitAmount.Text = #Units.."/" .. MaxUnitsInventory
        end
    end))
end

local RarityText
local StrokeEffect

local function OpenItemInfoFrame(ItemFrame,ItemName, ItemData, ItemUI : TextButton)
    local InfoFrame = ItemFrame.Parent:WaitForChild("ItemInfoFrame")
    local RarityInNumber = 5
    local UseBtn = InfoFrame.ScrollingFrame.Frame:WaitForChild("Use")
    local ItemInfo = ItemsModule.Items[ItemName] or ItemsModule.Materials[ItemName]
    local ItemRarity = ItemInfo.Rarity

    if RarityText then RarityText:Destroy() end
    if StrokeEffect then StrokeEffect:Destroy() end

    local XOffset = ItemUI.AbsoluteSize.X + 10 --200
    local YOffset = ItemUI.AbsoluteSize.Y + 50  --100

    InfoFrame.Size = UDim2.fromScale(0,0)

    UIManager:Resize(InfoFrame,.5,5,{
        Size = UDim2.fromScale(0.128,0.158)
    })

    InfoFrame.Position = UDim2.fromOffset(ItemUI.AbsolutePosition.X + XOffset, ItemUI.AbsolutePosition.Y + YOffset)
    InfoFrame.Visible = true

    task.spawn(function()
        while InfoFrame.Visible do
            XOffset = ItemUI.AbsoluteSize.X + 10 --200
            YOffset = ItemUI.AbsoluteSize.Y + 50  --100

            InfoFrame.Position = UDim2.fromOffset(ItemUI.AbsolutePosition.X + XOffset, ItemUI.AbsolutePosition.Y + YOffset)
            task.wait()
        end
    end)

    if LastViewport then LastViewport:Destroy() end
    if InfoMaid then InfoMaid:Destroy() end

    InfoFrame.Rarity.Text = ItemRarity
    InfoFrame.Desc.Text = ItemInfo.Desc

    RarityText = UIManager:AddEffectToText(InfoFrame.Rarity,ItemRarity,0,1.5)
    StrokeEffect = UIManager:AddEffectToText(InfoFrame.UIStroke,ItemRarity,0,1.5)

    InfoFrame.ItemName.Text = ItemName

    if (ItemInfo.Type == "Food" or ItemInfo.Usable) then
        UseBtn.UIGradient.Enabled = true
        UseBtn.Btn.Text = "Use" 
    else
        UseBtn.UIGradient.Enabled = false
        UseBtn.Btn.Text = "Not Usable" 
    end

    local OriginalSize = UseBtn.Size

    UIManager:OnMouseChanged(UseBtn,UDim2.fromScale(0.98,0.265),OriginalSize)
    UIManager:AddButton(UseBtn,UDim2.fromScale(0.9,0.185),OriginalSize)

    _maid:AddMaid(UseBtn,"OnActivated",UseBtn.Activated:Connect(function()
        -- print("CLICKED THE ITEMS....", ItemInfo.Type, " is usable? ", ItemInfo.Usable)
        if ItemInfo.Type == "Food" then
            SystemController.OpenRequestFeed:Fire() 
            UIManager:UIClose(InfoFrame)
        elseif ItemInfo.Type == "Items" and ItemInfo.Usable then
            EffectService:ActivateBoost(ItemName)
            UIManager:UIClose(InfoFrame)
        end
    end))
end

function LoadCatogory(Table, Content : Frame, Type : string?, Use : boolean)
    local maid = Maid.new()

    for _, Item in ipairs(Table) do
        local ItemData = ItemsModule.Items[Item.Name] or ItemsModule.Materials[Item.Name]
        if ItemData and (Type == ItemData.Type) then
            warn("Item to load: ", Item.Name, Item)
            if not Item.Name:find("Star") and not ItemData.IsThreeD and Item.Amount > 0 then
                local ItemUI : TextButton = UnitCreator.CreateItemIconForChallenge(Item.Name, Item) --or UnitCreator.CreateRecipesIcon(Item.Name,Item.Amount,{Amount = 0},"Rare")
                ItemUI.UnitName.AnchorPoint = Vector2.new(.5,.5)
                ItemUI.UnitName.Position = UDim2.new(.5,0,0,0)
                ItemUI.Size = UDim2.new(0.12, 0,0.2, 0) --if not Use then UDim2.new(0.12, 0,0.2, 0) else UDim2.new(0.184, 0,0.804, 0)

                ItemUI.Parent = Content
                ItemUI.Visible = true

                UIManager:OnMouseChanged(ItemUI,if not Use then UDim2.new(0.13, 0,0.3, 0) else UDim2.new(0.19, 0,0.825, 0), if not Use then UDim2.new(0.12, 0,0.2, 0) else UDim2.new(0.184, 0,0.804, 0))
                UIManager:AddEffect(ItemUI, ItemData.Rarity)

                _maid:AddMaid(ItemUI,"OnHover", ItemUI.Activated:Connect(function()
                    print(`Item has been selected {Item.Name}`)
                    UIManager:HideItemInfo()
                    task.spawn(OpenItemInfoFrame,Content.Parent.Parent,Item.Name, Item, ItemUI)               
                end))
            elseif (Item.Name:find("Star") or ItemData.IsThreeD) and Item.Amount > 0 then
                local ItemUI,viewport = UnitCreator.CreateRecipesIcon(Item.Name,Item.Amount,{Amount = 0},ItemData.Rarity)--UnitCreator.CreateItemIcon(Item.Name)
                viewport.Size = UDim2.new(1,0,1,0)
                ItemUI.UnitName.AnchorPoint = Vector2.new(.5,.5)
                ItemUI.UnitName.Position = UDim2.new(.5,0,0,0)
                ItemUI.Size = UDim2.new(0.12, 0,0.2, 0)
                ItemUI.Parent = Content

                ItemUI.Coin.AnchorPoint = Vector2.new(1,.5) 
                ItemUI.Coin.Size = UDim2.new(0.624, 0,0.397, 0)
                ItemUI.Coin.Position = UDim2.new(1.15,0,1,0) 

                ItemUI.Coin.Text = Item.Amount .. "x"
                ItemUI.Coin.TextColor3 = Color3.fromRGB(255,255,255)
                ItemUI.Visible = true

                UIManager:OnMouseChanged(ItemUI,if not Use then UDim2.new(0.13, 0,0.3, 0) else UDim2.new(0.19, 0,0.825, 0), if not Use then UDim2.new(0.12, 0,0.2, 0) else UDim2.new(0.184, 0,0.804, 0))
                UIManager:AddEffect(ItemUI, ItemData.Rarity)

                _maid:AddMaid(ItemUI,"Activated",ItemUI.Activated:Connect(function()
                    if not Use then
                        UIManager:HideItemInfo()
                        task.spawn(OpenItemInfoFrame,Content.Parent.Parent,Item.Name, Item)               
                    else
                        warn(`This item { Item.Name } can't be used`)
                    end
                end))
            end
        end
    end
end



function LoadItems(ItemsFrame, Content, InventoryData)
    local Food_btn = ItemsFrame:WaitForChild("Food")
    local Items_btn = ItemsFrame:WaitForChild("Items")
    local Material_btn = ItemsFrame:WaitForChild("Material")
    local All_btn = ItemsFrame:WaitForChild("All")

    local Items = InventoryData.Items
    local Materials = InventoryData.Materials
    local Boosts = InventoryData.Boosts
    local maid = Maid.new()

    local LatestSelected = All_btn;

    LoadCatogory(Items,Content,"Food")
    LoadCatogory(Materials,Content,"Material")
    LoadCatogory(Items,Content,"Items")
    
    local function Select(Frame, Value) 
        for _, Elements in ipairs(Frame:GetDescendants()) do
            if Elements.Name == "UIGradient" then
                Elements.Enabled = not Value
            elseif Elements.Name == "SelectedGradient" then
                Elements.Enabled = Value
            end
        end
    end

    Select(All_btn, true)

    _maid:AddMaid(Food_btn,"Activated",Food_btn.Btn.Activated:Connect(function()
        UIManager:ClearFrame("TextButton", Content)

        Select(Food_btn, true)
        if LatestSelected then
            Select(LatestSelected, false)
        end

        LatestSelected = Food_btn
        LoadCatogory(Items,Content,"Food")
    end))

    _maid:AddMaid(Material_btn,"Activated",Material_btn.Btn.Activated:Connect(function()
        UIManager:ClearFrame("TextButton", Content)

        Select(Material_btn, true)
        if LatestSelected then
            Select(LatestSelected, false)
        end
        LatestSelected = Material_btn
        LoadCatogory(Materials,Content,"Material")
    end))

    _maid:AddMaid(Items_btn,"Activated",Items_btn.Btn.Activated:Connect(function()
        UIManager:ClearFrame("TextButton", Content)

        Select(Items_btn, true)
        if LatestSelected then
            Select(LatestSelected, false)
        end
        LatestSelected = Items_btn
        LoadCatogory(Items,Content,"Items")
    end))

    _maid:AddMaid(All_btn,"Activated",All_btn.Btn.Activated:Connect(function()
        UIManager:ClearFrame("TextButton", Content)

        Select(All_btn, true)
        if LatestSelected then
            Select(LatestSelected, false)
        end
        LatestSelected = All_btn
        LoadCatogory(Items,Content,"Food")
        LoadCatogory(Materials,Content,"Material")
        LoadCatogory(Items,Content,"Items")
    end))
end

function InventoryController.OpenItems()
    local ItemsFrame = Content:WaitForChild("Items")
    local InfoFrame =  Content:WaitForChild("ItemInfoFrame")
    local ItemContent = ItemsFrame:WaitForChild("Content")
    local RecievedInventory = ProfileService:Get("Inventory")

    RecievedInventory:andThen(function(Inventory)
        UIManager:ClearFrame("TextButton",ItemContent.Frame)
        LoadItems(ItemsFrame, ItemContent.Frame, Inventory)

        UIManager:UIOpened(ItemsFrame, function()
            InfoFrame.Visible = false
            -- InfoFrame.Position = UDim2.new(0.863, 0,0.546, 0)
            UIManager:ClearFrame("TextButton",ItemContent.Frame)
        end)
    end)

end

function InventoryController.OpenInventory()
    local InventoryFrame = Content:WaitForChild("Inventory")
    local InfoFrame = InventoryFrame:WaitForChild("InfoFrame")
    local InventoryContent = InventoryFrame:WaitForChild("Content")
    local RecievedInventory = ProfileService:Get("Inventory")
    local UnitAmount = InventoryFrame:WaitForChild("UnitAmount")

    local SellFrame = InventoryFrame:WaitForChild("SellFrame")
    local SellBtn = InventoryFrame:WaitForChild("SellBtn")
    local Cancel_btn = SellFrame:WaitForChild("Cancel")
    local Sell_btn = SellFrame:WaitForChild("Sell")
    local MaxUnitsInventory = ProfileService:Get("MaxUnitsInventory"):expect() 

    RecievedInventory:andThen(function(Inventory)
        if InvMaid then InvMaid:Destroy() end
        local Units = Inventory.Units
        UnitAmount.Text = "Units: " .. #Units.."/" .. MaxUnitsInventory
        LoadInventory(InventoryFrame, InventoryContent.Frame, Units)

        UIManager:UIOpened(InventoryFrame,function()
            if  InvMaid then InvMaid:Destroy() end
            InfoFrame.Visible = false
        end)
    end)

    SellBtn.SellMode.Activated:Connect(function()
        SellFrame.Visible = true
        InventoryController:EnterSellMode()
    end)
end

function InventoryController.UpdateItems(ItemData)
    local ItemsFrame = Content.Items
    local ItemsContent = ItemsFrame.Content
    local ContentFrame = ItemsContent.Frame
    local ActualItem = ContentFrame:FindFirstChild(ItemData.Name)

    if ActualItem then
        warn("Item has been updated: ", ItemData)
        ActualItem.Coin.Text = ItemData.Amount .. "x"
        if ItemData.Amount <= 0 then
            ActualItem:Destroy()   
        end
    end
end

function InventoryController:KnitInit()
end

function InventoryController:KnitStart()
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    Content = Core:WaitForChild("Content")

    ProfileService = Knit.GetService("ProfileService")
    InventoryService = Knit.GetService("InventoryService")
    SummonService = Knit.GetService("SummonService")
    PlayerService = Knit.GetService("PlayerService")
    SystemController = Knit.GetController("SystemController")
    PromptController = Knit.GetController("PromptController")
    EffectService = Knit.GetService("EffectService")

    task.delay(2, function()
        LoadEquippedUnits()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.KeyCode == Enum.KeyCode.R then
            -- PlayerService:GiveItemTest("Materials","5 Star", 3)
            PlayerService:TestExp()
            -- PlayerService:GiveItemTest("Materials","1 Star", 5)
            -- PlayerService:GiveItemTest("Materials","7 Star", 2)
        end
    end)

    -- InventoryController.RequestOpenFeed(InventoryController.OpenFeed)
    InventoryService.StopAnimation:Connect(InventoryController.StopAnimation)
    InventoryService.PlayAnimation:Connect(InventoryController.PlayAnimation)
    InventoryService.UnitEquipped:Connect(EquipUnit)
    PlayerService.UpdateEquipped:Connect(LoadEquippedUnits)
    PlayerService.UpdateInventory:Connect(InventoryController.UpdateItems)
    InventoryController.RequestOpenInventory:Connect(InventoryController.OpenInventory)
    InventoryController.RequestOpenItems:Connect(InventoryController.OpenItems)
end

return InventoryController