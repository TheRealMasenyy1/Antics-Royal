local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local LegendaryBerserker = {}
LegendaryBerserker.__index = setmetatable(LegendaryBerserker,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string,
    Args : any,
}

function LegendaryBerserker.Setup(Unit, CustomUnitInfo) 
	local self = UnitManager.new(Unit,CustomUnitInfo)
	setmetatable(self,LegendaryBerserker)

	self.Type = "Ground"
	self.Ability = "EraserBlast"--"MeteorShower"--"EraserBlast"--"BreakerRay"
	self.AbilityForLevel = {
		[2] = "BreakerRay",
		[4] = "MeteorShower",
	}

	Unit:SetAttribute("UltimateCharge",0)
	--- Empty Constructor
	return self
end

function LegendaryBerserker:Attack(Enemy)
	self.AbilityHitbox = {
		["BreakerRay"] = {
			Type = "BeamAndDamageOverTime",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(5,5,self.Range),
			PositionToCharacter = CFrame.new(0,0,-5);
			PushPower = 120,
			MaxEntity = 10,
			--StopRotate = true,
			Duration = 1.25,
			HitDelay = .1885,
		},

		["MeteorShower"] = {
			Type = "AOEAndDamageOverTime",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(self.Range,self.Range,self.Range),
			PushPower = 120,
			MaxEntity = 10,
			StopRotate = true,
			Duration = 5,
		},

		["EraserBlast"] = {
			Type = "Throw",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(10,10,10),
			--PositionToCharacter = CFrame.new(0,0,-5);
			PushPower = 120,
			MaxEntity = 10,
			StopRotate = false,
		},
	}
	
	if (not self.InCooldown and not self.AttackInUse) then --- If not in Cooldown Attack
		local TargetHealth = self.Target:GetAttribute("Health")
        local UnitService = Knit.GetService("UnitService")
        local UnitInfo : UnitInformation = {
            Unit = self.Unit,
			Name = self.Name, 
            Owner = self.Owner, 
            UnitId = self.Unit:GetAttribute("Id"), 
            Ability = self.Ability,
            Target = self.Target.HumanoidRootPart,
			Range = self.Range,
            -- Args = {Position = self.Target.HumanoidRootPart.Position}
        }

		self.AttackInUse = true

		if self.AbilityHitbox[self.Ability].StopRotate ~= nil and self.AbilityHitbox[self.Ability].StopRotate then
			self.Unit:SetAttribute("StopRotate", true)

			task.delay(.75,function()
				self.Unit:SetAttribute("StopRotate", false)
			end)

		end

		UnitService.Client.AttackVFX:FireAll(UnitInfo)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function LegendaryBerserker:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return LegendaryBerserker	