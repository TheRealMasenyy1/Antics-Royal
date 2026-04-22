local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Voxbreaker = require(ReplicatedStorage.Shared.Utility.VoxBreaker)

local Assets = ReplicatedStorage.Assets
local AnimationsFolder = Assets.Animations
local SoundController;

local EntityController = Knit.CreateController {
    Name = "EntityController"
}

local Animations = {
    WalkAnimation = "rbxassetid://107193539929267"
}

function EntityController:LoadAnimations()
    for name, Id in Animations do
        local Animation = Instance.new("Animation")
        Animation.AnimationId = Id
        Animations[name] = Animation
    end
end

local function IsPlaying(AnimationName)
	local Animator : Animator = Humanoid.Animator
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

function EntityController.PlayAnimation(Character : Model, AnimationName : string, State : string, Speed : number?, isRandom : boolean?, ...)
	
	print("Should be playing animaiton -> ", Character)

	local Animation = isRandom and getAnimation(AnimationName) or AnimationsFolder:FindFirstChild(AnimationName)
	Speed = Speed or 1
	if Animation then
		if not IsPlaying(AnimationName) or State == "Override" then
			local extra_args = {...}
			
			if State == "Override" then
				AnimationController.StopAnimation()
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
			
			table.insert(CurrentlyPlaying, newAnimation)
			
			if not newAnimation.Looped then
				newAnimation.Ended:Connect(function()
					table.remove(CurrentlyPlaying, table.find(CurrentlyPlaying,newAnimation))
				end)
			end
		else
			-- print("It's already playing:", CurrentlyPlaying)
		end 
	else
		warn(`Could not find {AnimationName} in table`, Animations)
	end

end

function QuadraticBezier(t, p0, p1, p2)
    local u = 1 - t
    local tt = t * t
    local uu = u * u

    local p = uu * p0 -- (1-t)^2 * P0
    p = p + 2 * u * t * p1 -- 2(1-t)t * P1
    p = p + tt * p2 -- t^2 * P2

    return p
end

local DEBUG = false

function EntityController.SphereKnockback(Mob,Distance)
    local FallDirections = {
        Mob:GetPivot().Position + Vector3.new(0,0,Distance), 
        Mob:GetPivot().Position - Vector3.new(0,0,Distance),
        Mob:GetPivot().Position + Vector3.new(Distance,0,0), 
        Mob:GetPivot().Position - Vector3.new(Distance,0,0),
    }
    local p0 = Mob:GetPivot().Position
    local p1 = p0 + Vector3.new(0,math.random(5,15),0);
    local p2 = FallDirections[math.random(1,#FallDirections)] --Mob:GetPivot().LookVector * math.random(1,5);
    local HeartBeat;

    -- local TestPart = Instance.new("Part")
    -- TestPart.CFrame = Mob:GetPivot()
    -- TestPart.Anchored = true
    -- TestPart.Size = Vector3.new(2,2,2)
    -- TestPart.Parent = workspace.Debris

    -- task.delay(2,game.Destroy,TestPart)

    for t = 0, 1, .01 do
        -- Mob.PrimaryPart.CFrame = CFrame.new(QuadraticBezier(t, p0, p1, p2))
        Mob:PivotTo(CFrame.new(QuadraticBezier(t, p0, p1, p2)))

        -- TestPart.CFrame = CFrame.new(QuadraticBezier(t, p0, p1, p2)) 
        task.wait()
    end
end

function Emit(Part)
	for i, v in pairs(Part:GetChildren()) do
		if v.ClassName == "ParticleEmitter"  then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function EntityController.KnockbackEffects(CFrame)
    -- local RandomNr = math.random(1,100)
    local GroundSlam = Assets.VFX.GroundSlam
    local GroundSmoke = Assets.VFX.GroundSmoke

    local newGroundSmoke = GroundSmoke:Clone()
    newGroundSmoke.CFrame = CFrame
    newGroundSmoke.Parent = workspace.Debris

    newGroundSmoke.Attachment.Smoke:Emit(25)
    -- newGroundSmoke.Attachment.Smoke.Enabled = true

    -- if RandomNr >= 60 then
    --     local newGroundSlam = GroundSlam:Clone()
    --     newGroundSlam.CFrame = CFrame
    --     newGroundSlam.Parent = workspace.Debris

    --     Emit(newGroundSlam.Attachment)
    --     task.delay(5,game.Destroy,newGroundSlam)
    -- end

    task.delay(5,game.Destroy,newGroundSmoke)
end

function EntityController.Knockback(Npc,Distance : number)
    local HumanoidRootPart = Npc.HumanoidRootPart
    local Animator : Animator = Npc.Humanoid.Animator
    local DistanceDown = 3.5
    local DetectionRadius = 10
    local Ray_results;
    local LifeTime : number = 5

    if not workspace:FindFirstChild("Map") then return end

    for _,animation in Animator:GetPlayingAnimationTracks() do
        animation:Stop()
    end 

    local function destroy(object, duration)
        task.spawn(function()
            task.wait(duration)
            object:Destroy()
        end)	
    end
    --- Cast a raycast that check how close he's to the ground if close then break
    task.delay(.5,function()
        -- Ray_results = Shortcut.RayCast(HumanoidRootPart.Position, HumanoidRootPart.Position - Vector3.new(0,DistanceDown,0))
        -- while not Ray_results do
        --     Ray_results = Shortcut.RayCast(HumanoidRootPart.Position, HumanoidRootPart.Position - Vector3.new(0,DistanceDown,0))
        --     LifeTime -= RunService.Heartbeat:Wait()

        --     if LifeTime <= 0 then
        --         break;
        --     end
        -- end
        local Destruction = workspace.Values:FindFirstChild("Destruction")
        local Velocity

        if Distance > 10 and Destruction then
            if Destruction.Value > 1 then
                Velocity = workspace.CurrentCamera.CFrame.LookVector * - math.random(10,Distance/2)
                
                SoundController:Play("CollapsingBuilding", {Parent = Npc})
                task.spawn(EntityController.KnockbackEffects,CFrame.new(HumanoidRootPart.Position))

                task.spawn(function()
                    local parts = Voxbreaker:CreateHitbox(Vector3.new(3,3,3),CFrame.new(HumanoidRootPart.Position),nil,2,10)
                    local MaxParts = 10
                    local Count = 0
    
                    for i, v in ipairs(parts) do
                        Count += 1
    
                        if Count <= MaxParts then
                            v.Anchored = false
                            v.CastShadow = false

                            local bv = Instance.new("BodyVelocity", v)
                            bv.Velocity = Velocity * Vector3.new(math.random(.9,1.5),math.random(-.5,1.5),math.random(.9,1.5))
                            bv.MaxForce = Vector3.new(99999,99999,99999)
                            bv.Name = "Velocity"
                            bv.Parent = v
                            destroy(bv, .2)
                        else
                            v:Destroy()
                        end
                    end
                end)
            end
        end
    end)
end

function EntityController.KeepTrackOfHealth(Mob : Model)
    local maid = Maid.new()
    local MobStatusUI = Assets.MobStatusUI:Clone()
	-- local Humanoid = Mob.Humanoid
    local health = Mob:GetAttribute("Health")
    local MaxHealth = Mob:GetAttribute("MaxHealth")
    local Shield = Mob:GetAttribute("Shield")
    local DamagePart = ReplicatedStorage.Assets.DamagePart

    MobStatusUI.Parent = Mob:WaitForChild("Head")

    MobStatusUI.Frame.MobName.Text = Mob.Name
    MobStatusUI.Frame.Health.Amount.Text = health .."/".. health

    if Shield then
        MobStatusUI.Frame.Shield.Visible = true
        MobStatusUI.Frame.Shield.Amount.Text = Shield .."/".. Shield
    end

    if Mob:GetAttribute("IsBoss") then
        MobStatusUI.Frame.Health.bar.BackgroundColor3 = Color3.fromRGB(128, 29, 209)
    end

    local function IndicateDamage(Damage,wasAcrtical, isShield)
        local newDamagePart : Part = DamagePart:Clone()
        local DamageIndicator = newDamagePart:FindFirstChild("DamageIndicator")

        if DamageIndicator then
            local newFrame = DamageIndicator.Frame
            newFrame.Parent = DamageIndicator

            if isShield then
                newFrame.Value1.TextColor3 = Color3.fromRGB(40, 255, 244)
                newFrame.Value2.TextColor3 = Color3.fromRGB(30, 184, 176)
            end

            if not wasAcrtical then
                newFrame.Value1.Text = string.format("%.1f",Damage)
                newFrame.Value2.Text = string.format("%.1f",Damage)
            else
                newFrame.Value1.Text = "Crit. " .. string.format("%.1f",Damage)
                newFrame.Value2.Text = "Crit. " .. string.format("%.1f",Damage)

                if not Shield then
                    newFrame.Value1.TextColor3 = Color3.fromRGB(255, 87, 36)
                    newFrame.Value2.TextColor3 = Color3.fromRGB(255, 87, 36)
                else
                    newFrame.Value1.TextColor3 = Color3.fromRGB(40, 126, 255)
                    newFrame.Value2.TextColor3 = Color3.fromRGB(30, 45, 184)
                end
            end

            newFrame.Parent = DamageIndicator
            newDamagePart.CFrame = Mob.HumanoidRootPart.CFrame
            newDamagePart.Velocity = Vector3.new(math.random(-10,25),math.random(10,35),math.random(-10,25))
            newDamagePart.Parent = workspace.Debris

            task.delay(1, game.Destroy, newDamagePart)
        end
    end
    
    local function format(num)
        local formatted = string.format("%.2f", math.floor(num*100)/100)
        if string.find(formatted, ".00") then
            return string.sub(formatted, 1, -4)
        end
        return formatted
    end

    local Count = 0

    maid:GiveTask(Mob.AttributeChanged:Connect(function(AttributeName)
        local newHealth = Mob:GetAttribute("Health")
        local Maxhealth = Mob:GetAttribute("MaxHealth")
        local newShield = Mob:GetAttribute("Shield")
        local CriticalHit = Mob:GetAttribute("CriticalHit")
        local Regen = Mob:GetAttribute("Regen")

        if AttributeName == "Shield" and Shield > newShield then
            local ShieldDamage = Shield - newShield
            MobStatusUI.Frame.Shield.Amount.Text = newShield .."/".. Shield
            IndicateDamage(ShieldDamage, CriticalHit, true)

            TweenService:Create(MobStatusUI.Frame.Shield.bar,TweenInfo.new(.5),{Size = UDim2.new((newShield / Shield) - 0.03, 0 , 0.75,0)}):Play()

            if newShield <= 0 then
                MobStatusUI.Frame.Shield.Visible = false
            end

            Shield = newShield
        end

        local isHealth = if AttributeName == "Health" then true else false
        
        if AttributeName == "Health" and (health > newHealth) or Regen then
            --print("HEALTH BAR CHANGED")
            local Damage = health - newHealth
            local showDamageIndicator = if health > newHealth then true else false

            Count += 1
            health = newHealth
            MobStatusUI.Frame.Health.Amount.Text = format(health) .."/".. Maxhealth

            if showDamageIndicator then
                IndicateDamage(Damage,CriticalHit)
            end
            
            TweenService:Create(MobStatusUI.Frame.Health.bar,TweenInfo.new(.5),{Size = UDim2.new((health / Maxhealth) - 0.03, 0 , 0.75,0)}):Play()
            
            if health <= 0 then
                MobStatusUI:Destroy()
            end
        end
    end))
end

function EntityController:KnitStart()
    local MobService = Knit.GetService("MobService")
    SoundController = Knit.GetController("SoundController")
    EntityController:LoadAnimations()
    
    MobService.Knockback:Connect(EntityController.Knockback)
    MobService.TrackHealth:Connect(EntityController.KeepTrackOfHealth)
end

return EntityController
