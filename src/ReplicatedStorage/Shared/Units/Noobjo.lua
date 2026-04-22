local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Noobjo = {}
Noobjo.__index = setmetatable(Noobjo,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string,
    Args : any,
}

function Noobjo.Setup(Unit, CustomUnitInfo) 
	local self = UnitManager.new(Unit,CustomUnitInfo)
	setmetatable(self,Noobjo)

	self.UltimateInfo = {
		RequiredToActivate = 1500, -- Damage should increase
		HasActivated = false,
	}

	self.Type = "Hybrid"
	self.Ability = "Red"
	self.AbilityForLevel = {
		[1] = "Red",
		[4] = "Purple",
		--[3] = "RasenShuriken",
	}

	self.AbilityHitbox = {
		["Red"] = {
			Type = "Throw",
			Size = Vector3.new(10,10,10),
			PushPower = 50,
			MaxEntity = 5,
		},

		["Purple"] = {
			Type = "Throw",
			Size = Vector3.new(3,3,3),
			PushPower = 150,
			MaxEntity = 5,
			StopRotate = true,
		},
	}

	Unit:SetAttribute("UltimateCharge",0)
	--- Empty Constructor
	return self
end

function Noobjo:Attack(Enemy)
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
        UnitService.Client.AttackVFX:FireAll(UnitInfo)

		if self.AbilityHitbox[self.Ability].StopRotate ~= nil and self.AbilityHitbox[self.Ability].StopRotate then
			self.Unit:SetAttribute("StopRotate", true)

			task.delay(2.1,function()
				self.Unit:SetAttribute("StopRotate", false)
			end)

		end

		-- self.Target:SetAttribute("Health", TargetHealth - self.Damage)
		--self.Target.Humanoid:TakeDamage(self.Damage)
		
		-- task.wait(self.Animations.Attack.Length)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function Noobjo:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return Noobjo	