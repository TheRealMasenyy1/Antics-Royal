local Hitbox = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local PartCache = require(ReplicatedStorage.Shared.Utility.PartCache)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local HitboxVisualize = ReplicatedStorage.Assets.HitboxVisualize
local Knit = require(ReplicatedStorage.Packages.Knit)

local tempHitbox = Instance.new("Part")
tempHitbox.Name = "tempHitbox"
tempHitbox.Color = Color3.fromRGB(255)
tempHitbox.Transparency = 1
tempHitbox.Anchored = true
tempHitbox.CanCollide = false
tempHitbox.Shape = Enum.PartType.Ball

local overlaps = OverlapParams.new()
overlaps.FilterType = Enum.RaycastFilterType.Include
overlaps.FilterDescendantsInstances = {workspace.Gameplay.Mobs}

local function DeleteCurrentHitbox(Npc)
    local Zone = workspace.GameAssets.Units.Detectors:FindFirstChild(Npc:GetAttribute("Id"))

    if Zone then
        Zone.Floor.Decal.Transparency = 1
    end

    for _,Part in pairs(workspace.Debris:GetChildren()) do
        if Part:GetAttribute("Hitbox") then
            Part:Destroy()
        end
    end
end

function Hitbox.Transparency(hitBox,value)
    if not hitBox then return end 

    local GetDescendants = hitBox:GetDescendants()
    value = value or 0

    for _,part in GetDescendants do
        if (part:IsA("Decal")) then
            part.Transparency = value
        elseif (part:IsA("Beam") or part:IsA("ParticleEmitter")) then
            part.Transparency = NumberSequence.new(value,value)

            if value == 1 then
                part.Enabled = false
            else
                part.Enabled = true
            end
        end
    end
end

function Hitbox.ThrowVisualize(Npc : Model, Target, Info)
    local ThrowVisualize = workspace.Debris:FindFirstChild("ThrowVisualize")

    if not ThrowVisualize then
        DeleteCurrentHitbox(Npc)
        local TweenInformation = TweenInfo.new(2,Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, math.huge, false, 0)
        ThrowVisualize = HitboxVisualize.ThrowVisualize:Clone()
        ThrowVisualize.Base:PivotTo(Npc.PrimaryPart.CFrame)
        ThrowVisualize.End:PivotTo(Target.PrimaryPart.CFrame)
        ThrowVisualize.End.Size = Vector3.new(Info.Size.X,Info.Size.X,.1) --.PrimaryPart.Size = Vector3.new(Info.Size.X,0,Info.Size.Z)
        --ThrowVisualize.End.CFrame = Target.PrimaryPart.CFrame * CFrame.new(0,-1.3,0)--)-- - Vector3.new(0,-1.3,0)  --:PivotTo(CFrame.new(Target:GetPivot().Position) * CFrame.new(0,-1.3,0))
        --ThrowVisualize.Base.CFrame = Npc.PrimaryPart.CFrame-- * CFrame.Angles(math.rad(180),0,0) --:PivotTo(CFrame.new(Npc:GetPivot().Position))
        ThrowVisualize.Parent = Workspace.Debris

        --TweenService:Create(ThrowVisualize.End,TweenInformation,{Orientation = ThrowVisualize.End.Orientation + Vector3.new(0,0,360)}):Play()
    else
        Hitbox.Transparency(ThrowVisualize,0)

        local succ, err = pcall(function()
            ThrowVisualize.Base:PivotTo(Npc.PrimaryPart.CFrame)
            ThrowVisualize.End:PivotTo(CFrame.new(Target.PrimaryPart.Position) * CFrame.new(0,-1,0)) --* Target.PrimaryPart.CFrame    
        end)

        
        if err then Hitbox.Transparency(ThrowVisualize,1) return false end
    end

    return ThrowVisualize
end

function Hitbox.AOEVisualize(Npc : Model, Target, Info)
    local Zone = workspace.GameAssets.Units.Detectors:FindFirstChild(Npc:GetAttribute("Id"))
    local AOEVisualize = Zone.Floor

    if AOEVisualize.Decal.Transparency == 1 then
        DeleteCurrentHitbox(Npc)
        --local TweenInformation = TweenInfo.new(5.5,Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, math.huge, false, 0)

        AOEVisualize.Decal.Transparency = .6
        --TweenService:Create(Zone,TweenInformation,{CFrame = Zone.CFrame * CFrame.Angles(0,math.rad(180),0)}):Play()

       -- AOEVisualize.Size = Vector3.new(Info.Size.X + 30,.001,Info.Size.Z + 30)
    else

        AOEVisualize.Size = Vector3.new(Info.Size.X + 30,.001,Info.Size.Z + 30)

        AOEVisualize.CFrame = AOEVisualize.CFrame * CFrame.Angles(0,math.rad(1),0)
        -- incraes size here
        --Hitbox.Transparency(AOEVisualize,0)

        --local succ, err = pcall(function()
        --    AOEVisualize.Base:PivotTo(Npc.PrimaryPart.CFrame)
        --    AOEVisualize.End:PivotTo(CFrame.new(Target.PrimaryPart.Position) * CFrame.new(0,-1,0)) --* Target.PrimaryPart.CFrame    
        --end)

        
        --if err then Hitbox.Transparency(AOEVisualize,1) return false end
    end

    return AOEVisualize
end

function Hitbox.BeamVisualize(Npc : Model, Target, Info, Range)
    --warn("here", Info)

    local Wide = Info.Size.X

    Range = Range --+ 1
    local BeamVisualize = workspace.Debris:FindFirstChild("BeamVisualize")

    if not BeamVisualize then
        DeleteCurrentHitbox(Npc)
        BeamVisualize = HitboxVisualize.BeamVisualize:Clone()
        BeamVisualize:PivotTo(Npc.PrimaryPart.CFrame * CFrame.new(0,-1.11,0))        --BeamVisualize.End.WorldCFrame = Target.HumanoidRootPart.CFrame * CFrame.new(0,-2.5,0)
        BeamVisualize.Parent = Workspace.Debris
        BeamVisualize.Beam.Width0 = Wide
        BeamVisualize.Beam.Width1 = Wide
    else
        Hitbox.Transparency(BeamVisualize,0)

        local succ, err = pcall(function()
            BeamVisualize.Beam.Width0 = Wide
            BeamVisualize.Beam.Width1 = Wide
            BeamVisualize:PivotTo(Npc.PrimaryPart.CFrame * CFrame.new(0,-1.11,0))        --BeamVisualize.End.WorldCFrame = Target.HumanoidRootPart.CFrame * CFrame.new(0,-2.5,0)
            BeamVisualize.End.WorldCFrame = ((Npc.PrimaryPart.CFrame) * CFrame.new(0,-1.11,-Range)) * CFrame.Angles(0,0,math.rad(-90))
            --BeamVisualize.End.WorldCFrame = Target.HumanoidRootPart.CFrame * CFrame.new(0,-2.5,0)
        end)

        
        if err then Hitbox.Transparency(BeamVisualize,1) return false end
    end

    return BeamVisualize
end

function Hitbox.PoisonDamage(Npc, Info,UnitInfo, _callback)
    local Duration = Info.Duration or 10
    local HitboxDuration = Info.HitboxDuration or 10
    local MaxEntity = Info.MaxEntity or 10
    local Delay = Info.Delay or 1
    local Count = 0
    local Hitbox = tempHitbox:Clone()
    Hitbox.Parent = workspace.Debris
    Hitbox.Size = Info.Size
    Hitbox.Name = "Hitbox"
    -- Hitbox.Transparency = .75
    Hitbox.CFrame = Info.TargetCFrame

    local AlreadyHit = {}
    local dt = 0;
    local Attackdt = 0

    task.delay(Duration, game.Destroy, Hitbox)

    repeat
        local PartsInHitbox = workspace:GetPartsInPart(Hitbox,overlaps)

        for _,hits in PartsInHitbox do
            local AnimationController = hits.Parent:FindFirstChild("Humanoid")

            if AnimationController then
                local Mob = AnimationController.Parent
                local Health = Mob:GetAttribute("Health")

                if Health and Health > 0 and not AlreadyHit[Mob:GetAttribute("Id")] and Count < MaxEntity then
                    Count += 1
                    task.spawn(function()

                        while Attackdt <= Duration do
                            if not AlreadyHit[Mob:GetAttribute("Id")] then
                                _callback(Mob,Health)
                                AlreadyHit[Mob:GetAttribute("Id")] = true

                                task.delay(Delay,function()
                                    AlreadyHit[Mob:GetAttribute("Id")] = nil
                                end)
                            end 
                            Attackdt += RunService.Heartbeat:Wait()
                        end

                    end)
                elseif Count >= MaxEntity then
                    dt = Duration
                    break;
                end
            end
        end

        dt += RunService.Heartbeat:Wait()
    until dt >= HitboxDuration
end

function Hitbox.ThrowAndDamageOverTime(Npc, Info,UnitInfo, _callback)
    local Duration = Info.Duration or 10
    local MaxEntity = Info.MaxEntity or 10
    local Count = 0
    local Hitbox = tempHitbox:Clone()
    Hitbox.Parent = workspace.Debris
    Hitbox.Size = Info.Size
    Hitbox.Name = "Hitbox"
    -- Hitbox.Transparency = .75
    Hitbox.CFrame = Info.TargetCFrame

    local AlreadyHit = {}
    local dt = 0;

    task.delay(Duration, game.Destroy, Hitbox)
    local PartsInHitbox = workspace:GetPartsInPart(Hitbox,overlaps)

    repeat
        for _,hits in PartsInHitbox do
            local AnimationController = hits.Parent:FindFirstChild("Humanoid")

            if AnimationController then
                local Mob = AnimationController.Parent
                local Health = Mob:GetAttribute("Health")

                if Health and Health > 0 and not AlreadyHit[Mob:GetAttribute("Id")] and Count < MaxEntity then
                    Count += 1
                    _callback(Mob,Health)
                    AlreadyHit[Mob:GetAttribute("Id")] = true

                    task.delay(1,function()
                        Count -= 1
                        AlreadyHit[Mob:GetAttribute("Id")] = nil
                    end)
                -- elseif Count >= MaxEntity then
                    -- dt = Duration
                    -- break;
                end
            end
        end

        dt += RunService.Heartbeat:Wait()
    until dt >= Duration
end

function Hitbox.BeamAndDamageOverTime(Npc, Info,UnitInfo, _callback)
    if not Info.TargetCFrame then return end
    local Count = 0;
    local Duration = Info.Duration or 10
    local MaxEntity = Info.MaxEntity or 10
    local Hitbox = tempHitbox:Clone()
    local HitDelay = Info.HitDelay or 1 -- How long until a mob can be hit again etc 1 sec

    Hitbox.Parent = workspace.Debris
    Hitbox.Size = Info.Size
    --Hitbox.Transparency = .5
    Hitbox.Name = "Hitbox"
    Hitbox.CFrame = Npc.PrimaryPart.CFrame * Info.PositionToCharacter -- or Info.TargetCFrame

    task.delay(Duration,game.Destroy,Hitbox)

    local AlreadyHit = {}
    local dt = 0;
    
    local PartsInHitbox = workspace:GetPartsInPart(Hitbox,overlaps)

    repeat 
        for _,hits in PartsInHitbox do
            local AnimationController = hits.Parent:FindFirstChild("Humanoid")

            if AnimationController then
                local Mob = AnimationController.Parent
                local Health = Mob:GetAttribute("Health")

                if Health and Health > 0 and not AlreadyHit[Mob:GetAttribute("Id")] and Count < MaxEntity then
                    Count += 1
                    _callback(Mob,Health)
                    AlreadyHit[Mob:GetAttribute("Id")] = true

                    task.delay(HitDelay,function()
                        Count -= 1
                        AlreadyHit[Mob:GetAttribute("Id")] = nil
                    end)
                end
            end
        end

        dt += RunService.Heartbeat:Wait()
    until dt >= Duration
end

function Hitbox.AOEAndDamageOverTime(Npc, Info,UnitInfo, _callback)
    if not Info.TargetCFrame then return end
    
    local Duration = Info.Duration or 10
    local Delay = Info.Delay or 1
    local MaxEntity = Info.MaxEntity or 10
    local Count = 0
    local AlreadyHit = {}
    local Hitbox = tempHitbox:Clone()
    local Level = UnitInfo.Level
    --print(UnitInfo)
    local RealSize,_,value = UnitManager:ConvertGradeInGame(UnitInfo,"Range",Level)
    --print(RealSize,_,value)
    Hitbox.Parent = workspace.Debris
    Hitbox.Size = Vector3.new(value * 1.6,value * 1.6,value * 1.6)
    Hitbox.Name = "Hitbox"
    Hitbox.CFrame = Npc.PrimaryPart.CFrame

    task.delay(Duration, game.Destroy, Hitbox)

    local AlreadyHit = {}
    local dt = 0;
    local PartsInHitbox = workspace:GetPartsInPart(Hitbox,overlaps)

    repeat
        for _,hits in PartsInHitbox do
            local AnimationController = hits.Parent:FindFirstChild("Humanoid")

            if AnimationController then
                local Mob = AnimationController.Parent
                local Health = Mob:GetAttribute("Health")

                if Health and Health > 0 and not AlreadyHit[Mob:GetAttribute("Id")] and Count < MaxEntity then
                    Count += 1
                    --print("MOB ADDED")
                    _callback(Mob,Health)
                    AlreadyHit[Mob:GetAttribute("Id")] = true

                    task.delay(Delay,function()
                        Count -= 1
                        --print("MOB REMOVED: ", Delay)
                        AlreadyHit[Mob:GetAttribute("Id")] = nil
                    end)
                -- elseif Count >= MaxEntity then
                    -- dt = Duration
                    -- break;
                end
            end
        end

        dt += RunService.Heartbeat:Wait()
    until dt >= Duration
end

function Hitbox.StickAndDamageOverTime(Npc, Info,UnitInfo, _callback) -- follow units
    local Duration = Info.Duration or 10
    local Delay = Info.Delay or 1
    local MaxEntity = Info.MaxEntity or 10
    local Count = 0
    local Hitbox = tempHitbox:Clone()
    Hitbox.Parent = workspace.Debris
    Hitbox.Size = Info.Size
    Hitbox.Name = "Hitbox"
    Hitbox.CFrame = Info.TargetCFrame

    local WeldConstraint = Instance.new("WeldConstraint")
    WeldConstraint.Part0 = Hitbox
    WeldConstraint.Part1 = Npc.HumanoidRootPart
    WeldConstraint.Parent = Hitbox

    local AlreadyHit = {}
    local dt = 0;

    task.delay(Duration, game.Destroy, Hitbox)
    local PartsInHitbox = workspace:GetPartsInPart(Hitbox,overlaps)

    repeat
        for _,hits in PartsInHitbox do
            local AnimationController = hits.Parent:FindFirstChild("Humanoid")

            if AnimationController then
                local Mob = AnimationController.Parent
                local Health = Mob:GetAttribute("Health")

                if Health and Health > 0 and not AlreadyHit[Mob:GetAttribute("Id")] and Count < MaxEntity then
                    Count += 1
                    --print("MOB ADDED")
                    _callback(Mob,Health)
                    AlreadyHit[Mob:GetAttribute("Id")] = true

                    task.delay(Delay,function()
                        Count -= 1
                        --print("MOB REMOVED: ", Delay)
                        AlreadyHit[Mob:GetAttribute("Id")] = nil
                    end)
                -- elseif Count >= MaxEntity then
                    -- dt = Duration
                    -- break;
                end
            end
        end

        dt += RunService.Heartbeat:Wait()
    until dt >= Duration
end

function Hitbox.Beam(Npc, Info,UnitInfo, _callback)
    if not Info.TargetCFrame then return end
    local Count = 0;
    local MaxEntity = Info.MaxEntity or 10
    local AlreadyHit = {}
    local Hitbox = tempHitbox:Clone()
    Hitbox.Parent = workspace.Debris
    Hitbox.Size = Info.Size
    -- Hitbox.Transparency = .5
    Hitbox.Name = "Hitbox"
    Hitbox.CFrame = Npc.PrimaryPart.CFrame * Info.PositionToCharacter --* CFrame.new(0,0, (Info.Size.Z * -1) ) --Info.PositionToCharacter -- or Info.TargetCFrame
    Hitbox.Shape = Enum.PartType.Block

    task.delay(2,game.Destroy,Hitbox)

    local PartsInHitbox = workspace:GetPartsInPart(Hitbox,overlaps)

    for _,hits in PartsInHitbox do
        local AnimationController = hits.Parent:FindFirstChild("Humanoid")

        if AnimationController then
            local Mob = AnimationController.Parent
            local Health = Mob:GetAttribute("Health")

            if Health and Health > 0 and not AlreadyHit[Mob:GetAttribute("Id")] and Count < MaxEntity then
                Count += 1
                _callback(Mob,Health)
                AlreadyHit[Mob:GetAttribute("Id")] = true

                task.delay(1,function()
                    AlreadyHit[Mob:GetAttribute("Id")] = nil
                end)
            end
        end
    end
end

function Hitbox.Throw(Npc, Info,UnitInfo, _callback)
    if not Info.TargetCFrame then return end

    local MaxEntity = Info.MaxEntity or 10
    local Count = 0
    local AlreadyHit = {}
    local Hitbox = tempHitbox:Clone()
    Hitbox.Parent = workspace.Debris
    Hitbox.Size = Info.Size
    Hitbox.Name = "Hitbox"
    Hitbox.CFrame = Info.TargetCFrame

    task.delay(2,game.Destroy,Hitbox)

    local PartsInHitbox = workspace:GetPartsInPart(Hitbox,overlaps)

    for _,hits in PartsInHitbox do
        local AnimationController = hits.Parent:FindFirstChild("Humanoid")

        if AnimationController then
            local Mob = AnimationController.Parent
            local Health = Mob:GetAttribute("Health")

            if Health and Health > 0 and not AlreadyHit[Mob:GetAttribute("Id")] and Count < MaxEntity then
                _callback(Mob,Health)
                AlreadyHit[Mob:GetAttribute("Id")] = true

                task.delay(1,function()
                    AlreadyHit[Mob:GetAttribute("Id")] = nil
                end)
            end
        end
    end
end

function Hitbox.AOE(Npc, Info,UnitInfo, _callback)
    if not Info.TargetCFrame then return end

    local MaxEntity = Info.MaxEntity or 10
    local Count = 0
    local AlreadyHit = {}
    local Hitbox = tempHitbox:Clone()
    local Level = UnitInfo.Level
    --print(UnitInfo)
    local RealSize,_,value = UnitManager:ConvertGradeInGame(UnitInfo,"Range",Level)
    --print(RealSize,_,value)
    Hitbox.Parent = workspace.Debris
    Hitbox.Size = Vector3.new(value * 1.6,value * 1.6,value * 1.6)
    Hitbox.Name = "Hitbox"
    Hitbox.CFrame = Npc.PrimaryPart.CFrame

    task.delay(2,game.Destroy,Hitbox)

    local PartsInHitbox = workspace:GetPartsInPart(Hitbox,overlaps)

    for _,hits in PartsInHitbox do
        local AnimationController = hits.Parent:FindFirstChild("Humanoid")

        if AnimationController then
            local Mob = AnimationController.Parent
            local Health = Mob:GetAttribute("Health")

            if Health and Health > 0 and not AlreadyHit[Mob:GetAttribute("Id")] and Count < MaxEntity then
                _callback(Mob,Health)
                AlreadyHit[Mob:GetAttribute("Id")] = true

                task.delay(1,function()
                    AlreadyHit[Mob:GetAttribute("Id")] = nil
                end)
            end
        end
    end
end

return Hitbox