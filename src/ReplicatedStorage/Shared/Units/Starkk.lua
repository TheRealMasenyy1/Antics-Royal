local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Starkk = {}
Starkk.__index = setmetatable(Starkk,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string
}

function Starkk.Setup(Unit, CustomData)
	local self = UnitManager.new(Unit, CustomData)
	setmetatable(self,Starkk)

	self.Type = "Hybrid"
	self.Ability = "Metralleta"
	self.AbilityForLevel = {
		[2] = "Wolf Barrage",
		[3] = "Dual Eclipse",
		--[2] = "Solar Sphere",
	}
	self.AbilityHitbox = {
		["Wolf Barrage"] = {
			Type = "Throw",
			Size = Vector3.new(10,0,10),
			PushPower = 175,
			MaxEntity = 5,
			Stun = .5,
		},
		["Metralleta"] = {
			Type = "Beam",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(10,10,self.Range),
			PositionToCharacter = CFrame.new(0,0,-5);
			PushPower = 120,
			MaxEntity = 10,
			StopRotate = true,
		},
		["Dual Eclipse"] = {
			Type = "Beam",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(6,6,self.Range-2),
			PositionToCharacter = CFrame.new(0,0,-4);
			PushPower = 120,
			MaxEntity = 10,
			StopRotate = true,
		},
	}

	--- Empty Constructor
	return self
end

function Starkk:Attack(Enemy)
	
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

		-- task.spawn(function()
		-- 	self:SetCooldown()
		-- end)
		
		-- task.wait(self.Animations.Attack.Length)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function Starkk:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return Starkk	