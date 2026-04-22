local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Stab = {}
local UnitService;

local Assets = ReplicatedStorage.Assets

local Animations = Assets.Animations
local VFX = Assets.VFX
local Warrior = VFX.Warrior

function Emit(Part)
	for _, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function Stab.StabMob(Unit, UnitInfo)
    local RequestSent = false
    local StabAnimation : AnimationTrack = Unit.Humanoid:LoadAnimation(Animations.Warrior.Stab)
    StabAnimation:Play()
    StabAnimation.Looped = false
    
    local newVFX = Warrior.StabEffect:Clone()
    newVFX.Parent = Unit
    newVFX.CFrame = Unit.HumanoidRootPart.CFrame

    StabAnimation:GetMarkerReachedSignal("Activate"):Connect(function()
        if not RequestSent then
            RequestSent = true
            Emit(newVFX)
            UnitService:RequestDamage(Unit)
        end
    end)

    task.delay(1.3, function()
        if not RequestSent then
            RequestSent = true
            UnitService:RequestDamage(Unit)
        end
    end)

end

function Stab.Attack(Unit, UnitInfo)
    UnitService = Knit.GetService("UnitService")
    Stab.StabMob(Unit, UnitInfo)
end

return Stab