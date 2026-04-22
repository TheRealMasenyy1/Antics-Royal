local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Starkk = {}

local VFX = ReplicatedStorage.Assets.VFX
local StarkkAssets = ReplicatedStorage.Assets.VFX.Starkk
local Animations = ReplicatedStorage.Assets.Animations.Starkk
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
	local Distance = (Ball.Position - TheTarget.Position).Magnitude
	local Direction = (TheTarget.Position - Ball.Position).Unit

	Ball.CFrame = Ball.CFrame + Direction * .25

	return Distance
end

function Starkk.metralleta(Unit,UnitInfo : UnitInformation)
	local Track : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(Animations.Wolf)
	
	Track:Play()
	
	Track:AdjustSpeed(0.9)
	
	Track:GetMarkerReachedSignal("Hit"):Connect(function()

		local DistanceToTarget = (Unit.HumanoidRootPart.CFrame.Position - UnitInfo.Target.CFrame.Position).Magnitude 

		DistanceToTarget = DistanceToTarget * (-1)
		
		for i = 1,3 do
			local wolf = StarkkAssets.WolfModel:Clone()
			wolf.Parent = workspace
			
			wolf.CFrame = Unit.HumanoidRootPart.CFrame * CFrame.new(math.random(-7,7),-1,7)
			
			local runTween = TweenService:Create(wolf,TweenInfo.new(.75),{CFrame = (wolf.CFrame * CFrame.new(0,0,DistanceToTarget)) })
			
			runTween:Play()
			
			runTween.Completed:Connect(function()
				wolf:Destroy()
				local Explode = StarkkAssets.WolfExplode:Clone()
				
				Explode.Parent = workspace
				
				Explode.CFrame = wolf.CFrame
				
				Emit(Explode.Attachment)

				game.Debris:AddItem(Explode,3)
			end)
			
			game.Debris:AddItem(wolf,3)
			
			task.wait(.5)
		end
	
	
	end)

	UnitService:RequestDamage(Unit)

end

function Starkk.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Starkk.metralleta(Unit,UnitInfo)
end

return Starkk