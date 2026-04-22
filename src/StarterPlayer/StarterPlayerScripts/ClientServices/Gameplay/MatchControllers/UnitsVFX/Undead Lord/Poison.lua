local Poison = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer

local Knit = require(ReplicatedStorage.Packages.Knit)

local UndeadLordVFX = ReplicatedStorage.Assets.VFX["Undead Lord"]
local PoisonVFX = UndeadLordVFX.Poison
local UnitService;

function Emit(Part)
	for i, v in pairs(Part:GetChildren()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function Toggle(Part,Value, Ignore : {[string] : boolean})
    Ignore = Ignore or {}
    --print("IGNORING: ", Ignore)
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

function Poison.Activate(Unit,UnitInfo)
    -- local newPoison = PoisonVFX:Clone()
    -- newPoison.CanCollide = false
    -- newPoison.CFrame = CFrame.new(UnitInfo.Target.Position)
    -- newPoison.WeldConstraint.Part1 = UnitInfo.Target
    -- newPoison.Parent = workspace

	local Anim : AnimationTrack = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.UndeadLord.Poison)
	Anim:Play()
    Anim.Looped = false
    -- Anim:AdjustSpeed(.8)

    Anim:GetMarkerReachedSignal("Activate"):Connect(function()
        -- Emit(newPoison.Attachment)
        -- task.spawn(Toggle,newPoison, true, {["SkullEmit"] = true})
        UnitService:RequestDamage(Unit)

        -- task.delay(1,function()
        --     ParticleTranparency(newPoison,1)
        --     -- Toggle(newPoison, false)
        --     -- task.wait(1)
        --     newPoison:Destroy()
        -- end)
    end)
    -- Toggle(newPoison, true)
end

function Poison.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    Poison.Activate(Unit,UnitInfo)
end

return Poison