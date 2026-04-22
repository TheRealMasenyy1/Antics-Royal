local Destruction = {}
Destruction.REFRESH_TIME = 25;
Destruction.MinimumSize = 2
Destruction.MaxParts = 50
Destruction.Lifetime = 5

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService= game:GetService("TweenService")
local Processing = {}

local DebrisFolder = Instance.new("Folder")
DebrisFolder.Parent = workspace
DebrisFolder.Name = "DebrisFolder";

local partPool = {}

local MAX_PARTS_PER_FRAME = Destruction.MaxParts

local tempHitbox = Instance.new("Part")
tempHitbox.Name = "tempHitbox"
tempHitbox.Color = Color3.fromRGB(255)
tempHitbox.Transparency = 1
tempHitbox.Anchored = true
tempHitbox.CanCollide = false

function Destruction:PartitionAndVoxelizePart(Location: CFrame, sectionSize:Vector3, Velocity:Vector3)
	local DestructionActor = ReplicatedStorage.Destruction:Clone()

	local hitbox = tempHitbox:Clone()
	hitbox.Size = Vector3.new(5,5,5) --sectionSize
	hitbox.CFrame = Location
	hitbox.Parent = workspace.Debris

	DestructionActor.Parent = hitbox
	DestructionActor.Script.Enabled = false

	DestructionActor.sectionSize.Value = sectionSize
	DestructionActor.Velocity.Value = Velocity
	DestructionActor.Location.Value = Location

	DestructionActor.MaxParts.Value = Destruction.MaxParts
	DestructionActor.MinimumSize.Value = Destruction.MinimumSize
	DestructionActor.Lifetime.Value = Destruction.Lifetime

	task.delay(.25,function()
		DestructionActor.Script.Enabled = true
	end)
	task.delay(1, game.Destroy, hitbox)
end

return Destruction
