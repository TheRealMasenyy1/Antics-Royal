local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RocksModule = require(ReplicatedStorage.Shared.Utility.RocksModule)
local Cutscene = require(ReplicatedStorage.Shared.Cutscene)
local Destruction = require(ReplicatedStorage.Shared.Destruction)
local CameraShake = require(ReplicatedStorage.Shared.Utility.CameraShaker)

local CurseKing = {}

local player = Players.LocalPlayer
local PirateKingAssets = ReplicatedStorage.Assets.VFX.PirateKing
local UnitService;
local Camera = workspace.CurrentCamera
local playerScripts = player:WaitForChild("PlayerScripts")


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

function Toggle(Part,Value)
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "Beam" or v.ClassName == "ParticleEmitter" or v.ClassName == "PointLight" then
			v.Enabled = Value
		end
	end
end

function Move(TheTarget,Unit,Ball,step : number, Speed : number)
	local Distance = (Ball.Position - TheTarget.Position).Magnitude
	local Direction = (TheTarget.Position - Ball.Position).Unit

	Ball.CFrame = Ball.CFrame + Direction * .25

	return Distance
end

local CurveTime = 0
-- local Selection = game:GetService("Selection"):Get()[1]

-- for _, part in pairs(Selection:GetDescendants()) do
-- 	if part:IsA("BasePart") then
-- 		part.Anchored = true
-- 	end
-- end

-- function 
local function TweenModel(Model : Model, Duration : number, GoalCFrame : CFrame, _callback : any) : (Model, number, CFrame) -> ()
	local Pivot : CFrame = Model:GetPivot()
	local Time : number = 0
	repeat
		Time += task.wait()
		local InterpolatedCFrame : CFrame = Pivot:Lerp(GoalCFrame, 1 - ((Duration - Time) / Duration))
		Model:PivotTo(InterpolatedCFrame)
	until Time > Duration

	if _callback then
		_callback()
	end
end
-- TweenService:Create(parts,TweenInfo.new(Speed),{Transparency = Value}):Play()
-- TweenService:Create(decal,TweenInfo.new(Speed),{Transparency = Value}):Play()

function CurseKing.ShowDomain(Unit, Value)
	if Value then
		local newDomain = ReplicatedStorage.Assets.VFX["Curse King"].Domain:Clone()
		newDomain.Parent = workspace.Debris
		newDomain.CFrame = Unit:GetPivot()

		TweenService:Create(newDomain,TweenInfo.new(2),{Transparency = 0}):Play()
	else
		local oldDomain = workspace.Debris:FindFirstChild("Domain")

		if oldDomain then
			local Tween = TweenService:Create(oldDomain,TweenInfo.new(2),{Transparency = 1})
			Tween:Play()

			Tween.Completed:Connect(function(playbackState)
				oldDomain:Destroy()
			end)
		end
	end

end

local Map = workspace.Map
local MapDescendants = workspace.Map:GetDescendants()
local Buildings = CollectionService:GetTagged("Buildings")

function CurseKing.SetTransparent(Value : number, Speed : number)

	if Value > 0 then
		workspace.DebrisFolder.Parent = ReplicatedStorage
	end

	-- local newGround = Map.Buildings.Maps:Clone()
	-- newGround.Parent = ReplicatedStorage

	for _,Building in ipairs(Buildings) do
		local Descendants = Building:GetDescendants() 
		for _,parts in ipairs(Descendants) do
			if parts:IsA("BasePart") or parts:IsA("Decal") or parts:IsA("Texture") then
				-- local HasTexture = parts:FindFirstChildWhichIsA("Decal") or parts:FindFirstChildWhichIsA("Texture") 
				TweenService:Create(parts,TweenInfo.new(Speed),{Transparency = Value}):Play()
				-- parts.Transparency = Value

				if parts:IsA("BasePart") then
					parts.CanCollide = if Value > 0 then false else true
				end

				-- if HasTexture then
				-- 	for _,decal in pairs(parts:GetChildren()) do
				-- 		if decal:IsA("Decal") then
				-- 			TweenService:Create(parts,TweenInfo.new(1),{Transparency = Value}):Play()
				-- 			-- decal.Transparency = Value
				-- 		end
				-- 	end
				-- end
				-- --print(parts.Name)
			end
		end
		RunService.Heartbeat:Wait()
	end

	if Value > 0 then
		task.delay(.5,function()
			Map.Parent = ReplicatedStorage
		end)
	end
end

-- Sky settings
-- Cover: 1
-- Density: 0.241
-- Color = 62, 15, 9

function CurseKing.SetReflection(Value : number, Speed : number)
	local Map = workspace.Map
	local newGround = ReplicatedStorage.Maps
	newGround.Parent = workspace

	for _,parts in pairs(newGround:GetDescendants()) do
		if parts:IsA("BasePart") then
			-- local HasTexture = parts:FindFirstChildWhichIsA("Decal") or parts:FindFirstChildWhichIsA("SurfaceTexture") 
			parts.Reflectance = Value
		end
	end
end

function CurseKing.SetClouds(Value : boolean)
	local Cloud = workspace.Terrain.Clouds

	if Value then
		Cloud.Enabled = Value
		TweenService:Create(Cloud,TweenInfo.new(10),{Cover = 1, Density = 0.241, Color = Color3.fromRGB(62,15,9)}):Play()
	else
		TweenService:Create(Cloud,TweenInfo.new(10),{Cover = 0, Density = 0, Color = Color3.fromRGB(255, 255, 255)}):Play()
		task.wait(11)
		Cloud.Enabled = Value
	end
end

local function ShakeCamera(shakeCFrame)
	Camera.CFrame = Camera.CFrame * shakeCFrame
end

-- local camerashake = function()
-- 	local camShake = CameraShake.new(Enum.RenderPriority.Camera.Value,ShakeCamera)
-- 	local dt = 0
-- 	camShake:Start()	
-- 	camShake:ShakeSustain(CameraShake.Presets.Earthquake)
-- 	repeat
-- 		dt += RunService.Heartbeat:Wait()
-- 	until dt >= Shake_Time
-- 	camShake:StopSustained(1) -- Argument is the fadeout time (defaults to the same as fadein time if not supplied)
-- end


function CurseKing.NewRealm(Unit,UnitInfo : UnitInformation)
	local CurseTemple = Unit["Curse Temple"]
	local Temple = CurseTemple.Temple
	local Skulls = CurseTemple.Skulls
	local Domain = CurseTemple.domainexpansion
	local DomainStart : AnimationTrack = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.CurseKing.DomainStart)
	local DomainHolding : AnimationTrack = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.CurseKing.DomainHolding)
	local DomainLaughing : AnimationTrack = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.CurseKing.DomainLaughing)
	local Shake_Time = 5
	canContinue = false

	local Velocity = workspace.CurrentCamera.CFrame.LookVector * - 100
	local VelocityForDomain = workspace.CurrentCamera.CFrame.LookVector * - 200

	task.spawn(Cutscene.DisableUI,Players.LocalPlayer, Unit:GetAttribute("Id"))
	Cutscene:Enabled(true)

	task.spawn(CurseKing.SetClouds,true)
	task.spawn(Cutscene.DisableUI,Players.LocalPlayer,"Main")
	task.spawn(Cutscene.DisableUI,Players.LocalPlayer,"MovieMode",true)

	local function Deactivate()
		local Map = ReplicatedStorage:FindFirstChild("Map")

		if Map then
			Map.Parent = workspace
			task.spawn(CurseKing.SetClouds, false)
			
			CurseKing.ShowDomain(Unit, false)
			DomainHolding:Stop()
			DomainLaughing:Play()
			
			TweenModel(Temple, 3, CFrame.new(CurseTemple.TempleLoc.CFrame.Position.X,CurseTemple.TempleLoc.CFrame.Position.Y - 10,CurseTemple.TempleLoc.CFrame.Position.Z))
			TweenModel(Skulls, 3, CFrame.new(CurseTemple.SkullsLoc.CFrame.Position.X,CurseTemple.SkullsLoc.CFrame.Position.Y - 10,CurseTemple.SkullsLoc.CFrame.Position.Z))
			
			task.spawn(CurseKing.SetTransparent, 0, .5)
			Toggle(Domain.starforchar, false)
			Toggle(Domain.floordomain.First, false)
			Toggle(Domain.floordomain.BloodSpikes, false)
			Toggle(Domain.domain, false)
			ReplicatedStorage.DebrisFolder.Parent = workspace
		end 
	end

	Cutscene:TravelTo(CurseTemple.CameraPos.CFrame, 1, function()
		task.spawn(CurseKing.SetTransparent, 1, .5)
		Camera.CFrame = CurseTemple.CameraPos.CFrame
		DomainStart:Play()
		DomainStart:AdjustSpeed(1)
		CurseKing.ShowDomain(Unit, true)

		task.wait(DomainStart.Length - .2)

		DomainHolding:Play()
		DomainStart:Stop()
		canContinue = true
	end)

	repeat
		task.wait()
	until canContinue

	task.spawn(function()
		Cutscene:TravelTo(CurseTemple.CameraPos2.CFrame, 1.25, function()
			Camera.CFrame = CurseTemple.CameraPos2.CFrame
		end)
	end)

	playerScripts.WindController.Enabled = false
	Toggle(Domain.starforchar, true)
	Toggle(Domain.floordomain.First, true)
	Toggle(Domain.floordomain.BloodSpikes, true)

	TweenModel(Skulls, 3, CurseTemple.SkullsLoc.CFrame)
	TweenModel(Temple, 3, CurseTemple.TempleLoc.CFrame)

	task.spawn(function()
		DomainHolding:Stop(.25)
		DomainLaughing:Play(.1,2)
		task.wait(DomainLaughing.Length - .2)
		DomainHolding:Play(1)
	end)

	Toggle(Domain.domain, true)
	UnitService:RequestDamage(Unit)

	-- Destruction.REFRESH_TIME = 100
	-- task.spawn(function()
	-- 	Destruction:PartitionAndVoxelizePart(Temple.PrimaryPart.CFrame,Vector3.new(100,100,100),Velocity)
	-- end)

	for i = 3, 6 do
		local Continue = false
		Cutscene:TravelTo(CurseTemple["CameraPos"..i].CFrame, 1.25, function()
			Continue = true
		end)

		repeat
			task.wait()
		until Continue
	end

	Cutscene:Enabled(false)
	task.spawn(Cutscene.DisableUI,Players.LocalPlayer,"Main", true)
	task.spawn(Cutscene.DisableUI,Players.LocalPlayer,"MovieMode")

	task.delay(UnitInfo.Duration, function()
		Deactivate()
	end)
	-- local TempleTween = TweenService:Create(Temple.PrimaryPart,TweenInfo.new(1),TweenProp)
	-- TempleTween:Play()
end

function CurseKing.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
	UnitService = Knit.GetService("UnitService")
	warn("ULTIMATE HAS BEEN INVOKED IN THE CLIENT : ", UnitInfo)
	CurseKing.NewRealm(Unit,UnitInfo)
end

return CurseKing