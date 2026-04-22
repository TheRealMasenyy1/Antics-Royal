local PartCache = require(script:WaitForChild("PartCache"))

local PartTemplate = Instance.new("Part")
PartTemplate.CanTouch = false
PartTemplate.CanQuery = false
PartTemplate.CastShadow = false
PartTemplate.Transparency = 0
PartTemplate.Material = Enum.Material.SmoothPlastic

local VoxelCache = PartCache.new(PartTemplate, 100, workspace:WaitForChild("PartCacheFolder"))

local function GetMinimumN(targetPart: BasePart)
	local largest = math.max(targetPart.Size.X, targetPart.Size.Y, targetPart.Size.Z)
	local smallest = math.min(targetPart.Size.X, targetPart.Size.Y, targetPart.Size.Z)
	local N = math.ceil(largest / smallest)
    -- warn("THIS IS THE MINIMUN N: ", N)
	return N
end

local function CanPartSubdivide(targetPart: BasePart, N: number)
	N = N or GetMinimumN(targetPart)
	local largest = math.max(targetPart.Size.X, targetPart.Size.Y, targetPart.Size.Z)
	local smallest = math.min(targetPart.Size.X, targetPart.Size.Y, targetPart.Size.Z)
    local result = smallest >= largest / N

	return result
end

local function SubdividePart(TargetPart: BasePart, N: number)
	local PartTables = {}
	local VectorSet = {}
	
	local X, Y, Z = TargetPart.Size.X, TargetPart.Size.Y, TargetPart.Size.Z
	local LargestAxis = math.max(X, Y, Z)
	if LargestAxis == X then
		X /= 2
		VectorSet = {Vector3.xAxis, -Vector3.xAxis}
	elseif LargestAxis == Y then
		Y /= 2
		VectorSet = {Vector3.yAxis, -Vector3.yAxis}
	elseif LargestAxis == Z then
		Z /= 2
		VectorSet = {Vector3.zAxis, -Vector3.zAxis,}
	end

	for _, offsetVector in VectorSet do
		local clone = VoxelCache:GetPart()
		clone.Parent = workspace
		clone.Size = Vector3.new(X, Y, Z)
		clone.CFrame += TargetPart.CFrame:VectorToWorldSpace((Vector3.new(X, Y, Z) / 2.0) * offsetVector)
		table.insert(PartTables, clone)
	end
	
	TargetPart:Destroy()
	return PartTables
end

local function Voxelize(TargetPart: Part, N: number, ClearTime: number?): {BasePart}
	local Voxels = {}
	local InitialClone = VoxelCache:GetPart()
	local LeftCorner = -TargetPart.Size / 2
	local InitialPos = LeftCorner + Vector3.new(N / 2, N / 2, N / 2)
	local TargetSize = Vector3.new(
		N * math.ceil(TargetPart.Size.X / N),
		N * math.ceil(TargetPart.Size.Y / N),
		N * math.ceil(TargetPart.Size.Z / N)
	)
	
	-- This of this as traveling a 3D grid, from top left corner 
	for x = 0, TargetSize.X - N, N do
		for y = 0, TargetSize.Y - N, N do
			for z = 0, TargetSize.Z - N, N do
				local NewBlockSize = Vector3.new(
					math.min(N, TargetPart.Size.X - x),
					math.min(N, TargetPart.Size.Y - y),
					math.min(N, TargetPart.Size.Z - z)
				)
				local NewBlockPos = Vector3.new(x, y, z) + 
					((NewBlockSize / 2) - (Vector3.new(N, N, N) / 2))
				
				local NewBlockCFrame = TargetPart.CFrame * CFrame.new(InitialPos + NewBlockPos)
				local clone = VoxelCache:GetPart()
				clone.Anchored = true
				clone.Size = NewBlockSize
				clone.CFrame = NewBlockCFrame
				clone.Material = TargetPart.Material
				clone.Color = TargetPart.Color
				clone.Transparency = 0
				clone.Parent = TargetPart.Parent

				InitialClone.CFrame = NewBlockCFrame
				InitialClone.Size = NewBlockSize
				InitialClone.Transparency = 1
				table.insert(Voxels, clone)
			end    
		end
	end
	
	if type(ClearTime) == 'number' then
		task.delay(ClearTime, function()
			for _, part in Voxels do
				VoxelCache:ReturnPart(part)
			end
		end)
	end
	
	TargetPart:Destroy()
	InitialClone:Destroy()
	return Voxels
end

local function VoxelizePartsInRadius( --- Used to remove think inside a parts 
	Position: Vector3,
	Radius: number,
	ClearTime : number,
	DestroyType: "Destroy" | "Unanchor"
)
	ClearTime = ClearTime or 1.5
	
	local Hitbox = Instance.new("Part")
	Hitbox.Size = Vector3.new(Radius*1.5,Radius*1.5,Radius*1.5)
	Hitbox.CFrame = CFrame.new(Position)
	Hitbox.Color = Color3.fromRGB(255)
	Hitbox.Transparency = .5
	Hitbox.Anchored = true
	Hitbox.Parent = workspace
	
	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = {workspace.Map.Buildings, workspace.GameAssets.Maps} -- Add other things that we don't want to be destroyed

	local Targets = workspace:GetPartsInPart(Hitbox, Params)	
	local TargetParts = {}
	
	task.delay(1, function()
		Hitbox:Destroy()
	end)
	
	if Targets then
		for _,part in Targets do
            local N = GetMinimumN(part)

            if CanPartSubdivide(part, N) then
                local Voxels = Voxelize(part, N)
                local Params = OverlapParams.new()
                Params.FilterType = Enum.RaycastFilterType.Include
                Params.FilterDescendantsInstances = Voxels
                
                part.Color = Color3.fromRGB(255)
                local Results = workspace:GetPartBoundsInRadius(Position, Radius, Params)

                for _, part in Results do
                    if DestroyType == "Destroy" then
                        part:Destroy()
                    elseif DestroyType == "Unanchor" then
                        part.Anchored = false
                        table.insert(TargetParts, part)
                    end
                end
            end
		end
		
		if type(ClearTime) == 'number' then
			task.delay(ClearTime, function()
				for _, part in TargetParts do
					VoxelCache:ReturnPart(part)
				end
			end)
		end
	end	
	
	return TargetParts
end


return {
	GetMinimumN = GetMinimumN;
	CanPartSubdivide = CanPartSubdivide;
	SubdividePart = SubdividePart;
	Voxelize = Voxelize;
	
	VoxelizePartsInRadius = VoxelizePartsInRadius;
}