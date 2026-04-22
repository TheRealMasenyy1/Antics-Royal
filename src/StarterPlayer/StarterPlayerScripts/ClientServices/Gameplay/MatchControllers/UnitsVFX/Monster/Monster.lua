local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RocksModule = require(ReplicatedStorage.Shared.Utility.RocksModule)

local Monster = {}

local VFX = ReplicatedStorage.Assets.VFX
local MonsterAssets = ReplicatedStorage.Assets.VFX.PirateKing

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


function Monster.Roar(Unit,UnitInfo : UnitInformation)
    local AttackAnimation = Unit.Humanoid.Animator:LoadAnimation(VFX.Monster.Roar)
	local roarVFX = MonsterAssets.KaijuNo8RoarVFX:Clone()
	roarVFX.Parent = Unit.HumanoidRootPart
	roarVFX.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,2,-1.5) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
	
	local movePart = Instance.new("Part",workspace.Debris)
	movePart.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(0,-2,0)
	movePart.Anchored = true
	movePart.CanCollide = false
	movePart.Transparency = 1
	
	local Distance = 5
	
    AttackAnimation:Play()
    AttackAnimation:AdjustSpeed(.95)

	Toggle(roarVFX,false)
	
	task.delay(.25,function()
		Toggle(roarVFX,true)
		local con
		con = RunService.RenderStepped:Connect(function(DeltaTime)
			local Direction = Unit.HumanoidRootPart.CFrame.LookVector
			task.spawn(function()
				Distance = Distance + 1
				task.wait(.5)
			end)

			movePart.CFrame = movePart.CFrame + (Direction * (DeltaTime*30))
			-- RocksModule.Ground(movePart.Position,Distance,Vector3.new(1.25,1.25,1.25),{movePart,roarVFX,workspace.GameAssets.Units.Detectors},2,false,.5)
			task.wait(.5)
			movePart:Destroy()
			con:Disconnect()
		end)
		task.wait(1)
		Toggle(roarVFX,false)
		DebrisService:AddItem(roarVFX,1)
	end)

end

function Monster.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Monster.Roar(Unit,UnitInfo)
end

return Monster