local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- local SharedPackages = ReplicatedStorage.SharedPackage
-- local Particles = ReplicatedStorage.Assets.Particles

local Assets = ReplicatedStorage.Assets
local Units_Folder = ReplicatedStorage.Units

local UnitClasses = ReplicatedStorage.Shared.Units

local Knit = require(ReplicatedStorage.Packages.Knit)
local Units = require(ReplicatedStorage.SharedPackage.Units)
local UnitInformation = require(ReplicatedStorage.Shared.UnitInfo).UnitInformation
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local Network = require(game.ReplicatedStorage.Shared.Utility.Network)
local RemoteManager = require(ReplicatedStorage.RemoteManager)
local HitboxModule = require(ReplicatedStorage.Shared.Utility.Hitbox)
local Types = require(ReplicatedStorage.Shared.Utility.Types)

local MatchFolder;
local ProfileService;
local MobService;

local UnitService = Knit.CreateService {
	Name = "UnitService",
	Units = {},
	Client = {
		TargetChanged = Knit.CreateSignal(),
		AttackVFX = Knit.CreateSignal(),
		ExplodeVFX = Knit.CreateSignal(),
		Place = Knit.CreateSignal(),
		GetUnitInfo = Knit.CreateSignal(),
		Upgrade = Knit.CreateSignal(),
		Sell = Knit.CreateSignal(),
		UpgradeUnit = Knit.CreateSignal(),
		UpdateDamage = Knit.CreateSignal(),
		VisualizeUltimate = Knit.CreateSignal(),
		OnHit = Knit.CreateSignal(),
		PlayAnimation = Knit.CreateSignal(),
		StopAnimation = Knit.CreateSignal(),
		BossTransition = Knit.CreateSignal(),
		MovieMode = Knit.CreateSignal(),
		BossWarning = Knit.CreateSignal(),
	},
}

local unitAmount = {}
local Validations = {}
local Active_Units = {}

type PlaceInfo = {
	Spot : CFrame;
	Name : string; -- which npc 
	Floor : string;
	Room : string;
}
local Room = workspace.Gameplay

PhysicsService:RegisterCollisionGroup("Units")
PhysicsService:RegisterCollisionGroup("MobGroup")
PhysicsService:RegisterCollisionGroup("Players")

PhysicsService:CollisionGroupSetCollidable("Units","Players",false)
PhysicsService:CollisionGroupSetCollidable("MobGroup","Players",false)

local function GetTheMapFolder()
	for _,Map in pairs(workspace.Floors:GetDescendants()) do
		if Map:IsA("Model") and Map.Name == "Map" then
			return Map.Parent.Room1
		end
	end

	return nil
end

function UnitService.Client:GetUnitInfo(_,UnitId)
	return self.Server.Units[UnitId]
end

function UnitService.Client:ChangeTargeting(player,UnitId)
	local Unit = self.Server.Units[UnitId]
	if Unit.Owner.Name ~= player.Name then return end 

	if Unit.Unit:GetAttribute("UnitType") == "Buff" then return "First" end

	local newTargeting = Unit:ChangeTargeting()
	return newTargeting
end

function UnitService.Client:Sell(player,UnitId)
	local Unit = self.Server.Units[UnitId]
	if Unit.Owner.Name ~= player.Name then return end 

	-- player.PlacementAmount.Value -= 1
	if unitAmount[player.Name][Unit.Name] then
		unitAmount[player.Name][Unit.Name] -= 1
		print("After selling Unit --> ", unitAmount)
	end

	-- Unit.IsActive = false
	local UnitSold = Unit:Sell()

	return UnitSold
end

function UnitService.Client:ActivateUltimate(player,UnitId)
	local Unit = self.Server.Units[UnitId]

	if Unit then
		local UltimateInfo = Unit.AbilityHitbox["Ultimate"]
		Unit.IsActive = false
		Unit.NormalAbility = Unit.Ability
		Unit.Ability = "Ultimate"

		Unit:Ultimate()
		task.delay(UltimateInfo.Duration,function()
			Unit.IsActive = true
			Unit.Ability = Unit.NormalAbility
			Unit:Run()
		end)
	end
end

function UnitService.Client:UpgradeUnit(player,UnitId)
	local Unit = self.Server.Units[UnitId]
	if Unit.Owner.Name ~= player.Name then return end 

	local hasBeenUpgraded,UnitUnitData = Unit:Upgrade(player)

	if hasBeenUpgraded then
		Unit.IsActive = false -- Temp stop for updating stats	
		task.delay(.1,function()
			Unit.IsActive = true -- Activated the Unit

			task.spawn(function() -- And run again
				Unit:Run()
			end)
		end)		
	end
	return hasBeenUpgraded, UnitUnitData
end

function UnitService:ResetTable()
	local Unit = self.Units

	for _,UnitInfo in pairs(Unit) do
		if UnitInfo then
			UnitInfo.IsActive = false
		end
	end

	for _, player in pairs(game.Players:GetChildren()) do
		unitAmount[player.Name] = {}
	end
	--warn("THE UNIT AMOUNT ", unitAmount)
end

function UnitService:StunUnits(unitTable : table, duration : number, osClock)
	--print(os.clock() - osClock)
	for _,unit in pairs(unitTable) do
		unit:SetAttribute("Stun",true)
		UnitService.Client.PlayAnimation:FireAll(unit, ReplicatedStorage.Assets.Animations.Units.Stun)
		
		task.delay(duration, function()
			UnitService.Client.StopAnimation:FireAll(unit, "Stun")
            unit:SetAttribute("Stun",false)
        end)
	end
	--warn("THE UNIT AMOUNT ", unitAmount)
end


local function ValidateRequest(sender,Id,Request, UnitInfo)
	local validation = Validations[Id] 
	local AmountOfPlayers = #Players:GetChildren()
	local verify

	if UnitInfo.InCooldown then warn("The ability is in cooldown...", UnitInfo.InCooldown) return false end

	local succ,err = pcall(function()
		verify = validation[Request] 
	end)

	if succ and verify ~= nil then
		--print(verify)
		verify.Count += 1	
	else
		validation[Request] = {
			Sender = sender.Name,
			Id = Id,
			Count = 1
		}
	end

	if validation[Request].Count == AmountOfPlayers then
		validation[Request] = nil
		return true
	end

	return false
end

function UnitService.Client:RequestDamage(Owner, Npc)
	local Id = Npc:GetAttribute("Id")
	local TotalDamage = Owner.leaderstats:FindFirstChild("Damage")
	local Cash = Owner.leaderstats:FindFirstChild("Cash")
	local UnitInfo = self.Server.Units[Id]
	local UnitAbility = UnitInfo.Ability
	local UnitHitboxInfo = UnitInfo.AbilityHitbox[UnitAbility]
	local TraitValue,TraitLevel = UnitInfo:CheckTraits("Critical")
	local FallDirections = {
		["Forward"] = Npc:GetPivot().LookVector, 
		["Backward"] = -Npc:GetPivot().LookVector,
		["Right"] = Npc:GetPivot().RightVector, 
		["Left"] = -Npc:GetPivot().RightVector,
	}


	--- Request recieved, counter.
	local Validated = ValidateRequest(UnitInfo.Owner.Name,Id,UnitAbility, UnitInfo)
	local function isCritical(CriticalChance)
		local randomValue = math.random()
		return randomValue <= CriticalChance
	end

	print("Client is requesting damage", Validated)
	if Validated then
		if not UnitHitboxInfo.SkillType then
			local TargetPosition;
	
			local succ,err = pcall(function()
				TargetPosition = UnitInfo.Target:GetPivot()
			end)
	
			if succ then
				UnitHitboxInfo.TargetCFrame = UnitInfo.Target:GetPivot()
			else
				UnitHitboxInfo.TargetCFrame = self.LastTargetPosition
			end
		elseif UnitHitboxInfo.SkillType == "AEO" then
			UnitHitboxInfo.TargetCFrame = UnitInfo.Unit:GetPivot()
		end

		task.spawn(function()
			if (not UnitHitboxInfo.FireTimes) then
				-- print("Set in cooldown")
				UnitInfo.AttackInUse = false
				UnitInfo:SetCooldown()
				UnitHitboxInfo.CurrentFires = 0
			else
				UnitHitboxInfo.CurrentFires += 1

				if (UnitHitboxInfo.CurrentFires >= UnitHitboxInfo.FireTimes) then
					-- print("Set in cooldown")
					UnitInfo.AttackInUse = false
					UnitInfo:SetCooldown()
					UnitHitboxInfo.CurrentFires = 0
				end
			end
		end)

		HitboxModule[UnitHitboxInfo.Type](Npc, UnitHitboxInfo,UnitInfo, function(Mob : Model,CurrentHealth)
			-- print(`{Mob.Name} has been dealt { UnitInfo.Damage } damage has trait { TraitValue }: { TraitLevel }`)
			local Damage = if UnitHitboxInfo.Damage then UnitHitboxInfo.Damage else UnitInfo.Damage
			local CurrentShield = Mob:GetAttribute("Shield")
			local isCriticalHit = if TraitValue then isCritical(TraitValue) else false
	
	
			if isCriticalHit then
				Damage *= 2 -- Damage two times
				Mob:SetAttribute("CriticalHit",true)
			end
	
			if TotalDamage then
				TotalDamage.Value += Damage
			end
	
			UnitInfo.TotalDamage += Damage
	
			if Cash then
				Cash.Value += Damage
			end
	
			if UnitInfo.UltimateInfo then
				local CurrentUltimateCharage = Npc:GetAttribute("UltimateCharge")
				local RequiredToActivate = UnitInfo.UltimateInfo.RequiredToActivate
				
				if CurrentUltimateCharage < RequiredToActivate then
					Npc:SetAttribute("UltimateCharge", CurrentUltimateCharage + Damage)
				end
			end
	
			if UnitHitboxInfo.Slowness then
				local CurrentSpeed = Mob:GetAttribute("OriginalSpeed") or Mob:GetAttribute("Speed")
	
				if not Mob:GetAttribute("OriginalSpeed") then
					Mob:SetAttribute("OriginalSpeed", CurrentSpeed)
				else
					CurrentSpeed = Mob:GetAttribute("OriginalSpeed")
				end
	
				Mob:SetAttribute("Speed", CurrentSpeed * UnitHitboxInfo.Slowness)
	
				task.delay(UnitHitboxInfo.Duration,function()
					Mob:SetAttribute("Speed", CurrentSpeed)
				end)
			end

			if UnitHitboxInfo.Stun ~= nil and UnitHitboxInfo.Stun ~= false then
				local CurrentSpeed = Mob:GetAttribute("OriginalSpeed") or Mob:GetAttribute("Speed")
	
				if not Mob:GetAttribute("OriginalSpeed") then
					Mob:SetAttribute("OriginalSpeed", CurrentSpeed)
				else
					CurrentSpeed = Mob:GetAttribute("OriginalSpeed")
				end
	
				Mob:SetAttribute("Speed", 0)
	
				task.delay(UnitHitboxInfo.Stun,function()
					Mob:SetAttribute("Speed", CurrentSpeed)
				end)
			end

	
			if UnitHitboxInfo.HitVFX or UnitHitboxInfo.OnHitSound then
				UnitService.Client.OnHit:FireAll(Mob, UnitHitboxInfo)
			end

			if UnitHitboxInfo.PushDirection then
				Mob:SetAttribute("PushDirection",FallDirections[UnitHitboxInfo.PushDirection])
			end
	
			Mob:SetAttribute("PushPower",UnitHitboxInfo.PushPower)
			Npc:SetAttribute("TotalDamage", Damage)

			if (not CurrentShield or CurrentShield <= 0) then
				Mob:SetAttribute("Health",CurrentHealth - Damage)
				Mob:SetAttribute("Tagged",Npc:GetAttribute("Owner"))
				Mob:SetAttribute("LastHit",Npc:GetAttribute("Id"))
			else
				local LeftOver = CurrentShield - Damage --- Might be buggy I don't know as of right now (2024-09-05, 17:17)
				Mob:SetAttribute("Shield",CurrentShield - Damage)
				CurrentShield = Mob:GetAttribute("Shield")
	
				if CurrentShield <= 0 and LeftOver > 0 then
					Mob:SetAttribute("Health",CurrentHealth - LeftOver)
					Mob:SetAttribute("LastHit",Npc:GetAttribute("Id"))
				end
			end
	
			task.delay(.5,function()
				Mob:SetAttribute("CriticalHit",false)
			end)
		end)
	else
		warn("THIS ATTACK COULDN'T BE VALIDATED")
	end

	-- end
	-- warn(` Has { Npc.Name } done damage to another Npc?`, UnitInfo, UnitHitboxInfo)
end

function UnitService.PlaceUsingSpawner(Team : string, UnitName : string, Frame : CFrame)
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = { workspace.Map.Buildings.Maps}

	local UnitPlaced = false
	-- local UnitInfo = UnitInformation.Cold.
	local Pack = {
		Model = game.ReplicatedStorage.Units:FindFirstChild(UnitName):Clone();
		Location = Frame;
		Owner = nil;
		TimePlace = workspace:GetServerTimeNow();
		Info = {}; -- stats of unit and stuff for server if needed
	};
	
	local function DisableCollsion(Model)
		for _,Parts : BasePart in pairs(Model:GetChildren()) do
			if Parts:IsA("BasePart") then
				Parts.CanCollide = false
			end
		end
	end
		
	local function GetUnitByName(UnitsData, UnitName : string)
		UnitsData = UnitsData or {}

		for pos,UnitData in UnitsData do
			if UnitData.Unit == UnitName then
				return UnitData,pos
			end
		end

		return nil
	end
	
	local MyUnitInfo = { -- We'll get the info from UnitDatastore
		Unit = UnitName,
		Level = 1;
		UnitType = "Hybrid",
		Traits = {
			Name = "", 
			Level = 0,
		},
		Stats = {Damage = "S", Cooldown = "F", Range = "C"};
	}
	
	if MyUnitInfo then
		local newUnit = Pack.Model
		local Unit_Class = UnitClasses:FindFirstChild(Units[UnitName].Name)

		if Unit_Class then -- and Cash and Cash.Value >= Units[UnitName].Price

			newUnit.Parent = workspace.GameAssets.Units
			newUnit.HumanoidRootPart.Anchored = false
			newUnit:PivotTo(Frame);

			local Unit = require(Unit_Class).Setup(newUnit, MyUnitInfo)	-- Load Class
			Unit.Heart = Room.End
			Unit.Traits = MyUnitInfo.Traits
			Unit.Owner = Players:GetChildren()[1]
			Unit.Team = Team
			Unit.Room = Room

			local UpgradeVFX = Assets.VFX.Units.Upgrade:Clone()
			UpgradeVFX.CFrame = newUnit.PrimaryPart.CFrame
			UpgradeVFX.Anchored = true
			UpgradeVFX.CanCollide = false
			UpgradeVFX.Parent = newUnit
			
			newUnit.Humanoid.MaxHealth = Unit.Health
			newUnit.Humanoid.Health = Unit.Health

			newUnit:SetAttribute("Team", Unit.Team)
			newUnit:SetAttribute("IsActive", true)
			newUnit:SetAttribute("Id",math.random(-1000,1000))
			-- newUnit:SetAttribute("Owner",Owner.Name)
			newUnit:SetAttribute("TotalDamage", 0)

			Validations[newUnit:GetAttribute("Id")] = {Owner = Team}
			UnitService.Units[newUnit:GetAttribute("Id")] = Unit

			task.delay(.5,function()
				if Unit.UltimateInfo then
					-- UnitService.Client.VisualizeUltimate:Fire(Owner, newUnit, Unit.UltimateInfo.RequiredToActivate)
				end
			end)
			
			MobService.Client.TrackHealth:FireAll(newUnit)
			UnitService.AddUnit(Unit)
			DisableCollsion(newUnit)

			task.spawn(function()
				Unit:Run()
			end)	

			UnitPlaced = true
		elseif not Unit_Class then
			warn("[ CLASS ] - CLASS WAS NOT FOUND...", Units[UnitName].Name)
		else
			warn("[ LACK FUND ] - TO BUY ", UnitName)
		end	
		
		
		Network:FireAllClients("PlaceUnit",UnitName,Pack.Model)
		-- setmetatable(ServerBuildManager,Pack)
	end

	return UnitPlaced
end

function UnitService:Place(UnitName, Frame, Owner : player)
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = { workspace.Map.Buildings.Maps}

	local UnitPlaced = false
	-- local UnitInfo = UnitInformation.Cold.
	local AllowedPlacement = Shortcut.RayCast(Frame.Position + Vector3.new(0,10,0),Vector3.new(0,-100,0), Params)
	local Pack = {
		Model = game.ReplicatedStorage.Units:FindFirstChild(UnitName):Clone();
		Location = Frame;
		Owner = Owner;
		TimePlace = workspace:GetServerTimeNow();
		Info = {}; -- stats of unit and stuff for server if needed
	};
	
	local function DisableCollsion(Model)
		for _,Parts : BasePart in pairs(Model:GetChildren()) do
			if Parts:IsA("BasePart") then
				Parts.CanCollide = false
			end
		end
	end
		
	local function GetUnitByName(UnitsData, UnitName : string)
		UnitsData = UnitsData or {}

		for pos,UnitData in UnitsData do
			if UnitData.Unit == UnitName then
				return UnitData,pos
			end
		end

		return nil
	end
	
	local Equipped = ProfileService:Get(Owner,"Equipped")
	local MyUnitInfo = GetUnitByName(Equipped,UnitName) or { -- We'll get the info from UnitDatastore
		Unit = UnitName,
		Level = 1;
		UnitType = "Hybrid",
		Traits = {
			Name = "", 
			Level = 0,
		},
		Stats = {Damage = "S", Cooldown = "F", Range = "C"};
	}
	
	if AllowedPlacement and unitAmount[Owner.Name][UnitName] < Units[UnitName].MaxPlacement and MyUnitInfo then
		local newUnit = Pack.Model
		local Cash = Owner.leaderstats:FindFirstChild("Cash")

		local Unit_Class = UnitClasses:FindFirstChild(Units[UnitName].Name)

		if Unit_Class then -- and Cash and Cash.Value >= Units[UnitName].Price

			newUnit.Parent = workspace.GameAssets.Units
			newUnit.HumanoidRootPart.Anchored = false
			newUnit:PivotTo(Frame);

			local Unit = require(Unit_Class).Setup(newUnit, MyUnitInfo)	-- Load Class
			Unit.Heart = Room.End
			Unit.Traits = MyUnitInfo.Traits
			Unit.Room = Room
			Unit.Owner = Owner

			local UpgradeVFX = Assets.VFX.Units.Upgrade:Clone()
			UpgradeVFX.CFrame = newUnit.PrimaryPart.CFrame
			UpgradeVFX.Anchored = true
			UpgradeVFX.CanCollide = false
			UpgradeVFX.Parent = newUnit
			
			newUnit.Humanoid.MaxHealth = Unit.Health
			newUnit.Humanoid.Health = Unit.Health

			newUnit:SetAttribute("Team", Unit.Team)
			newUnit:SetAttribute("IsActive", true)
			newUnit:SetAttribute("Id",math.random(-1000,1000))
			newUnit:SetAttribute("Owner",Owner.Name)
			newUnit:SetAttribute("TotalDamage", 0)

			Validations[newUnit:GetAttribute("Id")] = {Owner = Owner.Name}
			self.Units[newUnit:GetAttribute("Id")] = Unit
			Cash.Value -= Units[UnitName].Price

			task.delay(.5,function()
				if Unit.UltimateInfo then
					UnitService.Client.VisualizeUltimate:Fire(Owner, newUnit, Unit.UltimateInfo.RequiredToActivate)
				end
			end)
			
			MobService.Client.TrackHealth:FireAll(newUnit)
			UnitService.AddUnit(Unit)
			DisableCollsion(newUnit)

			task.spawn(function()
				Unit:Run()
			end)	

			UnitPlaced = true
		elseif not Unit_Class then
			warn("[ CLASS ] - CLASS WAS NOT FOUND...", Units[UnitName].Name)
		else
			warn("[ LACK FUND ] - TO BUY ", UnitName)
		end	
		
		
		Network:FireAllClients("PlaceUnit",UnitName,Pack.Model)
		-- setmetatable(ServerBuildManager,Pack)
	end

	return UnitPlaced
end

function UnitService:KnitStart()
	-- local ProfileService = Knit.GetService("ProfileService")
	local playerUnits = {}
	self.Units = {}	

	ProfileService = Knit.GetService("ProfileService")

	local function ChangeTableFormat(Table)
		local newtable = {}
		for _,UnitData in pairs(Table) do
			newtable[UnitData.Unit] = UnitData
		end
		return newtable
	end

	local function SetCollisionGroup()
		for _,unit in pairs(ReplicatedStorage.Units:GetDescendants()) do
			if unit:IsA("BasePart") then
				unit.CollisionGroup = "Units"
			end
		end
	end

	local cooldowns = {}
	Network:BindEvents({
		["AttemptUnitPlacement"] = function(Player,Unit,Frame)
			if not cooldowns[Player] then
				cooldowns[Player] = 0 
			end
			if tick() - cooldowns[Player] < .5 then
				return
			end
			cooldowns[Player] = tick()

			if not unitAmount[Player.Name] then
				unitAmount[Player.Name] = {[Unit] = 0}
			elseif unitAmount[Player.Name] and not unitAmount[Player.Name][Unit] then
				unitAmount[Player.Name][Unit] = 0
			end

			-- if unitAmount[Player.Name] and 			-- --print(Player,Unit,Frame)
			local UnitPlaced = UnitService:Place(Unit,Frame,Player)
			
			if UnitPlaced then
				if unitAmount[Player.Name][Unit] then unitAmount[Player.Name][Unit] += 1 end	
			end
		end,
	})

	SetCollisionGroup() -- Sets collision group for all the MODELS
end

function UnitService.AddUnit(Unit : Types.UnitManagerObject)
	table.insert(Active_Units, Unit)
end

function UnitService.UpdateUnits()
	for _, Unit in Active_Units do
		if Unit.Health > 0 then
			if Unit.IsRunning then
				continue
			end

			Unit:Update()
		end
	end
end

function UnitService:KnitInit()
	MobService = Knit.GetService("MobService")
	RemoteManager:Listen("SpawnNpc", UnitService.PlaceUsingSpawner)
	RunService.Stepped:Connect(UnitService.UpdateUnits)
end

return UnitService
