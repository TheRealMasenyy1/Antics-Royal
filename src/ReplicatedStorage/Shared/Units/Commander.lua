local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Commander = {}
Commander.__index = setmetatable(Commander,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string,
    Args : any,
}

function Commander.Setup(Unit, CustomUnitInfo) 
	local self = UnitManager.new(Unit,CustomUnitInfo)
	setmetatable(self,Commander)

	-- self.UltimateInfo = {
	-- 	RequiredToActivate = 1500, -- Damage should increase
	-- 	HasActivated = false,
	-- }

	self.Type = "Hybrid"
	self.Ability = "Precision Shot"
	self.AbilityForLevel = {
		[1] = "Precision Shot",
		[3] = "Bullet Barrage", 
		[6] = "Strong beam",
	}

	self.AbilityHitbox = {
		["Strong beam"] = {
			Type = "Beam",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(5,5,self.Range),
			PositionToCharacter = CFrame.new(0,0,-5);
			PushPower = 120,
			MaxEntity = 5,
		},

		["Bullet Barrage"] = {
			Type = "Beam",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(5,5,self.Range),
			PositionToCharacter = CFrame.new(0,0,-5);
			FireTimes = 5;
			CurrentFires = 0;
			PushPower = 120,
			MaxEntity = 5,
		},

		["Precision Shot"] = {
			Type = "Throw",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(5,5,5),
			FireTimes = 2;
			CurrentFires = 0;
			PushPower = 50,
			MaxEntity = 5,
		},
	}

	-- Unit:SetAttribute("UltimateCharge",0)
	--- Empty Constructor
	return self
end

function Commander:Attack(Enemy)

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

function Commander:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return Commander	