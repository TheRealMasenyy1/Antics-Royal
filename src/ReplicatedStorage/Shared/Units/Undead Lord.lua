local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local UndeadLord = {}
UndeadLord.__index = setmetatable(UndeadLord,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string,
    Args : any,
}

function UndeadLord.Setup(UnitObject,CustomUnitInfo)
	local Unit = UnitManager.new(UnitObject,CustomUnitInfo)
	setmetatable(Unit,UndeadLord)

	-- self.UltimateInfo = {
	-- 	RequiredToActivate = 1500, -- Damage should increase
	-- 	HasActivated = false,
	-- }
	
	Unit.Type = "Hybrid"
	Unit.Ability = "Rock Rain"
	Unit.AbilityForLevel = {
		[1] = "Rock Rain",
		[3] = "Poison",
	}
	
	Unit.AbilityHitbox = {
		["Poison"] = {
			Type = "PoisonDamage",
			HitVFX = "Poison",
			PushPower = 1,
			Damage = 10,
			Duration = 5;
			HitboxDuration = 2;
			Delay = .5,
			Size = Vector3.new(5,5,5),
			MaxEntity = 5,
		},

		["Rock Rain"] = {
			Type = "Throw",
			Destruction = true,
			PushPower = 100,
			Size = Vector3.new(10,10,10),
			MaxEntity = 5,
		},
	}

	return Unit
end

function UndeadLord:Attack(Enemy)
	if (not self.InCooldown and not self.AttackInUse) then --- If not in Cooldown Attack
		local TargetHealth = self.Target:GetAttribute("Health")
        local UnitService = Knit.GetService("UnitService")
        local UnitInfo : UnitInformation = {
            Unit = self.Unit,
			Name = self.Name, 
            Owner = self.Owner, 
            UnitId = self.Unit:GetAttribute("Id"), 
            Ability = self.Ability,
			AbilityInfo = self.AbilityHitbox[self.Ability],
            Target = self.Target.HumanoidRootPart,
            -- Args = {Position = self.Target.HumanoidRootPart.Position}
        }

		self.AttackInUse = true
        UnitService.Client.AttackVFX:FireAll(UnitInfo)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function UndeadLord:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return UndeadLord	