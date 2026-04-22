local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local Grades = require(ReplicatedStorage.SharedPackage.Grades)
local Units = require(ReplicatedStorage.SharedPackage.Units)
local Hitbox = require(ReplicatedStorage.Shared.Utility.Hitbox)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local UISpring = require(ReplicatedStorage.Shared.Utility.UISpring)

--local Signal = require(ReplicatedStorage.Packages.Signal)

local UnitController = Knit.CreateController {
    Name = "UnitController",
}

local player = game:GetService("Players").LocalPlayer
local Detectors = workspace.GameAssets.Units.Detectors
local Mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local Assets = ReplicatedStorage.Assets
local Animations = Assets.Animations
local LoadedEmotes = {}
local UnitService
local UIController

local InteractionMaid;
local MousePosition;
local UnitService;
local MatchService;
local UnitViewing;
local UnitViewingInfo;
local UpgradeIsOpened = false

local playerGui = player:WaitForChild("PlayerGui")
local UnitInfo = playerGui:WaitForChild("UnitInfo")

local Core = playerGui:WaitForChild("Main")
local Content = Core:WaitForChild("Content")

local ToolbarUI = Content:WaitForChild("Toolbar")

local ButtonConnections = {}

function UnitController:CloseInteraction(Unit)
	local Detector = Detectors:FindFirstChild(Unit:GetAttribute("Id")) 
	local SelectUnit = workspace.Debris:FindFirstChild("SelectUnit")
	--local UnitInfoFolder = playerGui.UnitInfoFolder

	if Detector then
		--UnitInfoFolder:ClearAllChildren()
		Detector.Transparency = 1 
	end

	if SelectUnit then
		SelectUnit:Destroy()
	end

	UnitViewingInfo = nil
	UnitInfo.Enabled = false
end

function ClearFrame(ParentFrame)
	for _,Frames in ParentFrame:GetChildren() do
		if Frames:IsA("Frame") then
			Frames:Destroy()
		end
	end
end

function UnitController:GetGrade(UnitInfo, StatName : string)
	local UnitStats = UnitInfo.Stats
	local Grades = Grades.Ranks
	local ActualGrade = UnitStats[StatName]
	local GradeValue = Grades[ActualGrade]

	return GradeValue, ActualGrade
end

function UnitController:ShowStats(Unit, UI, Level, UnitInfo)
	--- Get the players unit
	local MainFrame = UI.Frame
	local UpgradesFrame = MainFrame:WaitForChild("UpgradeStat")
	local TempFolder = UpgradesFrame.temp
	local UpgradeButton = MainFrame.Upgrade
	
	local UnitUpgrades = Units[Unit.Name].Upgrades	
	ClearFrame(UpgradesFrame)

	MainFrame.UpgradeHeader.Text = "Upgrade[" .. Level .. "]" 
	local ActualStat ;
	local StatLogos = {
		["Range"] = "rbxassetid://106476292437407",
		["Cooldown"] = "rbxassetid://121634661870252"
	}

	local is_string = #UnitInfo.AbilityForLevel
	local New_Attack = UnitInfo.AbilityForLevel[Level+1] or false

	if is_string == 0 then
		New_Attack = UnitInfo.AbilityForLevel[tostring(Level+1)] or false
	end

	if UnitInfo.Ability == New_Attack then
		New_Attack = false
	end

	--local New_Attack = UnitInfo.AbilityForLevel[Level+1] or false

	--print(UnitUpgrades[Level])
	--print(UnitInfo)
	for StatsName, Values in pairs(UnitUpgrades[Level]) do
		local Upgrades = #UnitUpgrades
		local NextLevel = if Level < Upgrades then Level + 1 else Level

		if StatsName ~= "Cost" then
			if StatsName ~= "Damage" then
				_,_,ActualStat = UnitManager:ConvertGradeInGame(UnitInfo,StatsName,Level)
			else
				ActualStat = UnitManager:GetDamageWithBenefitsInGame(UnitInfo, "Damage")
			end

			UI.Frame[StatsName].TextLabel.Text = ActualStat

			local Frame = TempFolder.Frame:Clone()
			Frame.Visible = true
			Frame.Parent = UpgradesFrame

			if StatLogos[StatsName] then
				local ImageFrame = Instance.new("ImageLabel")
				ImageFrame.Size = Frame.Button.Size
				ImageFrame.Position = Frame.Button.Position
				ImageFrame.AnchorPoint = Frame.Button.AnchorPoint
				ImageFrame.BackgroundTransparency = 1
                ImageFrame.Image = StatLogos[StatsName]
                ImageFrame.Parent = Frame

				for _,child in pairs(Frame.Button:GetChildren()) do
					child:Clone().Parent = ImageFrame
				end

				Frame.Button:Destroy()

				ImageFrame.Name = "Button"
			end

			if StatsName == "Damage" then
				local DamageColor = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromHex("#ed71a1")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("#eb4744")),
				}
				Frame.Current.UIGradient.Color = DamageColor
				Frame.Button.UIGradient.Color = DamageColor
			elseif StatsName == "Cooldown" then
				local CooldownColor = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromHex("#ec7aea")),
					ColorSequenceKeypoint.new(.5, Color3.fromHex("#d8e9e2")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("#b34aec")),
				}
				Frame.Current.UIGradient.Color = CooldownColor
				Frame.Button.UIGradient.Color = CooldownColor
			end

			if Level < Upgrades then
				if NextLevel ~= Level then
					local _,_,NextActualStat = UnitManager:ConvertGradeInGame(UnitInfo,StatsName,NextLevel)
					-- Frame.Current.Text = string.format("%.1f",Values * GradeValue)
					-- Frame.Next.Text = string.format("%.1f", UnitUpgrades[NextLevel][StatsName] * GradeValue)

					Frame.Current.Text = ActualStat.. " >"
					Frame.Next.Text = NextActualStat
				else
					Frame.Current.Text = ActualStat
					Frame.Next.Visible = false
					Frame.TextLabel.Visible = false
				end
			else
				Frame.Current.Text = ActualStat
				Frame.Next.Text = "Max"

				UpgradeButton.BackgroundColor3 = Color3.fromRGB(108, 108, 108)
				UpgradeButton.UIGradient.Enabled = false
				--UpgradeButton.Enabled = false

				UpgradeButton.Text.Text = "Max"
			end
		elseif StatsName == "Cost" then
			UpgradeButton.Text.Text = "$" .. UnitUpgrades[NextLevel][StatsName]
		else
			--print("[ LOG ] - The player has gotten his stuff ---> ", Units_Data[Unit].Upgrades[Level])
		end		
	end

	if New_Attack then
		local Frame = TempFolder.NewSkill:Clone()
		Frame.Visible = true
		Frame.Parent = UpgradesFrame

		Frame.Current.Text = New_Attack

		UIManager:AddEffectToText(Frame.Current,"Mythical",0)
		UIManager:AddEffect(Frame.Button,"Mythical",0,0)

		
	end
end

function UnitController.VisualizeHitbox(Unit)
	local UnitHitbox;
	local UnitInfo 
	
	local UnitInfoPromise = UnitService:GetUnitInfo(Unit:GetAttribute("Id"))
	
	UnitInfoPromise:andThen(function(UnitData)
		UnitInfo = UnitData
	end):await()

	while UpgradeIsOpened do
		
		if UnitInfo.Target then
			local HitboxType = UnitInfo.AbilityHitbox[UnitInfo.Ability].Type

			if HitboxType == "Throw" or HitboxType == "ThrowAndDamageOverTime" then
				UnitHitbox = Hitbox.ThrowVisualize(Unit,UnitInfo.Target,UnitInfo.AbilityHitbox[UnitInfo.Ability])
			elseif HitboxType == "BeamAndDamageOverTime" or HitboxType == "Beam" then
				UnitHitbox = Hitbox.BeamVisualize(Unit,UnitInfo.Target,UnitInfo.AbilityHitbox[UnitInfo.Ability],UnitInfo.Range)
			elseif HitboxType == "AOE" or HitboxType == "AOEAndDamageOverTime"  then 
				UnitHitbox = Hitbox.AOEVisualize(Unit,UnitInfo.Target,UnitInfo.AbilityHitbox[UnitInfo.Ability],UnitInfo.Range)
			end
		end

		UnitInfoPromise = UnitService:GetUnitInfo(Unit:GetAttribute("Id"))
		
		UnitInfoPromise:andThen(function(UnitData)
			UnitInfo = UnitData
		end)

		task.wait()
	end

	Hitbox.Transparency(UnitHitbox,1)
end

function Emit(Part)
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function UnitController:OpenInteraction(Unit : Model)
	local Cash = player.leaderstats:FindFirstChild("Cash")
	local Detector = Detectors:FindFirstChild(Unit:GetAttribute("Id")) 
	local Owner = Unit:GetAttribute("Owner")
	--local UnitInfoFolder = playerGui.UnitInfoFolder

	if Detector then
		UnitViewing = Unit
		Shortcut:PlaySound("MouseClick") -- Play audio

		local newUnitInfo : ScreenGui = UnitInfo; UnitViewingInfo = newUnitInfo ---:Clone();
		--local Buttons = newUnitInfo.Frame.Buttons
		local UpgradeButton = newUnitInfo.Frame.Upgrade
		local SellButton = newUnitInfo.Frame.Sell
		local TargetButton = newUnitInfo.Frame.Target
		local SelectUnitVFX = ReplicatedStorage.Assets.SelectUnit:Clone()

		if InteractionMaid then InteractionMaid:Destroy() end

		local UnitInfoPromise = UnitService:GetUnitInfo(Unit:GetAttribute("Id"))
		local UnitInfo;
		local UnitUpgrades = Units[Unit.Name].Upgrades

		InteractionMaid = Maid.new()

		local function UpdateDamage(Attribute)
			local UI
			local succ, err = pcall(function()
				UI = newUnitInfo.Frame
			end)

			if succ and Attribute == "TotalDamage" and newUnitInfo then
				--UI.TotalDamage.Amount.Text = Unit:GetAttribute("TotalDamage")
			end
		end

		local function GetButtonsInButton(Btn : TextButton, _callback)
			for _, button in pairs(Btn:GetDescendants()) do
				if button:IsA("TextButton") then
					InteractionMaid:GiveTask(button.MouseButton1Up:Connect(_callback))
				end
			end
		end

		InteractionMaid:GiveTask(Unit.AttributeChanged:Connect(UpdateDamage))

		UnitInfoPromise:andThen(function(UnitData)
			UnitInfo = UnitData
			newUnitInfo.Frame.TotalDamage.Amount.Text = UnitData.TotalDamage
			newUnitInfo.Frame.UpgradeHeader.Text = "Upgrade [" .. UnitData.Level .. "]" 
			newUnitInfo.Frame.Target.Text.Text = UnitData.Targeting
		end):await()

		task.spawn(UnitController.VisualizeHitbox, Unit)
		local UnitFrame = newUnitInfo.Frame
		--Size it should be = {0.327, 0},{0.307, 0}
		-- Position it should be = {0.175, 0},{0.5, 0}
		
		UnitFrame.Size = UDim2.fromScale(0,0)

		UISpring.target(UnitFrame,.5,2,{
			Size = UDim2.fromScale(.327,.307)
		})

		newUnitInfo.Enabled = true

		UnitController:ShowStats(Unit,newUnitInfo,UnitInfo.Level or 0,UnitInfo)

		SelectUnitVFX.CFrame = Unit:GetPivot()
		SelectUnitVFX.Parent = workspace.Debris

		Detector.Transparency = 0

		newUnitInfo.Frame.ItemBox.Text.Text = Unit.Name

		if newUnitInfo.Frame.ItemBox:FindFirstChild("UnitViewingUI") then
			newUnitInfo.Frame.ItemBox:FindFirstChild("UnitViewingUI"):Destroy()
		end

		local UnitUI : TextButton, UnitViewport = UnitCreator.CreateUnitIcon(Unit.Name)
		UnitUI.Name = "UnitViewingUI"
		UnitUI.Parent = newUnitInfo.Frame.ItemBox
		UnitUI.Size = UDim2.new(1,0,1,0)

		UnitUI.Coin:Destroy()
		UnitUI.Level:Destroy()
		
		local function UpdateMoney()
			local Level = UnitInfo.Level
			local NextLevel = if Level < #UnitUpgrades then Level + 1 else Level

			if Cash.Value >= UnitUpgrades[NextLevel].Cost then
				UpgradeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				UpgradeButton.UIGradient.Enabled = true
				UpgradeButton.UIStroke.Enabled = true
				UpgradeButton:SetAttribute("Active",true)
			else
				UpgradeButton.BackgroundColor3 = Color3.fromRGB(108, 108, 108)
				UpgradeButton.UIGradient.Enabled = false
				UpgradeButton.UIStroke.Enabled = false
				UpgradeButton:SetAttribute("Active",false)
			end
		end

		UpdateMoney()

		InteractionMaid:GiveTask(Cash.Changed:Connect(UpdateMoney))

		--if player.Name ~= Owner then
			--Buttons.Visible = false
		--end

		InteractionMaid:GiveTask(UpgradeButton.Text.MouseButton1Up:Connect(function() -- Activated didnt work idk why
			self:UpgradeUnit()
		end))

		GetButtonsInButton(SellButton,(function()
			UnitController:SellUnit()
		end))

		GetButtonsInButton(TargetButton,function()
			--print("WE REQUESTING TO CHANGE")
			local PromisedTargeting = UnitService:ChangeTargeting(Unit:GetAttribute("Id"))

			PromisedTargeting:andThen(function(newTargeting)
				-- if newUnitInfo.Frame then return end
				newUnitInfo.Frame.Target.Text.Text = newTargeting
			end)
		end)
	end
end

function UnitController:ConnectHover(Button)
	local connection : RBXScriptConnection
	local HoverFrame = Button:FindFirstChild("Hover");

	TweenService:Create(HoverFrame,TweenInfo.new(.1),{BackgroundTransparency = .85}):Play()
	TweenService:Create(HoverFrame.UIStroke,TweenInfo.new(.1),{Transparency = 0}):Play()
end

function UnitController:ConnectLeave(Button)
	local HoverFrame = Button:FindFirstChild("Hover");

	TweenService:Create(HoverFrame,TweenInfo.new(.1),{BackgroundTransparency = 1}):Play()
	TweenService:Create(HoverFrame.UIStroke,TweenInfo.new(.1),{Transparency = 1}):Play()
end


function UnitController.CheckUltimates(Npc,RequiredToActivate)
	if not Npc then return end

	local Id = Npc:GetAttribute("Id")
	local UnitUltimate = playerGui.UltimateFolder:FindFirstChild(Id)

	local Updatebar = function(Attribute)
		local UltimateCharge = Npc:GetAttribute("UltimateCharge")

		if Attribute == "UltimateCharge" and UltimateCharge <= RequiredToActivate then
			TweenService:Create(UnitUltimate.Ultimate.bar,TweenInfo.new(1),{Size = UDim2.new( UltimateCharge / RequiredToActivate, 0,1,0)}):Play()
		elseif UltimateCharge >= RequiredToActivate then
			UnitUltimate.Ultimate.bar.Size = UDim2.new(0,0,0,0)
			UnitUltimate.Ultimate.Activate.Visible = true
		end
	end

	if UnitUltimate then
		-- warn("WE FOUND THE ULTIMATE UI HERE")
		UnitUltimate.Ultimate.Activate.Activated:Connect(function()
			UnitService:ActivateUltimate(Id)
		end)
		Npc.AttributeChanged:Connect(Updatebar)
	end
end

function UnitController:GetAnimation(AnimationName : string)
	local Animations = ReplicatedStorage.Assets.Animations
	local Animation = Animations:FindFirstChild(AnimationName, true)

	if Animation then
		return Animation
	end

	warn(`Could not find animation {AnimationName}`)
	return nil
end

function UnitController:GetUnitById(Id : string | number)
	local Units = workspace.GameAssets.Units

	for _, unit in pairs(Units:GetChildren()) do
		local id = unit:GetAttribute("Id")
		if Id == id then
			return unit
		end
	end

	return nil
end

function UnitController:UpgradeUnit()
	--UnitViewing is Unit same thing
	if not UnitViewing then return end
	if not UnitViewingInfo then return end

	local PromisedData = UnitService:UpgradeUnit(UnitViewing:GetAttribute("Id"))

	PromisedData:andThen(function(HasbeenUpgraded, UnitData)
		--print("We're upgrading the unit", HasbeenUpgraded, UnitData)
		if HasbeenUpgraded then
			local Upgrade = UnitViewing:FindFirstChild("Upgrade")
			if Upgrade then
				Emit(Upgrade)
			end
			--newUnitInfo.Frame.Skill.Text = UnitData.Ability @koto
			UnitController:ShowStats(UnitViewing,UnitViewingInfo,UnitData.Level, UnitData)
		end
	end)
end

function UnitController:SellUnit()

	if not UnitViewing then return end
	if not UnitViewingInfo then return end

	local PromisedData = UnitService:Sell(UnitViewing:GetAttribute("Id"))

	PromisedData:andThen(function(UnitSold)
		if UnitSold then
			local UltimateChargeUI = playerGui.UltimateFolder:FindFirstChild(UnitViewing:GetAttribute("Id")) 
			local UnitInfoUI = playerGui.UnitInfoFolder:FindFirstChild(UnitViewing:GetAttribute("Id")) 

			if UltimateChargeUI then
				UltimateChargeUI:Destroy()
			end

			UnitController:CloseInteraction(UnitViewing)
		end
		--print(`{Unit.Name} was sold {UnitSold}`)
	end)
end

function UnitController:PlayUnitAnimation(UnitId, AnimationName : string, Info : {Duration : number, Speed : number}) -- will mostly be used to animate unit for emots
	local Unit = UnitController:GetUnitById(UnitId)
	Info = Info or {}

	if Unit then
		local Humanoid = Unit:FindFirstChild("Humanoid")

		if Humanoid then
			local Animator = Humanoid.Animator
			local Animation = UnitController:GetAnimation(AnimationName)

			if Animation then
				local Animation : AnimationTrack = Animator:LoadAnimation(Animation)
				Animation:Play()
				
				if Info.Duration then
					local dt = Info.Duration
					
					while dt > 0 do
						dt -= RunService.Heartbeat:Wait()
					end
	
					Animation:Stop(.5)
				end
			end
		end
	else
		warn(`Could not find unit with Id {UnitId}`)
	end
end


function UnitController.PlayAllClientAnimation() -- AnimationName : string, Info : {Duration : number, Speed : number}
	local UnitFolder = workspace.GameAssets.Units:GetChildren()
	--local Emotes = Animations.Emotes:GetChildren()

	for _,units in pairs(UnitFolder) do
		if units:IsA("Model") then
			local Id = units:GetAttribute("Id")

			task.spawn(function()
				UnitController:PlayUnitAnimation(Id,LoadedEmotes[math.random(1,#LoadedEmotes)].Name,{Duration = 5})
			end)
		end
	end
end

function UnitController:GetInputs()
	-- local UnitInfo : BillboardGui = playerGui:WaitForChild("UnitInfo")
	local InputCleaner = Maid.new() -- Gets removed when player leaves ends the game
	local UICleaner = Maid.new()

	local SelectedTarget;
	local Inputs = {
		["One"] = true;
		["Two"] = true;
		["Three"] = true;
		["Four"] = true;
		["Five"] = true;
	}

	local function GetUnit(position, processedByUI)
		if processedByUI then
			return
		end

		local unitRay = camera:ViewportPointToRay(position.X, position.Y)
		local ray = Ray.new(unitRay.Origin, unitRay.Direction * 20)
		local hitPart : BasePart, worldPosition = workspace:FindPartOnRay(ray)

		if hitPart then 
			-- warn("GET THE HITBOX --> ", hitPart.Name)
			return hitPart
		end
	end

	InputCleaner:GiveTask(UserInputService.TouchTapInWorld:Connect(function(position)
		MousePosition = position
	end))

	InputCleaner:GiveTask(UserInputService.InputBegan:Connect(function(input,gameProcessedEvent)
		local IsKeydown = UserInputService:IsKeyDown(input.KeyCode.Name)

		if gameProcessedEvent then
			return
		end

		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 or input.UserInputType == Enum.UserInputType.Touch) then
			local Target;

			local succ,err = pcall(function()
				Target = Mouse.Target.Parent or GetUnit(MousePosition, true)
			end)

			--print(`Target: {Target}`)
			if SelectedTarget and UpgradeIsOpened then --InsideUpgradeUI 
				local Detector = Detectors:FindFirstChild(tostring(SelectedTarget:GetAttribute("Id")))

				UpgradeIsOpened = false

				Shortcut:PlaySound("MouseClick")

				-- if UnitHighlighter then UnitHighlighter:Destroy() end
				if Detector then Detector.Transparency = 1; end
				if UICleaner then UICleaner:Destroy() end
				-- if UpgradeInputs then UpgradeInputs:Destroy() end

				UnitController:CloseInteraction(SelectedTarget)
				SelectedTarget = nil	
			elseif succ and Target and (Target:FindFirstChild("HumanoidRootPart") or Target:FindFirstChild("RootPart")) and Target.Name ~= "Detector" and Target:IsDescendantOf(workspace.GameAssets.Units) then
				if SelectedTarget and SelectedTarget:GetAttribute("Id") ~= Target:GetAttribute("Id") then
					if SelectedTarget:GetAttribute("Owner") ~= player.Name then return end
					local Detector = Detectors:FindFirstChild(SelectedTarget:GetAttribute("Id"))

					if Detector then
						UICleaner:Destroy()
						Detector.Transparency = 1;
						SelectedTarget = nil
					end
				end


				UpgradeIsOpened = true

				UICleaner = Maid.new()						
				SelectedTarget = Target

				Shortcut:PlaySound("MouseClick")

				self:OpenInteraction(Target)

			end	
		end

	end))
end

function UnitController:ConnectEvents()
	local UpgradeButton = UnitInfo.Frame.Upgrade
	local SellButton = UnitInfo.Frame.Sell
	local TargetButton = UnitInfo.Frame.Target

	local Buttons = {
		SellButton,
		TargetButton,
		UpgradeButton,
	}

	for _,Button in Buttons do
		local HoverFrame = Button:FindFirstChild("Hover")

		if not HoverFrame then
			UIController:CreateHoverFrame(Button)
		end

		local newSize = UDim2.new(Button.Size.X.Scale / 15,0,Button.Size.Y.Scale / 15,0)

		local attributeArgument = if Button:GetAttribute("Active") ~= nil then "Active" else nil

		UIManager:OnMouseChanged(Button,
			Button.Size + newSize,--UDim2.new(.05,0,.05,0),
			Button.Size,
			nil,
	
			--On Hover
			function()
			self:ConnectHover(Button)
			end,
			function()
			self:ConnectLeave(Button)
			end,
			attributeArgument
		)

	end
	

	--self:ConnectHover(UpgradeButton)
	--self:ConnectHover(SellButton)
	--self:ConnectHover(TargetButton)
	--:OnMouseChanged(UI : ImageButton | TextButton, OnEnterSize : UDim2, OnExitSize : UDim2, UIOnHover : Frame, OnHover : any, OnHoverExit : any)

	--print(UpgradeButton.Size/ 10)



end

function UnitController:KnitInit()

end

function UnitController:KnitStart()
	UnitService = Knit.GetService("UnitService")
	MatchService = Knit.GetService("MatchService")
	UIController = Knit.GetController("UIController")

	task.delay(1,UnitController.CheckUltimates)

	MatchService.PlayUnitAnimations:Connect(UnitController.PlayAllClientAnimation)
	UnitService.VisualizeUltimate:Connect(UnitController.CheckUltimates)

	UnitController:GetInputs()
	UnitController:ConnectEvents()

	for _,Emote in pairs(ReplicatedStorage.Assets.Animations.Emotes:GetChildren()) do
		local newAnimation = Emote:Clone()
		newAnimation.Name = "Emote"

		table.insert(LoadedEmotes,Emote)
	end
end

return UnitController
