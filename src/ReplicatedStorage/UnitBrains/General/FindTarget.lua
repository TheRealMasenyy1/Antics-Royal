local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Utility.Types)
local brain = {}
local SUCCESS, FAILED, RUNNING = 1, 2, 3


function brain.run(self : Types.UnitManagerObject, deltatime)
	local HumanoidRootPart = self.Unit.HumanoidRootPart
	self:GetTargets(HumanoidRootPart)
	self.Target = self:DecideTarget()

	if self.Target ~= nil then
		self.Blackboard.HasTarget = true
		return SUCCESS;
	end
	
	return FAILED
end

return brain
