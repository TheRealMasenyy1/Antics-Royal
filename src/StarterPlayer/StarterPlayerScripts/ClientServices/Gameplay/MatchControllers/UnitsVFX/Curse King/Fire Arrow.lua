local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RocksModule = require(ReplicatedStorage.Shared.Utility.RocksModule)
local CameraShake = require(ReplicatedStorage.Shared.Utility.CameraShaker)

local CurseKing = {}
local Camera = workspace.CurrentCamera

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

function Toggle(Part,Value)
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "Beam" or v.ClassName == "ParticleEmitter" or v.ClassName == "PointLight" then
			v.Enabled = Value
		end
	end
end

function Move(TheTarget,Unit,Ball,step : number, Speed : number)
	local realDistance = 0
	if Ball:IsA("Model") then
		for _,Part in pairs(Ball:GetChildren()) do
			local Distance = (Part.Position - TheTarget.Position).Magnitude
			local Direction = (TheTarget.Position - Part.Position).Unit
		
			Part.CFrame = Part.CFrame + Direction * .25

			realDistance = Distance
		end

		return realDistance
	else
		local Distance = (Ball.Position - TheTarget.Position).Magnitude
		local Direction = (TheTarget.Position - Ball.Position).Unit
	
		Ball.CFrame = Ball.CFrame + Direction * .25
	
		return Distance
	end
end

local CurveTime = 0

local function ShakeCamera(shakeCFrame)
	Camera.CFrame = Camera.CFrame * shakeCFrame
end

function CurseKing.FlameArrow(Unit,UnitInfo : UnitInformation)
	local camshake = CameraShake.new(Enum.RenderPriority.Camera.Value, ShakeCamera)
	local arrowTrail = PirateKingAssets["Flame Arrow"].FlameArrowHandTrail:Clone()
	local arrowTrail_2 = PirateKingAssets["Flame Arrow"].FlameArrowHandTrail:Clone()

	local flamearrowEmit = PirateKingAssets["Flame Arrow"].FlameArrowHandEmit:Clone()
	local flamearrowBase = PirateKingAssets["Flame Arrow"].Arrow:Clone()	
	local flamearrowCharge = PirateKingAssets["Flame Arrow"].Charge:Clone()
	
	local flamearrowExplosion = PirateKingAssets["Flame Arrow"].Beam:Clone()
    local SoundController = Knit.GetController("SoundController")

	arrowTrail.Parent = Unit.HumanoidRootPart
	arrowTrail_2.Parent = Unit.HumanoidRootPart
	
	flamearrowEmit.Parent = Unit.HumanoidRootPart
	flamearrowBase.Parent = Unit.HumanoidRootPart
	flamearrowCharge.Parent = Unit.HumanoidRootPart
	
	--flamearrowFired.Parent = Unit.HumanoidRootPart
	flamearrowExplosion.Parent = Unit.HumanoidRootPart
	
	local firearrowAnim = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.CurseKing.Firearrow_anim)
	firearrowAnim:Play()
	
	SoundController:Play("FireArrow", {
		Parent = Unit.HumanoidRootPart
	})
	
	local con
	con = RunService.RenderStepped:Connect(function()
		arrowTrail.CFrame = Unit["Right Arm"].CFrame * CFrame.new(0,-.5,0)
		arrowTrail_2.CFrame = Unit["Left Arm"].CFrame * CFrame.new(0,-.5,0)
		task.delay(.15,function()
			con:Disconnect()
			Toggle(arrowTrail.Center,false)
			Toggle(arrowTrail_2.Center,false)
			
			DebrisService:AddItem(arrowTrail,1.5)
			DebrisService:AddItem(arrowTrail_2,1.5)
			
			flamearrowEmit.CFrame = Unit["Left Arm"].CFrame * CFrame.new(0,-.5,0)
			Emit(flamearrowEmit.Center)
			flamearrowCharge.CFrame = Unit.HumanoidRootPart.CFrame --* CFrame.new(0,-.5,0)
			flamearrowBase:PivotTo((Unit.HumanoidRootPart.CFrame * CFrame.new(-1,0,-5)) * CFrame.Angles(math.rad(90),0,0)) --* CFrame.new(0,-.5,0)
			DebrisService:AddItem(flamearrowEmit,1.5)
			
			Toggle(flamearrowBase,true)

			task.wait(.1)
			Toggle(flamearrowCharge,false)
			DebrisService:AddItem(flamearrowCharge,1.5)
			--flamearrowFired.CFrame = Unit.HumanoidRootPart.CFrame
			--Emit(flamearrowFired.Center)
		end)
	end)

	task.delay(.5,function()
		local MoveConnection : RBXScriptConnection;
		local HasExploded = false
		local DistanceToTarget;
		local newShuriken = flamearrowBase:Clone()
		--newShuriken.Anchored = true
		newShuriken.Parent = workspace
		flamearrowBase:Destroy()

		-- local TweenProp = {
		--     WorldCFrame = newShuriken.SpinPiece.WorldCFrame * CFrame.Angles(0,math.rad(360 * 10),0)
		-- }

		-- local Tween = TweenService:Create(newShuriken.SpinPiece,TweenInfo.new(5),TweenProp)
		-- Tween:Play()
		local relativeVector = (newShuriken.PrimaryPart.Position - UnitInfo.Target.Position)
		local distance = relativeVector.Magnitude

		local ArrowHitTween = TweenService:Create(newShuriken.PrimaryPart,TweenInfo.new(1),{CFrame = newShuriken.PrimaryPart.CFrame * CFrame.new(0,-distance - 1,0)})

		ArrowHitTween:Play()

		ArrowHitTween.Completed:wait()

		SoundController:Play("FireArrowExplode", {
			Parent = Unit.HumanoidRootPart
		})

		--flamearrowExplosion:PivotTo(UnitInfo.Target.CFrame * CFrame.new(0,-3,0))
		flamearrowExplosion:PivotTo(CFrame.new(UnitInfo.Target.Position + Vector3.new(0,-2.9,0)))
		flamearrowExplosion.Parent = workspace.Debris
		-- camshake:Start()

		-- camshake:Shake(CameraShake.Presets.SmallExplosion)
		-- camshake:ShakeOnce(3, 1, 0.2, 1.5)
		Toggle(newShuriken,false)
		Toggle(flamearrowExplosion,true)
		UnitService:RequestDamage(Unit)

		for _,attachment in pairs(flamearrowExplosion.BeamMesh:GetChildren()) do
			if attachment.Name ~= "2" then continue end

			TweenService:Create(attachment,TweenInfo.new(.15),{WorldCFrame = attachment.WorldCFrame * CFrame.new(0,0,-50)}):Play()

		end
		--Emit(flamearrowExplosion.Attachment)
		
		
		DebrisService:AddItem(newShuriken,3)
		task.wait(1)
		Toggle(flamearrowExplosion,false)
		--TweenService:Create(flamearrowExplosion.BaseCylinder,TweenInfo.new(.5),{Transparency = 1}):Play()
		DebrisService:AddItem(flamearrowExplosion,.5)
	end)
end

function CurseKing.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM Should be flameArrow", UnitInfo.Unit)
	CurseKing.FlameArrow(Unit,UnitInfo)
end

return CurseKing