local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Voxel = require(ReplicatedStorage.Shared.Utility.VoxelizeHandler)

local Purple = {}

local VFX = ReplicatedStorage.Assets.VFX
local Animations = ReplicatedStorage.Assets.Animations
local NoobjoAnimation = Animations.Noobjo
local UnitAssets = VFX.Noobjo

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
local SoundController;

function Emit(Attachment,Value)
   Value = Value or 10

    for _, particle in Attachment:GetDescendants() do
        if particle:IsA("ParticleEmitter") then
            -- Value = particle:GetAttribute("EmitCount") 
            particle:Emit(Value) 
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

function SetAttachments(Part : BasePart, Character)
    local attachmentsTable = {}
    for _,Attachment in pairs(Part:GetChildren()) do
        if Attachment:IsA("Attachment") then
            local clonedAttachment = Attachment:Clone()
            clonedAttachment.Parent = Character[clonedAttachment:GetAttribute("Place")]

            table.insert(attachmentsTable,clonedAttachment)
        end
    end

    return attachmentsTable
end

function Move(TheTarget,Unit,Ball,step : number, Speed : number)
	local Distance = (Ball.Position - TheTarget.Position).Magnitude
	-- local Direction = (Ball.Position - TheTarget.Position).Unit
	local Direction = (TheTarget.Position - Ball.Position).Unit

    -- Ball.CFrame = CFrame.lookAt(Ball.CFrame.Position, TheTarget.Position)
    Ball.CFrame = Ball.CFrame + Direction * .25

    return Distance
end

function Invisible(Model, Value)
    for _, part in Model:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= ("Detector") and part.Name ~= ("Upgrade") then
           -- if Value == 0 and part.Transparency == 1 then continue end
            part.Transparency = Value 
        end
    end
end

function Scale(Model : Model, Value, _callback)
    for i = Model:GetScale(), Value, .01 do
        Model:ScaleTo(i)
        -- RunService.Heartbeat:Wait()
        task.wait()
    end

    if _callback then
        _callback()
    end
end

function Purple:Activate(Unit,UnitInfo)
    local HumanoidRootPart = Unit.HumanoidRootPart
    local Purple = UnitAssets.HollowPurple:Clone()
    local PurpleExplosion = UnitAssets.Boomboom:Clone()
    local MoveConnection;
    local HasExploded = false
    local CurveTime = 0
    local DistanceToTarget;
    local Projectile = Purple.Purple.MainPart
    
    local Red = Purple.Red
    local Blue = Purple.Blue

    local HollowPurpleAn : AnimationTrack = Unit.Humanoid.Animator:LoadAnimation(NoobjoAnimation.HollowPurple)
    HollowPurpleAn:Play()
    HollowPurpleAn.Looped = false
    
    Purple:PivotTo(HumanoidRootPart.CFrame)

    HollowPurpleAn:GetMarkerReachedSignal("AddCharge"):Connect(function()
        Purple:PivotTo(Unit.PrimaryPart.CFrame * CFrame.new(0,0,-4))
        Purple.Parent = Unit
     
        Red.CFrame = Unit["LeftPart"].CFrame * CFrame.new(0,0,0)
        Red.WeldConstraint.Part1 = Unit["LeftPart"]
    
        Blue.CFrame = Unit["RightPart"].CFrame * CFrame.new(0,0,0)
        Blue.WeldConstraint.Part1 = Unit["RightPart"]
    
        Blue.Anchored = false
        Red.Anchored = false
    end)

    HollowPurpleAn:GetMarkerReachedSignal("Purple"):Connect(function()
        Red:Destroy()
        Blue:Destroy()

        Purple.Purple:PivotTo(HumanoidRootPart.CFrame * CFrame.new(0,2.75,-2)) 
        Purple.Purple:ScaleTo(0.01)
        task.delay(.1,Scale, Purple.Purple, .35)
        -- Purple.Purple.PrimaryPart.WeldToUnit.Part1 = HumanoidRootPart
        -- Purple.Purple.PrimaryPart.Anchored = false
    end)

    HollowPurpleAn:GetMarkerReachedSignal("PurpleFire"):Connect(function()
            
        MoveConnection = RunService.Stepped:Connect(function(time,step)
            CurveTime = 0
            DistanceToTarget = Move(UnitInfo.Target,Unit,Projectile,step,5)

            if DistanceToTarget <= 1 and not HasExploded then
                PurpleExplosion.Parent = Unit
                PurpleExplosion.CFrame = CFrame.new(UnitInfo.Target.Position)

                HasExploded = true
                Purple:Destroy()
                Projectile:Destroy()

                Emit(PurpleExplosion, 8)
                UnitService:RequestDamage(Unit)
                MoveConnection:Disconnect()
            end
        end)
    end)
    -- task.spawn(Toggle,Purple.Blue, true)


    -- task.spawn(Toggle,Purple.Red, false)
    -- task.spawn(Toggle,Purple.Purple["Hollow Purple"], false)

    -- task.delay(1,Toggle,Purple.Blue, true)
    -- task.delay(1,Toggle,Purple.Red, true)
    -- task.delay(1,Toggle,Purple.Purple["Hollow Purple"], true)

    -- TweenService:Create(Purple.Blue, TweenInfo.new(2.5),{Position = Purple.Purple["Hollow Purple"].CFrame.Position}):Play()
    -- TweenService:Create(Purple.Red, TweenInfo.new(2.5),{Position = Purple.Purple["Hollow Purple"].CFrame.Position}):Play()


    -- task.wait(2.5)

    -- task.delay(1, game.Destroy, Purple.Blue)
    -- task.delay(1, game.Destroy, Purple.Red)
    -- Emit(PurpleExplosion, 10)
end

function Purple.Attack(Unit,UnitInfo)
    UnitService = Knit.GetService("UnitService")
    Purple:Activate(Unit,UnitInfo)
end

return Purple