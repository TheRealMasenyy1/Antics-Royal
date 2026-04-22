local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Voxel = require(ReplicatedStorage.Shared.Utility.VoxelizeHandler)

local LeafNinja = {}

local VFX = ReplicatedStorage.Assets.VFX
local LeafNinjaAssets = VFX.LeafNinja

type UnitInformation = {
    Unit : any, -- This is the unit model
    Name : string, -- Name
    UnitId : number, -- This is an attribute on model
    Owner : string, -- Who placed the unit
    Ability : string, -- Which Ability to use
    Target : any, -- This is a model
    Args : any,
}
local CurveTime = 0
local UnitService;

function Emit(Attachment,Value)
    Value = Value or 10

    for _, particle in Attachment:GetChildren() do
        if not Value then
            Value = particle:GetAttribute("EmitCount") 
        end
        particle:Emit(Value) 
    end
end

function Enable(Attachment,Value)
    for _, particle in Attachment:GetDescendants() do
        if not particle:IsA("Attachment") then
            particle.Enabled = Value 
        end
    end
end

function Move(TheTarget,Unit,Ball,step : number, Speed : number)
	local Distance = (Ball.Position - TheTarget.Position).Magnitude
	-- local Direction = (Ball.Position - TheTarget.Position).Unit
	local Direction = (TheTarget.Position - Ball.Position).Unit

    -- Ball.CFrame = CFrame.lookAt(Ball.CFrame.Position, TheTarget.Position)
    Ball.CFrame = Ball.CFrame + Direction * .25

    return Distance
end

function RasenExplosion(Target, Unit)
    local RasenShurikenExplosion = LeafNinjaAssets.MagnetExplosion:Clone()
    RasenShurikenExplosion.CFrame = CFrame.new(Target.Position)
    RasenShurikenExplosion.Parent = workspace.Debris

    local TweenProp = {
        CFrame = RasenShurikenExplosion.CFrame * CFrame.Angles(0,math.rad(360 * 10),0)
    }

    local Tween = TweenService:Create(RasenShurikenExplosion,TweenInfo.new(.5),TweenProp)
    Tween:Play()

    Emit(RasenShurikenExplosion.Implode)

    task.wait(.55)

    TweenService:Create(RasenShurikenExplosion,TweenInfo.new(1),{Transparency = 1}):Play()

    Emit(RasenShurikenExplosion.Explode)

    UnitService:RequestDamage(Unit)

    task.delay(5,game.Destroy,RasenShurikenExplosion)
end

function LeafNinja.RasenShuriken(Unit,UnitInfo : UnitInformation)
    UnitService = Knit.GetService("UnitService")
    local RasenShuriken = LeafNinjaAssets.RasenganBall:Clone()
    local ThrowAnimation : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(LeafNinjaAssets.Throw)
    local ChargingAnimation = Unit.Humanoid.Animator:LoadAnimation(LeafNinjaAssets.Charging)
    local SoundController = Knit.GetController("SoundController")

    ChargingAnimation:Play()
    
    -- Enable(RasenShuriken.SpawnEmit,true) -- enable particles
    
    local Weld = RasenShuriken.WeldConstraint
    RasenShuriken.CFrame = Unit["Right Arm"].CFrame * CFrame.Angles(0,math.rad(90),0) * CFrame.new(0,-.5,-.75)
    Weld.Part1 = Unit["Right Arm"]
    
    RasenShuriken.Parent = Unit
    
    task.delay(.25,function()
        SoundController:Play("RasenShuriken", {
            Parent = Unit.HumanoidRootPart
        })
        --Enable(RasenShuriken.SpawnEmit,false)
        --Enable(RasenShuriken.Floor,false)

       -- Enable(RasenShuriken.Center,true)
       -- Enable(RasenShuriken.SpinPiece,true)
        task.wait(.5)
        ChargingAnimation:Stop()

        ThrowAnimation:Play()

        task.delay(.5,function()
            local MoveConnection : RBXScriptConnection;
            local HasExploded = false
            local DistanceToTarget;
            local newShuriken = RasenShuriken:Clone()
            newShuriken.WeldConstraint:Destroy()
            newShuriken.Anchored = true
            newShuriken.Parent = workspace
            RasenShuriken:Destroy()

           -- Enable(newShuriken.SpinPiece,true)

            -- local TweenProp = {
            --     WorldCFrame = newShuriken.SpinPiece.WorldCFrame * CFrame.Angles(0,math.rad(360 * 10),0)
            -- }

            -- local Tween = TweenService:Create(newShuriken.SpinPiece,TweenInfo.new(1),TweenProp)
            -- Tween:Play()

            MoveConnection = RunService.Stepped:Connect(function(time,step)
                CurveTime = 0
                DistanceToTarget = Move(UnitInfo.Target,Unit,newShuriken,step,5)

                if DistanceToTarget <= 1 and not HasExploded then
                    HasExploded = true
                    newShuriken:Destroy()
                    MoveConnection:Disconnect()

                    RasenExplosion(UnitInfo.Target, Unit)
                end
            end)

            warn("STEPPED HAS ENDED")
        end)
    end)
end

function LeafNinja.Attack(Unit,UnitInfo : UnitInformation)
    UnitService = Knit.GetService("UnitService")
    LeafNinja.RasenShuriken(Unit,UnitInfo)
end

return LeafNinja