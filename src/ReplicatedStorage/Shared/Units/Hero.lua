local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Hero = {}
Hero.__index = setmetatable(Hero,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string
}

function Hero.Setup(Unit)
	local self = UnitManager.new(Unit)
	setmetatable(self,Hero)

	self.Ability = "???"

	--- Empty Constructor
	return self
end

function Hero:Attack(Enemy)
	
	if (not self.InCooldown and not self.AttackInUse) then
		local TargetHealth = self.Target:GetAttribute("Health")
        local UnitService = Knit.GetService("UnitService")
        local UnitInfo : UnitInformation = {Unit = self.Unit,Name = self.Name, Owner = self.Owner, UnitId = self.Unit:GetAttribute("Id"), Ability = self.Ability}

		self.AttackInUse = true
		
        UnitService.Client.AttackVFX:FireAll(UnitInfo)
		
		-- task.wait(self.Animations.Attack.Length)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function Hero:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return Hero	