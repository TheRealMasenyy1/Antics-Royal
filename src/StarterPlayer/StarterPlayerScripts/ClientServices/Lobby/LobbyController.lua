local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local PurchaseIds = require(ReplicatedStorage.SharedPackage.PurchaseIds)

local LobbyController = Knit.CreateController {
    Name = "LobbyController",
}

local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local _maid = MaidManager.new()

local BattlepassFolder = ReplicatedStorage.Battlepass
local Assets = ReplicatedStorage.Assets
local Items = Assets.Items

local Content
local ProfileService;
local ProductService;
local QuestsService

LobbyController.OpenBattlepass = Signal.new()

local function UpdateLevelBar()
    -- local BattleFrame = Content:WaitForChild("BattlePass")
    -- local BattleContent = BattleFrame:WaitForChild("ScrollingFrame").Frame
    -- local XP = BattleFrame:WaitForChild("XP")
    -- local LevelFrame = BattleContent:WaitForChild("LevelBar")
    -- local PremiumFrame = BattleContent:WaitForChild("Premium")
    -- local FreeFrame = BattleContent:WaitForChild("Free")
    -- local Expbar = XP.Expbar.bar

    -- local Battlepass = ProfileService:Get("Battlepass")
    -- local barGroup = LevelFrame.barGroup
    -- local bar = barGroup.bar

    -- Battlepass:andThen(function(Data)
    --     local Tween = TweenService:Create(bar, TweenInfo.new(.5), { Size = UDim2.new(0.025 * Data.Level,0,1,0)})
    --     local Tweenbar = TweenService:Create(Expbar, TweenInfo.new(.5), { Size = UDim2.new(Data.Exp / Data.MaxExp,0,1,0)})
    --     Tweenbar:Play()
    --     Tween:Play()
    -- end)
end

local function returnChildren(Folder : Folder)
    local Child;
    for _, child in pairs(Folder:GetChildren()) do
        Child = child
    end
    return Child
end

local function CheckCollected(Battlepass,Frame, BattlePassOwned)
    local Season = Battlepass.Season
    local Level = Battlepass.Level
    local Rewards = Battlepass.Rewards
    local pass = BattlepassFolder["Season"..Season]
    local Amount = #pass:GetChildren()

    local Types = {
        "Free",
        "Premium"
    }

    for i = 1, Amount do
        local Tier = pass[i] -- Contains a Free and Premium Version

        for x = 1, #Types do
            local Type = Types[x]
            local Reward : IntValue | StringValue = returnChildren(pass[i]) -- Contain Reward
            local RewardButton = Frame[i][Type]

            if Level >= i and Type == "Free" or (Type == "Premium" and  BattlePassOwned) then --! Removing this doesn't mean that you get the reward :clown:
                local IsCollected = Rewards[Type][tostring(i)]
                RewardButton.Locked.Visible = false

                if IsCollected then
                    RewardButton.Unlocked.Visible = true
                end
            end
        end
    end
end

local function LoadBattlepass(BattleFrame, BattleData, BattlePassOwned)
    local BattleContent = BattleFrame:WaitForChild("ScrollingFrame")
    local TempFolder = BattleContent.Temp
    -- local LevelFrame = BattleContent:WaitForChild("LevelBar")
    -- local PremiumFrame = BattleContent:WaitForChild("Premium")
    -- local FreeFrame = BattleContent:WaitForChild("Free")
    local BattlepassLevel = BattleData.Level
    local Season = BattleData.Season
    local Rewards = BattleData.Rewards

    local function placeIcons()
        local pass = BattlepassFolder["Season"..Season]
        local Amount = #pass:GetChildren()
        local Types = {
            "Free",
            "Premium"
        }

        warn("Do you own the gamepass: ", BattlePassOwned)

        for i = 1, Amount do
            local Tier = pass[i] -- Contains a Free and Premium Version
            for x = 1, #Types do
                local Type = Types[x]
                local Reward : IntValue | StringValue = returnChildren(Tier[Type]) -- Contain Reward
                local RewardButton = BattleContent[i][Type]
    
                if BattlepassLevel >= i and Type == "Free" or (BattlepassLevel >= i and Type == "Premium" and BattlePassOwned) then --! Removing this doesn't mean that you get the reward :clown:
                    local IsCollected = Rewards[Type][tostring(i)]
                    RewardButton.Locked.Visible = false
    
                    if IsCollected then
                        RewardButton.Unlocked.Visible = true
                    end
                end
    
                if Reward.Name ~= "Unit" then
                    local Item = Items:FindFirstChild(Reward.Name, true)
                    
                    if Item then
                        local newItem = UnitCreator.CreateItemIconForChallenge(Reward.Name,{Amount = Reward.Value}) --Item:Clone()
                        newItem.Size = UDim2.new(1, 0,1, 0)
                        newItem.UnitName.Visible = false
                        newItem.Parent = RewardButton
                        newItem.Visible = true
                        newItem.UIAspectRatioConstraint:Destroy()
                    else
                        warn("Could not find the Item: ", Reward.Name)
                    end
                elseif Reward.Name == "Unit" then
                    local UnitUI : TextButton, _, Rarity = UnitCreator.CreateUnitIcon(Reward.Value)
                    UnitUI.Name = Reward.Name
                    UnitUI.Parent = RewardButton
                    UnitUI.Size = UDim2.new(1,0,1,0)
                    UnitUI.Visible = true
                    UnitUI.Interactable = false
                    
                    UnitUI.UIAspectRatioConstraint:Destroy()
                    UnitUI.Coin:Destroy()
                    UnitUI.Level:Destroy()
                    UnitUI.UnitName:Destroy()
    
                    -- UIManager:AddEffect(UnitUI, Rarity)
                end
            end
        end
    end

    local function AddIcons()
        local pass = BattlepassFolder["Season"..Season]
        local Amount = #pass:GetChildren()

        for i = 1, Amount do
            local newClone = TempFolder.Tier:Clone()
            newClone.Parent = BattleContent
            newClone.Name = i
            newClone.Level.LevelText.Text = "Level " .. i
            newClone.Visible = true
        end

    end

    -- UpdateLevelBar()
    AddIcons()

    task.spawn(placeIcons,BattleContent)
end

function format(num)
    local formatted = string.format("%.2f", math.floor(num*100)/100)
    if string.find(formatted, ".00") then
        return string.sub(formatted, 1, -4)
    end
    return formatted
end

function CountCollectable(Table, BattlePassOwned ) : number
    local Count : number = 0

    for Type, Children in Table do
        for Key, Value in Children do
            if Value and Type == "Free" or (Value and Type == "Premium" and BattlePassOwned) then
                Count += 1
            end
        end
    end

    return Count
end

-- Claim button when there is nothign to claim --> 36, 36, 36 else --> 132, 247, 0
function LobbyController.OpenBPS() -- Open BattlePass
    local BattlePass = Content:WaitForChild("BattlePass")
    local BattleContent = BattlePass:WaitForChild("ScrollingFrame")

    local PurchaseBattlepass = BattlePass:WaitForChild("BattlePassBtn")
    local BuyFrame = PurchaseBattlepass:WaitForChild("BuyFrame")
    local Btn = BuyFrame:WaitForChild("Btn")

    local Claim : TextButton = BattlePass:WaitForChild("Claim")
    local XP = BattlePass:WaitForChild("XP") 
    local Level = BattlePass:WaitForChild("Level") 

    local BattlePassData = ProfileService:Get("Battlepass") 
    local BattlePassOwned = ProductService:GetPlayerPurchase(PurchaseIds.Gamepasses.BattlePassSeasonOne):expect()

    local function checkClaimable()
        local Claimable = QuestsService:CheckBattlepass():expect()
        local Collectable = CountCollectable(Claimable, BattlePassOwned)

        -- Claim.Amount.Text = "Claim: ".. Collectable
        print("Check Claimable: ", Claimable, Collectable)
        if Collectable >= 1 then
            Claim.UIGradient.Enabled = true
            Claim.UIStroke.UIGradient.Enabled = true

            Claim.SelectedUI.Enabled = false
            Claim.UIStroke.SelectedUI.Enabled = false

            Claim.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Claim.Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            Claim.UIGradient.Enabled = false
            Claim.UIStroke.UIGradient.Enabled = false

            Claim.SelectedUI.Enabled = true
            Claim.UIStroke.SelectedUI.Enabled = true
            Claim.Btn.TextColor3 = Color3.fromRGB(76, 76, 76)
        end
    end

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

    UIManager:HoverOver(Btn)
    UIManager:OnMouseChanged(BuyFrame,UDim2.fromScale(0.5,0.2),BuyFrame.Size)
    _maid:AddMaid(Btn,"Activated",Btn.Activated:Connect(function()
        local ProductType, ProductId = GetProduct(Btn:GetAttribute("Product"))
        Shortcut:PlaySound("MouseClick")

        print("The maid has been pressed: ", ProductType, ProductId)
        if ProductType == "Products" then
            print("This is a product: ", ProductId)
            MarketplaceService:PromptProductPurchase(player,ProductId)
        else
            print("This is a Gamepass: ", ProductId)
            MarketplaceService:PromptGamePassPurchase(player,ProductId)
        end
    end))   

    checkClaimable()

    _maid:AddMaid(Claim.Btn,"Activated",Claim.Btn.Activated:Connect(function()
        print("CLICKED THE CLAIM BTN")
        QuestsService:ClaimBattlePass():andThen(function(Collected, newBattlepass)
            if Collected then
                Shortcut:PlaySound("Claim", true)
                checkClaimable()
                task.spawn(CheckCollected,newBattlepass,BattleContent,BattlePassOwned)
            end
        end)
    end))
    
    BattlePassData:andThen(function(BattleData)
        UIManager:UIOpened(BattlePass,function()
            --- Do something OnClose
        end)
        
        Level.Text = "Lv. " .. BattleData.Level
        XP.Text = format(BattleData.Exp) .. "/" .. format(BattleData.MaxExp) --.. " XP"

        LoadBattlepass(BattlePass,BattleData, BattlePassOwned )
    end):await()
end

function LobbyController:KnitInit()

end

function LobbyController:KnitStart()
    local PlayerGui = player:WaitForChild("PlayerGui")
    local Core = PlayerGui:WaitForChild("Core")
    Content = Core:WaitForChild("Content")

    QuestsService = Knit.GetService("QuestsService")
    ProfileService = Knit.GetService("ProfileService")
    ProductService = Knit.GetService("ProductService")
    local PlayerService = Knit.GetService("PlayerService")

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.KeyCode == Enum.KeyCode.B then
            PlayerService:TestExp()
            -- LobbyController.OpenBPS()
        end
    end)


    QuestsService.UpdateBattleLevel:Connect(UpdateLevelBar)
    LobbyController.OpenBattlepass:Connect(LobbyController.OpenBPS)
end

return LobbyController