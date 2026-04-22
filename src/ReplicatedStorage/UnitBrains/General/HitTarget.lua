local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Utility.Types)
local brain = {}
local SUCCESS, FAILED, RUNNING = 1, 2, 3


function brain.run(self : Types.UnitManagerObject, deltatime)
	local HumanoidRootPart = self.Unit.HumanoidRootPart
	local Distance = (HumanoidRootPart:GetPivot().Position - self.Target:GetPivot().Position).Magnitude
	-- warn("Here is the distance", Distance)
	if not self.InCooldown then
		self:Attack(self.Target)
		return SUCCESS
	end
	
	-- warn("Currenlty in cooldown")
	return FAILED
end

return brain
