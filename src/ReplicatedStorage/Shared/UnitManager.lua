local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")

local SharedPackages = ReplicatedStorage.SharedPackage
local Assets = ReplicatedStorage.Assets
local Gameplay = workspace.Gameplay

local Units = require(SharedPackages.Units)
local Grades = require(SharedPackages.Grades)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Types = require(ReplicatedStorage.Shared.Utility.Types)
local BehaviorTreeCreator = require(ReplicatedStorage.BehaviorTree.BehaviorTreeCreator)

-- ─── Type Aliases (imported from Types module) ───────────────────────────────

type UnitManagerObject = Types.UnitManagerObject
type UnitManagerClass  = Types.UnitManagerClass
type CustomUnitInfo    = Types.CustomUnitInfo
type TargetData        = Types.TargetData
type BuffInfo          = Types.BuffInfo
type PriorityTable     = Types.PriorityTable
type UnitDataInGame    = Types.UnitDataInGame
type UnitDataGeneric   = Types.UnitDataGeneric
type StatGrade         = Types.StatGrade

-- ─── Module ──────────────────────────────────────────────────────────────────

local UnitManager: UnitManagerClass = {} :: UnitManagerClass
UnitManager.__index = UnitManager

local UnitService: any -- Lazily fetched via Knit on first OnZoneTouched call

-- ─── Private Helpers ─────────────────────────────────────────────────────────

local function format(num: number): string
	local formatted: string = string.format("%.2f", math.floor(num * 100) / 100)
	if string.find(formatted, ".00") then
		return string.sub(formatted, 1, -4)
	end
	return formatted
end
-- ─── Constructor ─────────────────────────────────────────────────────────────

function UnitManager.new(Unit: Model, CustomUnitInfo: CustomUnitInfo): UnitManagerObject
	local DefaultStats = Units[Unit.Name]
	local self: UnitManagerObject = setmetatable({} :: any, UnitManager)

	self.Unit           = Unit
	self.Name           = Unit.Name
	self.Owner          = nil
	self.Upgrades       = DefaultStats.Upgrades
	self.Traits         = CustomUnitInfo.Traits or nil
	self.UnitLevel      = CustomUnitInfo.Level
	self.AttackInUse    = false
	self.Type           = CustomUnitInfo.UnitType or "Ground"
	self.ActualLevel    = CustomUnitInfo.Level or 1
	self.Team			= "Blue"
	self.Level          = 0
	self.Health			= 100
	self.TotalDamage    = 0
	self.Tree			= BehaviorTreeCreator:_createTree(ServerScriptService.UnitBrain.Brain) 
	self.Stats          = CustomUnitInfo.Stats or { Damage = "F", Cooldown = "F", Range = "F" }
	self.Range          = self.Upgrades[self.Level].Range
	self.Cooldown       = self.Upgrades[self.Level].Cooldown
	self.Damage         = self.Upgrades[self.Level].Damage
	or self.Upgrades[self.Level].Profit
	or self.Upgrades[self.Level].Slowness
	or self.Upgrades[self.Level].Buff
	self.DefaultDamage  = self.Damage
	self.Tags           = self.Upgrades.Tags
	self.Moneyspent     = (DefaultStats.Price * 0.5) or (self.Upgrades[0].Cost * 0.5)
	self.IsShiny        = false
	self.Detector       = nil
	self.Target         = nil
	self.LastTargetPosition = Vector3.new(0, 0, 0)
	self.Targeting      = "First"
	self.InsideZone     = {}
	self.TargetsInZone  = 0
	self.InCooldown     = false
	self.Attacked       = false
	self.IsActive       = true
	self.Priority       = {
		First     = true,
		Strongest = false,
		Weakest   = false,
		Fastest   = false,
	} :: PriorityTable

	return self
end

-- ─── Methods ─────────────────────────────────────────────────────────────────

function UnitManager:CheckTraits(Trait: string): (number?, number?)
	local UnitTraits = self.Traits

	if UnitTraits and UnitTraits.Name == Trait then
		local TraitsTable = Grades.Traits
		local ActualTrait = TraitsTable[Trait][UnitTraits.Level]
		local TraitValue: number = ActualTrait.Value

		return TraitValue, UnitTraits.Level
	end

	return nil
end

function UnitManager:CreateDetector(Unit: Model, Range: number): BasePart
	local Storage = workspace.GameAssets.Units.Detectors
	local AlreadyExists: BasePart? = Storage:FindFirstChild(Unit:GetAttribute("Id"))

	if not AlreadyExists then
		local Zone: BasePart = ReplicatedStorage.Assets.AOECircleP:Clone()
		Zone.Size          = Vector3.new(Range, Range, Range)
		Zone.CFrame        = Unit.PrimaryPart.CFrame
		Zone.Anchored      = true
		Zone.Transparency  = 1
		Zone.Name          = Unit:GetAttribute("Id")
		Zone.Parent        = Storage

		Zone.Mesh.Scale        = Vector3.new(Range, Range, Range)
		Zone.Floor.Decal.Transparency = 1

		return Zone
	else
		local Zone: BasePart = AlreadyExists

		Zone.CFrame       = Unit.PrimaryPart.CFrame
		Zone.Anchored     = true
		Zone.Transparency = 0
		Zone.Name         = Unit:GetAttribute("Id")

		TweenService:Create(
			Zone.Mesh,
			TweenInfo.new(1, Enum.EasingStyle.Bounce),
			{ Scale = Vector3.new(Range, Range, Range) }
		):Play()

		return Zone
	end
end

function UnitManager:SetCooldown(): ()
	local dt: number = 0

	self.InCooldown = true

	while dt < (self.Cooldown) do -- / workspace.Values.GameSpeed.Value
		dt += RunService.Heartbeat:Wait()
	end

	self.InCooldown = false
end

function UnitManager:Sell(): boolean
	if self.Unit then
		self.Owner.leaderstats.Cash.Value += self.Moneyspent
		self.IsActive = false
		self.Unit:Destroy()
		self.Detector:Destroy()

		return true
	end

	return false
end

function UnitManager:GetDictionaryLength(Table: { [any]: any }): number
	local count: number = 0

	for _, value in pairs(Table) do
		if value ~= nil then
			count += 1
		end
	end

	return count
end

function UnitManager:DecideTarget(): Model?
	local TargetAmount: number = #self.InsideZone

	local function accountForFastUnits(): Model?
		local FastestEntity: number = 0
		local newTarget: Model?

		for position, TargetInfo: TargetData in pairs(self.InsideZone) do
			local Speed: number = TargetInfo.Character:GetAttribute("Speed")

			if Speed > FastestEntity then
				FastestEntity = Speed
				newTarget = self.InsideZone[position].Character
			end
		end

		return newTarget
	end

	if TargetAmount > 1 then
		if self.Priority.First then
			if #self.InsideZone[1].Character:GetChildren() <= 0 then
				table.remove(self.InsideZone, 1)
			end

			self.Targeting = "First"
			return self.InsideZone[1].Character

		elseif self.Priority.Weakest then
			self.Targeting = "Weakest"
			local position: number = 1
			local ChoosenTarget = { Health = math.huge, Target = nil }

			for targetPos: number, Data: TargetData in ipairs(self.InsideZone) do
				if Data.Health <= ChoosenTarget.Health then
					ChoosenTarget.Health = Data.Health
					position = targetPos
				end
			end

			return self.InsideZone[position].Character or self.InsideZone[1].Character

		elseif self.Priority.Strongest then
			self.Targeting = "Strongest"
			local position: number = 1
			local ChoosenTarget = { Health = 0, Target = nil }

			for targetPos: number, Data: TargetData in ipairs(self.InsideZone) do
				if Data.MaxHealth and Data.MaxHealth >= ChoosenTarget.Health then
					ChoosenTarget.Health = Data.MaxHealth
					position = targetPos
				end
			end

			return self.InsideZone[position].Character or self.InsideZone[1].Character

		elseif self.Priority.Fastest then
			if #self.InsideZone[1].Character:GetChildren() <= 0 then
				table.remove(self.InsideZone, 1)
			end

			self.Targeting = "Fastest"
			return accountForFastUnits() or self.InsideZone[1].Character
		end

	elseif TargetAmount == 1 then
		return self.InsideZone[1].Character
	end

	return nil
end

function UnitManager:RemoveTarget(Id: number): ()
	for key: number, Data: TargetData in ipairs(self.InsideZone) do
		if Data.Id == Id then
			table.remove(self.InsideZone, key)
			return
		end
	end
end

function UnitManager:FindTarget(Id: number): boolean
	for _, Data: TargetData in ipairs(self.InsideZone) do
		if Data.Id == Id then
			return true
		end
	end

	return false
end

function UnitManager:LoadSound(SoundFile: Sound, Volume: number?): Sound
	local Sound: Sound? = self.Unit.RootPart:FindFirstChild(SoundFile.Name)
	Volume = Volume or 0.5

	if not Sound then
		Sound = SoundFile:Clone()
		Sound.Parent = self.Unit.RootPart
	end

	return Sound :: Sound
end

function UnitManager:BuffUnit(BuffInfo: BuffInfo): ()
	local UnitsCollection: { Model } = CollectionService:GetTagged("Units")

	self.Unit:SetAttribute("Distance", self.Range / 2)

	for _, Unit: Model in pairs(UnitsCollection) do
		local Distance: number = (Unit.PrimaryPart.Position - self.Unit.PrimaryPart.Position).Magnitude

		if (self.Range / 2) >= Distance and Unit.Name ~= self.Unit.Name then
			for name: string, value: number in pairs(BuffInfo) do
				if (Unit:GetAttribute(name) and Unit:GetAttribute(name) < value) or not Unit:GetAttribute(name) then
					Unit:SetAttribute(name, value)
					self.Unit:SetAttribute("Buff", true)
				elseif Unit:GetAttribute(name) and Unit:GetAttribute("Shiny") then
					if name == "Damage" then
						local _, dec: number = math.modf(value)
						local CurrentDamage: number = 1.3

						Unit:SetAttribute(name, CurrentDamage + dec)
						self.Unit:SetAttribute("Buff", true)
					end
				end
			end
		end
	end
end

function UnitManager:SlowUnit(Target: Model, burnTime: number, Type: string?): ()
	local t: number = 0

	task.spawn(function()
		local TargetSpeed: number = Target:GetAttribute("Speed")
		local Storage: { ParticleEmitter } = {}

		if Type then
			local Particle = Particles:FindFirstChild(Type)

			for _, parts in pairs(Target:GetChildren()) do
				if parts:IsA("BasePart") then
					local newParticle: ParticleEmitter = Particle:Clone()
					newParticle.Parent = Target.PrimaryPart
					table.insert(Storage, newParticle)
				end
			end
		end

		Target:SetAttribute("Speed", TargetSpeed - self.Damage)

		while t < burnTime do
			t += RunService.Heartbeat:Wait()
		end

		if #Storage > 0 then
			for _, particle: ParticleEmitter in ipairs(Storage) do
				particle:Destroy()
			end
		end

		Target:SetAttribute("Speed", TargetSpeed)
	end)
end

function UnitManager:Burn(Target: Model, burnTime: number, Type: string): ()
	local Particle = Particles:FindFirstChild(Type)
	local t: number = 0

	if Particle then
		local Storage: { ParticleEmitter } = {}

		for _, parts in pairs(Target:GetChildren()) do
			if parts:IsA("BasePart") then
				local newParticle: ParticleEmitter = Particle:Clone()
				newParticle.Parent = Target.PrimaryPart
				table.insert(Storage, newParticle)
			end
		end

		task.spawn(function()
			while t < burnTime do
				if Target then
					local TargetHealth: number = Target:GetAttribute("Health")
					Target:SetAttribute("Health", TargetHealth - self.Damage)
				end
				t += 1
				task.wait(0.5)
			end

			for _, particle: ParticleEmitter in ipairs(Storage) do
				particle:Destroy()
			end
		end)
	end
end

function UnitManager:LoadAnimation(Animation: Animation, Speed: number?): AnimationTrack
	local AnimationController: Humanoid = self.Unit.Humanoid
	Speed = Speed or 1

	local AnimationTrack: AnimationTrack = AnimationController:LoadAnimation(Animation)
	AnimationTrack:AdjustSpeed(Speed :: number)

	return AnimationTrack
end

function UnitManager:ChangeTargeting(): string?
	local TargetingMode: boolean = self.Priority[self.Targeting]

	if TargetingMode then
		local targetingModes: { string } = {
			"First",
			"Strongest",
			"Weakest",
			"Fastest",
		}

		self.Priority[self.Targeting] = false

		for key: number, value: string in ipairs(targetingModes) do
			if value == self.Targeting then
				self.Targeting = if key < #targetingModes
					then targetingModes[key + 1]
					else targetingModes[1]
				self.Priority[self.Targeting] = true
				return self.Targeting
			end
		end
	end

	return nil
end

function UnitManager:ConvertGradeInGame(
	UnitData: UnitDataInGame,
	StatName: string,
	Level: number?
): (number, StatGrade, string)
	local UnitStats         = UnitData.Stats
	local GradesTable       = Grades.Ranks
	local ActualGrade: StatGrade = UnitStats[StatName]
	local GradeValue: number     = GradesTable[ActualGrade]
	Level = Level or 0
	local UnitDefaultStats  = Units[UnitData.Name].Upgrades[Level :: number]
	local actualValue: number    = UnitDefaultStats[StatName] * GradeValue

	if StatName == "Cooldown" then
		actualValue = UnitDefaultStats[StatName] / GradeValue
	end

	return GradeValue, ActualGrade, format(actualValue)
end

function UnitManager:GetDamageWithBenefitsInGame(UnitData: UnitDataInGame, StatName: string): string
	local Level: number         = UnitData.Level
	local UnitDefaultStats      = Units[UnitData.Name].Upgrades[Level]
	local StatWithGrade: number = UnitManager:ConvertGradeInGame(UnitData, StatName)
	local Damage: number        = 0.0038 * (Level ^ 2) + 1.69 * Level + UnitDefaultStats.Damage

	Damage *= StatWithGrade

	return format(Damage)
end

function UnitManager:ConvertGrade(UnitData: UnitDataGeneric, StatName: string): (number, StatGrade, string)
	local UnitStats              = UnitData.Stats
	local GradesTable            = Grades.Ranks
	local ActualGrade: StatGrade = UnitStats[StatName]
	local GradeValue: number     = GradesTable[ActualGrade]
	local UnitDefaultStats       = Units[UnitData.Unit].Upgrades[0]
	local actualValue: number    = UnitDefaultStats[StatName] * GradeValue

	if StatName == "Cooldown" then
		actualValue = UnitDefaultStats[StatName] / GradeValue
	end

	return GradeValue, ActualGrade, format(actualValue)
end

function UnitManager:GetDamageWithBenefits(UnitData: UnitDataGeneric, StatName: string): string
	local Level: number         = UnitData.Level - 1
	local UnitDefaultStats      = Units[UnitData.Unit].Upgrades[0]
	local StatWithGrade: number = UnitManager:ConvertGrade(UnitData, StatName)
	local Damage: number        = 0.0038 * (Level ^ 2) + 1.69 * Level + UnitDefaultStats.Damage

	Damage *= StatWithGrade

	return format(Damage)
end

function UnitManager:GetGrade(StatName: string): (number, StatGrade)
	local UnitStats              = self.Stats
	local GradesTable            = Grades.Ranks
	local ActualGrade: StatGrade = UnitStats[StatName]
	local GradeValue: number     = GradesTable[ActualGrade]

	return GradeValue, ActualGrade
end

function UnitManager:Upgrade(player: Player): (boolean, UnitManagerObject)
	local CurrentLevel: number = self.Level
	local Upgrades             = self.Upgrades
	local nr_upgrades: number  = #self.Upgrades
	local Cash                 = player.leaderstats:FindFirstChild("Cash")

	local StatsToTrait: { [string]: string } = {
		["Damage"]   = "Ferocity",
		["Cooldown"] = "Haste",
		["Range"]    = "Hawkeye",
	}

	if Cash then
		if CurrentLevel < nr_upgrades then
			local NextStats = Upgrades[CurrentLevel + 1]
			local Cost: number = NextStats.Cost

			if Cash.Value >= Cost then
				local RootPart: BasePart? = self.Unit:FindFirstChild("HumanoidRootPart")
					or self.Unit:FindFirstChild("RootPart")

				if RootPart then
					local Holder = RootPart:FindFirstChild("Upgrading")

					for StatName: string, StatValue: number in pairs(NextStats) do
						if self[StatName] then
							local TraitValue: number = self:CheckTraits(StatsToTrait[StatName]) or 1
							local StatsGrade: number = self:GetGrade(StatName) or 1

							if StatName == "Damage" and self.IsShiny then
								StatValue *= 1.3
							end

							self.DefaultDamage = if StatName == "Damage"
								then StatValue * StatsGrade * TraitValue
								else self.DefaultDamage

							self[StatName] = if not TraitValue
								then StatValue
								else StatValue * StatsGrade * TraitValue

						elseif StatName == "Buff" or StatName == "Slowness" or StatName == "Profit" then
							self["Damage"] = StatValue
						end
					end

					if Holder then
						for _, Emitter in pairs(Holder:GetChildren()) do
							Emitter:Emit(5)
						end
					end

					self.Level    += 1
					Cash.Value    -= Cost

					if self.AbilityForLevel and self.AbilityForLevel[self.Level] then
						self.Ability = self.AbilityForLevel[self.Level]
					end

					return true, self
				else
					warn(self.Unit.Name, " Doesn't have a RootPart")
				end
			else
				return false, self
			end
		end
	end

	return false, self
end

function UnitManager:GetTargets(RootPart: BasePart): ()
	local AllAttackable: { Model } = workspace.GameAssets.Units:GetChildren()
	for _, Enemies: Model in pairs(AllAttackable) do
		local HumanoidRootPart: BasePart? = Enemies:FindFirstChild("HumanoidRootPart")

		if HumanoidRootPart then
			local Distance: number  = (HumanoidRootPart.Position - RootPart.Position).Magnitude
			local Enemy : Model  = HumanoidRootPart.Parent :: Model
			local EnemyTeam = Enemy:GetAttribute("Team")

			if Enemy ~= self.Unit and Distance <= 100 and self.Team ~= EnemyTeam then -- self.Range
				if Enemy and Enemy:GetAttribute("IsActive") then
					if self.Type ~= "Hybrid" and self.Type ~= Enemy:GetAttribute("MobType") then return end

					local InTable: boolean = self:FindTarget(Enemy:GetAttribute("Id"))

					if not InTable then
						local Died: boolean = false
						local TargetData: TargetData = {
							Id        = Enemy:GetAttribute("Id"),
							Character = Enemy,
							Health    = Enemy:GetAttribute("Health"),
						}

						Enemy:GetAttributeChangedSignal("Health"):Connect(function()
							local Health: number = Enemy:GetAttribute("Health")
							if Health <= 0 then
								self:RemoveTarget(TargetData.Id)
								self.Target = nil
								Died = true
							end
						end)

						if not Died then
							table.insert(self.InsideZone, TargetData)
						end
					end
				else
					if Enemy and not game.Players:GetPlayerFromCharacter(Enemy) then
						local Id: number = Enemy:GetAttribute("Id")
						self:RemoveTarget(Id)
						self.Target = nil
					end
				end
			else
				if Enemy and not game.Players:GetPlayerFromCharacter(Enemy) then
					local Id: number = Enemy:GetAttribute("Id")
					self:RemoveTarget(Id)
					self.Target = nil
				end
			end
		end
	end
end

function UnitManager:GetBuffUnit(): (boolean, number?)
	local UnitsCollection: { Model } = CollectionService:GetTagged("Units")
	local foundBuffUnit: boolean = false

	for _, Unit: Model in pairs(UnitsCollection) do
		local Distance: number = (Unit.PrimaryPart.Position - self.Unit.PrimaryPart.Position).Magnitude

		if Unit.Name ~= self.Unit.Name
			and Unit:GetAttribute("Buff")
			and Unit:GetAttribute("Distance")
			and Distance <= Unit:GetAttribute("Distance")
		then
			foundBuffUnit = true
			return true
		end
	end

	if not foundBuffUnit and self.Unit:GetAttribute("Shiny") then
		return true, 1.3
	end

	return false
end

function UnitManager:OnZoneTouched(Attackfunc: () -> ()): ()
	self.Detector = self:CreateDetector(self.Unit, self.Range)
	UnitService   = Knit.GetService("UnitService")

	local RootPart: BasePart? = self.Unit:FindFirstChild("HumanoidRootPart")
		or self.Unit:FindFirstChild("RootPart")
	local Target: Model?

	self.Unit:SetAttribute("IsActive", self.IsActive)

	-- while self.IsActive or self.Unit:SetAttribute("IsActive") do
		RootPart = self.Unit:FindFirstChild("HumanoidRootPart")
			or self.Unit:FindFirstChild("RootPart")

		if RootPart then
			-- self:GetTargets(RootPart)
			-- Target = self:DecideTarget()
			--
			-- if Target
			-- 	and (Target:FindFirstChild("HumanoidRootPart") or Target:FindFirstChild("RootPart"))
			-- 	and Target:GetAttribute("Health") > 0
			-- then
			-- 	self.Target = Target

				local TargetRootPart: BasePart = (
					self.Target:FindFirstChild("HumanoidRootPart")
					or self.Target:FindFirstChild("RootPart")
				) :: BasePart

				local NearBuff: boolean, Value: number? = self:GetBuffUnit()
				local Position: Vector3 = Vector3.new(
					TargetRootPart.Position.X,
					RootPart:GetPivot().Position.Y,
					TargetRootPart.Position.Z
				)
				local StopRotate: boolean = self.Unit:GetAttribute("StopRotate")
				local Stun: boolean       = self.Unit:GetAttribute("Stun")

				if not StopRotate then
					self.Unit:PivotTo(CFrame.lookAt(RootPart:GetPivot().Position, Position))
				end

				self.LastTargetPosition = RootPart:GetPivot().Position

				if not NearBuff then
					self.Damage = self.DefaultDamage
				else
					local Boosted: number = 1

					if self.Unit:GetAttribute("Damage") then
						if self.Unit:GetAttribute("Damage") <= 0 then
							Boosted = 1
						else
							Boosted = self.Unit:GetAttribute("Damage")
						end
					end

					if self.Unit:GetAttribute("Shiny") and Value then
						self.Unit:SetAttribute("Damage", Value)
						Boosted = Value :: number
					end

					self.Damage = self.DefaultDamage * Boosted
				end

				if not Stun then
					Attackfunc()
				end
		-- 	else
		-- 		if Target then
		-- 			self:RemoveTarget(Target:GetAttribute("Id"))
		-- 			Target = nil
		-- 		end
		-- 	end
		-- else
		-- 	self.IsActive = false
		-- end

		task.wait()
	end
end

function UnitManager.HandleAnimation(self: Types.UnitManagerObject, Action : string, Name : string)
	local UnitService = Knit.GetService("UnitService")

	if Action == "Play" then
		UnitService.Client.PlayAnimation:FireAll(Action, self.Unit, Name, nil) -- "Override"
	else
		UnitService.Client.PlayAnimation:FireAll(Action, self.Unit, Name, false) -- "Override"
	end
end

function UnitManager.Update(self : Types.UnitManagerObject)
	local result = self.Tree:Run(self)
	self.IsRunning = (result == 3)
end

function UnitManager:Destroy(): ()
	self.Unit:Destroy()
	self.Detector:Destroy()
	self.IsActive = false
end

return UnitManager

