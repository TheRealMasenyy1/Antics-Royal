local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Warrior = {}
Warrior.__index = setmetatable(Warrior,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string,
    Args : any,
}

function Warrior.Setup(Unit, CustomUnitInfo) 
	local self = UnitManager.new(Unit,CustomUnitInfo)
	setmetatable(self,Warrior)

	-- self.UltimateInfo = {
	-- 	RequiredToActivate = 1500, -- Damage should increase
	-- 	HasActivated = false,
	-- }

	self.Type = "Ground"
	self.Ability = "Stab"
	self.AbilityForLevel = {
		[1] = "Stab",
		[3] = "RasenShuriken",
	}

	self.AbilityHitbox = {
		["Stab"] = {
			Type = "Beam",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(5,5,self.Range),
			PositionToCharacter = CFrame.new(0,0,-self.Range/2);
			PushPower = 120,
			MaxEntity = 5,
		},

		["RasenShuriken"] = {
			Type = "Throw",
			Size = Vector3.new(10,10,10),
			PushPower = 150,
			MaxEntity = 5,
		},
	}

	-- Unit:SetAttribute("UltimateCharge",0)
	--- Empty Constructor
	return self
end

function Warrior:Attack(Enemy)
	
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

		-- task.spawn(function()
		-- 	self:SetCooldown()
		-- end)
		
		-- task.wait(self.Animations.Attack.Length)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function Warrior:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return Warrior	