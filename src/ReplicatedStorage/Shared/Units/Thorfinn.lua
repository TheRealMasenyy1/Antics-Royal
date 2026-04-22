local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Thorfinn = {}
Thorfinn.__index = setmetatable(Thorfinn,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string
}

function Thorfinn.Setup(Unit, CustomData)
	local self = UnitManager.new(Unit, CustomData)
	setmetatable(self,Thorfinn)

	self.Type = "Hybrid"
	self.Ability = "360 Slash"
	self.AbilityForLevel = {
		[3] = "Flashing Strikes",
		--[2] = "Solar Sphere",
	}

	--- Empty Constructor
	return self
end

function Thorfinn:Attack(Enemy)
	self.AbilityHitbox = {
		["360 Slash"] = {
			Type = "AOE",
			Size = Vector3.new(self.Range,self.Range,self.Range),
			PushPower = 175,
			MaxEntity = 15,
		},
		["Flashing Strikes"] = {
			Type = "Beam",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(6,6,self.Range),
			PositionToCharacter = CFrame.new(0,0,-5);
			PushPower = 120,
			MaxEntity = 10,
			StopRotate = true,
		},
	}

	if (not self.InCooldown and not self.AttackInUse) then --- If not in Cooldown Attack
		local TargetHealth = self.Target:GetAttribute("Health")
        local UnitService = Knit.GetService("UnitService")
        local UnitInfo : UnitInformation = {Unit = self.Unit,Name = self.Name, 
			Owner = self.Owner, 
			UnitId = self.Unit:GetAttribute("Id"), 
			Ability = self.Ability,
            Target = self.Target.HumanoidRootPart,
		}
		
		self.AttackInUse = true
        UnitService.Client.AttackVFX:FireAll(UnitInfo)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function Thorfinn:Run()
	-- self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
	-- 	self:Attack(Enemy)
	-- end)
end

return Thorfinn	
