local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local PirateKing = {}
PirateKing.__index = setmetatable(PirateKing,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string
}

function PirateKing.Setup(Unit, CustomUnitInfo)
	local self = UnitManager.new(Unit, CustomUnitInfo)
	setmetatable(self,PirateKing)

	self.Type = "Ground"
	self.Ability = "Gatling"
	self.AbilityForLevel = {
		[1] = "Gatling",
	}

	-- Unit:SetAttribute("UltimateCharge",0)

	--- Empty Constructor
	return self
end

function PirateKing:Attack(Enemy)
	self.AbilityHitbox = {
		["Gatling"] = {
			Type = "Beam",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(5,5,self.Range),
			PositionToCharacter = CFrame.new(0,0,-self.Range/2);
			FireTimes = 3;
			CurrentFires = 0;
			PushPower = 120,
			MaxEntity = 5,
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
			Ability = self.Ability}

		self.AttackInUse = true
		
        UnitService.Client.AttackVFX:FireAll(UnitInfo)
		-- self.Target:SetAttribute("Health", TargetHealth - self.Damage)
		--self.Target.Humanoid:TakeDamage(self.Damage)

		-- task.wait(self.Animations.Attack.Length)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function PirateKing:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return PirateKing	