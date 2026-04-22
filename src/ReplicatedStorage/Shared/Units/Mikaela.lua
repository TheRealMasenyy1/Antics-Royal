local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Mikaela = {}
Mikaela.__index = setmetatable(Mikaela,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string
}

function Mikaela.Setup(Unit, CustomData)
	local self = UnitManager.new(Unit, CustomData)
	setmetatable(self,Mikaela)

	self.Type = "Hybrid"
	self.Ability = "Scarlet Pierce"
	self.AbilityForLevel = {
		[1] = "Blood Ascension",
		--[2] = "Solar Sphere",
	}
	self.AbilityHitbox = {
		["Blood Ascension"] = {
			Type = "Throw",
			Size = Vector3.new(7,7,7),
			PushPower = 175,
			MaxEntity = 5,
		},
		["Scarlet Pierce"] = {
			Type = "Throw",
			Size = Vector3.new(8,8,8),
			PushPower = 175,
			MaxEntity = 5,
		},
	}

	--- Empty Constructor
	return self
end

function Mikaela:Attack(Enemy)
	
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

function Mikaela:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return Mikaela	