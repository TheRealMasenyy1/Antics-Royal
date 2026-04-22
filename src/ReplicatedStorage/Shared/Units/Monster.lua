local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Monster = {}
Monster.__index = setmetatable(Monster,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string
}

function Monster.Setup(Unit, CustomData)
	local self = UnitManager.new(Unit, CustomData)
	setmetatable(self,Monster)

	self.Ability = "Roar"
	self.Type = "Hybrid"
	self.AbilityForLevel = {
		[1] = "Roar",
	}
	self.AbilityHitbox = {
		["Roar"] = {
			Type = "Beam",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(5,5,self.Range),
			PositionToCharacter = CFrame.new(0,0,-6);
			FireTimes = 3;
			CurrentFires = 0;
			PushPower = 120,
			MaxEntity = 5,
		},
	}

	--- Empty Constructor
	return self
end

function Monster:Attack(Enemy)
	
	if (not self.InCooldown and not self.AttackInUse) then --- If not in Cooldown Attack
		local TargetHealth = self.Target:GetAttribute("Health")
        local UnitService = Knit.GetService("UnitService")
        local UnitInfo : UnitInformation = {Unit = self.Unit,Name = self.Name, Owner = self.Owner, UnitId = self.Unit:GetAttribute("Id"), Ability = "RasenShuriken"}
		
		self.AttackInUse = true
        UnitService.Client.AttackVFX:FireAll(UnitInfo)

		-- task.wait(self.Animations.Attack.Length)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function Monster:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return Monster	