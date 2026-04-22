local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Utility.Types)
local brain = {}
local SUCCESS, FAILED, RUNNING = 1, 2, 3

function brain.run(self : Types.UnitManagerObject, deltatime)
	local HumanoidRootPart = self.Unit.HumanoidRootPart
	local Humanoid : Humanoid = self.Unit.Humanoid

	if self.Target ~= nil then
		-- print("Trying to call walkAnimation")
		self:HandleAnimation("Play", "WalkAnim")
		Humanoid:MoveTo(self.Target:GetPivot().Position)
		return SUCCESS
	end
	return FAILED;
end

return brain
