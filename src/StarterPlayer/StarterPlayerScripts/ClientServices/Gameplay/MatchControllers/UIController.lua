local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Grades = require(ReplicatedStorage.SharedPackage.Grades)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local TopbarUI = require(ReplicatedStorage.Shared.Icon)

local UIController = Knit.CreateController {
    Name = "UIController",
}

local MobService;
local player = Players.LocalPlayer
local Mouse : Mouse = player:GetMouse()
local Camera = workspace.CurrentCamera

local playerGui = player:WaitForChild("PlayerGui")
local Core = playerGui:WaitForChild("Main")
local HoverUI : BillboardGui = playerGui:WaitForChild("HoverUI")
local Content = Core:WaitForChild("Content")
local Toolbar = Content:WaitForChild("Toolbar")
local MoneyFrame = Toolbar:WaitForChild("MoneyFrame")
local WaveInfoHolder = Core:WaitForChild("WaveInfoHolder")
local EntitiesUI = WaveInfoHolder:WaitForChild("Entities")
local BossDialogFrame = Content:WaitForChild("BossDialogFrame")
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)

local BossDialogModule = require(ReplicatedStorage.Shared.BossDialog)
local Spring = require(ReplicatedStorage.Shared.Utility.UISpring)

local TweenState = {
	Idle = 0,
	Animating = 1
}

local Size = {
	In = UDim2.new(.0008, 0, .0008, 0),
	Out = UDim2.new(3, 0, 3, 0)
}

function TweenGUI(Type, Frame)
	if Type == "Close" then
		Frame:TweenSize(Size.In, Enum.EasingDirection.In, Enum.EasingStyle.Linear, .5)
	elseif Type == "Open" then
		Frame:TweenSize(Size.Out, Enum.EasingDirection.Out, Enum.EasingStyle.Linear, .5)
	end
end

local function typeWrite(guiObject, text : string, delayBetweenChars)
    guiObject.Visible = true
    guiObject.AutoLocalize = false
    -- self.ShowSkip.Visible = true
    local displayText = text
    -- local Btn_maid = maid.new()
    local skip = false

    -- Translate text if possible
    -- if translator then
    --     displayText = translator:Translate(guiObject, text)
    -- end

    -- Replace line break tags so grapheme loop will not miss those characters
    displayText = displayText:gsub("<br%s*/>", "\n")
    displayText:gsub("<[^<>]->", "")

    -- --warn("The new dialog " .. displayText)
    -- Set translated/modified text on parent
    guiObject.Text = displayText

    local index = 0
    -- TypingSound:Play()

    -- Btn_maid:GiveTask(self.ShowSkip.Activated:Connect(function()
    --     skip = true
    -- end))

    for first, last in utf8.graphemes(displayText) do
        index = index + 1
        guiObject.MaxVisibleGraphemes = index

        if skip then
            guiObject.MaxVisibleGraphemes = text:len()
            break;
        end
        task.wait(delayBetweenChars)
    end
    -- TypingSound:Stop()
    -- Btn_maid:Destroy()
    -- self.ShowSkip.Visible = false
end

local function GetViewport(Boss,Port)
    if Boss then
        local WM = Instance.new("WorldModel")
        local NewUnit = Boss:Clone()
        NewUnit.Name = "VPModel"

        NewUnit:PivotTo(CFrame.new(0,0,0))

        WM.Parent = Port;
        
        local Cam = Instance.new("Camera")
        Cam.Parent = Port
        Port.CurrentCamera = Cam;
        NewUnit.Parent = WM;
            
        Cam.CFrame = CFrame.new((NewUnit.Head.CFrame * CFrame.Angles(math.rad(0),math.rad(-30),math.rad(-180)) * CFrame.new(0,.25,-1.5)).Position,NewUnit.Head.Position + Vector3.new(0,-.1,0))
        -- Cam.CFrame = CFrame.new((NewUnit.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)) * CFrame.new(0,0,-1.5)).Position,NewUnit.HumanoidRootPart.Position + Vector3.new(0,-.27,0))
        
        local UnitInfo = require(game.ReplicatedStorage.Shared.UnitInfo).UnitInformation["Leaf Ninja"]
        local AnimId = UnitInfo.IdleAnim
        local Speed = UnitInfo.AdjustSpeed or 1
        local Anim = Instance.new("Animation")
        Anim.Name = "Idle";
        Anim.AnimationId = "rbxassetid://" .. AnimId
        -- Anim.Parent = WM.Animate;

        local Track = NewUnit.Humanoid:LoadAnimation(Anim)
        Track:Play()
        -- WM.Animate.Enabled = true 
    else
    end
end

function UIController.StartBossDialog(Boss,Condition)
    local Dialog = BossDialogModule[Boss.Name][Condition]
    local ChatBox = BossDialogFrame.Dialog
    local ViewportFrame = BossDialogFrame.ViewportFrame
    local BossName = BossDialogFrame.BossName

    BossDialogFrame.Visible = true

    BossName.Text = tostring(Boss.Name)

    if not ViewportFrame:FindFirstChild("WorldModel") then
        GetViewport(Boss,BossDialogFrame.ViewportFrame)
        typeWrite(ChatBox,Dialog)
    else
        typeWrite(ChatBox,Dialog)
    end

    task.delay(5,function()
        BossDialogFrame.Visible = false
    end)
end

function UIController:StartTimer(Countdown : number)

end

function UIController:ShowSkipbtn()

end

function UIController:CreateHoverFrame(ParentFrame)
    local HoverFrame = Instance.new("Frame")
	HoverFrame.Name = "Hover"
	HoverFrame.Parent = ParentFrame
	HoverFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	HoverFrame.Size = UDim2.new(1, 0,1, 0)
	HoverFrame.BackgroundTransparency = 1

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Parent = HoverFrame
	UIStroke.Color = Color3.fromRGB(240, 240, 240)
	UIStroke.Transparency = 1

	if ParentFrame:FindFirstChildWhichIsA("UICorner") then
		local newCorner = ParentFrame:FindFirstChildWhichIsA("UICorner"):Clone()

		newCorner.Parent = HoverFrame
	end
end

function UIController:ConnectHover(ParentFrame)
	local HoverFrame = ParentFrame:FindFirstChild("Hover");

	TweenService:Create(HoverFrame,TweenInfo.new(.1),{BackgroundTransparency = .85}):Play()
	TweenService:Create(HoverFrame.UIStroke,TweenInfo.new(.1),{Transparency = 0}):Play()
end

function UIController:ConnectLeave(ParentFrame)
	local HoverFrame = ParentFrame:FindFirstChild("Hover");

	TweenService:Create(HoverFrame,TweenInfo.new(.1),{BackgroundTransparency = 1}):Play()
	TweenService:Create(HoverFrame.UIStroke,TweenInfo.new(.1),{Transparency = 1}):Play()
end

function UIController.Transition(TransitionTime)
    local playerGui = player.PlayerGui
    local Transition = playerGui.Transition
    local Frame = Transition.Black

    --TweenService:Create(Frame,TweenInfo.new(.2),{BackgroundTransparency = 0}):Play()
    TweenGUI("Close", Frame)

    task.wait(TransitionTime)

    TweenGUI("Open", Frame)
end

function UIController.BossWarning()
    local playerGui = player.PlayerGui
    local Transition = playerGui.Transition
    local WarningFrame = Transition.WarningFrame
    local WarningList = WarningFrame.List

    --local SizeUpHeightTween = TweenService:Create(WarningFrame,TweenInfo.new(.3),{Size = UDim2.new(1, 0,0.01, 0)})
	--local SizeUpWideTween = TweenService:Create(WarningFrame,TweenInfo.new(.2),{Size = UDim2.new(1, 0,0.2, 0)})
	--local SizeDownHeightTween = TweenService:Create(WarningFrame,TweenInfo.new(.3),{Size = UDim2.new(1, 0, 0.01, 0)})
	local SizeDownWideTween = TweenService:Create(WarningFrame,TweenInfo.new(.2),{Size = UDim2.new(0.1, 0, 0.01, 0)})
	local MainObjectTween = TweenService:Create(WarningList.Glow,TweenInfo.new(.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out,0,false),{Size = UDim2.new(0.45, 0,25, 0), Rotation = - 8})
	--local MainObjectTween2 = TweenService:Create(WarningList.Glow,TweenInfo.new(.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),{Size = UDim2.new(0.2, 0,1.4, 0), Rotation = 16, ImageTransparency = 1})

	local ObjectTransparencyTween = TweenService:Create(WarningList.Glow.Arrow,TweenInfo.new(.25),{ImageTransparency = 1})

	WarningFrame.Visible = true

	--SizeUpHeightTween:Play()
	--SizeUpHeightTween.Completed:Wait()

	Spring.target(WarningFrame,1,1.5,{
		Size = UDim2.fromScale(1, 0.01)--UDim2.fromScale(0.5,0.5)
	})

	task.wait(.55)

	Spring.target(WarningFrame,.8,2,{
		Size = UDim2.fromScale(1, 0.2)--UDim2.fromScale(0.5,0.5)
	})

	task.wait(0.525)

	--SizeUpWideTween:Play()
	--SizeUpWideTween.Completed:Wait()

	--MainObjectTween:Play()

	Spring.target(WarningList.Glow,.3,3,{
		Size = UDim2.new(0.4, 0,2, 0),
		Rotation = - 8
	})

	--MainObjectTween:Play()

	--MainObjectTween.Completed:Wait()

	--TweenService:Create(WarningList.Glow,TweenInfo.new(.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out,0,false),{Size = UDim2.new(0.4, 0,2, 0)}):Play()

	for i = 1,4 do
		local oldPosL = WarningList["ArrowL"..i].Position
		local oldPosR = WarningList["ArrowR"..i].Position
		
		TweenService:Create(WarningList["ArrowR"..i],TweenInfo.new(.5),{Position = WarningList["ArrowR"..i].Position + UDim2.new(.5,0,0,0)}):Play()
		TweenService:Create(WarningList["ArrowL"..i],TweenInfo.new(.5),{Position = WarningList["ArrowL"..i].Position + UDim2.new(-.5,0,0,0)}):Play()

		task.wait(.1)

		task.delay(.5,function()
			WarningList["ArrowL"..i].ImageTransparency = 1
			WarningList["ArrowR"..i].ImageTransparency = 1
		end)
		
		task.delay(3,function()
			WarningList["ArrowL"..i].ImageTransparency = 0
			WarningList["ArrowL"..i].Position = oldPosL
			
			WarningList["ArrowR"..i].ImageTransparency = 1
			WarningList["ArrowR"..i].ImageTransparency = oldPosR
		end)
	end

	--task.wait(.25)


	--MainObjectTween.Completed:Wait()

	task.wait(.77)

	Spring.target(WarningList.Glow,.5,4,{
		Size = UDim2.new(0.2, 0,1.4, 0),
		Rotation = 16,
		ImageTransparency = 1
	})

	ObjectTransparencyTween:Play()

	task.wait(.35)

	Spring.target(WarningFrame,1,5,{
		Size = UDim2.new(1, 0, 0.01, 0)--UDim2.fromScale(0.5,0.5)
	})

	task.wait(.25)

	Spring.target(WarningFrame,1,5,{
		Size = UDim2.new(0.01, 0, 0.01, 0)--UDim2.fromScale(0.5,0.5)
	})

	task.wait(.1)

	WarningFrame.Visible = false

end

function UIController.MovieMode(Boolean)
    local playerGui = player.PlayerGui
    local MovieMode = playerGui.MovieMode

    MovieMode.Enabled = Boolean
end

function UIController.DeductBy(TotalEntities : number,DeductedNumber : number)
    local ActualValue = EntitiesUI:WaitForChild("ActualValue")
    local Deducted = EntitiesUI:WaitForChild("Deducted")

    -- --print("THIS HAS BEEN FIREL")
    ActualValue.Text = TotalEntities

    if DeductedNumber then
        Deducted.Text = "-" .. DeductedNumber
        Deducted.Visible = true
        task.delay(1,function()
            Deducted.Visible = false
        end)
    end 
end

local function ParticleTranparency(Part,Value)
    TweenService:Create(Camera,TweenInfo.new(1),{FieldOfView = 50}):Play()
    TweenService:Create(Part,TweenInfo.new(1),{BackgroundTransparency = 0}):Play()
    task.wait(1.2)

    TweenService:Create(Camera,TweenInfo.new(.25),{FieldOfView = 70}):Play()

    Part.TextLabel.Visible = true
    Part.TextLabel1.Visible = true

    for t = 0.0, Value , .01 do
        Part.UIGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, t-.5),
            NumberSequenceKeypoint.new(.5, t),
            NumberSequenceKeypoint.new(1, t-.5)
        })
        task.wait()
    end
end

local function ShowResult(Frame : Frame & { UIGradient })
    local UIGradient = Frame.UIGradient

    ParticleTranparency(Frame, 1)
    task.wait(5)
    Camera.FieldOfView = 70
    ParticleTranparency(UIGradient, 0)
end

local function GetGrade(UnitInfo, StatName : string)
	local UnitStats = UnitInfo.Stats
	local Grades = Grades.Ranks
	local ActualGrade = UnitStats[StatName]
	local GradeValue = Grades[ActualGrade]

	return GradeValue, ActualGrade
end

local function ShowStats(Frame : Frame, Info)
    Frame.OwnersName.Text = "@" .. Info.Owner.Name  --Info.Owner
    Frame.UnitName.Text = Info.Name

    for _,Frames : Frame in pairs(Frame:GetChildren()) do
        if Frames:IsA("Frame") then
            local ActualStat 

            if Frames.Name ~= "Damage" then
                _,_,ActualStat = UnitManager:ConvertGradeInGame(Info,Frames.Name,Info.Level)
            else
                ActualStat = UnitManager:GetDamageWithBenefitsInGame(Info, "Damage")
            end

            Frames.TextLabel.Text = ActualStat
        end
    end
end

function UIController:KnitStart()
    local Cash = player.leaderstats:WaitForChild("Cash")
    local UnitService = Knit.GetService("UnitService")
    local WorldService = Knit.GetService("WorldService")
    local UnitInfoFolder = playerGui.UnitInfoFolder
    local maid = Maid.new()
    local Highlight : Highlight = playerGui.Highlight
    local UnitUI_Shown = false
    local Detector;
    MobService = Knit.GetService("MobService")

    local function UpdateCash(Value)
        MoneyFrame.TextLabel.Text = "$" .. Value
    end

    UpdateCash(Cash.Value)

    local AutoSkipEnabled = false

    local AutoSkip = TopbarUI.new()
    AutoSkip:setLabel("AutoSkip: ❌"):setCaption("Enabled AutoSkip"):align("Left")

    AutoSkip.selected:Connect(function()
        if AutoSkipEnabled then
            AutoSkipEnabled = false
            AutoSkip:setLabel("AutoSkip: ❌")
        elseif not AutoSkipEnabled then
            AutoSkipEnabled = true
            AutoSkip:setLabel("AutoSkip: ✔️")
        end
        WorldService:AdminCommands("AutoSkip") -- I WAS DOING SPEED MANIPULATION (2024-08-30)
        print("Requested to toggle autoskip")
    end)

    local Speed1x = TopbarUI.new()
    Speed1x:setLabel("1x"):setCaption("Increase Game speed by 1x"):align("Right")

    Speed1x.selected:Connect(function()
        WorldService:AdminCommands("MultiplySpeed",nil,true) -- I WAS DOING SPEED MANIPULATION (2024-08-30)
        print("Requested to increase speed")
    end)

    local Speed2x = TopbarUI.new()
    Speed2x:setLabel("2x"):setCaption("Increase Game speed by 2x"):align("Right")

    Speed2x.selected:Connect(function()
        WorldService:AdminCommands("MultiplySpeed",2,true) -- I WAS DOING SPEED MANIPULATION (2024-08-30)
        print("Requested to increase speed")
    end)

    local Speed3x = TopbarUI.new()
    Speed3x:setLabel("3x"):setCaption("Increase Game speed by 3x"):align("Right")

    Speed3x.selected:Connect(function()
        WorldService:AdminCommands("MultiplySpeed",3,true) -- I WAS DOING SPEED MANIPULATION (2024-08-30)
        print("Requested to increase speed")
    end)

    Mouse.Move:Connect(function()
        Detector = Mouse.Target
        if Detector then
            local Unit = Detector.Parent
			
			if Unit.Parent:FindFirstChild("Humanoid") then
                Unit = Unit.Parent
            end

            local Id = Unit:GetAttribute("Id")
			local Owner = Unit:GetAttribute("Owner")

			if Id and Owner then
                local Id = Unit:GetAttribute("Id") 
                local HumanoidRootPart = Unit:FindFirstChild("HumanoidRootPart") or Unit:FindFirstChild("RootPart")
                local UpgradeUI = UnitInfoFolder:FindFirstChild("UnitInfo")
                local InfoRequest = UnitService:GetUnitInfo(Id)

                InfoRequest:andThen(function(UnitInfo)
                    if not UpgradeUI then
                        local Content = HoverUI.Content
                        HoverUI.Adornee = HumanoidRootPart
                        Highlight.Adornee = Unit
                        HoverUI.Enabled = true
                        UnitUI_Shown = true
                        ShowStats(Content, UnitInfo)
                    end
                end)
            else
                Highlight.Adornee = nil
                UnitUI_Shown = false
                HoverUI.Enabled = false
            end
        end
    end)
    
    maid:GiveTask(Cash.Changed:Connect(UpdateCash))

    MobService.BossDialog:Connect(UIController.StartBossDialog)
    MobService.TotalEntities:Connect(UIController.DeductBy)
end

return UIController
