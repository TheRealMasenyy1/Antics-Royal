local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Mikaela = {}

local VFX = ReplicatedStorage.Assets.VFX
local MikaelaAssets = ReplicatedStorage.Assets.VFX.Mikaela
local Animations = ReplicatedStorage.Assets.Animations.Mikaela
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

function GetBloodBall(Unit)
	if Unit:FindFirstChild("MainBall") then
		return Unit:FindFirstChild("MainBall")
	else
		local Ball = MikaelaAssets.MainBall:Clone()
		Ball:PivotTo(Unit.HumanoidRootPart.CFrame * CFrame.new(0,15,0))
		Ball.Parent = Unit
		
		Unit:SetAttribute("BloodScale",.3)
		
		return Ball
	end
end

function lerp(a, b, c)
	return a + (b - a) * c
end

function quadBezier(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)

	local l2 = lerp(p1, p2, t)

	local quad = lerp(l1, l2, t)

	return quad
end

function Mikaela.BloodAscension(Unit,UnitInfo : UnitInformation)	
	local Track : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(Animations.Attack2)
	local Temp = MikaelaAssets.MainPart
	local gotKill = false -- If the attack killed a mob testing

	Track:Play()
	
	Track:AdjustSpeed(1.25)

	Track:GetMarkerReachedSignal("Hit"):Connect(function()
		local Explosion = Temp:Clone()

		Explosion:PivotTo(UnitInfo.Target.CFrame)
		Explosion.Parent = workspace

		game.Debris:AddItem(Explosion,3)
		
		Emit(Explosion.Explosion)
		
		for _,Child in pairs(Explosion:GetDescendants()) do
			if not Child:IsA("ParticleEmitter") then continue end
			if not Child:GetAttribute("NoEnable") then
				Child.Enabled = true
				
				task.delay(.75,function()
					Child.Enabled = false
				end)
			end
		end

		UnitService:RequestDamage(Unit)
		
		if gotKill then
			task.wait(.25)
			
			local BloodBall = GetBloodBall(Unit)
			local BloodOrb = MikaelaAssets.Ball:Clone()
			
			BloodOrb.Parent = workspace
			BloodOrb.CFrame = Explosion.CFrame
			
			local CalcPosition = BloodBall.Ball.Position - Vector3.new(math.random(-5,5),math.random(3,10),math.random(-5,5))
			
			for i = 0, 1, 0.025 do
				BloodOrb:PivotTo(CFrame.new(quadBezier(i, Explosion.Position, CalcPosition, BloodBall.Ball.Position)))
				task.wait(1/50)
			end
			
			task.wait(.5)
			
			BloodOrb:Destroy()
			
			--local newScale = Unit:GetAttribute("BloodScale") + .05
			
			--Unit:SetAttribute("BloodScale",newScale)

			local newSize = BloodBall.Ball.Size * 1.1
			
			--BloodBall:ScaleTo(newScale)
			
			TweenService:Create(BloodBall.Ball,TweenInfo.new(.5),{Size = newSize}):Play()
			
		end

	end)	
	
end

function Mikaela.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Mikaela.BloodAscension(Unit,UnitInfo)
end

return Mikaela