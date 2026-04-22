local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityInfo = require(ReplicatedStorage.SharedPackage.Animations)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local Knit = require(ReplicatedStorage.Packages.Knit)

local CurseKing = {}
CurseKing.__index = setmetatable(CurseKing,UnitManager)

local UnitService;
local WorldService;

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string,
    Args : any,
}

function CurseKing.Setup(Unit, OwnerUnitInfo)
	local self = UnitManager.new(Unit,OwnerUnitInfo)
	setmetatable(self,CurseKing)

	self.UltimateInfo = {
		RequiredToActivate = 1500, -- Damage should increase
		HasActivated = false,
	}

	self.Ability = "Dismantle"
	self.AbilityForLevel = {
		[1] = "Dismantle",
		[3] = "Fire Arrow"
	}

	self.AbilityHitbox = {
		["Fire Arrow"] = {
			Type = "Throw",
			Size = Vector3.new(15,15,15),
			PushPower = 200,
			MaxEntity = 5,
		},

		["Dismantle"] = {
			Type = "ThrowAndDamageOverTime",
			HitVFX = "OnHit",
			Size = Vector3.new(10,10,10),
			Duration = 2,
			Slowness = 0.5, 
			PushPower = 100,
			MaxEntity = 5,
		},

		["Ultimate"] = {
			SkillType = "AEO",
			Type = "ThrowAndDamageOverTime",
			HitVFX = "OnHit",
			PushPower = 50,
			Damage = 5,
			Duration = 30;
			Size = Vector3.new(100,100,100),
			MaxEntity = 5,
		}
	}

	Unit:SetAttribute("UltimateCharge",0)
	--- Empty Constructor
	return self
end

function CurseKing:Ultimate()
	-- warn("THE UNIT IS USING HE'S ULTIMATE")
	local UnitInfo : UnitInformation = {
		Unit = self.Unit,
		Name = self.Name, 
		Owner = self.Owner, 
		Duration = self.AbilityHitbox.Ultimate.Duration,
		UnitId = self.Unit:GetAttribute("Id"), 
		Ability = "New Realm",
	}

	local CurseTemple = ReplicatedStorage.Assets.Buildings["Curse Temple"]:Clone()
	CurseTemple:PivotTo(self.Unit.HumanoidRootPart.CFrame)
	CurseTemple.Parent = self.Unit

	self.Unit:SetAttribute("UltimateCharge",0)
		
	--WorldService.MultiplySpeed:Fire(.1, true)
	UnitService.Client.AttackVFX:FireAll(UnitInfo)
end

function CurseKing:Attack(Enemy)
	
	if (not self.InCooldown and not self.AttackInUse) then
		local TargetHealth = self.Target:GetAttribute("Health")
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
		-- self.Target:SetAttribute("Health", TargetHealth - self.Damage)
		--self.Target.Humanoid:TakeDamage(self.Damage)
		
	else
		--warn("[ UNIT ] - IS IN COOLDOWN....")
	end 	
end

function CurseKing:Run()
	UnitService = Knit.GetService("UnitService")
	WorldService = Knit.GetService("WorldService")

	self:OnZoneTouched(function(Enemy) -- Attack when mobs in range
		self:Attack(Enemy)
	end)
end

return CurseKing	