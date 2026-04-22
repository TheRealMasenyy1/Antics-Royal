local Dismantle = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer

local Knit = require(ReplicatedStorage.Packages.Knit)

local CurseKingVFX = ReplicatedStorage.Assets.VFX["Curse King"]
local DismantleVFX = CurseKingVFX.Dismantle
local UnitService;

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

function Dismantle.Activate(Unit,UnitInfo)
    local newDismantle = DismantleVFX:Clone()
    local SoundController = Knit.GetController("SoundController")

	SoundController:Play("Dismantle", {
		Parent = Unit.HumanoidRootPart
	})

    newDismantle.Anchored = true
    newDismantle.CanCollide = false
    newDismantle.CFrame = CFrame.new(UnitInfo.Target.Position)
    newDismantle.Parent = workspace.Debris

	local Anim = Unit.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.CurseKing.Dismantle)
	Anim:Play()
    Anim:AdjustSpeed(.8)

    Toggle(newDismantle, true)
    UnitService:RequestDamage(Unit)

    task.delay(2,function()
        Toggle(newDismantle, false)
        task.wait(1)
        newDismantle:Destroy()
    end)
end

function Dismantle.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    Dismantle.Activate(Unit,UnitInfo)
end

return Dismantle