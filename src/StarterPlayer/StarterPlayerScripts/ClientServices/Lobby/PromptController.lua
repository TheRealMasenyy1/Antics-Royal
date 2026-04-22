local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPrompt = game:GetService("ProximityPromptService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Dialog = require(ReplicatedStorage.Shared.BossDialog)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local Signal = require(Knit.Util.Signal)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)
local UnitDataModule = require(ReplicatedStorage.SharedPackage.Units)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Cutscene = require(ReplicatedStorage.Shared.Cutscene)
local Promise = require(ReplicatedStorage.Shared.Utility.PromiseTyped)
local SummonModule = require(ReplicatedStorage.Shared.SummonModule)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local _maid = MaidManager.new()

local PromptController = Knit.CreateController{
    Name = "PromptController",
}

PromptController.OpenSelectUnit = Signal.new()
PromptController.SelectedUnit = Signal.new()

PromptController.OpenSelectItem = Signal.new()
PromptController.SelectedItem = Signal.new()

local SummonController;
local SystemController;
local ProfileService;
local LobbyService;
local CurrentPrompt;

local Assets = ReplicatedStorage.Assets
local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Content;
local InfoMaid;

local Rarity = {
    [1] = "Rare",
    [2] = "Epic",
    [3] = "Legendary",
    [4] = "Mythical",
    [5] = "Secret",
}

local function typeWrite(guiObject, text : string, delayBetweenChars)
    guiObject.Visible = true
    guiObject.AutoLocalize = false
    -- self.ShowSkip.Visible = true
    local displayText = text
    -- local Btn_maid = maid.new()
    local skip = false

    -- Translate text if possible
    -- if translator then
    --     displayText = translator:Translate(guiObject, text)
    -- end

    -- Replace line break tags so grapheme loop will not miss those characters
    displayText = displayText:gsub("<br%s*/>", "\n")
    displayText:gsub("<[^<>]->", "")

    -- --warn("The new dialog " .. displayText)
    -- Set translated/modified text on parent
    guiObject.Text = displayText

    local index = 0
    -- TypingSound:Play()

    -- Btn_maid:GiveTask(self.ShowSkip.Activated:Connect(function()
    --     skip = true
    -- end))

    for first, last in utf8.graphemes(displayText) do
        index = index + 1
        guiObject.MaxVisibleGraphemes = index

        if skip then
            guiObject.MaxVisibleGraphemes = text:len()
            break;
        end
        task.wait(delayBetweenChars)
    end
    -- TypingSound:Stop()
    -- Btn_maid:Destroy()
    -- self.ShowSkip.Visible = false
end

local function GetUnit(UnitsData, Hash : string)
    for pos,UnitData in UnitsData do
        if UnitData.Hash == Hash then
            return UnitData,pos
        end
    end

    return nil
end

local LastViewport;
local LastRarityActivated;

local function OpenInfoFrame(UnitData)
    local InventoryFrame = Content:WaitForChild("SelectFrame")
    local StatsFrame = InventoryFrame:WaitForChild("InfoFrame")
    -- local RarityInNumber = UnitDataModule[UnitData.Unit].Rarity
    -- local UnitRarity = Rarity[RarityInNumber]
    local Viewport = Assets.Viewports:FindFirstChild(UnitData.Unit)

    if Viewport then

        if LastRarityActivated then LastRarityActivated.Visible = false end
        if LastViewport then LastViewport:Destroy() end
        if InfoMaid then InfoMaid:Destroy() end

        UIManager:Visibility(StatsFrame, "Frame", 0)
        StatsFrame.Position = UDim2.new(0.5, 0,0.5, 0)

        InfoMaid = Maid.new()

        local IsUnitEquipped = false
        local newViewport = Viewport:Clone()
        newViewport.Size = UDim2.new(1,0,1,0)
        newViewport.Parent = StatsFrame
        newViewport.WorldModel.Animate.Enabled = true

        StatsFrame.UnitName.Text = UnitData.Unit
        StatsFrame.LevelBar.Level.Text = "Lvl. " .. UnitData.Level
        StatsFrame.LevelBar.ExpAmount.Text = UnitData.Exp .. "/"..UnitData.MaxExp .." XP"

        -- .Visible = true
        local _,_,ActualRange = UnitManager:ConvertGrade(UnitData,"Range")
        local _,_,ActualCooldown = UnitManager:ConvertGrade(UnitData,"Cooldown")
        local Equipped = ProfileService:Get("Equipped")

        -- Show trait as well(if unit has one ) -- 
        StatsFrame.Damage.Label.Text = "DMG" .. "(" ..UnitData.Stats.Damage .. "): " .. UnitManager:GetDamageWithBenefits(UnitData, "Damage")
        StatsFrame.Range.Label.Text = "RNG" .. "(" ..UnitData.Stats.Range.. "): " .. ActualRange
        StatsFrame.Cooldown.Label.Text = "CD" .. "(" ..UnitData.Stats.Cooldown.. "): " .. ActualCooldown

        StatsFrame.Visible = true

        TweenService:Create(StatsFrame,TweenInfo.new(.25),{Position = UDim2.new(1.244, 0,0.5, 0)}):Play()
        TweenService:Create(StatsFrame.Parent,TweenInfo.new(.25),{Position = UDim2.new(0.418, 0,0.5, 0)}):Play()

        LastViewport = newViewport
        -- LastRarityActivated = BackgroundFrame
    end
end

local function OpenItemInfoFrame(ItemName, ItemData)
    local InventoryFrame = Content:WaitForChild("SelectFrame")
    local StatsFrame = InventoryFrame:WaitForChild("InfoFrame")
    local RarityInNumber = 5
    local UnitRarity = Rarity[RarityInNumber]
    local Viewport = Assets.Items:FindFirstChild(ItemName, true)

    if Viewport then
        UIManager:Visibility(StatsFrame, "Frame", 1)
        StatsFrame.Position = UDim2.new(0.5, 0,0.5, 0)
        StatsFrame.Visible = true

        -- if LastRarityActivated then LastRarityActivated.Visible = false end
        if LastViewport then LastViewport:Destroy() end
        if InfoMaid then InfoMaid:Destroy() end

        InfoMaid = Maid.new()

        local IsUnitEquipped = false
        local newViewport = Viewport:Clone()
        newViewport.Size = UDim2.new(1,0,1,0)
        newViewport.Parent = StatsFrame
        -- newViewport.WorldModel.Animate.Enabled = true

        StatsFrame.UnitName.Text = ItemName
        -- StatsFrame.Level:Destroy() --.Text = "Lvl. " .. UnitData.Level

        local function GetItem()
            local Item = newViewport.WorldModel:FindFirstChildWhichIsA("BasePart") or newViewport.WorldModel:FindFirstChildWhichIsA("Model")  
            if Item then
                return Item
            end

            return nil
        end

        local Item = GetItem()
        local s = 0

        task.spawn(function()
            while newViewport do
                if Item then
                    if s >= 360 then s = 50 end
                    Item:PivotTo(Item:GetPivot() * CFrame.Angles(0,math.rad(s/360),0))
                    s += 1
                else
                    break;
                end
                task.wait()
            end
        end)

        TweenService:Create(StatsFrame,TweenInfo.new(.25),{Position = UDim2.new(1.244, 0,0.5, 0)}):Play()
        TweenService:Create(StatsFrame.Parent,TweenInfo.new(.25),{Position = UDim2.new(0.418, 0,0.5, 0)}):Play()

        LastViewport = newViewport
        -- LastRarityActivated = BackgroundFrame
    end
end

function PromptController:ConvertItems( ItemName : string )
    local ItemsFolder = ReplicatedStorage.Recipes:GetChildren()
    local Items = {}

    local function ItemData(Item)
        local n = {}

        for _,t in pairs(Item:GetChildren()) do
            if t:IsA("IntValue") then
                -- table.insert(n,{Name = t.Name, Amount = t.Value})   
                n[t.Name] = t.Value
            else
                n["Icon"] = t:Clone()
            end
        end

        return n
    end

    for _,Item in pairs(ItemsFolder) do
        local Data = ItemData(Item)
        Items[Item.Name] = Data
    end

    if ItemName then
        return Items[ItemName]
    end

    return Items
end

function PromptController.SelectItems()
    local SelectFrame = Content:WaitForChild("SelectFrame")
    local ConfirmBtn = SelectFrame:WaitForChild("Confirm")
    local LeaveBtn = SelectFrame:WaitForChild("Close")
    local Items = PromptController:ConvertItems()

    local SelectItem : string;
    local ItemName : string;
    local maid = Maid.new()
    local Selected;

    SelectFrame.Position = UDim2.new(0.5,0,0.5,0)

    -- UIManager:ClearFrame("ImageButton", SelectFrame.Content.Frame)
    UIManager:ClearFrame("TextButton", SelectFrame.Content.Frame)

    UIManager:UIOpened(SelectFrame,function()
        UIManager:ClearFrame("TextButton", SelectFrame.Content.Frame)
        maid:Destroy()
    end)

    maid:GiveTask(ConfirmBtn.Btn.Activated:Connect(function()
        print("Confirmed and selected: ", SelectItem)
        Selected = true
        maid:Destroy()
        PromptController.SelectedItem:Fire(ItemName, SelectItem)
    end))

    maid:GiveTask(LeaveBtn.Activated:Connect(function()
        maid:Destroy()
        -- UIManager:UIClose(SelectFrame)
        Selected = false
    end))

    for Name, ItemData in Items do
        local ItemFrame = UnitCreator.CreateItemIcon(Name,ItemData)
        ItemFrame.Parent = SelectFrame.Content.Frame
        ItemFrame.Size = UDim2.new(0.27,0,0.065,0)
        ItemFrame.Visible = true
        
        maid:GiveTask(ItemFrame.Activated:Connect(function()
            print("Info: ", Name, ItemData)
            SelectItem = ItemData
            ItemName = Name
            OpenItemInfoFrame(Name, ItemData)
        end))
    end
end

function PromptController.SelectUnit(OnlyShowRarity : string)
    local SelectFrame = Content:WaitForChild("SelectFrame")
    local Confirm = SelectFrame:WaitForChild("Confirm")
    local LeaveBtn = SelectFrame:WaitForChild("Close")
    local Inventory = ProfileService:Get("Inventory"):expect()
    local SelectUnit : string;
    local maid = Maid.new()
    local Selected;

    UIManager:ClearFrame("TextButton", SelectFrame.Content.Frame)
    SelectFrame.Position = UDim2.new(0.5,0,0.5,0)
    SelectFrame.InfoFrame.Visible = false

    UIManager:UIOpened(SelectFrame,function()
        maid:Destroy()
    end)

    print("Confirmed and selected: ", SelectUnit)

    _maid:AddMaid(Confirm,"Activated",Confirm.Btn.Activated:Connect(function()
        Selected = true

        warn("Unit has been selected: ", SelectUnit)
        if SelectUnit ~= nil then
            PromptController.SelectedUnit:Fire(SelectUnit.Hash, SelectUnit)
        end
    end))

    _maid:AddMaid(LeaveBtn,"Activated",LeaveBtn.Activated:Connect(function()
        maid:Destroy()
        UIManager:UIClose(SelectFrame)
        Selected = false
    end))

    for _, UnitData in Inventory.Units do
        local RarityInNumber = UnitDataModule[UnitData.Unit].Rarity
        local UnitRarity = Rarity[RarityInNumber]
        local unitFrame = UnitCreator.CreateUnitIcon(UnitData.Unit,UnitData)
        unitFrame.Parent = SelectFrame.Content.Frame
        unitFrame.Size = UDim2.new(0.15, 0,0.1, 0)
        
        -- UIManager:OnMouseChangedWithCondition(UnitUI,UDim2.new(0.115 + .015, 0,0.1 + 0.005, 0), OriginalSize,"ViewportFrame")
        -- UIManager:AddEffect(unitFrame,UnitRarity)
        _maid:AddMaid(unitFrame,"Activated",unitFrame.Activated:Connect(function()
            SelectUnit = UnitData
            OpenInfoFrame(UnitData)
        end))

        -- if OnlyShowRarity and UnitRarity ~= OnlyShowRarity then
        --     unitFrame:Destroy()
        -- end
    end
end

local lastmaid;

function PromptController:Activate(Prompt, Action : string, player, CustomPrompt)
    local DialogBox = Content:WaitForChild("Chatbox")
    local PromptParent = Prompt.Parent
    local Type = Prompt:GetAttribute("Type")
    local ViewportPromise;

    Cutscene.DisableUI(player, "HUD", false)
    DialogBox.Dialog.Text = ""
    CurrentPrompt = nil

    LobbyService:DialogMode(true,PromptParent.CFrame.Position)

    -- task.wait(.25)
    if not Type then
        local success, policyInfo = pcall(function()
            return PolicyService:GetPolicyInfoForPlayerAsync(player)
        end)

        if success then
            if policyInfo.ArePaidRandomItemsRestricted then --! USE THIS TO DISABLE SUMMONING IF NOT ALLOWED IN THE COUNTRY
                -- Disable any policy-violating features
            end
        end

        if Action == "Summon" then
            SummonController.OpenRequestSummon:Fire()
        end
    else
        local Text = Dialog[Action]
        local Tween, buttonMaid
        local NpcName = Prompt:GetAttribute("NpcName")

        if not NpcName then
            DialogBox.ViewWindow.Visible = false
        else -- Add the viewport
            UIManager:ClearFrame("ViewportFrame",DialogBox.ViewWindow)
            UIManager:HideHUD(true)

            ViewportPromise = Promise.new(function(resolve, reject, cancel)
                local _,NpcViewport = UnitCreator.CreateUnitIcon(NpcName)

                if NpcViewport then
                    NpcViewport.Parent = DialogBox.ViewWindow 

                    local UICorner = Instance.new("UICorner")
                    UICorner.CornerRadius = UDim.new(200,0)
                    UICorner.Parent = NpcViewport
                else
                    cancel()
                end
            end):catch(function(error)
                warn(error)
            end)

            DialogBox.NpcName.Text = NpcName
            DialogBox.NpcNameShadow.Text = NpcName
            DialogBox.ViewWindow.Visible = true
        end

        Tween, buttonMaid = UIManager:OpenDialog(DialogBox,PromptParent,function()
            if lastmaid then lastmaid:Destroy() end

            lastmaid = buttonMaid
            SystemController["OpenRequest"..Action]:Fire()

            LobbyService:DialogMode(false, PromptParent.CFrame.Position) --! Maybe move this to UIOPEN on the closed function
            task.delay(.5,function()
                CustomPrompt.Adornee = Prompt.Parent
            end)

            ViewportPromise:cancel()
            UIManager:CloseDialog(DialogBox) 
        end,
        function() -- Happens when dialog gets closed
            LobbyService:DialogMode(false, PromptParent.CFrame.Position)
        end)

        UIManager:CloseToolbar()

        DialogBox.Accept.Text = "Click here to continue..." -- Action
        -- DialogBox.Close.Text = "..."

        Tween.Completed:Connect(function()
            typeWrite(DialogBox.Dialog,Text)
        end)
    end
end

function PromptController.SelectFirstUnit()
    local ViewportModule = require(ReplicatedStorage.Shared.Utility.ViewportModule)
    local SelectionFrame = Content.Parent:FindFirstChild("SelectionFrame")
    local Animations = ReplicatedStorage.Assets.Animations

    local Count = 1
    local Units = {
        ["Pirate King"] = {UIPosition = UDim2.fromScale(), ViewportPosition = CFrame.new(2,0,-3.5)},
        ["Leaf Ninja"] = {UIPosition = UDim2.fromScale(), ViewportPosition = CFrame.new(0,0,-3.5)},
        ["Curse King"] = {UIPosition = UDim2.fromScale(), ViewportPosition = CFrame.new(-2,0,-3.5)}
    }

    local Highlights = {}
    Cutscene.DisableUI(player,"Content", false)

    if SelectionFrame then

        local Label = Instance.new("TextLabel")
        Label.Text = "Choose starter Unit!"
        Label.TextScaled = true
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(255,255,255)
        Label.Size = UDim2.fromScale(.5,.15)
        Label.Font = Enum.Font.FredokaOne
        Label.AnchorPoint = Vector2.new(.5,.5)
        Label.Position = UDim2.fromScale(.5,.05)
        Label.Parent = SelectionFrame

        local UIStroke = Instance.new("UIStroke")
        UIStroke.Parent = Label
        UIStroke.Thickness = 4

        SelectionFrame.Visible = true
        SummonModule:SetDepthOfField(true, 2.36, true)

        for Unit, UnitInfo in pairs(Units) do
            local Button : TextButton = SelectionFrame:FindFirstChild(Count)
            local CameraCFrame,Camera = SummonModule:CameraGetCFrame()
            local SummonedUnit = SummonModule:GetUnit(Unit,CameraCFrame * CFrame.new(0,2,-3) * CFrame.Angles(0,math.rad(180),0))--createTracePart(player,CameraCFrame * CFrame.new(0,0,-3))
            local relativeCFrame = CameraCFrame * UnitInfo.ViewportPosition * CFrame.Angles(0,math.rad(180),0)
            local Particle = SummonModule:GetParticle("Summon")

            SummonedUnit.Parent = Camera
            SummonedUnit:PivotTo(relativeCFrame)

            Particle.upgrade.Parent = SummonedUnit.PrimaryPart

            local Highlight = Instance.new("Highlight")
            Highlight.FillColor = Color3.fromRGB()
            Highlight.FillTransparency = 0
            Highlight.OutlineTransparency = 1
            Highlight.Parent = SummonedUnit

            Highlights[Unit] = {
                Unit = SummonedUnit,
                Highlight = Highlight,
            }

            if Button then
                local Clicked;

                local NumberValue = Instance.new("NumberValue")
                NumberValue.Parent = SummonedUnit
                local SizeStart = .6

                NumberValue.Changed:Connect(function(value)
                    SummonedUnit:ScaleTo(NumberValue.Value)
                end)

                local Hover = _maid:AddMaid(Button,"HoverOver", Button.MouseEnter:Connect(function()
                    TweenService:Create(Highlight,TweenInfo.new(.25),{ OutlineTransparency = 0}):Play()
                    TweenService:Create(Highlight,TweenInfo.new(.25),{ FillTransparency = 1}):Play()
                    Shortcut:PlaySound("MouseHover", true)

                    local NumberTween = TweenService:Create(NumberValue, TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Value = .452})
                    NumberValue.Value = .35
                    NumberTween:Play()
                end))

                local Hover_end = _maid:AddMaid(Button,"HoverEnd", Button.MouseLeave:Connect(function()
                    TweenService:Create(Highlight,TweenInfo.new(.25),{ OutlineTransparency = 1}):Play()
                    TweenService:Create(Highlight,TweenInfo.new(.25),{ FillTransparency = 0}):Play()

                    local NumberTween = TweenService:Create(NumberValue, TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Value = .35})
                    NumberValue.Value = .452
                    NumberTween:Play()
                end))

                _maid:AddMaid(Button,"Activated", Button.Activated:Connect(function()
                    Hover:Destroy()
                    Hover_end:Destroy()
                    
                    TweenService:Create(Highlight,TweenInfo.new(.25),{ OutlineTransparency = 0}):Play()
                    TweenService:Create(Highlight,TweenInfo.new(.25),{ FillTransparency = 1}):Play()
                    Shortcut:PlaySound("MouseClick", true)

                    for unitName, UnitData in pairs(Highlights) do
                       if unitName ~= Unit then
                            TweenService:Create(UnitData.Unit.PrimaryPart,TweenInfo.new(.35),{CFrame = relativeCFrame * CFrame.new(0, -7, 0) }):Play()
                       end 
                    end

                    TweenService:Create(SummonedUnit.PrimaryPart,TweenInfo.new(.35),{CFrame = CameraCFrame * CFrame.new(0,0,-3.5) * CFrame.Angles(0,math.rad(180),0) }):Play()
                    task.delay(.375, function()
                        Shortcut:PlaySound("Claim", true)
                        SummonModule:Emit(SummonedUnit, 5)
                        task.wait(.5)
                        TweenService:Create(SummonedUnit.PrimaryPart,TweenInfo.new(1),{CFrame = CameraCFrame * CFrame.new(0,-7,-3.5) * CFrame.Angles(0,math.rad(180),0) }):Play()
                        SummonModule:SetDepthOfField(false)
                        LobbyService:PickFirstUnit(Unit)
                        SelectionFrame:Destroy()
                    end)
                end))
            end

            local Animation = Animations:FindFirstChild(Unit .."Idle", true)
            if Animation then
                local AnimationController = SummonedUnit:FindFirstChild("Humanoid") or SummonedUnit:FindFirstChild("AnimationController") 
                if AnimationController then
                    local Anim = AnimationController.Animator:LoadAnimation(Animation)
                    Anim:Play()
                end
            end

            Count += 1
        end
    end
end

function PromptController:KnitInit()

end

function PromptController:KnitStart()
    local PromptFolder = workspace.Important
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    local CustomPrompt = playerGui:WaitForChild("CustomPrompt")
    Content = Core:WaitForChild("Content")

    ProfileService = Knit.GetService("ProfileService")
    SystemController = Knit.GetController("SystemController")
    SummonController = Knit.GetController("SummonController")
    LobbyService = Knit.GetService("LobbyService")

    PromptController.OpenSelectUnit:Connect(PromptController.SelectUnit)
    PromptController.OpenSelectItem:Connect(PromptController.SelectItems)
    LobbyService.FirstTimeJoined:Connect(PromptController.SelectFirstUnit)

    UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
        if UserInputService.GamepadEnabled then
            CustomPrompt.Button.Controller.Visible = true
        else
            CustomPrompt.Button.Controller.Visible = false
        end
    end)

	UserInputService.InputBegan:Connect(function(input)
		if CurrentPrompt and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and
			input.UserInputState ~= Enum.UserInputState.Change then
			CurrentPrompt:InputHoldBegin()
			buttonDown = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if CurrentPrompt and input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			if buttonDown then
				buttonDown = false
				CurrentPrompt:InputHoldEnd()
			end
		end
	end)

    ProximityPrompt.PromptShown:Connect(function(prompt, inputType)
        CustomPrompt.Adornee = prompt.Parent
        CustomPrompt.Button.ActionText.Text = prompt.ActionText
        CustomPrompt.Button.Button.Text = prompt.KeyboardKeyCode.Name
        CustomPrompt.Enabled = true
        CurrentPrompt = prompt
    end)

    ProximityPrompt.PromptHidden:Connect(function(prompt)
        CustomPrompt.Enabled = false
        CurrentPrompt = nil
        CustomPrompt.Adornee = nil
    end)

    ProximityPrompt.PromptButtonHoldBegan:Connect(function(prompt)
        local bar = CustomPrompt.Button.Fillbar
        TweenService:Create(CustomPrompt.Button.Button,TweenInfo.new(.15),{Size = UDim2.new(0.75, 0,0.5, 0)}):Play()
        TweenService:Create(bar,TweenInfo.new(prompt.HoldDuration),{Size = UDim2.new(1,0,1,0)}):Play()
    end)

    ProximityPrompt.PromptButtonHoldEnded:Connect(function(prompt)
        local bar = CustomPrompt.Button.Fillbar
        TweenService:Create(CustomPrompt.Button.Button,TweenInfo.new(.15),{Size = UDim2.new(0.941, 0,0.614, 0)}):Play()
        TweenService:Create(bar,TweenInfo.new(prompt.HoldDuration),{Size = UDim2.new(1,0,0,0)}):Play()
    end)

    ProximityPrompt.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
        local Action = prompt:GetAttribute("Action")
        if Action then
            PromptController:Activate(prompt, Action, playerWhoTriggered, CustomPrompt)
            CustomPrompt.Adornee = nil
        end
    end)

    task.delay(2,function()
    end)
end

return PromptController