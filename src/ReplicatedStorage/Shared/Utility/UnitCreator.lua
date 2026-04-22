local UnitCreator = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedPackage = ReplicatedStorage.SharedPackage
local Assets = ReplicatedStorage.Assets
local RarityFolder = Assets.Rarity
local Units = require(SharedPackage.Units)
local Items = require(ReplicatedStorage.Shared.Items)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local _maid = MaidManager.new()

local player = Players.LocalPlayer

local Rarity = {
    [1] = "Rare",
    [2] = "Epic",
    [3] = "Legendary",
    [4] = "Mythical",
    [5] = "Secret",
}

function UnitCreator.CreateTrait(UI, UnitData)
    local _, hasTrait = pcall(function()
        return UnitData.Traits ~= nil
    end)

    if not hasTrait then return end
	
    local Trait = UnitData.Traits
    local TraitIcon = Items.TraitIcons[Trait.Name .. " " .. Trait.Level]
    local IconFrame = UI.Icons
    local Gradients = IconFrame.Gradients

    if TraitIcon then
        local ImageLabel = Instance.new("ImageLabel")
        ImageLabel.Image = TraitIcon.ImageId
        ImageLabel.Size = TraitIcon.IconSize
        ImageLabel.Name = Trait.Name
        ImageLabel.BackgroundTransparency = 1
        ImageLabel.ZIndex = 100
        ImageLabel.Parent = IconFrame
        ImageLabel:SetAttribute("IsTrait", true)

        Gradients[Trait.Name]:Clone().Parent = ImageLabel

        return ImageLabel
    end

    return nil
end

function UnitCreator.CreateUnitIcon(UnitName : string, UnitData)
    local viewport = Assets.Viewports:WaitForChild(UnitName,10)
    local EvolvedLength = "(Evolved)"
    UnitData = UnitData or {Level = 1}

    if viewport then
        local newUnitData = Units[UnitName]
        local UnitRarity = Rarity[newUnitData.Rarity]
        local newUnitViewport = viewport:Clone()
        local newRarity = RarityFolder[UnitRarity]:Clone()
        local SellImage = Assets.SellImage:Clone()

        newRarity.Name = UnitName

        if UnitName:find("(Evolved)") then
            newRarity.UnitName.Text = "⭐".. string.sub(UnitName,1,UnitName:len() - EvolvedLength:len()) .."⭐"
        else
            newRarity.UnitName.Text = UnitName
        end

        UIManager:AddEffect(newRarity,UnitRarity) --! Should have done this from the start :clown: @TheRealMasenyy1

        newUnitViewport.Parent = newRarity
        newUnitViewport.AnchorPoint = Vector2.new(.5,.5)
        newUnitViewport.Size = UDim2.new(1, 0, 1, 0)
        newUnitViewport.Position = UDim2.new(.5,0,.5,0)
        newUnitViewport.WorldModel.Animate.Enabled = true
        SellImage.Parent = newRarity

        newRarity.Coin.Text = "¥".. Units[UnitName].Upgrades[0].Cost
        newRarity.Level.Text = "Lv. " .. UnitData.Level 

        UnitCreator.CreateTrait(newRarity, UnitData)

        return newRarity, newUnitViewport, UnitRarity
    else
        warn("Could not find "..UnitName .. " viewport")
    end
end

function UnitCreator.DoesThisItemExistCurrently(ItemName : string)
    if Assets.Items:FindFirstChild(ItemName) then
        return true
    else
        return false
    end
end

function UnitCreator.CreateItemIcon(ItemName : string)
    local viewport = Assets.Items:WaitForChild(ItemName,10)

    if viewport then
        local UnitRarity = Rarity[4] -- newUnitData.Rarity
        local newUnitViewport = viewport:Clone()
        local newRarity = RarityFolder[UnitRarity]:Clone()

        newRarity.Name = ItemName
        newUnitViewport.Parent = newRarity
        newUnitViewport.AnchorPoint = Vector2.new(.5,.5)
        newUnitViewport.Size = UDim2.new(1, 0,0.8, 0)
        newUnitViewport.Position = UDim2.new(.5,0,.5,0)
        newRarity.UnitName.Position = UDim2.new(.5,0,.1,0) 

        -- newRarity.Text:Destroy()
        newRarity.Level:Destroy()
        newRarity.Coin:Destroy()
        -- newUnitViewport.WorldModel.Animate.Enabled = true

        newRarity.UnitName.Text = ItemName
        return newRarity,newUnitViewport
    else
        warn("Could not find ".. ItemName .. " viewport")
    end
end

function UnitCreator.CreateItemIconForChallenge(ItemName : string, ItemData)
    local TempUI = Assets:WaitForChild("tempUI")
    local Image = Items.Items[ItemName] or Items.Materials[ItemName]

    if TempUI and Image then
        local UnitRarity = Image.Rarity or Rarity[4] -- newUnitData.Rarity
        local newItemViewport = TempUI:Clone() --viewport:Clone()
        local newRarity = RarityFolder[UnitRarity]:Clone()

        newRarity.Name = ItemName
        newItemViewport.Parent = newRarity
        newItemViewport.Image = Image.ImageId
        newItemViewport.AnchorPoint = Vector2.new(.5,.5)
        newItemViewport.Size = Image.ImageSize or UDim2.new(1, 0, 1, 0)
        newItemViewport.Position = UDim2.new(.5,0,.5,0)

        newItemViewport.Visible = true
        newItemViewport.BackgroundTransparency = 1
        newItemViewport.Amount:Destroy()
        -- newItemViewport.Amount.Text = ItemData.Amount .."x"
        
        newRarity.UnitName.AnchorPoint = Vector2.new(.5,.5) 
        newRarity.UnitName.Position = UDim2.new(0,0,.1,0) 
        
        newRarity.Coin.AnchorPoint = Vector2.new(1,.5) 
        newRarity.Coin.Size = UDim2.new(0.624, 0,0.397, 0)
        newRarity.Coin.Position = UDim2.new(1.15,0,1,0) 
        newRarity.Coin.TextColor3 = Color3.fromRGB(255,255,255)
        newRarity.Coin.Text = ItemData.Amount .."x"

        _maid:AddMaid(newRarity,"HoverOver",newRarity.MouseEnter:Connect(function()
            UnitCreator:DisplayItemInfo(newRarity,ItemName, Image, newRarity.AbsolutePosition)
        end))

        _maid:AddMaid(newRarity,"HoverLeave",newRarity.MouseLeave:Connect(function()
            UIManager:HideItemInfo()
        end))

        newItemViewport.Percentage:Destroy() --.Text = ItemData.Percentage.."%"
        newRarity.Level:Destroy()

        if not ItemData.Percentage then
            newRarity.UnitName.Text = ItemName
        else
            newRarity.UnitName.Text = ItemData.Percentage.."%"
        end
        return newRarity, newItemViewport
    else
        warn("Could not find ".. ItemName .. " viewport")
    end
end

function UnitCreator:DisplayItemInfo(ParentUI : TextButton,ItemName, ItemData, Position : Vector2)
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core") or playerGui:WaitForChild("Main")
    local InfoFrame : Frame = Core.Content.InfoFrame

    local XOffset = ParentUI.AbsoluteSize.X + 25 --200
    local YOffset = ParentUI.AbsoluteSize.Y + 50--100

    task.wait(.05)
    local _, err = pcall(function()
        InfoFrame.ItemName.Text = ItemName
        InfoFrame.ItemRarity.Text = ItemData.Rarity
        InfoFrame.ItemDesc.Text = ItemData.Desc
        InfoFrame.Visible = true
        InfoFrame.Position = UDim2.fromOffset(Position.X + XOffset, Position.Y + YOffset)

        local StrokeEffect = UIManager:AddEffectToText(InfoFrame.UIStroke,ItemData.Rarity,0)
        local TextEffect = UIManager:AddEffectToText(InfoFrame.ItemRarity,ItemData.Rarity,0,.5)

        _maid:AddMaid(InfoFrame,"IsVisible",InfoFrame.Changed:Connect(function()
            if not InfoFrame.Visible then
                StrokeEffect:Destroy()
                TextEffect:Destroy()
            end
        end))
    end)

    if err then
        print("Error displaying item info: ", err)
    end
end
function UnitCreator.CreateRecipesIcon(ItemName : string, Amount : number, playerItemData, ItemRarity)
    local viewport = Assets.Items:WaitForChild(ItemName,10)

    if viewport then
        local Image = Items.Items[ItemName] or Items.Materials[ItemName]
        local UnitRarity = Image.Rarity or Rarity[4] -- newUnitData.Rarity
        local newUnitViewport = viewport:Clone()
        local newRarity : TextButton = RarityFolder[UnitRarity]:Clone()

        newRarity.Name = ItemName
        newUnitViewport.Parent = newRarity
        newUnitViewport.AnchorPoint = Vector2.new(.5,.5)
        newUnitViewport.Size = UDim2.new(1, 0, .8, 0)
        newUnitViewport.Position = UDim2.new(.5,0,.5,0)

        newRarity.UnitName.Position = UDim2.new(.5,0,.1,0) 
        newRarity.UnitName.AnchorPoint = Vector2.new(.5,.5) 
        
        newRarity.Coin.Text = playerItemData.Amount .." / " .. Amount
        newRarity.Coin.TextColor3 = Color3.fromRGB(238, 9, 9)

        _maid:AddMaid(newRarity,"HoverOver",newRarity.MouseEnter:Connect(function()
            UnitCreator:DisplayItemInfo(newRarity,ItemName, Image, newRarity.AbsolutePosition)
        end))

        _maid:AddMaid(newRarity,"HoverLeave",newRarity.MouseLeave:Connect(function()
            UIManager:HideItemInfo()
        end))

        UIManager:AddEffect(newRarity, ItemRarity or UnitRarity, 0.7)
        
        if playerItemData.Amount >= Amount then
            newRarity.Coin.TextColor3 = Color3.fromRGB(255, 255, 255)
        end

        newRarity.Level:Destroy()

        newRarity.UnitName.Text = ItemName
        return newRarity, newUnitViewport
    else
        warn("Could not find ".. ItemName .. " viewport")
    end
end

function UnitCreator:InsertToInventory(UnitData)

end

return UnitCreator
