local Toolbar = {}
--//Singleton Creation
setmetatable(Toolbar,require(script.Parent))
Toolbar.__index = Toolbar
--//Depdendancies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Network = require(game.ReplicatedStorage.Shared.Utility.Network)
local BuildManager = require(game.ReplicatedStorage.Shared.BuildManager);
local Units = require(game.ReplicatedStorage.SharedPackage.Units)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)
local Knit = require(ReplicatedStorage.Packages.Knit)

local UnitStorage = game.ReplicatedStorage.Units
local Assets = ReplicatedStorage.Assets

function Toolbar:Init()
	local Holder = self:GetUI(script.Name);
	-- local ProfileService = Knit.GetService("ProfileService")
	local PlayerService = Knit.GetService("PlayerService")
	local PlayerObject = self.PlayerObj

	if RunService:IsStudio() then

	 --Uncomment this to add your own units
	Toolbar.Units = {
		{Level = 1; Unit = "Thorfinn", Stats = {Damage = "D", Cooldown = "C", Speed = "F-"}};
		{Level = 1; Unit = "Might Guy", Stats = {Damage = "C", Cooldown = "B-", Speed = "A-"}};	
		{Level = 1; Unit = "Cold", Stats = {Damage = "D", Cooldown = "C", Speed = "B"}};	
		{Level = 1; Unit = "Noobjo", Stats = {Damage = "D", Cooldown = "C", Speed = "F-"}};	
		{Level = 1; Unit = "Yuichiro", Stats = {Damage = "S", Cooldown = "S", Speed = "S"}};	
	}
	
	-- else
	-- 	Toolbar.Units = ProfileService:Get("Equipped"):expect() -- Comment this for testing 
	warn("Units should be added")
	end
	
	Toolbar.Holder = self.MainUI.Content.Toolbar
	--//ParamInit

	PlayerObject.Units = Toolbar.Units;
	

	PlayerService.UpdateGivenUnit:Connect(function(newUnitTable, Position)
		local AlreadyExists = table.find(Toolbar.Units, newUnitTable)

		if #PlayerObject.Units > 6 then
			table.remove(Toolbar.Units, #Toolbar.Units)
		end
		
		if (not Position or Position == 0) then
			table.insert(Toolbar.Units, newUnitTable)
		else
			table.insert(Toolbar.Units, Position, newUnitTable)
		end

		PlayerObject.Units = Toolbar.Units;
		
		Toolbar:RefreshAllSlots()
	end)

	local RotButtons = self:GetUI("RotateButtons")
	local RightRotate = false
	RotButtons.Right.MouseButton1Down:Connect(function()
		if RightRotate then
			return
		end
		RightRotate = true;
		repeat
			BuildManager:IncrementRotate(-3)
			task.wait()
		until not RightRotate or not RotButtons.Visible
	end)
	RotButtons.Right.MouseButton1Up:Connect(function()
		RightRotate = false;

	end)

	local LeftRotate = false
	RotButtons.Left.MouseButton1Down:Connect(function()
		if LeftRotate then
			return
		end
		LeftRotate = true;
		repeat
			BuildManager:IncrementRotate(3)
			task.wait()
		until not LeftRotate or not RotButtons.Visible
	end)
	RotButtons.Left.MouseButton1Up:Connect(function()
		LeftRotate = false;

	end)
	
	RotButtons.Cancel.MouseButton1Click:Connect(function()
		BuildManager:EndBuildSession();
	end)

	for i,button in pairs(Toolbar.Holder:GetChildren()) do
		if not button:IsA("TextButton") or button.Name == "Health" or button.Name == "Money" then continue end

		button.Activated:Connect(function()
			local Index = Toolbar.Units[tonumber(button.Name)]
			if not Index then
				return
			end
			if not BuildManager:IsActive() then
				BuildManager:StartBuildSession()
				local LastInp = game:GetService("UserInputService"):GetLastInputType()
				if LastInp == Enum.UserInputType.Touch or LastInp == Enum.UserInputType.Gyro or LastInp == Enum.UserInputType.Accelerometer then
					PlayerObject.IsMobile = true;
					self:GetUI("RotateButtons").Visible = true;
					
				elseif string.find(LastInp.Name,"Gamepad") then

				end
			end
			BuildManager:ChangeUnit(Index.Unit)
		end)
	end

	Toolbar:RefreshAllSlots()
end

function Toolbar:RefreshAllSlots()
    local ToolbarFrame = self.Holder
	local UnitsData = Toolbar.Units
    local UnitAmount = #UnitsData
    local Colors = {
        ["Defualt"] = Color3.fromRGB(255, 255, 255),
        ["Rare"] = Color3.fromRGB(0, 208, 255),
        ["Epic"] = Color3.fromRGB(217, 2, 255),
        ["Legendary"] = Color3.fromRGB(255, 226, 7),
        ["Mythical"] = Color3.fromRGB(255, 255, 255),
        ["Secret"] = Color3.fromRGB(255, 255, 255),
    }

	local Rarity = {
		[1] = "Rare",
		[2] = "Epic",
		[3] = "Legendary",
		[4] = "Mythical",
		[5] = "Secret",
	}


    for Pos, UnitData in UnitsData do
        local Slot = self.Holder:FindFirstChild(Pos)
        if Slot then
            local RarityInNumber = Units[UnitData.Unit].Rarity
            local UnitRarity = Rarity[RarityInNumber]

            local RarityColor = Colors[UnitRarity]
            local Viewport = Assets.Viewports:WaitForChild(UnitData.Unit,10)
            local UnitDefualtStats = Units[UnitData.Unit].Upgrades[0]
            Slot.Locked.Visible = false
            -- Slot.Empty.Visible = true

            if Viewport then
                UIManager:ClearFrame("TextButton",Slot)

                Slot.Empty.Visible = false

                local UnitUI : TextButton = UnitCreator.CreateUnitIcon(UnitData.Unit, UnitData)
                local newUnitData = Units[UnitData.Unit]
                local UnitRarity = Rarity[newUnitData.Rarity]
                UnitUI.Name = UnitData.Hash or UnitData.Unit
                UnitUI.Parent = Slot
                UnitUI.Size = UDim2.new(1,0,1,0)
                local OriginalSize = Slot.Size
                UnitUI.Visible = true
                UnitUI.Interactable = false

                UnitUI.Level:Destroy()
                UnitUI.UnitName:Destroy()
                -- UnitUI.Coin:Destroy()
                -- UnitUI.Interactable = true
                -- UIManager:AddEffect(UnitUI, UnitRarity)
                
                UIManager:OnMouseChangedWithCondition(Slot,UDim2.new(.14, 0,.48, 0), OriginalSize,"Frame")

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
    end

    if UnitAmount < 6 then
        for Pos = UnitAmount + 1, 6 do
            local Slot = self.Holder:FindFirstChild(Pos)
    
            if Slot and Slot:FindFirstChildWhichIsA("TextButton") then
                UIManager:ClearFrame("TextButton",Slot)
                Slot.Empty.Visible = true
            end
        end
    end
end
return Toolbar
