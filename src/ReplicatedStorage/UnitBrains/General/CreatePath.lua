local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathService = game:GetService("PathfindingService")
local Types = require(ReplicatedStorage.Shared.Utility.Types)
local brain = {}
local SUCCESS, FAILED, RUNNING = 1, 2, 3

function Visualize(Info : {[number] : PathWaypoint})
	workspace.Debris:ClearAllChildren()

	for i = 1, #Info do
		local node = Instance.new("Part")
		node.Size = Vector3.new(.2, .2, .2)
		node.CFrame = CFrame.new(Info[i].Position)
		node.Parent = workspace.Debris
		node.Color = Color3.fromRGB(0, 255, 0)
		node.Material = Enum.Material.Neon
		node.Anchored = true
	end
end

function brain.run(self : Types.UnitManagerObject, deltatime)
	local HumanoidRootPart = self.Unit.HumanoidRootPart
	local Distance = (HumanoidRootPart:GetPivot().Position - self.Target:GetPivot().Position).Magnitude

	self.Blackboard.Simple = false
	--? Attack distance should be a configuration option 
	if Distance <= 20 then
		self.Blackboard.Simple = true
		return SUCCESS
	else
		local path = PathService:CreatePath()
		local success, result = pcall(function()
			path:ComputeAsync(
				HumanoidRootPart:GetPivot().Position,
				self.Target:GetPivot().Position
			)
		end)

		if success then
			self.Waypoints = path:GetWaypoints()
			task.spawn(Visualize, self.Waypoints)
			return SUCCESS
		end
	end
	
	return SUCCESS
end

return brain
