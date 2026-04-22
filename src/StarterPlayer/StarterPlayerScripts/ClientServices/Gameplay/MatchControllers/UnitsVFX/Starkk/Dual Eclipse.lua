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

function tweenBeams(attachment,start,ending, inc)
	local beams = {}
	
	for _,beam in pairs(attachment:GetDescendants()) do
		if beam:IsA("Beam") then
			table.insert(beams,beam)
		end
	end
	
	warn(beams)
	
	for i = start, ending, inc do
		for _,beam in beams do
			beam.Transparency = NumberSequence.new(i,1)
		end
		
	end
end

function Starkk.metralleta(Unit,UnitInfo : UnitInformation)
	local Track : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(Animations.DoubleCero)
	
	Track:Play()
	
	Track:AdjustSpeed(0.9)
	
	Track:GetMarkerReachedSignal("Fire"):Connect(function()
		local beam = StarkkAssets.Cero:Clone();
		local Gun = Unit.Gun
	
		beam:PivotTo(Unit.HumanoidRootPart.CFrame * CFrame.new(0,0,-4));
	
		--Toggle(beam,true)
		
		tweenBeams(beam,1,0, -.05)

		UnitService:RequestDamage(Unit)

		task.delay(.55,function()
			--Toggle(beam,false)
			tweenBeams(beam,0,1, .05)
			
			task.wait(.3)
			
			Toggle(beam,false)
			Toggle(Gun.Attachment,false)
		end)
		
		beam.Parent = workspace;
	
		game.Debris:AddItem(beam,3)
	
	
	end)


end

function Starkk.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Starkk.metralleta(Unit,UnitInfo)
end

return Starkk