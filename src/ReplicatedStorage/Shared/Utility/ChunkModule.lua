local Settings = {
	RangeOfLoad = 500, -- Distance in which parts will load / deload
	RestrictedPaths = {workspace.Map}, -- Folder / Instances you never want to be loaded / deloaded (Baseplate / required parts)
}

local ChunkLoader = {}

-- Tables
local PartData = {}
local PropertiesDATA = {}
PartData.__index = PartData


-- Services
local Camera = workspace.CurrentCamera
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ChunkFolder = workspace:WaitForChild("DebrisFolder")

local function CheckProperty(InstanceObject, PropertyName)
	InstanceObject.Archivable = true
	local ObjectClone = InstanceObject:Clone()
	if ObjectClone == nil then return end
	ObjectClone:ClearAllChildren()

	return (pcall(function()
		return ObjectClone[PropertyName]
	end))
end

local function SetProperties(InstanceObject)
	local NewProperties = {}
	
	setmetatable(NewProperties, PartData)
	NewProperties.Object = InstanceObject
	if CheckProperty(InstanceObject, "Transparency") then
		NewProperties.Transparency = InstanceObject.Transparency
	end
	if CheckProperty(InstanceObject, "CanCollide") then
		NewProperties.CanCollide = InstanceObject.CanCollide
	end
	if CheckProperty(InstanceObject, "Anchored") then
		NewProperties.Anchored = InstanceObject.Anchored
	end
	
	return NewProperties
	
end

local function GetParentPart(Object)
	local FirstParent = Object.Parent
    if not FirstParent then return end

	if not FirstParent:IsA("BasePart") then
		return FirstParent.Parent
	else
		return FirstParent
	end
end

local function CheckRestrictions(InstanceObject)
	for i, v in pairs(Settings.RestrictedPaths) do
		if InstanceObject:IsDescendantOf(v) then
			return
		end
	end
	for i, v in pairs(game.Players:GetPlayers()) do
		local CheckCharacter = v.Character or v.CharacterAdded:Wait()
		if InstanceObject:IsDescendantOf(CheckCharacter) then 
			return
		end
	end
	return true
end

local function GetPropertiesDATA(InstanceObject, TargetProperty)
	for i, v in pairs(PropertiesDATA) do
		if v.Object == InstanceObject and v:GetProperties(TargetProperty) then
			return v:GetProperties(TargetProperty)
		end
	end
end

local function Render(Object, Bool)
	if not Bool and CheckRestrictions(Object) then
		CollectionService:AddTag(Object, "Unrendered")
		if Object:IsA("BasePart") then
			Object.Transparency = 1
			Object.CanCollide = false
			Object.Anchored = true
		elseif Object:IsA("Texture") or Object:IsA("Decal") then
			Object.Transparency = 1
		elseif Object:IsA("ParticleEmitter") then
			Object:Clear()
		end
	else
		CollectionService:RemoveTag(Object, "Unrendered")
		if Object:IsA("BasePart") and CheckRestrictions(Object) then
			if Object:IsA("BasePart") then
				local Transparency = GetPropertiesDATA(Object, "Transparency")
				local CanCollide = GetPropertiesDATA(Object, "CanCollide")
				local Anchored = GetPropertiesDATA(Object, "Anchored")
				Object.Transparency = Transparency
				Object.CanCollide = CanCollide
				Object.Anchored = Anchored
			elseif Object:IsA("Texture") or Object:IsA("Decal") then
				local Transparency = GetPropertiesDATA(Object, "Transparency")
				Object.Transparency = Transparency
			end
		end
	end
end

local CheckLogic = {
	Unrendered = function(HRP, BasePart, RenderObject)
		local _, CanSee = Camera:WorldToViewportPoint(BasePart.Position)
		if (HRP.Position - BasePart.Position).Magnitude <= Settings["RangeOfLoad"] and CanSee then
			Render(RenderObject, true)
		end
	end,
	Rendered = function(HRP, BasePart, RenderObject)
		local _, CanSee = Camera:WorldToViewportPoint(BasePart.Position)
		if (HRP.Position - BasePart.Position).Magnitude >= Settings["RangeOfLoad"] or not CanSee then
			Render(RenderObject, false)
		end
	end,
}

local function PartCheck(Character, InstanceObject)
	local HRP = Character:WaitForChild("HumanoidRootPart")
	if CollectionService:HasTag(InstanceObject, "Unrendered") then
		if InstanceObject:IsA("BasePart") then
			CheckLogic["Unrendered"](HRP, InstanceObject, InstanceObject)
		else
			local ParentPart = GetParentPart(InstanceObject)
			if ParentPart:IsA("BasePart") then
				CheckLogic["Unrendered"](HRP, ParentPart, InstanceObject)
			end
		end
	else
		if InstanceObject:IsA("BasePart") then
			CheckLogic["Rendered"](HRP, InstanceObject, InstanceObject)
		else
			local ParentPart = GetParentPart(InstanceObject)
			if ParentPart:IsA("BasePart") then
				CheckLogic["Rendered"](HRP, ParentPart, InstanceObject)
			end
		end
	end
end

local function CheckChunk(Character, TotalProperties)
	for i, v in pairs(ChunkFolder:GetDescendants()) do
		if not v:IsA("Terrain") and CheckRestrictions(v) then
			PartCheck(Character, v)
		end
	end
end

function ChunkLoader.Initialize(Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild("Humanoid")
    local descendants = {}

    ChunkFolder.DescendantAdded:Connect(function(descendant)
        table.insert(descendants, descendant)
    end)

    local function CheckChunk(Character, TotalProperties)
        for _, descendant in ipairs(descendants) do
            if not descendant:IsA("Terrain") and CheckRestrictions(descendant) then
                PartCheck(Character, descendant )
            end
        end
    end

	for i, v in pairs(ChunkFolder:GetDescendants()) do
		if not v:IsA("Terrain") then
			local Properties = SetProperties(v)
			
			function Properties:GetProperties(PropertyName)
				return self[PropertyName]
			end
			
			table.insert(PropertiesDATA, Properties)
		end
	end
	
	local ChunkCheckConnection
	ChunkCheckConnection = RunService.Heartbeat:Connect(function()
		CheckChunk(Character)
	end)
	
	local ResetConnection
	ResetConnection = Humanoid.Died:Connect(function()
		ChunkCheckConnection:Disconnect()
		ResetConnection:Disconnect()
	end)
end

return ChunkLoader