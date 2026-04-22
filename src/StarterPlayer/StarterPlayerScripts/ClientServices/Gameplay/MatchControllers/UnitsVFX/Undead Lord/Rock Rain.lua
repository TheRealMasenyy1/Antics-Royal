local RockRain = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Destruction = require(ReplicatedStorage.Shared.Destruction)

local UndeadLordVFX = ReplicatedStorage.Assets.VFX["Undead Lord"]
local RockRainVFX = UndeadLordVFX.RockRain
local Groundslam = ReplicatedStorage.Assets.VFX.GroundSlam
local UnitService;
local SoundController;

function Emit(Part)
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function Toggle(Part,Value, Ignore : {[string] : boolean})
    Ignore = Ignore or {}
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "Beam" or v.ClassName == "ParticleEmitter" or v.ClassName == "PointLight" then
            if not Ignore[v.Name] then
                v.Enabled = Value
            end
		end
	end
end

function ParticleTranparency(Part,Value)
	for i, v : ParticleEmitter in pairs(Part:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			for t = 0.0, Value , .01 do
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

function RockRain.Activate(Unit,UnitInfo)
    local Rocks = {}
    local HumanoidRootPart = Unit.HumanoidRootPart
    local Speed = 2
    
    for i = 1, 3 do
        local newRocks = RockRainVFX:Clone()
        local Width = RockRainVFX.Size.X
        local TargetPosition = HumanoidRootPart.CFrame * CFrame.new((-Width) + (Width * i),5,5)
        newRocks.CFrame = HumanoidRootPart.CFrame * CFrame.new((-Width) + (Width * i),-5,5) -- * CFrame.Angles(math.rad(-90),0,0)
        newRocks.Anchored = true
        newRocks.Parent = workspace.Debris
        TweenService:Create(newRocks,TweenInfo.new(1),{CFrame = TargetPosition}):Play()
        table.insert(Rocks,newRocks)
    end

	local Anim : AnimationTrack = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.UndeadLord.Rock)
	Anim:Play()
    Anim.Looped = false
    -- Anim:AdjustSpeed(.8)

    Anim:GetMarkerReachedSignal("Activate"):Connect(function()
        for _, rock in ipairs(Rocks) do
            local Tween = TweenService:Create(rock,TweenInfo.new(1/Speed),{CFrame = CFrame.new(UnitInfo.Target.Position)})
            local newGroundSlam =  Groundslam:Clone()
            newGroundSlam.Parent = workspace.Debris
            newGroundSlam.CFrame = UnitInfo.Target.CFrame

            SoundController:Play("RockThrow",{Parent = rock})
            Tween:Play()
            Tween.Completed:Wait()
            
            rock.Transparency = 1
            task.spawn(ParticleTranparency, rock, 1)
            Emit(newGroundSlam)

            local Info = UnitInfo.AbilityInfo
            local Velocity = workspace.CurrentCamera.CFrame.LookVector * - math.random(10,Info.PushPower/2)

            UnitService:RequestDamage(Unit)
            task.spawn(function()
                Destruction:PartitionAndVoxelizePart(CFrame.new(UnitInfo.Target.Position),Info.Size,Velocity)
            end)

            task.delay(2, game.Destroy,rock)
            task.delay(5, game.Destroy, newGroundSlam)
        end
    end)
end

function RockRain.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    SoundController = Knit.GetController("SoundController")
    RockRain.Activate(Unit,UnitInfo)
end

return RockRain