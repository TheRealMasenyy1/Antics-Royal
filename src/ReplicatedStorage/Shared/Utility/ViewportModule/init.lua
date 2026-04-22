local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitStorage = ReplicatedStorage.Units
local Promise = require(ReplicatedStorage.Shared.Utility.PromiseTyped)
local ViewportModule = {}

function ViewportModule:ChangeAnimation(Viewport, Animation : string) --- Changes the animation of a unit in viewport

end

function ViewportModule:CreateUnitViewport(Name : string, CFrameRelativeToHead : CFrame) : ViewportFrame | nil
    local worldModel = script.WorldModel
	local Unit = UnitStorage:FindFirstChild(Name)

    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1,0,1,0)
	viewport.BackgroundTransparency = 1

	if Unit then
		local WM = worldModel:Clone()
		local NewUnit = Unit:Clone()
		NewUnit.Name = "VPModel"

		local Port: ViewportFrame = viewport:Clone()
		Port.BackgroundColor3 = Color3.fromRGB(96, 95, 97)
		WM.Parent = Port;
		
		local Cam = Instance.new("Camera")
		Cam.Parent = Port
		Port.BackgroundTransparency = 1
		Port.CurrentCamera = Cam;
		NewUnit.Parent = WM;
		
		Port.Name = Unit.Name
		Cam.CFrame = CFrame.new((NewUnit.Head.CFrame * (CFrameRelativeToHead or CFrame.new(0,0,-1.5))).Position,NewUnit.Head.Position + Vector3.new(0,-.3,0))
		
		Promise.new(function(resolve, reject, cancel)
			local UnitInfo = require(game.ReplicatedStorage.Shared.UnitInfo).UnitInformation[Unit.Name]
			local AnimId = UnitInfo.IdleAnim
			local Speed = UnitInfo.AdjustSpeed or 1
			local Anim = Instance.new("Animation")
			Anim.Name = "Idle";
			Anim.AnimationId = "rbxassetid://" .. AnimId
			Anim.Parent = WM.Animate;
			-- warn("Unit has been loaded")
		end):catch(function(Text)
			warn("Couldn not load animation for " .. Unit.Name)
			warn(Text)
		end)

		Port.Parent = ReplicatedStorage.Assets.Viewports

		return Port
	end

    return nil;
end

function ViewportModule:Initialize()
    local Count = 0
    local MaxCount = #UnitStorage:GetChildren() - 1

    local worldModel = script.WorldModel

    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1,0,1,0)
    viewport.Parent = script.Parent
	viewport.BackgroundTransparency = 1

	for i,Unit in pairs(UnitStorage:GetChildren()) do
		if Unit and Unit:IsA("Model") then
			local WM = worldModel:Clone()
			local NewUnit = Unit:Clone()
			NewUnit.Name = "VPModel"

			local Port: ViewportFrame = viewport:Clone()
			WM.Parent = Port;
            
			local Cam = Instance.new("Camera")
			Cam.Parent = Port
			Port.BackgroundTransparency = 1
			Port.CurrentCamera = Cam;
			NewUnit.Parent = WM;
			
            Port.Name = Unit.Name
			Cam.CFrame = CFrame.new((NewUnit.Head.CFrame * (Unit:GetAttribute("ViewportOffset") or CFrame.new(0,0,-1.5))).Position,NewUnit.Head.Position + Vector3.new(0,-.3,0))
			
			Promise.new(function(resolve, reject, cancel)
				local UnitInfo = require(game.ReplicatedStorage.Shared.UnitInfo).UnitInformation[Unit.Name]
				local AnimId = UnitInfo.IdleAnim
				local Speed = UnitInfo.AdjustSpeed or 1
				local Anim = Instance.new("Animation")
				Anim.Name = "Idle";
				Anim.AnimationId = "rbxassetid://" .. AnimId
				Anim.Parent = WM.Animate;
			end):catch(function(Text)
				warn("Couldn not load animation for " .. Unit.Name)
			end)
			-- WM.Animate.Enabled = false

            Port.Parent = ReplicatedStorage.Assets.Viewports

            Count += 1;
		end
	end

    return Count, MaxCount;
end

function ViewportModule:InitializeItems()
	local Items = ReplicatedStorage.Assets.Viewports.Items:GetChildren()
	local Count = 0
	local MaxCount = #Items
	
    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.new(1,0,1,0)
    viewport.Parent = script.Parent
	viewport.BackgroundTransparency = 1

	local WorldModel = Instance.new("WorldModel")
	WorldModel.Parent = viewport

	for _,Item in pairs(Items) do
		if not Item:IsA("PackageLink") then
			local newItem = Item:Clone()
			newItem.Parent = workspace
	
			local newCamera = workspace.CurrentCamera:Clone()
			newCamera.CFrame = newItem:GetPivot() * CFrame.new(0,0,1.5)
	
			newItem:PivotTo(CFrame.new((newItem:GetPivot() * (newItem:GetAttribute("ViewportOffset") or CFrame.new(0,0,0))).Position, newCamera.CFrame.Position))
	
			local newViewport = viewport:Clone()
			newViewport.Parent = ReplicatedStorage.Assets.Items
	
			newItem.Parent = newViewport.WorldModel
			newCamera.Parent = newViewport
	
			newViewport.CurrentCamera = newCamera
			newViewport.Name = Item.Name
	
			Count += 1;
		end
	end

	return Count, MaxCount
end

return ViewportModule
