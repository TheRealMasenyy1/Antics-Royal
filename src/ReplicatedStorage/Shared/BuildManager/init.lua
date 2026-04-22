local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local BuildManager = {}
BuildManager.__index = BuildManager;

local UnitStorage = game.ReplicatedStorage.Units
local UnitInfo = require(game.ReplicatedStorage.Shared.UnitInfo).UnitInformation
local Units = require(game.ReplicatedStorage.SharedPackage.Units)
-- local SpringModule = require(game.ReplicatedStorage.Shared.Utility.Spring)
local Network = require(game.ReplicatedStorage.Shared.Utility.Network)
local Cutscene = require(game.ReplicatedStorage.Shared.Cutscene)

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local ReplicatedStorage = game.ReplicatedStorage

local Camera = workspace.CurrentCamera

function BuildManager:Init(PlayerObject)
	self = BuildManager;
	self.PlayerObject = PlayerObject;
	self.AllowedBuildAreas = {};
	self.RaycastParams = RaycastParams.new()
	self.SelectedUnit = nil;
	self.SessionInfo = {
		Active = false;
		Rotation = 0;
		SelectedUnitInstance = nil;
		SelectedUnit = nil;
		NeonParts = {};
		PlaceMode = "Place"; --// Place or rotate
		
	}
	self.Mouse = game.Players.LocalPlayer:GetMouse()
	-- self.Mouse.TargetFilter = workspace.Debris

	local FilterPack = {};
	for i,BuildArea in pairs(workspace.Map.Buildings.Maps:GetDescendants()) do
		if BuildArea:IsA("BasePart") then -- v.Name == "BuildArea"

			if BuildArea.Parent.Name ~= "Maps" then
				self.AllowedBuildAreas[BuildArea] = {Cliff = BuildArea:GetAttribute("Cliff"), Disabled = true};
			elseif BuildArea.Parent.Name == "Maps" then
				self.AllowedBuildAreas[BuildArea] = {Cliff = BuildArea:GetAttribute("Cliff"), Disabled = false};
			end
			table.insert(FilterPack,BuildArea)
		end
	end
	self.RaycastParams.FilterDescendantsInstances = FilterPack
	
end

function BuildManager:ToggleBuildMode()
	-- warn(self)
	if self.SessionInfo.Active then
		self:EndBuildSession()
	else
		self:StartBuildSession()
	end
end

function BuildManager:StartBuildSession()
	if self.SessionInfo.Active then
		return
	end
	if not self.PlayerObject.IsMobile then
		self.PlayerObject.UI.MainUI.BuildTooltip.Visible = true;
	end
	self.SessionInfo.Active = true;
	
	local Params = self.RaycastParams
	Params.FilterType = Enum.RaycastFilterType.Include;
	self.SessionInfo.NeonParts = {}

	for Part,_ in pairs(self.AllowedBuildAreas) do
		local NeonPart = Part:Clone()
		NeonPart.Parent = workspace.GameAssets.FX
		NeonPart.Transparency = .7
		NeonPart.Color = Color3.new(0.00784314, 1, 0.12549)
		table.insert(self.SessionInfo.NeonParts,NeonPart);
	end
	
	local Highlight = Instance.new("Highlight")
	Highlight.FillTransparency = .5
	-- local NewSpring = SpringModule.new(15, 10, 100, 0, 50, 30);

	local LastRaw = nil
	local Previous = nil;
	local LastMousePosition = Vector2.new(self.Mouse.X,self.Mouse.Y)

	-- local XSpring = SpringModule.new(3, 60, 10, 0, 50, 30);
	-- local ZSpring = SpringModule.new(3, 60, 10, 0, 50, 30);

	local LastHit = self.Mouse.Hit
	local RotationInc = 0;
	local LENGTH = 500
	local MousePosition
	local ScreenPosition;
	local OnWorld = true

	UserInputService.TouchTap:Connect(function(_,ProccedByUI)
		OnWorld = ProccedByUI
	end)

	UserInputService.TouchTapInWorld:Connect(function(position, ProccedByUI)
		ScreenPosition = position
	end)

	-- self.Mouse.TargetFilter = workspace.Debris

	self.MoveConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		local GoalSpot;
		----print(NewSpring.Offset)
		if not self.SessionInfo.SelectedUnitInstance then return print("No unit") end
		if not self.SessionInfo.SelectedUnitInstance:FindFirstChild("Highlight") then
			Highlight.Parent = self.SessionInfo.SelectedUnitInstance
		end
			
		if self.PlayerObject.IsMobile then
			Cutscene:Enabled(true)
		end

		self.SessionInfo.SelectedUnitInstance.Parent = workspace.GameAssets.Units; -- Cloned Placement Unit Parent

		if self.Mouse.Target then
			MousePosition = self.Mouse.Hit.Position
			ScreenPosition = Vector2.new(self.Mouse.X,self.Mouse.Y)
		end

		if (self.PlayerObject.IsMobile and OnWorld) or (not self.PlayerObject.IsMobile) then
			GoalSpot = CFrame.new(self.Mouse.Hit.Position)

			local Origin = GoalSpot * CFrame.new(0,10,0)
			local Cast = workspace:Raycast(Origin.Position,Origin.UpVector * -50, Params) --self.RaycastParams

			if Cast and Cast.Position then
				GoalSpot = CFrame.new(Cast.Position) --* CFrame.new(0,) * CFrame.Angles(0,math.rad(self.SessionInfo.Rotation),0)
				local Ref = self.AllowedBuildAreas[Cast.Instance]

				if (Ref.Cliff and not UnitInfo[self.SessionInfo.SelectedUnit].AllowCliff)  or (not Ref.Cliff and not UnitInfo[self.SessionInfo.SelectedUnit].AllowGround) or Ref.Disabled then
					self.SessionInfo.CanPlace = false;
					Highlight.FillColor = Color3.new(1, 0, 0)
				else
					self.SessionInfo.CanPlace = true;
					Highlight.FillColor = Color3.new(0.101961, 1, 0)
				end
			else
				self.SessionInfo.CanPlace = false;
				Highlight.FillColor = Color3.new(1, 0, 0)
			end
		else
			self.SessionInfo.CanPlace = false;
		end
		
		if GoalSpot then
			self.SessionInfo.LastPosition = (GoalSpot * CFrame.new(0,0,0)) * CFrame.Angles(0,math.rad(self.SessionInfo.Rotation),0) 
			LastRaw = GoalSpot
		end

		RotationInc+= 1
		if LastRaw then
			if not Previous then
				warn("Didn't change for a reason")
				Previous = LastRaw
			end

			local currentMousePosition = Vector2.new(self.Mouse.X, self.Mouse.Y)
			local mouseDelta = currentMousePosition - LastMousePosition
			LastMousePosition = currentMousePosition
			mouseDelta = Vector2.new(mouseDelta.X, -mouseDelta.Y)

			local leanAngleX = mouseDelta.Y * 0.02 -- Adjust the multiplier for desired lean intensity
			local leanAngleZ = mouseDelta.X * 0.02 -- Adjust the multiplier for desired lean intensity
			leanAngleX = math.clamp(leanAngleX, -math.rad(30), math.rad(30))
			leanAngleZ = math.clamp(leanAngleZ, -math.rad(30), math.rad(30))

			local camera = game.Workspace.CurrentCamera
			local cameraCFrame = camera.CFrame

			local _, cameraYRotation, _ = cameraCFrame:ToEulerAnglesYXZ()

			local cameraYRotationCFrame = CFrame.Angles(0, cameraYRotation, 0)

			local globalTilt = CFrame.Angles(leanAngleX, 0, leanAngleZ)
			local cameraTilt = cameraYRotationCFrame * globalTilt

			local newRotation = LastRaw * cameraTilt

			-- Apply the new rotation to the rig
			self.SessionInfo.SelectedUnitInstance:PivotTo(CFrame.new(LastRaw.Position) * cameraTilt * CFrame.Angles(0,math.rad(self.SessionInfo.Rotation) - cameraYRotation,0))
			Previous = LastRaw
			if self.SessionInfo.RangeSphere then
				self.SessionInfo.RangeSphere.CFrame = LastRaw * CFrame.Angles(0,math.rad(RotationInc),0)
			end
		end
	end)
end

function BuildManager:IncrementRotate(Increment)
	if self:IsActive() then
		self.SessionInfo.Rotation += Increment;
	end
end

function BuildManager:LockInUnit()
	if self:IsActive() then
		local SessInfo = self.SessionInfo
		if SessInfo.CanPlace then
			local GoalFrame = SessInfo.LastPosition;
			local UnitName = SessInfo.SelectedUnit;
			
			self:EndBuildSession();
			
			--// Offload to server for true confirmation
			require(game.ReplicatedStorage.Shared.Utility.Network):FireServer("AttemptUnitPlacement",UnitName,GoalFrame) -- animation disables here
		end
	end
end

function BuildManager:ShowDetector(Unit,Range)
	local SphereMod = game.ReplicatedStorage.Assets.AOECircle:Clone();

	SphereMod:ScaleTo(Range);

	local HumanoidRootPart = Unit:FindFirstChild("HumanoidRootPart") or Unit:FindFirstChild("RootPart")
	local SphereOb = SphereMod.AOECircle
	
	if HumanoidRootPart then
		SphereMod.Parent = workspace.CurrentCamera
		SphereOb.CFrame = HumanoidRootPart.CFrame
		SphereOb.Floor.CFrame = SphereOb.CFrame * CFrame.new(0,SphereOb.Floor.Size.Y,0)
	end
	
	return SphereMod
end

Network:BindEvents({
	["PlaceUnit"] = function(UnitName, Mod)
		BuildManager:PlaceVFX(UnitName,Mod);
	end,

	-- ["ShowDetector"] = function(Unit)
	-- 	BuildManager:ShowDetector(Unit);
	-- end,
})

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local UltimateCharge = PlayerGui:WaitForChild("UltimateCharge")

function BuildManager:PlaceVFX(UnitName,MobToPlace)
	local Mod = MobToPlace
	local HasUltimateCharge = MobToPlace:GetAttribute("UltimateCharge")

	local highlight = script.Highlight:Clone()
	highlight.Parent = Mod
	game:GetService("TweenService"):Create(highlight,TweenInfo.new(1),{FillTransparency = 1}):Play()
	game:GetService("Debris"):AddItem(highlight,1.05);

	local UnitInfo = require(game.ReplicatedStorage.Shared.UnitInfo).UnitInformation[UnitName]
	local Anim = Instance.new("Animation")
	Anim.Name = "Idle"
	Anim.AnimationId = "rbxassetid://" .. UnitInfo.IdleAnim;

	local highlight = script.Highlight:Clone()
	highlight.Parent = Mod
	game:GetService("TweenService"):Create(highlight,TweenInfo.new(1),{FillTransparency = 1}):Play()
	game:GetService("Debris"):AddItem(highlight,1.05);
	Mod.Parent = workspace.GameAssets.Units;

	-- local Track : AnimationTrack = if Mod:FindFirstChild("Humanoid") then Mod.Humanoid:LoadAnimation(Anim) else Mod.AnimationController:LoadAnimation(Anim)
	-- Track.Priority = Enum.AnimationPriority.Idle
	-- Track:Play()

	--if Mod:FindFirstChild("Humanoid") then
	--	Track = Mod.Humanoid:LoadAnimation(Anim)
	--else
	--	Track = Mod.AnimationController:LoadAnimation(Anim)
	--end
	
	Mod.Parent = workspace.GameAssets.Units;

	local HumanoidRootPart = MobToPlace:FindFirstChild("HumanoidRootPart") or MobToPlace:FindFirstChild("RootPart")

	if HasUltimateCharge then
		local newUltimateInfo = UltimateCharge:Clone()
		newUltimateInfo.Name = MobToPlace:GetAttribute("Id")
		newUltimateInfo.Adornee = HumanoidRootPart
		newUltimateInfo.Enabled = true
		newUltimateInfo.Parent = PlayerGui.UltimateFolder
	end

	local Sound = ReplicatedStorage.Assets.Sounds["Place" .. math.random(1,3)]:Clone()
	Sound.Parent = script
	Sound:Play()
	game:GetService("Debris"):AddItem(Sound,3)

	local PlaceParticles = game.ReplicatedStorage.Assets.PlaceParticles:Clone()
	PlaceParticles.Parent = workspace.GameAssets.FX
	PlaceParticles.CFrame = HumanoidRootPart.CFrame

	local succ = pcall(function()
		game:GetService("TextChatService"):DisplayBubble(Mod:WaitForChild("Head"),require(script.Lines)[UnitName][math.random(1,#require(script.Lines)[UnitName])])
	end)

	if not succ then
		warn(`COULD NOT FIND LINES FOR {UnitName}`)
	end

	for i,v in pairs(PlaceParticles:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end

	-- preload anims for that unit

	local function removeSpaces(str)
		return string.gsub(str, "%s+", "")
	end

	local unitAnimations = ReplicatedStorage.Assets.Animations:FindFirstChild(removeSpaces(UnitName))

	if unitAnimations then
		for _,Animation in pairs(unitAnimations:GetChildren()) do
			if not Animation:IsA("Animation") then continue end

			if Mod:FindFirstChild("Humanoid") then Mod.Humanoid.Animator:LoadAnimation(Animation) else Mod.AnimationController:LoadAnimation(Animation) end
		end
    end

	game:GetService("Debris"):AddItem(PlaceParticles,3)
end

function BuildManager:IsActive()
	return self.SessionInfo.Active
end

function BuildManager:EndBuildSession()
	if self.SessionInfo.Active == false then 
		return
	end
	self.SessionInfo.Active = false;

	if not self.PlayerObject.IsMobile then
		self.PlayerObject.UI.MainUI.BuildTooltip.Visible = false;
	end

	self.MoveConnection:Disconnect()
	if self.SessionInfo.SelectedUnitInstance then
		self.SessionInfo.SelectedUnitInstance:Destroy()
	end
	if self.SessionInfo.RangeSphere then
		self.SessionInfo.RangeSphere:Destroy()
	end
	
	for i,v in pairs(self.SessionInfo.NeonParts) do
		v:Destroy()
	end
	self.SessionInfo = {
		Active = false;
		Rotation = 0;
		SelectedUnitInstance = nil;
		SelectedUnit = nil;
		NeonParts = {};
		PlaceMode = "Place"; --// Place or rotate
	}

	self.Mouse.TargetFilter = workspace.Debris;
	self.PlayerObject.UI:GetUI("RotateButtons").Visible = false
	Cutscene:Enabled(false)
end


function BuildManager:ChangeUnit(GoalUnit)
	if not UnitStorage:FindFirstChild(GoalUnit) then
		return --print("Cant find",GoalUnit)
	end
	if not self:IsActive() then
		self:StartBuildSession()
	end

	if self.SessionInfo.SelectedUnitInstance then
		if self.SessionInfo.SelectedUnitInstance.Name == GoalUnit  then
			warn("has this unit equipped yea")
			self:EndBuildSession()
			return
		end
	end


	if self.SessionInfo.SelectedUnitInstance then
		if self.SessionInfo.SelectedUnitInstance:FindFirstChild("Highlight") then
			self.SessionInfo.SelectedUnitInstance:FindFirstChild("Highlight").Parent = script
		end
		self.SessionInfo.SelectedUnitInstance:Destroy()
	end
	
	if self.SessionInfo.RangeSphere then
		self.SessionInfo.RangeSphere:Destroy()
	end
	
	local Unit = UnitStorage:FindFirstChild(GoalUnit):Clone();Unit.Parent = workspace
	local _,Size = Unit:GetBoundingBox()
	local NumberValue = Instance.new("NumberValue")
	local SphereNumberValue = Instance.new("NumberValue")
	local SizeStart = .6
	local NumberTween = TweenService:Create(NumberValue, TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Value = .452})
	NumberValue.Value = .452 * SizeStart

	NumberValue.Changed:Connect(function(value)
		Unit:ScaleTo(NumberValue.Value)
	end)

	self.SessionInfo.SelectedUnit = GoalUnit
	self.Mouse.TargetFilter = workspace.GameAssets.Units
	self.SessionInfo.SelectedUnitInstance = Unit
	self.SessionInfo.Offset = (Size.Y/2)

	local Range = UnitInfo[GoalUnit].Range
	local DefualtStats = Units[GoalUnit].Upgrades[0]
	local SphereMod = BuildManager:ShowDetector(Unit,DefualtStats.Range)
	local UnitInfo = require(game.ReplicatedStorage.Shared.UnitInfo).UnitInformation[GoalUnit]
	local Anim = Instance.new("Animation")
	local NumberTweenSphere =  TweenService:Create(SphereNumberValue, TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0),{Value = DefualtStats.Range})
	SphereNumberValue.Value = DefualtStats.Range * SizeStart
	Anim.Name = "Idle"
	Anim.AnimationId = "rbxassetid://" .. UnitInfo.IdleAnim;
	
	if Unit:FindFirstChild("Humanoid") then
		Unit.Humanoid:LoadAnimation(Anim):Play()
	else
		Unit.AnimationController:LoadAnimation(Anim):Play()
	end

	SphereNumberValue.Changed:Connect(function(value)
		SphereMod:ScaleTo(SphereNumberValue.Value)
	end)

	--[[local w=  Instance.new("Weld")
	w.Part0 = Unit.HumanoidRootPart
	w.Part1 = Sphere
	w.Parent = w.Part0]]

	self.SessionInfo.RangeSphere = SphereMod.AOECircle


	NumberTween:Play()
	NumberTweenSphere:Play()

	NumberTween.Completed:Connect(function()
		NumberValue:Destroy()
		SphereNumberValue:Destroy()
	end)


	-- SphereMod:Destroy()
--	--print("Unit Changed",Size.Y/2)
	
	
end





return BuildManager
