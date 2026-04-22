local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local UnitCreator = require(ReplicatedStorage.Shared.Utility.UnitCreator)
local Knit = require(ReplicatedStorage.Packages.Knit)
local UIManager = require(ReplicatedStorage.Shared.UIManager)

local MatchController = Knit.CreateController {
    Name = "MatchController",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local Cash = leaderstats:WaitForChild("Cash")

local UltimateFolder = playerGui:WaitForChild("UltimateFolder")
local UnitInfoFolder = playerGui:WaitForChild("UnitInfoFolder")
local Core = playerGui:WaitForChild("Main")
local Content = Core:WaitForChild("Content")
local Toolbar = Content:WaitForChild("Toolbar")
local MoneyFrame = Toolbar:WaitForChild("MoneyFrame")
local WaveInfoHolder = Core:WaitForChild("WaveInfoHolder")
local SkipWave = WaveInfoHolder:WaitForChild("SkipWave")
local WaveCounter = WaveInfoHolder:WaitForChild("WaveCounter")
local Time_lb = WaveInfoHolder:WaitForChild("TimeUI")
local StartGame_Btn : TextButton = Content:WaitForChild("StartGame")
local UnitFrame_template = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UnitFrame")

local ValuesFolder = workspace.Values
local MatchService
local UIController
local ProfileService
local Health : IntValue;
local ShowingPath = true
local maid
local skipmaid
local startmaid
local SoundController; 

local UnitFrame_Table = {}

function MatchController:toHMS(s)
	return string.format("%02i:%02i", s/60%60, s%60)
end

function MatchController.StartTimer(Deadline : number)
    local TimeIsActive = ValuesFolder:WaitForChild("TimeIsActive")
    local dt = Deadline

    while dt > 0 and TimeIsActive.Value do
        dt -= RunService.Heartbeat:Wait()
        Time_lb.Text = MatchController:toHMS(dt)   
    end
end

function MatchController.WaveEnd()
local SU = playerGui.BannerNotification
    local Canvas = SU.WaveEnd
    local Frame = Canvas.Frame

    local Grow = TweenService:Create(Frame,TweenInfo.new(.5,Enum.EasingStyle.Cubic),{Size = UDim2.fromScale(1,1)})
    local Shrink = TweenService:Create(Frame,TweenInfo.new(.25,Enum.EasingStyle.Cubic, Enum.EasingDirection.In,0,false,1.5),{Size = UDim2.fromScale(0.407,Frame.Size.Y.Scale)})

    Canvas.GroupTransparency = .2

    Grow:Play()

    Grow.Completed:Wait()

    Shrink:Play()

    Shrink.Completed:Wait()

    Canvas.GroupTransparency = 1
    

end

function MatchController:CleanUIs()
    UltimateFolder:ClearAllChildren()
    UnitInfoFolder:ClearAllChildren()
end

function MatchController.UpdateWave(Wave : number,MaxWave : number)
    MaxWave = MaxWave or 30
    local Wave_lb = WaveCounter:WaitForChild("Wave")

    Wave_lb.Text = "Wave: " .. Wave .. "/" .. MaxWave -- MaxWave 
end

type Matchresult = {
    Result : string,
    MatchInfo : {},
    Time : number,
}

function MatchController.CreateUnitExp(expGained) -- Creates unit exp frames
    local Units = ProfileService:Get("Equipped"):expect()
    local EndFrame = Core.EndFrame
    local LeftFrame = EndFrame.LeftFrame
    
    for _,UnitTable in pairs( Units ) do
        local Frame = LeftFrame.Temp.Image:Clone()  --UnitCreator.CreateUnitIcon(UnitTable.Unit, UnitTable)
        local UnitUI : TextButton, UnitViewport = UnitCreator.CreateUnitIcon(UnitTable.Unit, UnitTable)
       -- local UnitFrame = UnitFrame_template:Clone()
        local BlackBar = Frame.ItemBox.BlackBar
        local PurpleBar = BlackBar.PurpleBar
        local CurrentExp = if UnitTable.Exp == 0 then 1 else UnitTable.Exp
        --local expGainedFrame = Frame --UnitFrame.ExpGained

        local oldChange = if (CurrentExp - expGained) < 0 then 1 else (CurrentExp - expGained)

        local oldPercent = oldChange / UnitTable.MaxExp
        local Percent = CurrentExp / UnitTable.MaxExp

        PurpleBar.Size = UDim2.new(oldPercent,0,1,0)

        task.delay(1,function()
            TweenService:Create(PurpleBar,TweenInfo.new(.55),{Size = UDim2.new(Percent,0,1,0)}):Play()
        end)


        --Frame.Size = UDim2.new(1,0,1,0)
       -- UnitFrame.Parent = LeftFrame
        Frame.Parent = LeftFrame.ScrollingFrame
        Frame.Visible = true
       -- expGainedFrame.Parent

        Frame.ItemBox.Lvl.Text = "Lvl."..tostring(UnitTable.Level) --Frame.LevelLabel.Text = tostring(UnitTable.Level).."/100"
        Frame.NameLabel.Text = tostring(UnitTable.Unit)-- .UnitName.Position = UDim2.new(-0.254, 0,0.381, 0)
        Frame.ItemBox.ExpGained.Text = "+".. expGained
        Frame.ItemBox.Text.Text = CurrentExp.."/"..tostring(UnitTable.MaxExp)

        UnitUI.Parent = Frame.ItemBox
        UnitUI.Level:Destroy()
        UnitUI.UnitName:Destroy()
        UnitUI.Coin:Destroy()
        --UnitUI.Name:Destroy()
        UnitUI.Size = UDim2.new(1,0,1,0)
        UnitUI.Visible = true
        UnitUI.Interactable = false
        UnitUI.ZIndex = -1

       -- expGainedFrame.Text = "+"..tostring(expGained)

        table.insert(UnitFrame_Table, Frame)
    end
end

function MatchController.IndicatePath()
    local ArrowIndicator = ReplicatedStorage.Assets.Arrow
    local Path = workspace.Gameplay.Path

    local arrowTable = {}

    local function Move(TheTarget,Ball,step : number, Speed : number, angle)
        local pos = if typeof(TheTarget) == "Vector3" then TheTarget else TheTarget.Position
        local Distance = (Ball.Position - pos).Magnitude
        -- local Direction = (Ball.Position - TheTarget.Position).Unit
        local Direction = (pos - Ball.Position).Unit
    
        -- Ball.CFrame = CFrame.lookAt(Ball.CFrame.Position, TheTarget.Position)
        Ball:PivotTo((CFrame.new(Ball.Position,pos) ) + Direction * Speed)  --.CFrame = --CFrame.Angles(0,0,math.rad(90))  --(Ball.CFrame * angle) + Direction * Speed 
    
        return Distance
    end

    local function ray(Part)
        local raycastParams  = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {Part, workspace.Gameplay.Path, workspace.GameAssets}
        raycastParams.IgnoreWater = true

        local RayVector = Vector3.new(0, -50, 0)
    
        local raycastResult = workspace:Raycast(Part.Position,RayVector,raycastParams)
    
        if raycastResult then
            if raycastResult.Position.Magnitude > 0 then
                return raycastResult.Position,raycastResult.Normal,raycastResult.Instance
            else
                return Part.Position
            end
        end
    end

    local function getAngle(Part,NormalVector : Vector3) : Vector3 -- Gets the angle of the floor 
		-- if not Entity:GetAttribute("RotateRot") or Entity:GetAttribute("Ignore") == MatchFolder.Parent:GetAttribute("FloorName") then return 0 end
        if not NormalVector then return 0 end
		local Angle = math.deg(math.acos(NormalVector:Dot(Vector3.yAxis)))
		
		if NormalVector:Dot(Part:GetPivot().Position) < 0 then
			Angle = -math.deg(math.acos(NormalVector:Dot(Vector3.yAxis)))
		end
				
		return Angle
	end

    local function tweenArrow(arrow)
        for i = 1,#Path:GetChildren() do
            local MoveConnection : RBXScriptConnection;
            local DistanceToTarget : number;
            local finished = false
            local nextPath = if Path:FindFirstChild(i+1) ~= nil then Path[i+1] else false

            if not nextPath then
                nextPath = Vector3.new(workspace.Gameplay.End.Position.X,arrow.Position.Y,workspace.Gameplay.End.Position.Z)
            else
                arrow.CFrame = Path[i].CFrame
            end
            
            MoveConnection = RunService.Stepped:Connect(function(time,step)
                --local Position,RayNormal = ray(arrow)
                --local Normal =  getAngle(RayNormal)

                if not ShowingPath then
                    MoveConnection:Disconnect()
                    finished = true
                    arrow:Destroy()
                end
    
                --local angle = CFrame.Angles(math.rad(Normal),0,math.rad(90)) -- needs some tweaks

                DistanceToTarget = Move(nextPath,arrow,step,.35)
        
                if DistanceToTarget <= 1 and (not finished or i == #Path:GetChildren()) then
                    MoveConnection:Disconnect()
                    finished = true

                    if i == #Path:GetChildren() then
                        arrow:Destroy()
                    end
                end
            end)

            if i == #Path:GetChildren() then finished = true end

            repeat task.wait() until finished
            
        end
    end

    while ShowingPath do
        local arrow = ArrowIndicator:Clone()
        arrow.Parent = workspace.Debris

        table.insert(arrowTable,arrow)

        task.spawn(function()
            tweenArrow(arrow)
        end)

        task.wait(2)
    end


    for _,arrow in pairs(arrowTable) do
        arrow:Destroy()
    end
end

function MatchController.MatchEnd(MatchInfo : Matchresult)
    local EndFrame = Core:WaitForChild("EndFrame")
    local Restart_btn = EndFrame:WaitForChild("Restart")
    local Lobby_btn = EndFrame:WaitForChild("Lobby")
    local Next_btn = EndFrame:WaitForChild("Next")
    local Playtime = EndFrame:WaitForChild("Playtime")
    local TotalDamage_lb = EndFrame:WaitForChild("TotalDamage")
    local RewardContent = EndFrame:WaitForChild("Rewards"):WaitForChild("Content")
    local ExpEarned = EndFrame.ExpEarned
    --local RewardTemplate = RewardContent:WaitForChild("Temp"):WaitForChild("Image")
    -- local TotalDamage = player.leaderstats:FindFirstChild("TotalDamage")
    local TotalDamage = player.leaderstats.Damage
    local Votes = ValuesFolder[MatchInfo.VoteName].Votes
    local RequiredVotes = ValuesFolder[MatchInfo.VoteName].RequiredVotes
    local Matchresult = MatchInfo.Matchresult
    local Rewards = MatchInfo.Rewards
    local Restart_txt = function() -- Used to update text
        Restart_btn.Text.Text = "Try Again(".. Votes.Value.."/".. RequiredVotes.Value .. ")" 
    end

    local Reward_Icons = {}
    local unitExpGained = 0
    local ExpEarned_Amount = 0

    if Rewards[player.Name] then
        
        if Rewards[player.Name].UnitExp then
            unitExpGained = Rewards[player.Name].UnitExp
            Rewards[player.Name].UnitExp = nil
        end

        if Rewards[player.Name].Exp then
            ExpEarned_Amount = Rewards[player.Name].Exp
            Rewards[player.Name].Exp = nil
        end

        for reward,amount in pairs(Rewards[player.Name]) do
            if amount == 0 then continue end
            if typeof(reward) == "table" then continue end
            if not UnitCreator.DoesThisItemExistCurrently(reward) then continue end
            local recievedAmount = amount

            local newItem = UnitCreator.CreateItemIconForChallenge(reward,{Amount =  amount}) --Item:Clone()
            newItem.Size = UDim2.new(0.173, 0,0.658, 0)
            newItem.UnitName.Visible = false -- Gock du måste också göra UnitName till Visible = false annars ser man %
            newItem.Parent = RewardContent
            newItem.Visible = true

            table.insert(Reward_Icons,newItem)
        end

        for itemName, itemAmount in Rewards[player.Name].Items do
            if itemName == "Nothing" then continue end
            local RewardIcon = UnitCreator.CreateItemIconForChallenge(itemName,{Amount = itemAmount}); if not RewardIcon then continue end
            
            RewardIcon.Parent = RewardContent
            RewardIcon.Visible = true
            RewardIcon.Size = UDim2.new(0.173, 0,0.658, 0)

            RewardIcon.UnitName.Size = UDim2.new(1.3, 0,0.3, 0)
            RewardIcon.UnitName.Position = UDim2.new(0.5, 0,-0.085, 0)

            table.insert(Reward_Icons,RewardIcon)
        end
    end

    Restart_txt()

    MatchController.CreateUnitExp(unitExpGained)

    Content.Visible = false
    WaveInfoHolder.Visible = false
    EndFrame.Visible = true
    Health = nil
    

    --EndFrame.Titles[Matchresult.Result].Visible = true

    TotalDamage_lb.amount.Text = TotalDamage.Value
    Playtime.amount.Text = Matchresult.Time
    ExpEarned.amount.Text = ExpEarned_Amount

    MatchController:CleanUIs()

    Votes.Changed:Connect(Restart_txt)
    RequiredVotes.Changed:Connect(Restart_txt)

    Next_btn.Visible = false
    
    local titleText = "Failure!"

    if Matchresult.Result == "Win" then
        if MatchInfo.Matchresult.MapInfo.Challenges == 0 and MatchInfo.Matchresult.MapInfo.Chapter ~= 6 and MatchInfo.Matchresult.MapInfo.Chapter ~= 5 then
            Next_btn.Visible = true
        end
        titleText = "Victory!"        
        --Next_btn.NextMap.Text = "Next(".. Votes.Value.."/".. RequiredVotes.Value .. ")"        
    end

    for _,label in pairs(EndFrame.Titles:GetChildren()) do
        label.Text = titleText
    end

    maid:GiveTask(Next_btn.Text.Activated:Connect(function()
        -- Destroys the reward icons
        for _,frame in ipairs(Reward_Icons) do
            frame:Destroy()
        end
        -- Destroys the unit icons
        for _,frame in pairs(UnitFrame_Table) do
            frame:Destroy()
        end

        maid:Destroy()

       -- EndFrame.Titles[Matchresult.Result].Visible = false

        MatchService.NextChapter:Fire()
    end))
    
    maid:GiveTask(Restart_btn.Text.Activated:Connect(function()
        -- Destroys the reward icons
        for _,frame in ipairs(Reward_Icons) do
            frame:Destroy()
        end
        -- Destroys the unit icons
        for _,frame in pairs(UnitFrame_Table) do
            frame:Destroy()
        end

        maid:Destroy()

        --EndFrame.Titles[Matchresult.Result].Visible = false

        MatchService.Vote:Fire()
    end))

    maid:GiveTask(Lobby_btn.Text.Activated:Connect(function()

        maid:Destroy()

        --EndFrame.Titles[Matchresult.Result].Visible = false

        MatchService:SendToLobby()
    end))

    TweenService:Create(EndFrame,TweenInfo.new(.5),{Position = UDim2.new(.5,0,.5,0)}):Play()
end

function GetTextLabelInButton(Btn : TextButton, _callback)
    for _, button in pairs(Btn:GetDescendants()) do
        if button:IsA("TextLabel") then
            return 
        end
    end
end

function MatchController.RemoveSkip(VoteInfo)
    SkipWave.Visible = false
	if skipmaid then
		skipmaid:DoCleaning()
	end
end

function toS(s)
	return string.format("%02i", s%60)
end

function MatchController.SkipWave(VoteInfo)
    local Count = SkipWave:WaitForChild("Count")
    local Votes = ValuesFolder[VoteInfo.VoteName].Votes
    local RequiredVotes = ValuesFolder[VoteInfo.VoteName].RequiredVotes
    local AutoSkip = ValuesFolder:FindFirstChild("AutoSkip: ".. player.Name)
    skipmaid = Maid.new()

    SkipWave.Visible = true

    local UpdateCount = function() -- Used to update text
        Count.Text = "Skip Wave(".. Votes.Value.."/".. RequiredVotes.Value .. ")" 
    end

    task.spawn(function()
        local StartTime = VoteInfo.TimetoVote
        local TimeLabel = SkipWave.Time:FindFirstChild("TimeLabel", true)
        local Countdown

        skipmaid:GiveTask(RunService.Heartbeat:Connect(function(dt)
            StartTime -= RunService.Heartbeat:Wait()
            if TimeLabel then
                TimeLabel.Text = toS(StartTime) .. "s"
            end
        end))
    end)

    UpdateCount() 

    Votes.Changed:Connect(UpdateCount)

    if AutoSkip then
        MatchService.Vote:Fire()
    end

    skipmaid:GiveTask(SkipWave.Activated:Connect(function()
        MatchService.Vote:Fire()
    end))
end

function MatchController.MatchStart()
    local EndFrame = Core:WaitForChild("EndFrame")
    local Health = ValuesFolder:WaitForChild("Health")
    local MaxHealth = Health:GetAttribute("MaxHealth")
    local HealthUI = Toolbar:WaitForChild("Health").Text
    local CurrentCash = Cash.Value
    
    maid = Maid.new()
    
    EndFrame.Visible = false
    Content.Visible = true
    WaveInfoHolder.Visible = true
    StartGame_Btn.Visible = false

    ShowingPath = false

    HealthUI.Text = Health.Value .."/" .. Health:GetAttribute("MaxHealth")
    
    maid:GiveTask(Cash.Changed:Connect(function()
        if Cash.Value > CurrentCash then
            local newCash = Cash.Value - CurrentCash
            -- SoundController:Play("Gold")
            MatchController.UpdateCash(newCash)
        end
        CurrentCash = Cash.Value
    end))
    maid:GiveTask(Health.Changed:Connect(MatchController.UpdateHealth))
    maid:GiveTask(MatchService.SkipWave:Connect(MatchController.SkipWave))

end

function MatchController.UpdateHealth()
    local Health = ValuesFolder:WaitForChild("Health")
    local HealthUI = Toolbar:WaitForChild("Health").Text

    HealthUI.Text = Health.Value .."/" .. Health:GetAttribute("MaxHealth")
end

function MatchController.UpdateCash(Value : number)
    local CashTemplate = MoneyFrame.Temp:WaitForChild("AddedCash") 

    local newCash = CashTemplate:Clone()
    newCash.Text = "+" .. Value
    newCash.Visible = true
    newCash.Parent = MoneyFrame

    local Tween = TweenService:Create(newCash,TweenInfo.new(1),{TextTransparency = 1,Position = UDim2.new(0,0,0,0)})
    local Tween1 = TweenService:Create(newCash.UIStroke,TweenInfo.new(1),{Transparency = 1})
    Tween1:Play()
    Tween:Play()
    task.delay(1,game.Destroy,newCash)
    Tween.Completed:Wait()
end

function MatchController.StartGame(VoteInfo)
    local EndFrame = Core:WaitForChild("EndFrame")
    local Count = StartGame_Btn:WaitForChild("Count")
    local Time = StartGame_Btn:WaitForChild("Time")
    local StartTime = VoteInfo.StartTime
    local Votes = ValuesFolder[VoteInfo.VoteName].Votes
    local RequiredVotes = ValuesFolder[VoteInfo.VoteName].RequiredVotes
    startmaid = Maid.new()

    EndFrame.Visible = false
    Content.Visible = true
    StartGame_Btn.Visible = true

    local UpdateCount = function() -- Used to update text
        Count.Text = "StartGame (".. Votes.Value.."/".. RequiredVotes.Value .. ")" 
    end

    UpdateCount() 

    task.delay(1.5,function()
        MatchController.IndicatePath()
    end)

    Votes.Changed:Connect(UpdateCount)


    startmaid:GiveTask(StartGame_Btn.MouseButton1Click:Connect(function()
        startmaid:Destroy()
        MatchService.Vote:Fire()
    end))

    startmaid:GiveTask(RunService.Heartbeat:Connect(function(dt)
        StartTime -= RunService.Heartbeat:Wait()
        if Time then
            Time.Text = toS(StartTime) .. "s"
        end
    end))

end

function MatchController:ConnectButtons()
    local EndFrame = Core:WaitForChild("EndFrame")
    local Restart_btn = EndFrame:WaitForChild("Restart")
    local Lobby_btn = EndFrame:WaitForChild("Lobby")
    local Next_btn = EndFrame:WaitForChild("Next")

    local Buttons = {
        StartGame_Btn,
        SkipWave,
        Next_btn,
        Restart_btn,
        Lobby_btn
    }

    for _,Button in Buttons do
		local HoverFrame = Button:FindFirstChild("Hover")

		if not HoverFrame then
			UIController:CreateHoverFrame(Button)
		end

		local newSize = UDim2.new(Button.Size.X.Scale / 15,0,Button.Size.Y.Scale / 15,0)

		UIManager:OnMouseChanged(Button,
			Button.Size + newSize,--UDim2.new(.05,0,.05,0),
			Button.Size,
			nil,
	
			--On Hover
			function()
			    UIController:ConnectHover(Button)
			end,
			function()
			    UIController:ConnectLeave(Button)
			end,
			nil
		)

	end

end

function MatchController:PreLoadAnimations(character)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    local animations = ReplicatedStorage.Assets.Animations:GetDescendants()

    for _,Animation in ipairs(animations) do
        if not Animation:IsA("Animation") then continue end
        animator:LoadAnimation(Animation)
    end
end

function MatchController:KnitStart()
    MatchService = Knit.GetService("MatchService")
    ProfileService = Knit.GetService("ProfileService")
    SoundController = Knit.GetController("SoundController")
    UIController = Knit.GetController("UIController")

    MatchService.RequestToStart:Connect(MatchController.StartGame)
    MatchService.MatchStart:Connect(MatchController.MatchStart)

    MatchService.RemoveSkipWave:Connect(MatchController.RemoveSkip)
    MatchService.MatchEnd:Connect(MatchController.MatchEnd)
    MatchService.WaveUpdate:Connect(MatchController.UpdateWave)
    MatchService.StartTimer:Connect(MatchController.StartTimer)
    MatchService.WaveEnd:Connect(MatchController.WaveEnd)

    MatchService.EnemiesSpawned:Observe(function(CurrentEnemies)
        WaveInfoHolder.Entities.ActualValue.Text = tostring(CurrentEnemies)
    end)

    self:ConnectButtons()

    self:PreLoadAnimations()


end

return MatchController
