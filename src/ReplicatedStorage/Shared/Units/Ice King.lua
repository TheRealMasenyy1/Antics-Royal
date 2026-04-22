local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local IceKing = {}
IceKing.__index = setmetatable(IceKing,UnitManager)

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string,
    Args : any,
}

function IceKing.Setup(Unit,CustomUnitInfo)
	local self = UnitManager.new(Unit,CustomUnitInfo)
	setmetatable(self,IceKing)

	-- self.UltimateInfo = {
	-- 	RequiredToActivate = 1500, -- Damage should increase
	-- 	HasActivated = false,
	-- }

	self.Ability = "Ice Spikes"
	self.AbilityHitbox = {
		["Ice Spikes"] = {
			Type = "Throw",
			PushPower = 50,
			Size = Vector3.new(10,10,10),
			MaxEntity = 5,
		},
	}

	return self
end

function IceKing:Attack(Enemy)
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
		-- self.Target:SetAttribute("Health", TargetHealth - self.Damage)
		--self.Target.Humanoid:TakeDamage(self.Damage)

		-- task.spawn(function()
		-- 	self:SetCooldown()
		-- end)
		
		-- task.wait(self.Animations.Attack.Length)
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 
end

function IceKing:Run()
	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return IceKing	