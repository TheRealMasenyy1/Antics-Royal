local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(Knit.Util.Signal)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)
local UnitDataModule = require(ReplicatedStorage.SharedPackage.Units)
local SummonModule = require(ReplicatedStorage.Shared.SummonModule)
local ItemsModule = require(ReplicatedStorage.Shared.Items)
local TopbarUI = require(ReplicatedStorage.Shared.Icon)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local BannerNotify = require(ReplicatedStorage.Shared.Utility.BannerNotificationModule)
local Grades = require(ReplicatedStorage.SharedPackage.Grades)

local SystemController = Knit.CreateController {
    Name = "SystemController",
}

SystemController.OpenRequestRank = Signal.new()
SystemController.OpenRequestTraits = Signal.new()
SystemController.OpenRequestCraft = Signal.new()
SystemController.OpenRequestEvolve = Signal.new()
SystemController.OpenRequestFeed = Signal.new()
SystemController.OpenRequestCodes = Signal.new()
SystemController.OpenRequestStore = Signal.new()
SystemController.OpenRequestLevelMilestone = Signal.new()

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SummonService;
local ProfileService;
local PlayerService;
local InventoryService;

local PromptController;
local EmoteWheel;
local Content

local maidManager = MaidManager.new()

local Camera = workspace.CurrentCamera
local QuestsService;
local LevelMilestones = ReplicatedStorage.LevelMilestone

local bannerConfigError = {
	.2,                             -- Background Transparency
	Color3.fromRGB(168, 0, 0),         -- Background Color
	0,                                 -- Content Transparency
	Color3.fromRGB(255, 255, 255), -- Content Color
}

local function returnChildren(Folder : Folder)
    local Child = {};
    for _, child in pairs(Folder:GetChildren()) do
        table.insert(Child, child)
    end
    return Child
end

local function CheckCollected(Level, Rewards, Frame,CollectAll)
    local Amount = #LevelMilestones:GetChildren()
    local Exists = LevelMilestones:FindFirstChild(Level)

    if CollectAll then
        for i = 1, Amount do
            local RewardButton = Frame:FindFirstChild(i)
            
            if RewardButton and Level >= i then --! Removing this doesn't mean that you get the reward :clown:
                local Reward : IntValue | StringValue = returnChildren(LevelMilestones[i]) -- Contain Reward
                local IsCollected = Rewards[tostring(i)]
                -- RewardButton.Claim.BackgroundColor3 = Color3.fromRGB(132, 247, 0)
                RewardButton.Back.Locked.Visible = false

                if IsCollected then
                    RewardButton.Front.Unlocked.Visible = true
                    RewardButton.Back.Unlocked.Visible = true
                end
            end
        end
    else
        local RewardButton = Frame:FindFirstChild(Level)
        
        if RewardButton then --! Removing this doesn't mean that you get the reward :clown:
            local Reward : IntValue | StringValue = returnChildren(LevelMilestones[Level]) -- Contain Reward
            local IsCollected = Rewards[tostring(Level)]
            
            RewardButton.Back.Locked.Visible = false

            if IsCollected then
                RewardButton.Front.Unlocked.Visible = true
                RewardButton.Back.Unlocked.Visible = true
                Shortcut:PlaySound("Claim", true)
            end
        end
    end
end

function CountCollectable(Children) : number
    local Count : number = 0

    for Key, Value in Children do
        if Value then
            Count += 1
        end
    end

    return Count
end

local function LoadLevelMilestone(Frame)
    local Temp = Frame.Parent.temp
    local Claimed = QuestsService:CheckLevelMilestone():expect()
    local Items = ReplicatedStorage.Assets.Items

    local function createMilestone()
        local Level = ProfileService:Get("Level"):expect()
        local LevelMilestoneData = ProfileService:Get("LevelMilestone"):expect()

        --[[

            ! When hovering over
            *Backside move towards X = 1 or even 1.5
            *Frontside move towards X = 0 or even -.5
            *Then move both of them to the center
            *Change the ZIndex of the front to be 2 and the back to be 1
             
        --]]

        for i = 1, #LevelMilestones:GetChildren() do
            local Reward : IntValue | StringValue = returnChildren(LevelMilestones[i]) -- Contain Reward
            local MouseHasEntered = false
            local Milestone : Frame = Temp.Frame:Clone()
            local Back = Milestone.Back
            local Front = Milestone.Front
            -- Milestone.Level.Text = LevelMilestones[i].Name 
            local RewardFrame = Back.RewardBox.RewardsList
            Milestone.Front.LevelBox.LevelNumber.Text = LevelMilestones[i].Name 
            Milestone.Name = LevelMilestones[i].Name
            Milestone.Parent = Frame
            Milestone.Visible = true

            maidManager:AddMaid(Milestone,"OnHover", Milestone.MouseEnter:Connect(function()
                if not MouseHasEntered then
                    MouseHasEntered = true
                    local FirstMovement = {
                        [1] = {
                            Element = Milestone.Front,
                            Tween = {
                                Position = UDim2.fromScale(0,.5)
                            },
                        },
                        [2] = {
                            Element = Milestone.Back,
                            Tween = {
                                Position = UDim2.fromScale(1,.5)
                            },
                        }
                    }

                    UIManager:TweenMultipleUI(FirstMovement,.25,function()
                        Milestone.Front.ZIndex = 1
                        Milestone.Back.ZIndex = 2

                        local FrontBack = TweenService:Create(Milestone.Front,TweenInfo.new(.25),{
                            Position = UDim2.fromScale(.5,.5)
                        }):Play()
    
                        local BackFront = TweenService:Create(Milestone.Back,TweenInfo.new(.25),{
                            Position = UDim2.fromScale(.5,.5)
                        }):Play()
                    end)
                end
            end))

            maidManager:AddMaid(Milestone,"OnHoverLeave", Milestone.MouseLeave:Connect(function()
                if MouseHasEntered then
                    MouseHasEntered = false
                    local FirstMovement = {
                        [1] = {
                            Element = Milestone.Front,
                            Tween = {
                                Position = UDim2.fromScale(1,.5)
                            },
                        },
                        [2] = {
                            Element = Milestone.Back,
                            Tween = {
                                Position = UDim2.fromScale(0,.5)
                            },
                        }
                    }

                    UIManager:TweenMultipleUI(FirstMovement,.25,function()
                        Milestone.Front.ZIndex = 2
                        Milestone.Back.ZIndex = 1

                        local FrontBack = TweenService:Create(Milestone.Front,TweenInfo.new(.25),{
                            Position = UDim2.fromScale(.5,.5)
                        }):Play()
    
                        local BackFront = TweenService:Create(Milestone.Back,TweenInfo.new(.25),{
                            Position = UDim2.fromScale(.5,.5)
                        }):Play()
                    end)
                end
            end))

            Back.Claim.Activated:Connect(function()
               QuestsService:ClaimLevelMilestone(i):andThen(function(Claimed, newMilestone)
                    if Claimed then
                        CheckCollected(i, newMilestone, Frame)
                    end
               end) 
            end)

            for _,RewardInfo in pairs(Reward) do
                if RewardInfo.Name ~= "Unit" then
                    local newItem = UnitCreator.CreateItemIconForChallenge(RewardInfo.Name,{Amount = RewardInfo.Value}) --Item:Clone()

                    if newItem then
                        newItem.Size = UDim2.new(0.3, 0,0.5, 0)
                        newItem.UIStroke.Thickness = 2
                        newItem.UnitName.Visible = false
                        newItem.Parent = RewardFrame
                        newItem.Visible = true
                        UIManager:AddEffect(newItem,"Mythical",nil,2)
                    else
                        warn("Could not find the Item: ", RewardInfo.Name)
                    end
                end
            end
        end
        CheckCollected(Level, LevelMilestoneData, Frame, true)
    end
    
    createMilestone()
end

function SystemController.OpenLevelMilestone()
    local LevelMilestone = Content:WaitForChild("LevelMilestone")
    local MilestoneContent = LevelMilestone.Frame

    UIManager:UIOpened(LevelMilestone, function()
        UIManager:ClearFrame("Frame", MilestoneContent)
    end)

    LoadLevelMilestone(MilestoneContent)
end

local function Unlocked(newQuestFrame, Value : boolean)
    local Descendents = newQuestFrame:GetDescendants()

    if Value then
        for _, Elements in ipairs(Descendents) do
            if Elements.Name == "GradientComplete" then
                Elements.Enabled = false
            end

            if Elements.Name == "UIGradient" then
                Elements.Enabled = true
                newQuestFrame.Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            elseif Elements.Name == "LockedGradient" then
                Elements.Enabled = false
            end
        end
    else
        for _, Elements in ipairs(Descendents) do
            if Elements:IsA("UIGradient") then
                if Elements.Name == "UIGradient" then
                    Elements.Enabled = false
                elseif Elements.Name == "LockedGradient" then
                    Elements.Enabled = true
                end
            end
        end

        newQuestFrame.Btn.TextColor3 = Color3.fromRGB(81, 81, 81)
    end
end


function SimulateLevel(CurrentExp,CurrentMaxExp,CurrentLevel,Expbar,expAmount)
    local Level = 1

    local MaxExp = CurrentMaxExp
    local UnitActualExp = CurrentExp
    -- Check if player has double exp if so then double(expAmount * 2) exp amount

    local leftoverExp = expAmount
    local maxExp = MaxExp
    local PassedALevel = false

    while leftoverExp > 0 do
        if UnitActualExp + leftoverExp >= maxExp then
            -- Add exp to fill to MaxExp and level up
            leftoverExp = math.ceil((UnitActualExp + leftoverExp) - maxExp)

            UnitActualExp = 0

            Level += 1

            maxExp = maxExp * 1.25 -- Increase MaxExp by 25% for next level

            TweenService:Create(Expbar,TweenInfo.new(.15),{Size = UDim2.new( maxExp / maxExp,0,1.029,0)}):Play()
            task.delay(.15,function()
                TweenService:Create(Expbar,TweenInfo.new(.15),{Size = UDim2.new( 0 / maxExp,0,1.029,0)}):Play()
            end)
        else
            local newValue = UnitActualExp + leftoverExp
            TweenService:Create(Expbar,TweenInfo.new(.5),{Size = UDim2.new( newValue / maxExp,0,1.029,0)}):Play()
            UnitActualExp = newValue
            leftoverExp = 0
        end

        task.wait(.25)
    end

    warn("NEW LEVEL: ", Level, " NEXT MAX EXP: ", maxExp)

    return Level,math.ceil(UnitActualExp),math.ceil(maxExp)
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

local Feedmaid;

function SystemController.OpenFeed()
    local InventoryRequest = ProfileService:Get("Inventory")
    local Feed = Content:WaitForChild("Feed")
    local UnitFrame = Feed:WaitForChild("Frame")
    local SelectUnit = UnitFrame:WaitForChild("SelectUnit")
    local ShowFood = Feed:WaitForChild("ShowFood")
    local FeedBtn = Feed:WaitForChild("Feed")
    local AddAll = Feed:WaitForChild("AddAll")
    local RemoveAll = Feed:WaitForChild("RemoveAll")
    local MaxExp = Feed:WaitForChild("MaxExp")
    local ExpGain = Feed:WaitForChild("ExpGain")
    local LevelGain = Feed:WaitForChild("LevelGain")
    local ExpbarGroup = Feed:WaitForChild("Expbar")
    local bar = ExpbarGroup:WaitForChild("bar")
    local Hash = "";
    local TotalExp = 0
    local selectConnection; 
    local Unit;
    local FoodForUnit = {}
    local UnitInfo = {}
    local ShownFood = {}
    --[[
        MaxExp increases with a factor of 1.25
    --]]
    local PreviousMaxExp;
    local PreviousExp;
    local SimulateConnection : RBXScriptConnection;

    --! Feed Cleaner
    if Feedmaid then Feedmaid:Destroy() end
    Feedmaid = Maid.new()

    local function SimulateExpbar(CurrentExp : number, CurrentMaxExp : number)
        local Prop = {
            Size = UDim2.new((math.ceil(CurrentExp) or math.ceil(PreviousExp)) / (math.ceil(CurrentMaxExp) or math.ceil(PreviousMaxExp)),0,1.029,0)
        }

        local Simulate = TweenService:Create(bar,TweenInfo.new(.5), Prop)
        Simulate:Play()

        SimulateConnection = Simulate.Completed:Connect(function(playbackState)
            if PreviousExp and PreviousMaxExp then
                SimulateExpbar(PreviousExp, PreviousMaxExp)
            end

            PreviousMaxExp = CurrentMaxExp
            PreviousExp = CurrentExp
            SimulateConnection:Disconnect()
        end)
    end

    local function CheckExpAmount()
        TotalExp = 0
        for pos,Items in pairs(FoodForUnit) do
            print(pos.."| " .. Items.Name .. " | ", Items)
            TotalExp += (Items.Exp * Items.Amount)
        end

        ExpGain.Text = TotalExp .. " XP"
        local newUnitLevel, UnitLeftOverExp, newUnitMaxExp = SimulateLevel(UnitInfo.Exp,UnitInfo.MaxExp,UnitInfo.Level,bar,TotalExp)
        pcall(function()
            MaxExp.Text = UnitLeftOverExp .."/".. newUnitMaxExp
        end)
        LevelGain.Text = "+ " .. (newUnitLevel - 1) .." Lvls"
        warn("TOTALEXP: ", TotalExp, FoodForUnit)
    end

    local function UpdateIconAmount(Parent : any,Name : string, Amount : number)
        local FoodIcon = Parent:FindFirstChild(Name)

        if FoodIcon then
            local Coin = FoodIcon.Coin
            Coin.Text = Amount.."x"

            if Amount <= 0 then
                Coin:Destroy()
            end
        end
    end

    local function LoadCatogory(Table, Content : Frame, Type : string?, Use : boolean)
        local maid = Maid.new()
        local ReturnedItems = {}

        if typeof(Table) == "table" and not Use  then
            for _, Item in pairs(Table) do
                local ItemData = ItemsModule.Items[Item.Name] or ItemsModule.Materials[Item.Name]
                if (Type == ItemData.Type) then
                    if not Item.Name:find("Star") and Item.Amount > 0 then
                        local ItemUI = UnitCreator.CreateItemIconForChallenge(Item.Name, Item)
                        ItemUI.UnitName.AnchorPoint = Vector2.new(.5,.5)
                        ItemUI.UnitName.Position = UDim2.new(.5,0,0,0)
                        ItemUI.Name = Item.Name
                        ItemUI.Size = UDim2.new(0.184, 0,0.804, 0)
                        
                        ItemUI.Parent = Content
                        ItemUI.Visible = true

                        table.insert(ShownFood, ItemUI)
                        local TempTable = {Name = Item.Name, Exp = ItemData.Exp, Amount = Item.Amount}
                        table.insert(ReturnedItems, TempTable)

                        Feedmaid:GiveTask(ItemUI.Activated:Connect(function()
                            local _,Food,Value = deepSearch(FoodForUnit, Item.Name)

                            warn("FOOD FOR THE UNIT: ", Item.Name)
                            if Hash and not Food then
                                TempTable.Amount = 1
                                table.insert(FoodForUnit, TempTable)
                                LoadCatogory(TempTable,Feed.ShowItems,"Food",true)

                                --! HERE IS THE CHECK ZONE 
                                CheckExpAmount()
                            elseif Hash and Food then
                                if Item.Amount > Food.Amount then
                                    Food.Amount += 1
                                    UpdateIconAmount(Feed.ShowItems,Item.Name, Food.Amount)
                                    CheckExpAmount()
                                end 
                            end
                        end))
                    end
                end
            end
        else
            local ItemUI = UnitCreator.CreateItemIconForChallenge(Table.Name, Table)
            ItemUI.UnitName.AnchorPoint = Vector2.new(.5,.5)
            ItemUI.UnitName.Position = UDim2.new(.5,0,0,0)
            ItemUI.Size = UDim2.new(0.184, 0,0.804, 0)

            ItemUI.Parent = Content
            ItemUI.Visible = true

            if not table.find(ShownFood, ItemUI) then
                table.insert(ShownFood, ItemUI)
            end

            Feedmaid:GiveTask(ItemUI.Activated:Connect(function()
                local _,Food,Value = deepSearch(FoodForUnit,Table.Name)             
                warn("FOOD FOR THE UNIT: ", Table.Name)
                if Hash and Food then
                    if Food.Amount > 0 then
                        Food.Amount -= 1

                        if Food.Amount == 0 then
                            local TablePos = table.find(FoodForUnit, Food)
                            if TablePos then -- Removes
                                table.remove(FoodForUnit, TablePos)
                            end

                            -- table.remove(ShownFood,table.find(ShownFood,ItemUI))
                            ItemUI:Destroy() --! Don't know about this
                        end

                        UpdateIconAmount(Feed.ShowItems,Food.Name, Food.Amount)
                    end 
                    CheckExpAmount()
                end
            end))
        end

        return ReturnedItems
    end

    SelectUnit.Text = "?" 
    selectConnection = PromptController.SelectedUnit:Connect(function(UnitHash,UnitData) 
        SelectUnit:ClearAllChildren() 

        local unitFrame = UnitCreator.CreateUnitIcon(UnitData.Unit,UnitData) 
        unitFrame.Parent = UnitFrame 
        unitFrame.AnchorPoint = Vector2.new(.5,.5) 
        unitFrame.Size = UDim2.new(1,0,1,0) 
        unitFrame.Position = UDim2.new(0.5,0,0.5,0) 
        UnitInfo = UnitData 
        Hash = UnitHash 
        Unit = unitFrame 

        SelectUnit.Text = "" 
        MaxExp.Text = UnitData.Exp .."/"..UnitData.MaxExp .."XP"

        SimulateExpbar(UnitData.Exp,UnitData.MaxExp)
        Unlocked(AddAll, true)

        UIManager:UIOpened(Feed,function()
            MaxExp.Text = "+/- XP"
            Hash = ""
            selectConnection:Destroy()
        end)
    end)

    InventoryRequest:andThen(function(Inventory) 
        UIManager:ClearFrame("TextButton",ShowFood) 
        UIManager:ClearFrame("ViewportFrame",UnitFrame,true) 
        LoadCatogory(Inventory.Items,ShowFood,"Food") 

        maidManager:AddMaid(SelectUnit,"Activated",SelectUnit.Activated:Connect(function() 
            PromptController.OpenSelectUnit:Fire() 
        end)) 

        maidManager:AddMaid(FeedBtn,"Activated",FeedBtn.Btn.Activated:Connect(function() 
            InventoryService:FeedUnit(Hash,FoodForUnit):andThen(function(Status) 
                if Status then 
                    local UnitInfo = PlayerService:GetUnit(Hash):expect() 

                    if UnitInfo ~= nil then 
                        Unit.Level.Text = "Lvl. ".. UnitInfo.Level 
                    end 

                    Shortcut:PlaySound("Claim",true) 

                    for _, Object in pairs(ShownFood) do
                        local _,FoodTable = deepSearch(FoodForUnit, Object.Name)

                        if FoodTable then
                            UpdateIconAmount(Feed.ShowItems,FoodTable.Name, FoodTable.Amount)
                        end
                        Object:Destroy()
                    end

                    FoodForUnit = {}
                    CheckExpAmount()
                end
            end)
        end))

        maidManager:AddMaid(AddAll,"Activated",AddAll.Btn.Activated:Connect(function()
            if Hash then
                UIManager:ClearFrame("TextButton",ShowFood)
                UIManager:ClearFrame("TextButton",Feed.ShowItems)
                local ReturnedItems = LoadCatogory(Inventory.Items,Feed.ShowItems,"Food")

                for _, Item in ipairs(ReturnedItems) do
                    local _, AlreadyInside = deepSearch(FoodForUnit, Item.Name)
                    if not AlreadyInside then --! Might actually have to change to an acutal value
                        table.insert(FoodForUnit, Item)
                    elseif AlreadyInside then
                        AlreadyInside.Amount = Item.Amount
                    end
                end

                --! HERE IS THE CHECK ZONE 
                CheckExpAmount()
            end
        end))

        maidManager:AddMaid(RemoveAll,"Activated",RemoveAll.Btn.Activated:Connect(function()
            if Hash then
                UIManager:ClearFrame("TextButton",Feed.ShowItems)
                UIManager:ClearFrame("TextButton",ShowFood)
                local ReturnedItems = LoadCatogory(Inventory.Items,ShowFood,"Food")

                --! HERE IS THE CHECK ZONE 
                FoodForUnit = {}
                CheckExpAmount()
            end
        end))

        UIManager:UIOpened(Feed,function()
            UIManager:ClearFrame("TextButton",Feed.ShowItems)
            UIManager:ClearFrame("TextButton",ShowFood)

            FoodForUnit = {}
            if Hash ~= "" then
                CheckExpAmount()
            end
        end)
    end)
end

function SystemController.OpenRank()
    local Ranks = Content:WaitForChild("Stats")
    local UnitFrame = Ranks:WaitForChild("Frame")
    local SelectUnit = UnitFrame:WaitForChild("SelectUnit")
    local PinAmount = Ranks.PinAmount
    local Spin = Ranks:WaitForChild("Spin")
    local RankGem = 0
    local Hammer = 0
    local Hash;
    local selectConnection
    local OriginalSize = Spin.Size
    local AmountToUpgrade = 1;
    local PinnedStats = {}
    local RankGemAmount = Ranks:WaitForChild("RankGemAmount")

    PlayerService:GetItem("Items","Hammer"):andThen(function(Item)
        Hammer = Item.Amount
    end):await()

    PlayerService:GetItem("Items","Dice"):andThen(function(Item)
        RankGem = Item.Amount
    end):await()

    UIManager:UIOpened(Ranks,function()
        for _,Labels in pairs(Ranks:GetChildren()) do
            if Labels.Name == "Damage" then
                Labels.Text = "A"
            elseif Labels.Name == "Cooldown" then
                Labels.Text = "A"
            elseif Labels.Name == "Range" then
                Labels.Text = "A"
            end
        end

        for _,PinAttribute in pairs(Ranks:GetChildren()) do
            local PinStat = PinAttribute:GetAttribute("Stat")

            if PinAttribute:IsA("ImageButton") and PinStat then 
                PinAttribute.ImageColor3 = Color3.fromRGB(94, 94, 94)
            end
        end

        PinnedStats = {}
        UIManager:ClearFrame("ViewportFrame",UnitFrame,true)
    end)

    SelectUnit.Text = "?" 
    UIManager:OnMouseChanged(Spin,UDim2.new(0.22, 0,0.115, 0),OriginalSize)
    
    PinAmount.Amount.Text = Hammer.."x"
    RankGemAmount.Amount.Text = RankGem.."x"

    for _,PinAttribute in pairs(Ranks:GetChildren()) do
        local PinStat = PinAttribute:GetAttribute("Stat")

        if PinAttribute:IsA("ImageButton") and PinStat then 
            maidManager:AddMaid(PinAttribute,"Activated", PinAttribute.Activated:Connect(function()
                local Pinned = PinAttribute:GetAttribute("Pinned")

                if Hammer > 0 then
                    if Pinned then
                        PinAttribute.ImageColor3 = Color3.fromRGB(94, 94, 94)
                        table.remove(PinnedStats,table.find(PinnedStats,PinStat))
                        --Hammer += 1

                        PinAmount.Amount.Text = Hammer.."x"
                        task.delay(.25,function()
                            PinAttribute:SetAttribute("Pinned", false)
                        end)
                    elseif not Pinned then
                        PinAttribute.ImageColor3 = Color3.fromRGB(255 , 255, 255)
                        table.insert(PinnedStats, PinStat)
                        --Hammer -= 1

                        PinAmount.Amount.Text = Hammer.."x"
                        task.delay(.25,function()
                            PinAttribute:SetAttribute("Pinned", true)
                        end)
                    end
                end
            end))
        end
    end

    selectConnection = PromptController.SelectedUnit:Connect(function(UnitHash,UnitData)
        SelectUnit:ClearAllChildren()

        local unitFrame = UnitCreator.CreateUnitIcon(UnitData.Unit,UnitData)
        unitFrame.Parent = UnitFrame
        unitFrame.AnchorPoint = Vector2.new(.5,.5)
        unitFrame.Size = UDim2.new(1,0,1,0)
        unitFrame.Position = UDim2.new(0.5,0,0.5,0)
        SelectUnit.Text = "" 

        for _,Labels in pairs(Ranks:GetChildren()) do
            if Labels.Name == "Damage" then
                Labels.Text = UnitData.Stats.Damage
            elseif Labels.Name == "Cooldown" then
                Labels.Text = UnitData.Stats.Cooldown
            elseif Labels.Name == "Range" then
                Labels.Text = UnitData.Stats.Range
            end
        end

        Hash = UnitHash 
        UIManager:UIOpened(Ranks,function()
            selectConnection:Destroy()
        end)
    end)

    SelectUnit.Activated:Connect(function()
        PromptController.OpenSelectUnit:Fire()   
    end)

    maidManager:AddMaid(Spin.Btn,"Activated",Spin.Btn.Activated:Connect(function()
        if RankGem >= AmountToUpgrade and Hash then
            local Damage, Range, Cooldown = SummonService:Ranks(Hash,PinnedStats):expect()
            local RemainGem = RankGem - AmountToUpgrade

            PlayerService:GetItem("Items","Hammer"):andThen(function(Item)
                Hammer = Item.Amount
            end):await()

            PlayerService:GetItem("Items","Dice"):andThen(function(Item)
                RankGem = Item.Amount
            end):await()

            Shortcut:PlaySound("MouseClick", true)
            Shortcut:PlaySound("Claim", true)

            RankGemAmount.Amount.Text = RemainGem.."x"

            if Hammer > #PinnedStats and #PinnedStats > 0 then
                Hammer -= #PinnedStats
                PinAmount.Amount.Text = Hammer.."x"
            end

            warn("THE PINNEDTABLE: ", PinnedStats, " : - : ", Damage, Range, Cooldown)

            for _,Labels in pairs(Ranks:GetChildren()) do
                if Labels.Name == "Damage" and not table.find(PinnedStats,"Damage") then
                    Labels.Text = Damage
                elseif Labels.Name == "Cooldown" and not table.find(PinnedStats,"Cooldown") then
                    Labels.Text = Cooldown
                elseif Labels.Name == "Range" and not table.find(PinnedStats,"Range") then
                    Labels.Text = Range
                end
            end
        elseif Hash and RankGem < AmountToUpgrade then
            BannerNotify:Notify("Insufficient gems", "Not enough gems!","",5,bannerConfigError) --? In this case trait name will be the error 
        elseif (Hash == "" or not Hash) then
            BannerNotify:Notify("Empty Unit","You haven't selected a unit","",5,bannerConfigError) --? In this case trait name will be the error 
        end
        -- selectConnection:Disconnect()
    end))
end

function SystemController.OpenTraits()
    local Trait = Content:WaitForChild("Traits")
    local TraitInfo = Content:WaitForChild("TraitInfo")
    local InfoBtn = Trait:WaitForChild("Info")
    local UnitFrame = Trait:WaitForChild("Frame")
    local ShowGem = Trait:WaitForChild("ShowGem")
    local SelectUnit = UnitFrame:WaitForChild("SelectUnit")
    local TraitLabel = Trait:WaitForChild("Trait")
    local Spin = Trait:WaitForChild("Spin")
    local TitanCrystal = 0
    
    PlayerService:GetItem("Items","Titan Crystal"):andThen(function(Crystals)
        TitanCrystal = Crystals.Amount
    end):await()

    local OriginalSize = Spin.Size
    local Hash;
    local selectConnection : RBXScriptConnection;
    local LastUnitFrame;
    local AmountToUpgrade = 1

    UIManager:ClearFrame("ViewportFrame",ShowGem, true)
    UIManager:ClearFrame("ViewportFrame",UnitFrame, true)


    UIManager:UIOpened(Trait,function()
        TraitLabel.Visible = false
        Hash = nil;
    end)

    local TraitCrystal, ImageFrame = UnitCreator.CreateRecipesIcon("Titan Crystal",AmountToUpgrade,{Amount = TitanCrystal},"Mythical")
    TraitCrystal.Size = UDim2.fromScale(1,1)
    TraitCrystal.UnitName.Position = UDim2.fromScale(0,0)
    ImageFrame.Size = UDim2.fromScale( .5, .5)
    TraitCrystal.Parent = ShowGem

    SelectUnit.Text = "?" 

    selectConnection = PromptController.SelectedUnit:Connect(function(UnitHash,UnitData)
        SelectUnit:ClearAllChildren()

        if LastUnitFrame then LastUnitFrame:Destroy() end

        local unitFrame = UnitCreator.CreateUnitIcon(UnitData.Unit,UnitData)
        unitFrame.Parent = UnitFrame
        unitFrame.AnchorPoint = Vector2.new(.5,.5)
        unitFrame.Size = UDim2.new(1,0,1,0)
        unitFrame.Position = UDim2.new(0.5,0,0.5,0)

        LastUnitFrame = unitFrame
        Hash = UnitHash 
        SelectUnit.Text = "" 

        UIManager:UIOpened(Trait,function()
            LastUnitFrame:Destroy()
            selectConnection:Disconnect()
            Hash = nil;
        end)
    end)

    maidManager:AddMaid(SelectUnit,"Activated",SelectUnit.Activated:Connect(function()
        PromptController.OpenSelectUnit:Fire()
    end))

    UIManager:OnMouseChanged(Spin,UDim2.new(0.425, 0,0.136, 0),OriginalSize)

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

    maidManager:AddMaid(InfoBtn,"Activated", InfoBtn.Activated:Connect(function()
        local InfoContent = TraitInfo.Content.Frame
        local TraitInfoTable = Grades.Traits
        local TraitRarity = Grades.TraitsRarity

        for Trait,TraitLevels in pairs(TraitInfoTable) do
            for Pos, TraitData in pairs(TraitLevels) do
                local TraitFrame = InfoContent:FindFirstChild(Trait .. " " .. Pos)

                if TraitFrame then
                    local _,Rarity = deepSearch(TraitRarity,Trait .. " " .. Pos)

                    if Rarity then
                        TraitFrame.TraitName.Text = Trait .. " " .. Pos .. " \t\t" .. Rarity.Percentage .. "%"
                        TraitFrame.TraitDesc.Text = TraitData.Desc
                    end
                end
            end
        end

        UIManager:UIOpenedInsideAnother(Trait,TraitInfo,function()
            warn("TraitInfo Closed")
        end)
    end))

    maidManager:AddMaid(Spin,"Activated", Spin.Btn.Activated:Connect(function()
        local TraitName, TraitLevel, newUnitData = SummonService:Trait(Hash):expect()

        if TraitName and Hash and TitanCrystal > AmountToUpgrade then
            Shortcut:PlaySound("MouseClick", true)
            Shortcut:PlaySound("Claim", true)

            TitanCrystal -= AmountToUpgrade
            TraitCrystal.Coin.Text = TitanCrystal .. "/" .. AmountToUpgrade
            TraitLabel.Visible = true
            TraitLabel.Position = UDim2.new(0.708, 0,0.426, 0)

            for _,IconTrait in pairs(LastUnitFrame.Icons:GetChildren()) do
                if IconTrait:GetAttribute("IsTrait") then
                    IconTrait:Destroy()
                end
            end

            warn("Of the new information is here: ", newUnitData)
            UnitCreator.CreateTrait(LastUnitFrame, newUnitData)

            TweenService:Create(TraitLabel,TweenInfo.new(.15),{Position = UDim2.new(0.954, 0,0.429, 0)}):Play()
            TraitLabel.TraitText.Text = TraitName .. " " .. TraitLevel
            selectConnection:Disconnect()
        elseif Hash and TitanCrystal < AmountToUpgrade then
            BannerNotify:Notify("Insufficient gems",TraitName,"",5,bannerConfigError) --? In this case trait name will be the error 
        elseif (Hash == "" or not Hash) then
            BannerNotify:Notify("Empty Unit","You haven't selected a unit","",5,bannerConfigError) --? In this case trait name will be the error 
        end
    end))
end

function SystemController.OpenCraft()
    local Craft = Content:WaitForChild("Craft")
    local UnitFrame = Craft:WaitForChild("Frame")
    local SelectUnit = UnitFrame:WaitForChild("SelectUnit")
    local ShowItems = Craft:WaitForChild("ShowItems")
    local CraftBtn = Craft:WaitForChild("Craft")
    local Cost = Craft:WaitForChild("Cost")
    local CoinAmount = Craft:WaitForChild("CoinsAmount")
    local playerCoins = ProfileService:Get("Coins"):expect()
    
    local Hash;
    local selectConnection : RBXScriptConnection;
    local CostAmount = 0;

    SelectUnit.Text = "?" 
    CoinAmount.Amount.Text = "Coin: " .. playerCoins
    
    UIManager:UIOpened(Craft, function()
        UIManager:ClearFrame("ImageButton", ShowItems)
        UIManager:ClearFrame("ImageButton",UnitFrame)
    end)

    selectConnection = PromptController.SelectedItem:Connect(function(Item,ItemData)
        UIManager:ClearFrame("ImageButton", ShowItems)

        local unitFrame = UnitCreator.CreateItemIcon(Item)
        unitFrame.Parent = UnitFrame
        unitFrame.AnchorPoint = Vector2.new(.5,.5)
        unitFrame.Size = UDim2.new(1,0,1,0)
        unitFrame.Position = UDim2.new(0.5,0,0.5,0)

        for Item, Amount in ItemData do
            if Item ~= "Icon" and Item ~= "Cost" then
                local ItemInInventory = PlayerService:GetItem("Materials",Item):expect() or { Amount = 0 } -- ProfileService:Get("Inventory")
                local Recipes = UnitCreator.CreateRecipesIcon(Item, Amount, ItemInInventory)
                
                Recipes.Size = UDim2.new(.3,0,.3,0)
                Recipes.Visible = true
                Recipes.Parent = ShowItems
            elseif Item == "Cost" then
                CostAmount = Amount
                Cost.Amount.Text = "Cost: ".. Amount
            end
        end

        Hash = Item
        SelectUnit.Text = "" 

        UIManager:UIOpened(Craft,function()
            selectConnection:Disconnect()
        end)
    end)

    SelectUnit.Activated:Connect(function()
        UIManager:ClearFrame("ImageButton", ShowItems)
        PromptController.OpenSelectItem:Fire()   
    end)

    CraftBtn.Btn.Activated:Connect(function()
        local Crafted = PlayerService:CraftItem(Hash):expect()
        if Crafted then
            playerCoins = ProfileService:Get("Coins"):expect()
            if playerCoins >= CostAmount then
                CoinAmount.Amount.Text = "Coin: " .. (playerCoins - CostAmount)
            else
                CoinAmount.Amount.Text = "Coin: " .. playerCoins
            end
        end
        warn(`Was it Crafted? {Crafted}`)
    end)
end

function SystemController.OpenEvolve()
    local Evolve = Content:WaitForChild("Evolve")
    local UnitFrame = Evolve:WaitForChild("Frame")
    local SelectUnit = UnitFrame:WaitForChild("SelectUnit")
    local ShowItems = Evolve:WaitForChild("ShowItems")
    local ShowUnit = Evolve:WaitForChild("ShowUnit")
    local EvolveBtn = Evolve:WaitForChild("Evolve").Btn

    local Hash;
    local selectConnection : RBXScriptConnection;
    local CostAmount = 0;

    UIManager:UIOpened(Evolve, function()
        UIManager:ClearFrame("ImageButton", ShowItems)
        UIManager:ClearFrame("ImageButton", ShowUnit)
        UIManager:ClearFrame("ImageButton",UnitFrame)
        SelectUnit.Text = "?"
    end)

    selectConnection = PromptController.SelectedUnit:Connect(function(UnitHash,UnitData)
        SelectUnit:ClearAllChildren()

        local unitFrame = UnitCreator.CreateUnitIcon(UnitData.Unit,UnitData)
        unitFrame.Parent = UnitFrame
        unitFrame.Size = UDim2.new(1,0,1,0)
        unitFrame.AnchorPoint = Vector2.new(.5,.5)
        unitFrame.Position = UDim2.new(0.5,0,0.5,0)
        
        local ItemToEvolve = UnitDataModule[UnitData.Unit].ItemToEvolve
        local RequiredToEvolve = UnitDataModule[UnitData.Unit].RequiredToEvolve 
        warn("UNIT HAS BEEN SELECTED AND WE'RE HERE",UnitDataModule[UnitData.Unit])

        local ItemInInventory = PlayerService:GetItem("Materials",ItemToEvolve):expect() or { Amount = 0 } -- ProfileService:Get("Inventory")
        local Recipes = UnitCreator.CreateRecipesIcon(ItemToEvolve, RequiredToEvolve, ItemInInventory)
        Recipes.Size = UDim2.new(1,0,1,0)
        Recipes.Position = UDim2.new(0.5,0,0.5,0)
        Recipes.Visible = true
        Recipes.Parent = ShowItems

        local EvolvedunitFrame = UnitCreator.CreateUnitIcon(UnitData.Unit.."(Evolved)")
        EvolvedunitFrame.Parent = ShowUnit
        EvolvedunitFrame.Size = UDim2.new(1,0,1,0)
        EvolvedunitFrame.Position = UDim2.new(0.5,0,0.5,0)
        
        Hash = UnitHash 
        SelectUnit.Text = ""

        UIManager:UIOpened(Evolve,function()
            selectConnection:Disconnect()
        end)
    end)

    maidManager:AddMaid(SelectUnit,"Activated",SelectUnit.Activated:Connect(function()
        UIManager:ClearFrame("ImageButton", ShowItems)
        PromptController.OpenSelectUnit:Fire("Mythical")   
    end))

    maidManager:AddMaid(EvolveBtn,"Activated",EvolveBtn.Activated:Connect(function()
        local Succ, UnitData = SummonService:EvolveUnit(Hash):expect()

        if Succ then
            print("Returned Data: ", UnitData)
            SummonModule:ShowUnit(UnitData)
        end
    end))
end

function charCopy(player)
	local c = player.Character or player.CharacterAdded:Wait()
	c.Archivable = true
	local result = c:Clone()
    local Humanoid : Humanoid = result.Humanoid
    local billboard = result.Head:FindFirstChild("playerGui")
    local Face = result.Head:FindFirstChildWhichIsA("Decal")

    result.HumanoidRootPart.Anchored = true
    Humanoid:RemoveAccessories()

    if Humanoid then
        Humanoid:Destroy()
    end

    if Face then
        Face:Destroy()
    end

    if billboard then
        billboard:Destroy()
    end

    for _, part : BasePart in pairs(result:GetChildren()) do
        if part:IsA("Model") then
            part:Destroy()
        end

        if part.Name == "Part" then
            part:Destroy()
        end

        if part:IsA("BasePart") then
            if part.Name ~= "HumanoidRootPart" then
                part.Transparency = .85
                part.Reflectance = 0
                part.Material = Enum.Material.Neon
            end

            part.CollisionGroup = "Ghosts"
            part.Anchored = true
            part.Color = Color3.fromRGB(50, 231, 255)
            part.CanCollide = false
        elseif part:IsA("Shirt") or part:IsA("Pants") then
            part:Destroy()
        end
    end
	
	return result
end

local IsActive = false
local RunAnimation : AnimationTrack

function SystemController.SpeedBoost(Active : boolean)
    local CurrentTime = 0
    local Increment = .1
    local Humanoid : Humanoid = player.Character.Humanoid
    local Animator : Animator = Humanoid.Animator
    IsActive = Active

    if IsActive then
        RunAnimation = player.Character.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Player.Run)
        RunAnimation:Play()
    elseif RunAnimation then
        RunAnimation:Stop()
        for _, Animation in pairs(Animator:GetPlayingAnimationTracks()) do
            if Animation.Name == "Run" then
                Animation:Stop(.25)
            end
        end
    end

    while IsActive do
        if Humanoid.MoveDirection.Magnitude > 0 then
            local newClone = charCopy(player)

            if not RunAnimation.IsPlaying then
                RunAnimation:Play()
            end

            for _, part : BasePart in pairs(newClone:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    part.CollisionGroup = "Ghosts"
                end
            end

            newClone:PivotTo(player.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,0))
            newClone.Parent = workspace.Debris
            
            for _, part : BasePart in pairs(newClone:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false

                    task.spawn(function()
                        local Tween = TweenService:Create(part, TweenInfo.new(1), {Transparency = 1, Color = Color3.fromRGB(255, 255, 255)})
                        Tween:Play()
                        
                        part.CanCollide = false
    
                        Tween.Completed:Connect(function()
                            newClone:Destroy()
                        end)
                    end)
                end
            end
        else
            RunAnimation:Stop()
        end

        CurrentTime += Increment --RunService.Heartbeat:Wait()
        task.wait(Increment)
    end
end

function SystemController:KnitStart()

end

function CloneNoobWithEmote(EmoteName)
    local newCamera = Camera:Clone()
    local Animation = ReplicatedStorage.Assets.Animations.Emotes:FindFirstChild(EmoteName)

    if Animation then
        local newNoob = ReplicatedStorage.Noob:Clone()
        newNoob.Parent = workspace

        newCamera.CFrame = newNoob.PrimaryPart.CFrame * CFrame.new(0,0,-6)
        newCamera.CFrame = CFrame.new(newCamera.CFrame.Position, newNoob.PrimaryPart.CFrame.Position)

        local Viewport = Instance.new("ViewportFrame")    
        local WorldModel = Instance.new("WorldModel")

        Viewport.BackgroundTransparency = 1
        Viewport.Size = UDim2.new(1,0,1,0)
        WorldModel.Parent = Viewport

        newNoob.Parent = WorldModel
        newCamera.Parent = WorldModel
        Viewport.CurrentCamera = newCamera

        return Viewport, newNoob
    end

    return nil
end

local EmoteMaid 
local playing
local Icon

function SystemController:EmoteWheel()
    local Inventory = ProfileService:Get("Inventory"):expect()
    local Emotes = Inventory.Emotes
    local Amount = 1
    local MaxAmount = 4
    if EmoteMaid then EmoteMaid:Destroy() end

    EmoteMaid = Maid.new()

    for EmoteName, IsEquipped in Emotes do
        if IsEquipped and Amount < MaxAmount then
            local Animation = ReplicatedStorage.Assets.Animations.Emotes:FindFirstChild(EmoteName)
            local newViewport = CloneNoobWithEmote(EmoteName)
            newViewport.Parent = EmoteWheel[Amount]
            
            if Animation then
                local Emote = newViewport.WorldModel.Noob.Humanoid.Animator:LoadAnimation(Animation)
                Emote.Looped = true
                Emote:Play()

                EmoteMaid:GiveTask(EmoteWheel[Amount].Activated:Connect(function()
                    if playing then playing:Stop() end

                    playing = player.Character.Humanoid.Animator:LoadAnimation(Animation)
                    playing.Looped = true
                    playing:Play()

                    player.Character.Humanoid.WalkSpeed = 0
                    Icon:deselect()
                    -- UIManager:UIClose(EmoteWheel)
                end))

                Amount += 1
            end
        end
    end 
end

function SystemController.OpenCodes() --! @TheRealMasenyy1 code this later
    local Codes = Content:WaitForChild("Codes")
    local CodeFrame = Codes:WaitForChild("CodeFrame")
    local CodeInput = CodeFrame:WaitForChild("CodeInput")
    local RedeemButton = Codes:WaitForChild("RedeemButton")
    local bannerConfig = {
        .2,                             -- Background Transparency
        Color3.fromRGB(168, 0, 0),         -- Background Color
        0,                                 -- Content Transparency
        Color3.fromRGB(255, 255, 255), -- Content Color
    }

    maidManager:AddMaid(RedeemButton,"Activated",RedeemButton.Activated:Connect(function()
        if CodeInput.Text ~= "" then --! Check if code exists or is usable in the server
            PlayerService:RedeemCodes(CodeInput.Text):andThen(function(returnString, CodeRedeemed)
                if typeof(CodeRedeemed) == "boolean" and CodeRedeemed then
                    bannerConfig = {
                        .2,                             -- Background Transparency
                        Color3.fromRGB(43, 255, 15),         -- Background Color
                        0,                                 -- Content Transparency
                        Color3.fromRGB(255, 255, 255), -- Content Color
                    }

                    CodeInput.Text =  "Code redeemed!"
                    task.delay(2, function()
                        CodeInput.Text =  ""
                    end)

                    BannerNotify:Notify(returnString,"You have been granted your reward","",5,bannerConfig)
                elseif CodeRedeemed == "expired" then
                    BannerNotify:Notify(returnString,"the code is unavailable!","",5,bannerConfig)
                end

                print(returnString)
            end)           
        else
            warn("Please enter a code!")
        end
    end))

    UIManager:UIOpened(Codes,function()
        print("Here is the test")    
    end)
end

function SystemController.OpenStore() --! @TheRealMasenyy1 code this later
    local Store = Content:WaitForChild("Store")
    local Robux = CollectionService:GetTagged('Robux')
    local PurchaseIds = require(ReplicatedStorage.SharedPackage.PurchaseIds)

    local function GetProduct(Name)
        for ProductType, ProductTable in pairs(PurchaseIds) do
            for ProductName, ProductId in pairs(ProductTable) do
                if ProductName == Name then
                    return ProductType , ProductId
                end
            end
        end

        return nil
    end

    for _, BtnFrame in pairs(Robux) do
        local Product = BtnFrame:GetAttribute("Product")
        local SizeOnGrowth = BtnFrame:GetAttribute("Size")
        local SizeOnClick = BtnFrame:GetAttribute("DownSize")
        local OriginalSize = BtnFrame.Size

        maidManager:AddMaid(BtnFrame,"Activated", BtnFrame.Activated:Connect(function()
            local ProductType, ProductId = GetProduct(Product)
            print("The maid has been pressed: ", ProductType, ProductId)
            if ProductType == "Products" then
                print("This is a product: ", ProductId)
                MarketplaceService:PromptProductPurchase(player,ProductId)
            else
                print("This is a Gamepass: ", ProductId)
                MarketplaceService:PromptGamePassPurchase(player,ProductId)
            end
        end))

        UIManager:OnMouseChanged(BtnFrame,SizeOnGrowth,OriginalSize)
        UIManager:AddButton(BtnFrame,SizeOnClick,OriginalSize)
    end

    UIManager:UIOpened(Store,function()
        warn("Store has been closed")
    end)
end

function SystemController:KnitInit()
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    Content = Core:WaitForChild("Content")
    EmoteWheel = Content:WaitForChild("EmoteWheel")
    local LobbyService = Knit.GetService("LobbyService")

    SummonService = Knit.GetService("SummonService")
    PromptController = Knit.GetController("PromptController")
    ProfileService = Knit.GetService("ProfileService")
    PlayerService = Knit.GetService("PlayerService")
    QuestsService = Knit.GetService("QuestsService")
    InventoryService = Knit.GetService("InventoryService")
    local ProductService = Knit.GetService("ProductService")

    Icon = TopbarUI.new()
    Icon:setLabel("Emote"):bindToggleKey(Enum.KeyCode.M):setCaption("Emote wheel"):bindEvent("deselected", function()
        task.spawn(function()
            for i = 1, 4 do
                local viewportFrame = EmoteWheel[i]:FindFirstChild("ViewportFrame")
    
                if viewportFrame then
                    viewportFrame:Destroy()
                end
            end
        end)
        EmoteWheel.Visible = false
    end)

    Icon:bindToggleItem(EmoteWheel)
    Icon.toggled:Connect(function(IsVisible)
        if IsVisible then
            SystemController:EmoteWheel()	
            TweenService:Create(EmoteWheel.UIScale, TweenInfo.new(.25),{Scale = 1}):Play()
        else
            TweenService:Create(EmoteWheel.UIScale, TweenInfo.new(.25),{Scale = 0}):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
        if not gameProcessedEvent and (input.KeyCode == Enum.KeyCode.Space or player.Character.Humanoid.Jump) then
            if player.Character and player.Character.Humanoid.WalkSpeed == 0 then
                player.Character.Humanoid.WalkSpeed = 20
                for _,animation in  player.Character.Humanoid.Animator:GetPlayingAnimationTracks() do
                    if animation.Name == playing.Name then
                        animation:Stop()
                    end
                end 
            end
        end
    end)

    LobbyService.BoostEffect:Connect(SystemController.SpeedBoost)

    SystemController.OpenRequestCodes:Connect(SystemController.OpenCodes)
    SystemController.OpenRequestStore:Connect(SystemController.OpenStore)
    SystemController.OpenRequestRank:Connect(SystemController.OpenRank)
    SystemController.OpenRequestFeed:Connect(SystemController.OpenFeed)
    SystemController.OpenRequestTraits:Connect(SystemController.OpenTraits)
    SystemController.OpenRequestCraft:Connect(SystemController.OpenCraft)
    SystemController.OpenRequestEvolve:Connect(SystemController.OpenEvolve)
    SystemController.OpenRequestLevelMilestone:Connect(SystemController.OpenLevelMilestone)
end

return SystemController