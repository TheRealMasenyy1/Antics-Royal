local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Entity = {}

local Mobs = ServerStorage.Mobs
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local Signals = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Gameplay = workspace.Gameplay
local GameplayMobs = Gameplay.Mobs
local Assets = ReplicatedStorage.Assets
local MatchService

type EntityType = {
    Amount : number,
    Enemy : string,
    HP : number,
    Speed : number,
    Path : { [number] : CFrame}
}

local Scale = .425

local attachmentCFrames = {
	["Neck"] = {CFrame.new(0, 1* Scale, 0, 0, -1 * Scale, 0, 1* Scale, 0, -0, 0, 0, 1* Scale), CFrame.new(0, -0.5* Scale, 0, 0, -1* Scale, 0, 1* Scale, 0, -0, 0, 0, 1* Scale)},
	["Left Shoulder"] = {CFrame.new(-1.3* Scale, 0.75* Scale, 0, -1* Scale, 0, 0, 0, -1* Scale, 0, 0, 0, 1* Scale), CFrame.new(0.2* Scale, 0.75* Scale, 0, -1* Scale, 0, 0, 0, -1* Scale, 0, 0, 0, 1* Scale)},
	["Right Shoulder"] = {CFrame.new(1.3* Scale, 0.75* Scale, 0, 1* Scale, 0, 0, 0, 1* Scale, 0, 0, 0, 1* Scale), CFrame.new(-0.2* Scale, 0.75* Scale, 0, 1* Scale, 0, 0, 0, 1* Scale, 0, 0, 0, 1* Scale)},
	["Left Hip"] = {CFrame.new(-0.5* Scale, -1* Scale, 0, 0, 1* Scale, -0, -1* Scale, 0, 0, 0, 0, 1* Scale), CFrame.new(0, 1* Scale, 0, 0, 1* Scale, -0, -1* Scale, 0, 0, 0, 0, 1* Scale)},
	["Right Hip"] = {CFrame.new(0.5* Scale, -1* Scale, 0, 0, 1* Scale, -0, -1* Scale, 0, 0, 0, 0, 1* Scale), CFrame.new(0, 1* Scale, 0, 0, 1* Scale, -0, -1* Scale, 0, 0, 0, 0, 1* Scale)},
}

local ragdollInstanceNames = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}

local function SetCollisionGroup(Model, Name)
    local Descendants = Model:GetDescendants()

    for _, part : BasePart in Descendants do
        if part:IsA("BasePart") then
            part.CollisionGroup = Name
        end
    end
end

local function getUnitById(ID : number)
    local parentFolder = workspace.GameAssets.Units:GetChildren()

    for _, unit in pairs(parentFolder) do
        local unitID = unit:GetAttribute("Id")

       -- print*

        if unitID and unitID == ID then
            return unit
        end 
    end
end

local function getAffectedUnitsByExplosion(Unit, distance) -- Id is of the unit that killed the mob that will explode
    local units = {}
    local parentFolder = workspace.GameAssets.Units:GetChildren()

    for _, unit in pairs(parentFolder) do
        if unit:GetAttribute("Stun") == true then continue end
        if not unit:FindFirstChild("HumanoidRootPart") then continue end
        local currentDistance = (unit.HumanoidRootPart.Position - Unit.HumanoidRootPart.Position).Magnitude

        if currentDistance <= distance then
            table.insert(units, unit)
        end
    end

    --table.insert(units, Unit)

    return units
end

local function createColliderPart(part: BasePart)
	if not part then return end
	local rp = Instance.new("Part")
	rp.Name = "ColliderPart"
	rp.Size = part.Size/1.7
	rp.Massless = true			
	rp.CFrame = part.CFrame
	rp.Transparency = 1

	local wc = Instance.new("WeldConstraint")
	wc.Part0 = rp
	wc.Part1 = part

	wc.Parent = rp
	rp.Parent = part
end

local TS = game:GetService("TweenService")
local TI = TweenInfo.new(.5,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,true,0)

local bossModules = {}

for _,module in pairs(script:GetChildren()) do
    bossModules[module.Name] = require(module)
end

function Entity.new(EntityInfo : EntityType)
    local entity = Mobs:FindFirstChild(EntityInfo.Enemy)
    local GameSpeed = workspace.Values.GameSpeed
    local MatchService = Knit.GetService("MatchService")
    local UnitService = Knit.GetService("UnitService")

    if entity then
        local newEntity : Model = entity:Clone()
        local Humanoid = newEntity.Humanoid
        local newTrove = Trove.new()

        newEntity.HumanoidRootPart.Anchored = true
        newEntity:PivotTo(EntityInfo.Path[1])
        
        newEntity:SetAttribute("IsActive", true)
        newEntity:SetAttribute("Speed",EntityInfo.Speed * GameSpeed.Value)
        newEntity:SetAttribute("OriginalSpeed",EntityInfo.Speed)
        newEntity:SetAttribute("Health", EntityInfo.HP)
        newEntity:SetAttribute("MaxHealth", EntityInfo.HP)
        newEntity:SetAttribute("IsBoss", EntityInfo.IsBoss or false)
        newEntity:SetAttribute("Shield", EntityInfo.Shield)
        newEntity:SetAttribute("MobType", EntityInfo.MobType)
        newEntity:SetAttribute("Regen", EntityInfo.Regen or false)
        newEntity:SetAttribute("Explode", EntityInfo.Explode or false)
        newEntity:SetAttribute("RegenPercent", EntityInfo.RegenPercent or 0)

        SetCollisionGroup(newEntity, "MobGroup")

        newEntity.Parent = GameplayMobs
        newTrove:Add(newEntity)

        if newEntity:GetAttribute("Regen") then
            task.spawn(function()
                Entity.Regen(newEntity)
            end)
        end
        
        newEntity.AttributeChanged:Connect(function(attribute)
            if attribute == "Health" then
                local Health = newEntity:GetAttribute("Health")

                if Health <= 0 then
                    Entity.Died(newEntity)
                --elseif Regen then
                    
                    
                end
            end
        end)

        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        -- Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

        task.spawn(function()
            Entity.FollowNode(newEntity, EntityInfo.Path)
        end)

        if EntityInfo.IsBoss then
            if bossModules[EntityInfo.Enemy] ~= nil then
                task.spawn(function()
                    MatchService.CurrentPauseWave(true)
    
                    UnitService.Client.BossWarning:FireAll()
    
                    task.wait(3)
    
                    bossModules[EntityInfo.Enemy]:Intro(newEntity)
    
                    MatchService.CurrentPauseWave(false)
    
                    bossModules[EntityInfo.Enemy]:Activate(newEntity)
                end) 
            end
        end

        MatchService.InsertEntityTable:Fire(newEntity)

        return newEntity,newTrove
    end
end

function Entity.Regen(Character)
    local willRegen = true

    while willRegen do
        task.wait(1)

        local Health = Character:GetAttribute("Health")
        local RegenPercent = Character:GetAttribute("RegenPercent")
        local MaxHealth = Character:GetAttribute("MaxHealth")

        if Health <= 0 then willRegen = false break end

        if Health < MaxHealth then
            local newHealth = ((MaxHealth / 100) * RegenPercent) + Health

            if newHealth > MaxHealth then
                newHealth = MaxHealth
            end

            if newHealth <= MaxHealth then
                Character:SetAttribute("Health",newHealth)
            end
        end
    end

end

--> Converts Motor6D's into BallSocketConstraints
function replaceJoints(Character)
	for _, motor: Motor6D in pairs(Character:GetDescendants()) do
		if motor:IsA("Motor6D") then
			if not attachmentCFrames[motor.Name] then return end
			motor.Enabled = false;
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.CFrame = attachmentCFrames[motor.Name][1]
			a1.CFrame = attachmentCFrames[motor.Name][2]

			a0.Name = "RagdollAttachment"
			a1.Name = "RagdollAttachment"

			createColliderPart(motor.Part1)

			local b = Instance.new("BallSocketConstraint")
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Name = "RagdollConstraint"

			b.Radius = 0.15
			b.LimitsEnabled = true
			b.TwistLimitsEnabled = false
			b.MaxFrictionTorque = 0
			b.Restitution = 0
			b.UpperAngle = 90
			b.TwistLowerAngle = -45
			b.TwistUpperAngle = 45

			if motor.Name == "Neck" then
				b.TwistLimitsEnabled = true
				b.UpperAngle = 45
				b.TwistLowerAngle = -70
				b.TwistUpperAngle = 70
			end

			a0.Parent = motor.Part0
			a1.Parent = motor.Part1
			b.Parent = motor.Parent
		end
	end
end

function Entity:Ragdoll(Character, value)
    local FallDirections = {
        Character:GetPivot().LookVector, 
        -Character:GetPivot().LookVector,
        Character:GetPivot().RightVector, 
        -Character:GetPivot().RightVector,
    }

    local Humanoid = Character.Humanoid
    local HumanoidRootPart = Character.HumanoidRootPart
    local Torso = Character.Torso

    local function push()
        if not Character:GetAttribute("PushDirection") then
            HumanoidRootPart:ApplyImpulse(Torso.CFrame.UpVector + FallDirections[math.random(1,#FallDirections)] * math.random(Character:GetAttribute("PushPower")/2,Character:GetAttribute("PushPower")))
        else
            local Direction = Character:GetAttribute("PushDirection")--DirectionTable[Character:GetAttribute("PushDirection")]
            HumanoidRootPart:ApplyImpulse(Torso.CFrame.UpVector + Direction * math.random(Character:GetAttribute("PushPower")/2,Character:GetAttribute("PushPower")))
        end
    end

    if value then
		Character.PrimaryPart:SetNetworkOwner(nil)
		Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		replaceJoints(Character)
		push()
	end
end

function Entity.CanCollide(EntityModel, Value)
    local GetDescendants = EntityModel:GetDescendants()

    for _, parts in GetDescendants do
        if parts:IsA("Part") then
            parts.CanCollide = Value
        end
    end
end

function Entity.Died(EntityModel)
    local MobService = Knit.GetService("MobService")
    local UnitService = Knit.GetService("UnitService")
    local MatchService = Knit.GetService("MatchService")
    local PlayerService = Knit.GetService("PlayerService")
    local HealthGui = EntityModel.Head:FindFirstChild("MobStatusUI")
    local GetDescendants = EntityModel:GetDescendants()
    local WillExplode = EntityModel:GetAttribute("Explode")
    local LastHit = EntityModel:GetAttribute("LastHit") -- Id of unit that killed this entity

    EntityModel:SetAttribute("IsActive",false)
    EntityModel:SetAttribute("Speed", 0)

    -- Ragdoll gets activated here 
    EntityModel.PrimaryPart.Anchored = false

    MatchService.RemoveEntityTable:Fire(EntityModel)
    -- Entity.CanCollide(EntityModel,true)

    if EntityModel:GetAttribute("IsBoss") then
        MobService.Client.BossDialog:FireAll(EntityModel,"Death")
    end

    if WillExplode then
        local Unit = getUnitById(LastHit)
        local AffectedUnits = getAffectedUnitsByExplosion(Unit,15)
        local Time = 3 -- stunned for 2 seconds

        UnitService.Client.ExplodeVFX:FireAll(EntityModel)
        EntityModel.HumanoidRootPart.Anchored = true

        task.spawn(function()
            UnitService:StunUnits(AffectedUnits,Time, os.clock())
        end)
    else
        Entity:Ragdoll(EntityModel, true)
        MobService.Client.Knockback:FireAll(EntityModel,EntityModel:GetAttribute("PushPower"))
    end



    local killedBy = EntityModel:GetAttribute("Tagged")

    PlayerService:GiveMobKill(killedBy, 1)

    if EntityModel:GetAttribute("IsBoss") then
        for _,player in pairs(Players:GetChildren()) do
            PlayerService:GiveBossKill(player, 1)
        end
    end

    task.wait(5)

    if HealthGui then HealthGui:Destroy() end

    for _, parts in GetDescendants do
        if parts:IsA("BasePart") then
            TweenService:Create(parts,TweenInfo.new(1),{Transparency = 1}):Play()
        end
    end

    task.delay(2, function()
        EntityModel:Destroy()
    end)
end

function Entity.KeepGroundLevel(RootPart : BasePart,RayVector: Vector3, rayparam) -- Casts a ray towards the floor and returns the Ground Position
    local raycastParams

    if not rayparam then
        raycastParams  = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = { RootPart.Parent, GameplayMobs, Gameplay.Path, workspace.GameAssets}
        raycastParams.IgnoreWater = true
    else
        raycastParams = rayparam
    end

	RayVector = RayVector or Vector3.new(0, -50, 0)

	local Ray_Cast =  Shortcut.RayCast(RootPart.Position, RayVector, raycastParams)

	if Ray_Cast then
		if Ray_Cast.Position.Magnitude > 0 then
			return Ray_Cast.Position,Ray_Cast.Normal,Ray_Cast.Instance
		else
			--warn("ERROR COULD NOT FIND THE PROBLEM ", Ray_Cast)
			return RootPart.Position
		end
	end
end

function Entity.FollowNode(EntityModel,Nodes) -- Follows the nodes for the given
    local Speed = .1
    local Offset = .5
    local CurrentNode = 1
    local Position,RayNormal
    local Normal;
    local HeightOffset = EntityModel:GetAttribute("HeightOffset") or 0.25
    local Walkspeed = EntityModel:GetAttribute("Speed")

    local function getAngle(NormalVector : Vector3) : Vector3 -- Gets the angle of the floor 
		-- if not Entity:GetAttribute("RotateRot") or Entity:GetAttribute("Ignore") == MatchFolder.Parent:GetAttribute("FloorName") then return 0 end
        if not NormalVector then return 0 end
		local Angle = math.deg(math.acos(NormalVector:Dot(Vector3.yAxis)))
		
		if NormalVector:Dot(EntityModel:GetPivot().Position) < 0 then
			Angle = -math.deg(math.acos(NormalVector:Dot(Vector3.yAxis)))
		end
				
		return Angle
	end

    while EntityModel:GetAttribute("IsActive") do
			local Distance 
            Walkspeed = EntityModel:GetAttribute("Speed")

            local succ,err = pcall(function()
                Distance = (Vector3.new(EntityModel.HumanoidRootPart.Position.X, Nodes[CurrentNode].Y,EntityModel.HumanoidRootPart.Position.Z) - Nodes[CurrentNode].Position).Magnitude
            end)

            if succ then
                Position,RayNormal = Entity.KeepGroundLevel(EntityModel.HumanoidRootPart)
                Normal = getAngle(RayNormal) -- needs some tweaks
                
                local TweenProp 
                local useAngle = if EntityModel:GetAttribute("Inverted") then CFrame.Angles(math.rad(Normal),math.rad(180),0) else CFrame.Angles(math.rad(Normal),0,0)

                if Walkspeed < 0 then 
                    EntityModel:SetAttribute("Speed",0) 
                    Walkspeed = 0 
                end
                
                TweenProp = {
                    CFrame = CFrame.new(
                        Vector3.new(
                            EntityModel.HumanoidRootPart.Position.X,
                            Position.Y + (EntityModel.HumanoidRootPart.Size.Y / 2) + HeightOffset, --- Keeps the attacker on the ground and not hovering
                            EntityModel.HumanoidRootPart.Position.Z
                        ),
                        Vector3.new(
                            Nodes[CurrentNode].X,
                            EntityModel.HumanoidRootPart.Position.Y, --+ math.clamp(Normal,-10,10),
                            Nodes[CurrentNode].Z
                        )
                    ) * useAngle + EntityModel.HumanoidRootPart:GetPivot().LookVector * (Walkspeed/10),
                }

                local Movement : TweenBase = TweenService:Create(EntityModel.HumanoidRootPart,TweenInfo.new(Speed),TweenProp)
                Movement:Play()

                -- --print("CurrentNode: ", CurrentNode)
                if Distance <= Offset then
                    CurrentNode += 1
                    EntityModel:SetAttribute("CurrentNode", CurrentNode)
                elseif CurrentNode > #Nodes then
                    EntityModel:SetAttribute("IsActive", false)
                end	
            else
                -- warn("Could not find next Node ")
            end
            task.wait()
		end
end

function Entity.Destroy(EntityModel)
    EntityModel:SetAttribute("IsActive", false)
    EntityModel:Destroy()

    warn("ENTITY HAS BEEN CLEANED")
    --- Send Signal to client
end


return Entity