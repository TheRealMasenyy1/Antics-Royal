local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local LostNinja = {}
LostNinja.__index = setmetatable(LostNinja,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string,
    Args : any,
}

function LostNinja.Setup(Unit, CustomUnitInfo) 
	local self = UnitManager.new(Unit,CustomUnitInfo)
	setmetatable(self,LostNinja)

	self.Type = "Ground"
	self.Ability = "Flamethrower"
	self.AbilityForLevel = {
		--[3] = "RasenShuriken",
		--[3] = "RasenShuriken",
	}

	self.AbilityHitbox = {
		["Flamethrower"] = {
			Type = "BeamAndDamageOverTime",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(5,5,self.Range),
			PositionToCharacter = CFrame.new(0,0,-5);
			PushPower = 120,
			MaxEntity = 5,
			StopRotate = true,
			Duration = 1.5,
		},
	}

	Unit:SetAttribute("UltimateCharge",0)
	--- Empty Constructor
	return self
end

function LostNinja:Attack(Enemy)
	
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
            -- Args = {Position = self.Target.HumanoidRootPart.Position}
        }

		self.AttackInUse = true

		if self.AbilityHitbox[self.Ability].StopRotate ~= nil and self.AbilityHitbox[self.Ability].StopRotate then
			self.Unit:SetAttribute("StopRotate", true)

			task.delay(2.25,function()
				self.Unit:SetAttribute("StopRotate", false)
			end)

		end

		UnitService.Client.AttackVFX:FireAll(UnitInfo)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function LostNinja:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return LostNinja	
