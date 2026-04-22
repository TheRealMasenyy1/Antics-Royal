local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Yuichiro = {}
Yuichiro.__index = setmetatable(Yuichiro,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string
}

function Yuichiro.Setup(Unit, CustomData)
	local self = UnitManager.new(Unit, CustomData)
	setmetatable(self,Yuichiro)

	self.Type = "Hybrid"
	self.Ability = "Raven Descent"
	self.AbilityForLevel = {
		[1] = "Eclipse Strike",
		--[2] = "Solar Sphere",
	}
	self.AbilityHitbox = {
		["Raven Descent"] = {
			Type = "Throw",
			Size = Vector3.new(10,0,10),
			PushPower = 175,
			MaxEntity = 5,
			Stun = .5,
		},
		["Eclipse Strike"] = {
			Type = "Beam",
			HitVFX = "MobHit",
			PushDirection = "Forward",
			Size = Vector3.new(4,4,self.Range),
			PositionToCharacter = CFrame.new(0,0,-5);
			PushPower = 120,
			MaxEntity = 10,
			StopRotate = true,
		},
	}

	--- Empty Constructor
	return self
end

function Yuichiro:Attack(Enemy)
	
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

function Yuichiro:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return Yuichiro	