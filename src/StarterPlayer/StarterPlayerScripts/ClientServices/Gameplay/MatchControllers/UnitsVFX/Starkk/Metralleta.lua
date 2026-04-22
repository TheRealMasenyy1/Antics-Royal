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
	local Positions = StarkkAssets.Positions:Clone()
	local Animation = Animations.Metralleta

	local Track : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(Animation)

	Positions.Parent = Unit
	Positions:PivotTo(Unit.HumanoidRootPart.CFrame * CFrame.new(0,0,-2.5))

	Track:Play()

	Track:GetMarkerReachedSignal("Charge"):Connect(function()
		local Gun = Unit.Gun
		
		Toggle(Gun.Attachment,true)
	end)

	Track:GetMarkerReachedSignal("ChargeEnd"):Connect(function()
		local Gun = Unit.Gun

		UnitService:RequestDamage(Unit)

		for _,pos in pairs(Positions:GetChildren()) do 
			if pos.Name == "Middle" then
				local beam = StarkkAssets.Beam:Clone();
				local random = math.random(1,6)
	
				task.wait(random / 15)
	
				beam:PivotTo(pos.CFrame);
	
				Toggle(beam,true)
	
				task.delay(1.45,function()
					Toggle(beam,false)
				end)
	
				beam.Parent = workspace;
	
				--task.delay(.55,function()
				--	Toggle(beam,false)
				--end)
	
				for i,BeamPart in pairs(beam:GetChildren()) do
					if not BeamPart:GetAttribute("Beam") then continue end
					local correctSize = BeamPart.Size
	
					TweenService:Create(BeamPart,TweenInfo.new(.15,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,false),
					{
						Transparency = 0, 
					}):Play()
	
					BeamPart.Size = (correctSize * .2)
	
					TweenService:Create(BeamPart,TweenInfo.new(.5,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,.05),
					{
						Size = correctSize * 1.5,
						--CFrame = BeamPart.CFrame * CFrame.new(0,0,7.5),
						Transparency = 0,
					}):Play()
	
					for _,Attachment in pairs(BeamPart:GetChildren()) do
						if not BeamPart:GetAttribute("Back") then continue end
			
						TweenService:Create(BeamPart,TweenInfo.new(.175,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,false),
							{
								CFrame = Attachment.CFrame * CFrame.new(0,0,16),
							}):Play()
			
						warn("playing")
					end
			
					task.delay(.66,function()
						TweenService:Create(BeamPart,TweenInfo.new(.175,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,false),
							{
								Transparency = 1, 
							}):Play()
					end)
	
				end
	
	
				game.Debris:AddItem(beam,3)
			end 
		end
		
		Toggle(Gun.Attachment,true)
		
		DebrisService:AddItem(Positions,1)
	end)


end

function Starkk.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
    UnitService = Knit.GetService("UnitService")
	-- warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	Starkk.metralleta(Unit,UnitInfo)
end

return Starkk