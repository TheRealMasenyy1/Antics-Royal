local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RocksModule = require(ReplicatedStorage.Shared.Utility.RocksModule)

local PirateKing = {}

local VFX = ReplicatedStorage.Assets.VFX
local PirateKingAssets = ReplicatedStorage.Assets.VFX.PirateKing

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

function PirateKing.Smash(Unit,UnitInfo : UnitInformation)
	local smashCharge = PirateKingAssets.TexasSmashChargeUp:Clone()
    local AttackAnimation = Unit.Humanoid.Animator:LoadAnimation(VFX.Hero.Punch)
	smashCharge.Parent = Unit.HumanoidRootPart
	smashCharge.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,3,0)

	local smashFired = PirateKingAssets.TexasSmashFired:Clone()
	smashFired.Parent = Unit.HumanoidRootPart
	smashFired.CFrame = smashCharge.CFrame * CFrame.new(0,-1,0)

	local smashPart = PirateKingAssets.OtherWindMesh:Clone()
	smashPart.Parent = Unit.HumanoidRootPart

	local Distance = 5

    AttackAnimation:Play()
    AttackAnimation:AdjustSpeed(.95)
	Toggle(smashCharge, true)

	task.delay(1, function()
		Toggle(smashCharge, false)
		DebrisService:AddItem(smashCharge, 1)

		smashPart.CFrame = smashCharge.CFrame * CFrame.new(0,-1,0) * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0))

		local Tween = TweenService:Create(smashPart, TweenInfo.new(1), {
			CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,0,-50) * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
			Size = smashPart.Size - Vector3.new(10,10,10)
		})
		Tween:Play()

		local con
		con = RunService.RenderStepped:Connect(function(DeltaTime)
			local Direction = Unit.HumanoidRootPart.CFrame.LookVector
			Distance = Distance + 1
			local RockPosition = smashPart.Position + Direction * Distance -- Ensure rocks are placed correctly relative to the direction
			RocksModule.Ground(RockPosition, Distance, Vector3.new(1.25, 1.25, 1.25), {smashPart, workspace.GameAssets.Units.Detectors}, 2, false, .5)
			task.wait(.5)
			smashPart:Destroy()
			con:Disconnect()
		end)

		for i, v in pairs(smashFired:GetDescendants()) do
			if v.ClassName == "ParticleEmitter" then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
		Tween.Completed:Wait()
		smashPart:Destroy()
	end)
	
	
end

function PirateKing.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
	PirateKing.Smash(Unit,UnitInfo)
end

return PirateKing