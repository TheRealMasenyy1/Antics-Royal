local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RocksModule = require(ReplicatedStorage.Shared.Utility.RocksModule)

local IceKing = {}

local IceKingAssets = ReplicatedStorage.Assets.VFX["Ice King"]
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
	for i, v in pairs(Part:GetDescendants()) do
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

local function evalNumberSequence(sequence: NumberSequence, time: number)
	if time == 0 then
		return sequence.Keypoints[1].Value, sequence.Keypoints[1].Envelope
	elseif time == 1 then
		return sequence.Keypoints[#sequence.Keypoints].Value, sequence.Keypoints[#sequence.Keypoints].Envelope
	end

	--> looping through keypoints until the time value fits in between two adjacent keypoints
	for i = 1, #sequence.Keypoints - 1 do
		local current = sequence.Keypoints[i]
		local next = sequence.Keypoints[i + 1]
		if time >= current.Time and time < next.Time then
			local alpha = (time - current.Time) / (next.Time - current.Time)
			return
				current.Value + (next.Value - current.Value) * alpha,
				current.Envelope + (next.Envelope - current.Envelope) * alpha
		end
	end

	return 1, 1 --> value, envelope
end

function ParticleTranparency(Part,Value)
	for i, v : ParticleEmitter in pairs(Part:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			for t = 0.0, 1 , .01 do
				-- local Sequence = NumberSequence.new({
				-- 	NumberSequenceKeypoint.new(0,Value),
				-- 	NumberSequenceKeypoint.new(.5,Value),
				-- 	NumberSequenceKeypoint.new(1,Value)
				-- })

				-- local x = evalNumberSequence(Sequence, t)

				v.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, t),
					NumberSequenceKeypoint.new(.5, t),
					NumberSequenceKeypoint.new(1,t)
				})
				task.wait()
			end
		end
	end
end

function Move(TheTarget,Unit,Ball,step : number, Speed : number)
	local Distance = (Ball.Position - TheTarget.Position).Magnitude
	local Direction = (TheTarget.Position - Ball.Position).Unit

	Ball.CFrame = Ball.CFrame + Direction * .25

	return Distance
end

function CreateTrackableValue(StartingValue : any, ValueType : string, TweenType : string, time : number, TweenProp, func : any)
	local Value = Instance.new(ValueType)
	Value.Value = StartingValue
	
	local newTween = TweenService:Create(Value, TweenInfo.new(time or 1,Enum.EasingStyle[TweenType],Enum.EasingDirection.InOut,0,false,.1), TweenProp)
	newTween:Play()

	Value.Changed:Connect(function(property)
		func(Value.Value)
	end)
end

function PartTransparency(Part : Part | Model, Speed , Value)
	for _, Parts in pairs(Part:GetDescendants()) do
		if Parts:IsA("BasePart") then
			local HasTexture = Parts:FindFirstChildWhichIsA("Texture")
			local HasParticle = Parts:FindFirstChildWhichIsA("ParticleEmitter")

			TweenService:Create(Parts,TweenInfo.new(Speed or 1),{Transparency = Value  or 1}):Play()

			if HasTexture then
				for _,Texture in pairs(Parts:GetChildren()) do
					if Texture:IsA("Texture") then
						TweenService:Create(Texture,TweenInfo.new(Speed or 1),{Transparency = Value  or 1}):Play()
					end
				end
			end

			if HasParticle then
				task.spawn(ParticleTranparency,Parts, 1)
			end
		end
	end
end

function IceKing.IceMountain(Unit,UnitInfo : UnitInformation)
	local IceSpike = IceKingAssets.IceSpike:Clone()
	IceSpike:PivotTo(Unit.HumanoidRootPart.CFrame)
	IceSpike.Parent = Unit.HumanoidRootPart

	local IceGroundData = {}
	
	local icemountainAnim : AnimationTrack = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.IceKing.IceMountain_anim)
	icemountainAnim:Play()

	for _, Ground : Model in pairs(IceSpike.IceGround:GetChildren()) do
		IceGroundData[Ground] = {Pivot = Ground:GetPivot(), Scale = Ground:GetScale() }
		Toggle(Ground, false)
		Ground:ScaleTo(.01)
	end

	icemountainAnim:GetMarkerReachedSignal("Activated"):Connect(function()
		for Ground : Model, GroundData in pairs(IceGroundData) do
			CreateTrackableValue(0.01,"NumberValue","Bounce",.5,{Value = GroundData.Scale},function(Value)
				Ground:PivotTo(GroundData.Pivot)
				Ground:ScaleTo(Value)
			end)
		end

		Emit(IceSpike.IceExplosion)

		for _, Spikes : BasePart in pairs(IceSpike.Spikes:GetChildren()) do
			task.spawn(CreateTrackableValue,Spikes.CFrame,"CFrameValue","Bounce",.5,{Value = IceSpike.IceGround:GetPivot() * CFrame.new(0,.25,math.random(-2,2)) },function(Value)
				Spikes.CFrame = Value -- math.random(2,6),2,math.random(2,6)
			end)

			task.spawn(CreateTrackableValue,Vector3.new(3.875, 2.358, 1.806),"Vector3Value","Bounce",.5,{Value = Vector3.new(7.575, 4.158, 2.606)},function(Value)
				Spikes.CFrame  = Spikes.CFrame
				Spikes.Size  = Value
			end)

			task.delay(1,PartTransparency, IceSpike, .5, 1)
		end

		task.delay(.25,function()
			UnitService:RequestDamage(Unit)
		end)
	end)
end

function IceKing.Attack(Unit,UnitInfo : UnitInformation) -- What's going to be fired on all players
	UnitService = Knit.GetService("UnitService")
	warn("ATTACK HAS BEEN FIRED FROM", UnitInfo.Unit)
	IceKing.IceMountain(Unit,UnitInfo)
end

return IceKing