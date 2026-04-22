local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Destruction = require(ReplicatedStorage.Shared.Destruction)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local UnitVFX = Knit.CreateController {
    Name = "UnitVFX",
}

local Assets = ReplicatedStorage.Assets
local VFX = ReplicatedStorage.Assets.VFX
local AnimationsFolder = Assets.Animations

local Animations = {
    WalkAnimation = "rbxassetid://107193539929267"
}
local SoundController;
local RequiredModules = {}

type UnitInformation = {
    Unit : any,
    Name : string,
    UnitId : number,
    Owner : string,
    Ability : string,
    Target : any,
}

function Emit(Part)
	for i, v in pairs(Part:GetDescendants()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function Invisible(Model, Value)
    for _, part in Model:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= ("Detector") and part.Name ~= ("Upgrade") then
           -- if Value == 0 and part.Transparency == 1 then continue end
            part.Transparency = Value 
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

function StopAnimsExeptIdle(Unit)
    local Humanoid = if Unit:FindFirstChild("Humanoid") then Unit.Humanoid else false
    local Animator = if Humanoid then Humanoid.Animator else Unit.AnimationController

    if Animator then
        for _,Animation in pairs(Animator:GetPlayingAnimationTracks()) do
            print(Animation.Name,Animation.Animation.Name)
            if Animation.Name ~= "Idle" then
                Animation:Stop()
            end
        end
    end
end

function UnitVFX.Attack(UnitInfo : UnitInformation)
    local GetModule = RequiredModules[UnitInfo.Ability]

    if not UnitInfo.IsBoss then
        StopAnimsExeptIdle(UnitInfo.Unit)
    end

    GetModule.Attack(UnitInfo.Unit,UnitInfo)
end

function UnitVFX.Explode(Mob)
    local explodeAsset = ReplicatedStorage.Assets.VFX.Explode:Clone()
    local explodeAnimations = ReplicatedStorage.Assets.Animations.MobExplosions:GetChildren()

    StopAnimsExeptIdle(Mob)

    local chosenAnimation = Mob.Humanoid.Animator:LoadAnimation(explodeAnimations[math.random(1,#explodeAnimations)])

    chosenAnimation:Play()

    chosenAnimation:GetMarkerReachedSignal("Explode"):Connect(function()
        for _,attachment in ipairs(explodeAsset:GetChildren()) do
            attachment.Parent = Mob.HumanoidRootPart

            Emit(attachment)

            Debris:AddItem(attachment,2)
        end

        explodeAsset:Destroy()

        Invisible(Mob,1)
    end)
end

function UnitVFX:LoadAnimations()
    for name, Id in Animations do
        local Animation = Instance.new("Animation")
        Animation.AnimationId = Id
        Animations[name] = Animation
    end
end

local function getPlayingAnimation(Unit)
	local Animator : Animator = Unit.Humanoid.Animator
	local isPlaying = {}
	for _, animation in pairs(Animator:GetPlayingAnimationTracks()) do
		table.insert(isPlaying, animation)
	end

	return isPlaying
end

local function IsPlaying(Unit, AnimationName)
	local Animator : Animator = Unit.Humanoid.Animator
	local CurrentlyPlaying = getPlayingAnimation(Unit)

	local result = TableUtil.Find(CurrentlyPlaying, function(Animation)
		return Animation.Name == AnimationName
	end)

	for _, animations in pairs(Animator:GetPlayingAnimationTracks()) do
		if animations.Name == AnimationName then
			result = true	
		end
	end

	return result
end

local function getAnimation(AnimationName : string, State : string)
	local random = {}
	for animName, anim in pairs(Animations) do
		if animName:find(AnimationName) then
			table.insert(random, anim)
		end
	end

	return random[math.random(1,#random)]
end

function UnitVFX.PlayAnimation(Character : Model, AnimationName : string, State : string, Speed : number?, isRandom : boolean?, ...)
	
	-- print("Should be playing animaiton -> ", Character, IsPlaying(Character, AnimationName))

	local Animation = isRandom and getAnimation(AnimationName) or AnimationsFolder:FindFirstChild(AnimationName)
	Speed = Speed or 1
	if Animation then
		if not IsPlaying(Character, AnimationName) or State == "Override" then
			local extra_args = {...}
			
			if State == "Override" then
				UnitVFX.StopAnimation(Character)
			end

			local newAnimation : AnimationTrack = Character.Humanoid.Animator:LoadAnimation(Animation)
			newAnimation:Play()
			newAnimation:AdjustSpeed(Speed)
			
			if extra_args[1] and extra_args[1].EventName then
				newAnimation:GetMarkerReachedSignal(extra_args[1].EventName):Connect(function(value)
					if extra_args[1].EventValue and extra_args[1].EventValue == value then
						print("ANIMATION FUNCTION CALLED")
						extra_args[1].func(value)
					end
				end)
			end
			
			-- if not newAnimation.Looped then
			-- 	newAnimation.Ended:Connect(function()
			-- 		table.remove(CurrentlyPlaying, table.find(CurrentlyPlaying,newAnimation))
			-- 	end)
			-- end
		else
			-- print("It's already playing:", CurrentlyPlaying)
		end 
	else
		warn(`Could not find {AnimationName} in table`, Animations)
	end
end

function UnitVFX.StopAnimation(Character, Specific : string?, All : boolean?)
	local Animator : Animator = Character.Humanoid.Animator
	All = All or false
	
	-- warn("Trying to stop animation in client", Animator:GetPlayingAnimationTracks())
    if Specific and IsPlaying(Character, Specific) then
		local CurrentlyPlaying = getPlayingAnimation(Character)
		local Animation = TableUtil.Find(CurrentlyPlaying,function(Animation)
			return Animation.Name == Specific
		end)

		if Animation then
			-- print("FOUND THE ANIMATION AND REMOVING IT")
			Animation:Stop()
			-- table.remove(CurrentlyPlaying, table.find(CurrentlyPlaying,Animation))

			for _, animations in pairs(Animator:GetPlayingAnimationTracks()) do
				if animations.Name == Specific then
					animations:Stop()
				end
			end
		else
			-- warn(`COULD NOT FIND {Specific} TO DELETE!!`, CurrentlyPlaying)
		end
    elseif not Specific then
		for _, animations : AnimationTrack in pairs(Animator:GetPlayingAnimationTracks()) do
			-- if animations.Name == "Sprint" then continue end
			if not All and animations.Priority ~= Enum.AnimationPriority.Idle then
				animations:Stop()
			elseif All then
				animations:Stop()
			end
		end
	else
        -- warn("No animation is currently playing.")
    end
end

function UnitVFX.OnHit(Mob,UnitHitboxInfo)
    UnitHitboxInfo.HitVFX = UnitHitboxInfo.HitVFX or "" 
    local OnHitVFX = VFX:FindFirstChild(UnitHitboxInfo.HitVFX, true)
    local InsideMob = Mob:FindFirstChild(UnitHitboxInfo.HitVFX, true)

    if UnitHitboxInfo.OnHitSound then
        SoundController:Play(UnitHitboxInfo.OnHitSound, {Parent = Mob})           
    end

    if OnHitVFX and not InsideMob then
        local OnHit = OnHitVFX:Clone()
        OnHit.CFrame = Mob.HumanoidRootPart.CFrame
        OnHit.Parent = Mob
        
        OnHit.WeldConstraint.Part1 = Mob.HumanoidRootPart

		for i, v in pairs(OnHit:GetDescendants()) do
			if v.ClassName == "Beam" or v.ClassName == "ParticleEmitter" or v.ClassName == "PointLight" then
				if v:GetAttribute("Toggle") then
					v.Enabled = true
                elseif v:GetAttribute("ShouldEmit") then
                    v:Emit(v:GetAttribute("EmitCount"))           
				end
			end
		end

        if UnitHitboxInfo.AbilityInfo then
            local Info = UnitHitboxInfo.AbilityInfo
            local Velocity = workspace.CurrentCamera.CFrame.LookVector * - math.random(10,Info.PushPower/2)

            Destruction:PartitionAndVoxelizePart(CFrame.new(Mob.HumanoidRootPart.Position),Info.Size,Velocity)
        end

        task.delay(UnitHitboxInfo.Duration, function()
            ParticleTranparency(OnHit, 1)
            OnHit:Destroy()
        end)
    elseif not OnHitVFX then
        
    end
end

function UnitVFX:RequireModule()
    for _, module in script:GetDescendants() do
        if module:IsA("ModuleScript") then
            local _,err = pcall(function()
                RequiredModules[module.Name] = require(module)   
            end)

            if err then
                warn(err.message)
            end
        end
    end
end

function UnitVFX.BossIntro(CameraModel)
    local connection : RBXScriptConnection
    local Camera = workspace.CurrentCamera
    local cameraTrack : AnimationTrack
    local PlayerGui = Players.LocalPlayer.PlayerGui
    local Main = PlayerGui.Main

    Main.Enabled = false

    for _,Animation in pairs(CameraModel.Humanoid.Animator:GetPlayingAnimationTracks()) do
        cameraTrack = Animation
    end

    cameraTrack:GetMarkerReachedSignal("End"):Connect(function()
        connection:Disconnect()
        Main.Enabled = true
    end)

    connection = RunService.RenderStepped:Connect(function()
        Camera.CFrame = CameraModel.Torso.CFrame
    end)
    
end

local function RemoteFire(Action, ...)
	-- print("Requested action,", Action, ...)
	if Action == "Play" then
		UnitVFX.PlayAnimation(...)
	elseif Action == "Stop" then
		UnitVFX.StopAnimation(...)
	end
end

function UnitVFX:KnitStart()
    local UnitService = Knit.GetService("UnitService")
    local MobService = Knit.GetService("MobService")
    local UIController = Knit.GetController("UIController")
    SoundController = Knit.GetController("SoundController")

    UnitVFX:RequireModule()

    UnitService.OnHit:Connect(UnitVFX.OnHit)
    UnitService.AttackVFX:Connect(UnitVFX.Attack)
    UnitService.ExplodeVFX:Connect(UnitVFX.Explode)
    UnitService.PlayAnimation:Connect(RemoteFire)
    UnitService.StopAnimation:Connect(UnitVFX.StopAnimation)
    UnitService.BossTransition:Connect(UIController.Transition)
    UnitService.MovieMode:Connect(UIController.MovieMode)
    UnitService.BossWarning:Connect(UIController.BossWarning)
    
    MobService.BossIntro:Connect(UnitVFX.BossIntro)
end

return UnitVFX 
