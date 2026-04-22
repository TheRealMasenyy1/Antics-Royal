local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RocksModule = require(ReplicatedStorage.Shared.Utility.RocksModule)

local PirateKing = {}

local PirateKingAssets = ReplicatedStorage.Assets.VFX.PirateKing
local UnitService;

type UnitInformation = {
	Unit : any, -- This is the unit model
	Name : string, -- Name
	UnitId : number, -- This is an attribute on model
	Owner : string, -- Who placed the unit
	Ability : string, -- Which Ability to use
	Target : any, -- This is a model
	Args : any,
}

function Emit(Part)
	for i, v in pairs(Part:GetChildren()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function TimeScale(Part, Value)
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "ParticleEmitter"  then
			v.TimeScale = Value
		end
	end
end

function Toggle(Part,Value)
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "Beam" or v.ClassName == "ParticleEmitter" or v.ClassName == "PointLight" then
			v.Enabled = Value
		end
	end
end

function ParticleTranparency(Part,Value)
	for i, v : ParticleEmitter in pairs(Part:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			task.spawn(function()
				for t = 0.0, Value , .01 do
					v.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, t),
						NumberSequenceKeypoint.new(.5, t),
						NumberSequenceKeypoint.new(1,t)
					})
					task.wait()
				end
			end)
		end
	end
end

function Move(TheTarget,Unit,Ball,step : number, Speed : number)
	local Distance = (Ball.Position - TheTarget.Position).Magnitude
	local Direction = (TheTarget.Position - Ball.Position).Unit

	Ball.CFrame = Ball.CFrame + Direction * .25

	return Distance
end

function PirateKing.Gatling(Unit,UnitInfo : UnitInformation)
	local armMeshes = {}
	local SoundController = Knit.GetController("SoundController")
	-- Clone and position the first set of arm meshes (right and left)
	local rightarmMesh = PirateKingAssets.LuffyBarrage:Clone()
	rightarmMesh.Parent = Unit.HumanoidRootPart
	table.insert(armMeshes, rightarmMesh)

	local leftarmMesh = PirateKingAssets.LuffyBarrage:Clone()
	leftarmMesh.Parent = Unit.HumanoidRootPart
	table.insert(armMeshes, leftarmMesh)

	-- Clone and position the second set of arm meshes (right and left, positioned above the first set)
	local rightarmMesh_3 = PirateKingAssets.LuffyBarrage:Clone()
	rightarmMesh_3.Parent = Unit.HumanoidRootPart
	table.insert(armMeshes, rightarmMesh_3)

	local leftarmMesh_4 = PirateKingAssets.LuffyBarrage:Clone()
	leftarmMesh_4.Parent = Unit.HumanoidRootPart
	table.insert(armMeshes, leftarmMesh_4)

	-- Function to tween transparency of all meshes to 0.9
	local function TweenTransparencyTo(meshes, targetTransparency, duration)
		for _, mesh in pairs(meshes) do
			for _, descendant in pairs(mesh:GetDescendants()) do
				if descendant:IsA("BasePart") then
					-- Create the tween
					local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
					local tweenGoal = {Transparency = targetTransparency}

					local tween = TweenService:Create(descendant, tweenInfo, tweenGoal)
					tween:Play()
				end
			end
		end
	end

	-- Call the function to tween the transparency
	TweenTransparencyTo(armMeshes, 0.75, 1.5)  -- Change the duration as needed
	-- Load and play animations for the first set of arm meshes
	local gatlingAnim_startup = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.PirateKing.Gatling_anim_startup)
	local gatlingAnim = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.PirateKing.Gatling_anim)
	local gatlingmeshAnim = rightarmMesh.AnimationController:LoadAnimation(ReplicatedStorage.Assets.Animations.PirateKing.GatlingMesh_anim)
	local gatlingmeshAnim_2 = leftarmMesh.AnimationController:LoadAnimation(ReplicatedStorage.Assets.Animations.PirateKing.GatlingMesh_anim)
	local gatlingmeshAnim_3 = rightarmMesh_3.AnimationController:LoadAnimation(ReplicatedStorage.Assets.Animations.PirateKing.GatlingMesh_anim)
	local gatlingmeshAnim_4 = leftarmMesh_4.AnimationController:LoadAnimation(ReplicatedStorage.Assets.Animations.PirateKing.GatlingMesh_anim)
	
	gatlingAnim_startup:Play()
	
	gatlingAnim_startup:GetMarkerReachedSignal("Start"):Connect(function()
		local barrageVFX = PirateKingAssets.Barrage:Clone()
		barrageVFX.Parent = Unit.HumanoidRootPart
		barrageVFX:PivotTo(Unit.HumanoidRootPart.CFrame)

		local WeldConstraint = barrageVFX.Gattling.WeldConstraint
		WeldConstraint.Part1 = Unit.HumanoidRootPart

		barrageVFX.Gattling.Anchored = false
		
		rightarmMesh.PrimaryPart.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(1, 0, -2) * CFrame.Angles(0, math.rad(180), 0)
		leftarmMesh.PrimaryPart.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(-1, 0, 0) * CFrame.Angles(0, math.rad(180), 0)

		TimeScale(barrageVFX,.2)

		SoundController:Play("PirateGattling", {
			Parent = Unit.HumanoidRootPart
		})

		gatlingAnim:Play()
		gatlingAnim:AdjustSpeed(1.25)
		gatlingmeshAnim:Play()
		task.wait(1)
		TimeScale(barrageVFX,1)
		gatlingmeshAnim_2:AdjustSpeed(1)
		gatlingmeshAnim_2:Play()
		UnitService:RequestDamage(Unit)
		task.wait(1)
		rightarmMesh_3.PrimaryPart.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(1, 1, 0) * CFrame.Angles(0, math.rad(180), 0)
		gatlingmeshAnim_3:AdjustSpeed(1)
		gatlingmeshAnim_3:Play()
		UnitService:RequestDamage(Unit)
		task.wait(1)
		leftarmMesh_4.PrimaryPart.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(-1, 1, -2) * CFrame.Angles(0, math.rad(180), 0)
		gatlingmeshAnim_4:AdjustSpeed(1)
		gatlingmeshAnim_4:Play()
		UnitService:RequestDamage(Unit)
		-- Load and play animations for the second set of arm meshes

		-- Wait and clean up
		task.wait(1)

		TimeScale(barrageVFX,.2)

		--task.spawn(function()
			ParticleTranparency(barrageVFX,1)
		--end)


		task.wait(.2)

		DebrisService:AddItem(barrageVFX, .1)
		DebrisService:AddItem(rightarmMesh, .1)
		DebrisService:AddItem(leftarmMesh, .1)
		DebrisService:AddItem(rightarmMesh_3, .1)
		DebrisService:AddItem(leftarmMesh_4, .1)
		gatlingmeshAnim:Stop()
		gatlingmeshAnim_2:Stop()
		gatlingmeshAnim_3:Stop()
		gatlingmeshAnim_4:Stop()
		gatlingAnim:Stop()
	end)
	
end

function PirateKing.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	UnitService = Knit.GetService("UnitService")
	PirateKing.Gatling(Unit,UnitInfo)
end

return PirateKing