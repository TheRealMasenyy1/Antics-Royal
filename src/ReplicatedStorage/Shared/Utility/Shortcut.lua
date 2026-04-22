local Shortcut = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--local Ragdoll = require(Shared.Managers.Ragdoll)

function Shortcut:GetMousePos(MouseHit,MouseOrigin,MouseTarget,MaxDistance,DestroyOnClick)
	--local Distance = (player.Character.HumanoidRootPart.Position - MouseHit.Position)
	local player = Players.LocalPlayer
	local part
	part = Instance.new("Part",workspace)
	part.Size = Vector3.new(1,1,1)
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.Name = "Marker"
	
	if MouseHit ~= nil then
		part.CFrame = MouseHit --+ Vector3.new(0,2,0)
	else
		part.CFrame = MouseOrigin
	end
	
	local Position = part.Position
	
	if (DestroyOnClick == nil or DestroyOnClick == true) then
		part:Destroy()
	end
	
	if MouseTarget ~= nil and MouseTarget.Name == "Zone" then
		part:Destroy()
		Position = MouseTarget.Position
		part = MouseTarget
	end
	
	return Position,part
end

function Shortcut:Debug(...)
	if RunService:IsStudio() then
		--print(...)
	end
end

function Shortcut:SuperDebug(...)
	if RunService:IsStudio() then
		warn(...)
	end
end

function Shortcut:Getlength(table)
	local amount = 0;
	
	for name,info in pairs(table) do
		amount += 1;
	end

	return amount;
end

function Shortcut:SetRagdoll(Character : Instance ,bool : BoolValue)
	local Humanoid = Character:FindFirstChild("Humanoid")

	if Humanoid and Humanoid.Health > 0 then
		Ragdoll.Ragdoll(Character,bool)
	end
end

function Shortcut:CustomRayCast(player,Pos,Size)
	local HumanoidRootPart;

	if game.Players:GetPlayerFromCharacter(player) then
		HumanoidRootPart = player.Character.HumanoidRootPart
	else
		HumanoidRootPart = player.HumanoidRootPart
	end

	local distance = (HumanoidRootPart.Position - Pos).Magnitude
	local p = Instance.new("Part",workspace.Debris)
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(Size, Size, distance+4)
	p.CFrame = CFrame.lookAt(player.Character.HumanoidRootPart.Position, Pos)*CFrame.new(0, 0, -distance/2)
	p.Name = player.Name.."- Attack"
	p.Transparency = 1
	
	return p
end

function Shortcut:Wait(t)
    t = typeof(t) == 'number' and t or 0

    local spent = 0
    repeat
        spent += RunService.Heartbeat:Wait()
    until spent >= t
end

local SoundId = {
	MouseClick = {Id = "rbxassetid://107451678463142", Volume = .75, Group = "SFX"},
	MouseHover = {Id = "rbxassetid://134427329241184", Volume = .75, Group = "SFX"},
	UIOpen = {Id = "rbxassetid://75154890323331", Volume = .75, Group = "SFX"},
	UIClose = {Id = "rbxassetid://109350327091792", Volume = .75, Group = "SFX"},
	Claim = {Id = "rbxassetid://89058042085874", Volume = 1, Group = "SFX"},
	Notify = {Id = "rbxassetid://76976643860805", Volume = 1, Group = "SFX"},

	Upgrade = {Id = "rbxassetid://16248110514", Volume = 10, Group = "SFX"},
	Place = {Id = "rbxassetid://16249543432", Volume = .5, Group = "SFX"}, 
	Died = {Id = "rbxassetid://9044728299", Volume = .5, Group = "SFX"},
	BossMusic = {Id = "rbxassetid://9042781325", Volume = .5, Group = "Music"},
	Lost = {Id = "rbxassetid://16286891068", Volume = 1.5, Group = "Music"},
	Tookdamage = {Id = "rbxassetid://1289666030", Volume = 1.5, Group = "Music"},
	Win = {Id = "rbxassetid://4612377122", Volume = 1.5, Group = "Music"}, 
	Buzz = {Id = "rbxassetid://16304659177", Volume = .75, Group = "SFX"},
}

function Shortcut:PlaySound(SoundName : string,shouldPlay : boolean?)
	local Sound = workspace:FindFirstChild(SoundName)
	shouldPlay = shouldPlay or true
	
	if not Sound then
		Sound = Instance.new("Sound")
		Sound.SoundId = SoundId[SoundName].Id
		Sound.Name = SoundName
		Sound.Parent = workspace		
	end
	
	if shouldPlay then
		Sound:Play()
		---warn("PLAYING --->  ", SoundName, Sound.Volume)
	end
	
	return Sound
end

function Shortcut.RayCast(Origin,Diraction,Params)
	
	if Params == nil then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = {workspace.Map.Buildings}
		raycastParams.IgnoreWater = true
		
		Params = raycastParams
	end
	
	local raycastResult = workspace:Raycast(Origin,Diraction,Params)
		
	return raycastResult
end

function Shortcut.Lightning(player,from,too,Damage,Off,Steps,SizeX,pSizeY,WaitTime)		
	local off = Off
	local Step = tonumber(Steps)

	local Touched = {}
	local Distance = (from-too).Magnitude
	
	lastPos = from
	
	if WaitTime == nil then
		WaitTime = 1
	end
--	--print(WaitTime)
	for i=0,Distance,Step do
		
		local from = lastPos
		
		local offset = Vector3.new(
				math.random(-off,off),
				math.random(-off,off),
				math.random(-off,off)			
				)/10			
		
		
		local too = from +- (from-too).unit*Step + offset
		local New_Distance = (from-too).Magnitude
		
		local p =  script.bolt:Clone()
		p.Parent = workspace:WaitForChild("Lightning_Debris-"..player.Name)
		p.Size = Vector3.new(SizeX,pSizeY,New_Distance)
		p.CFrame = CFrame.new(from:Lerp(too,0.5), too)
		
		p.Touched:Connect(function(hit)
			local Humanoid = hit.Parent:FindFirstChild("Humanoid")
			
			if Humanoid and hit.Parent.Name ~= player.Name and not Touched[hit.Parent.Name] then
				Touched[hit.Parent.Name] = true
				Humanoid:TakeDamage(Damage)
				----print("Touched him: "..Humanoid.Health)
			end
		end)
		
		game.Debris:AddItem(p,WaitTime)
		
		lastPos = too
	end

end

function Shortcut:Hair(Character,Object)
	for i,GetObject in pairs(Character:GetChildren()) do
		if GetObject:IsA("Model") and GetObject.Name:find("Hair") then
			GetObject:Destroy()
		end
	end				
			
	local Hair = Object:Clone()
	Hair.Parent = Character
	Hair:SetPrimaryPartCFrame(Character.Head.CFrame * CFrame.new(0,0,0))
			
	local Weld = Instance.new("WeldConstraint",Character.Head)
	Weld.Part0 = Character.Head
	Weld.Part1 = Hair.PrimaryPart
end

---function 

function Shortcut.SmoothLookAt(player,Target)
	local Character : Instance;

	if game.Players:FindFirstChild(player.Name) then
		Character = player.Character
	else
		Character = player 
	end

	local Prop = {
		CFrame = CFrame.new(Character.HumanoidRootPart.Position,Vector3.new(Target.HumanoidRootPart.Position.X,Character.HumanoidRootPart.Position.Y,Target.HumanoidRootPart.Position.Z))
	}

	local TweenInfomation = TweenInfo.new(.3,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,.1)
	local Tween = TweenService:Create(player.HumanoidRootPart,TweenInfomation,Prop)

	Tween:Play()
	return Tween
end


function Shortcut.LookAt(player,Target)
	local Character : Instance;

	if game.Players:FindFirstChild(player.Name) then
		Character = player.Character
	else
		Character = player 
	end
	
	player.HumanoidRootPart.CFrame = CFrame.new(Character.HumanoidRootPart.Position,Vector3.new(Target.HumanoidRootPart.Position.X,Character.HumanoidRootPart.Position.Y,Target.HumanoidRootPart.Position.Z))
	
	return true
end


function Shortcut.AttackAim(player,Target)
	local Character : Instance;

	if game.Players:FindFirstChild(player.Name) then
		Character = player.Character
	else
		Character = player
	end

	return CFrame.new(Character.HumanoidRootPart.Position,Target)
end

-- for Name,Info in pairs(SoundId) do
-- 	local Sound = workspace:FindFirstChild(Name)

-- 	if not Sound then
-- 		Sound = Instance.new("Sound")
-- 		Sound.SoundId = Info.Id
-- 		Sound.Name = Name
-- 		Sound.Volume = Info.Volume
-- 		--Sound.SoundGroup = game.SoundService[Info.Group]
-- 		Sound.Parent = workspace		
-- 	end
-- end

return Shortcut