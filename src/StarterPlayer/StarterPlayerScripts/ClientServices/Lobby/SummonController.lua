local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(Knit.Util.Signal)
local UIManager = require(ReplicatedStorage.Shared.UIManager)
local SummonModule = require(ReplicatedStorage.Shared.SummonModule)
local Maid = require(ReplicatedStorage.Shared.Utility.maid)
local CameraShake = require(ReplicatedStorage.Shared.Utility.CameraShaker)
local UnitModule = require(ReplicatedStorage.SharedPackage.Units)
local UnitManager = require(ReplicatedStorage.Shared.UnitManager)
local BannerNotify = require(ReplicatedStorage.Shared.Utility.BannerNotificationModule)
local Cutscene = require(ReplicatedStorage.Shared.Cutscene)
local Shortcut = require(ReplicatedStorage.Shared.Utility.Shortcut)
local MaidManager = require(ReplicatedStorage.Shared.Utility.MaidManager)
local _maid = MaidManager.new()

local Animations = ReplicatedStorage.Assets.Animations

local SummonController = Knit.CreateController {
    Name = "SummonController"
}

SummonController.OpenRequestSummon = Signal.new()

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Mouse = player:GetMouse()
local Core

local SummonService;
local ProfileService;
local CutsceneController;
local LobbyService;

local maid
local CutsceneDone = false
local AutoSell = {
    [1] = false,
    [2] = false,
    [3] = false,
}

local Rarity = {
    [1] = "Rare",
    [2] = "Epic",
    [3] = "Legendary",
    [4] = "Mythical",
    [5] = "Secret",
}

local RarityColor = {
    ["Defualt"] = Color3.fromRGB(255, 255, 255),
    ["Rare"] = Color3.fromRGB(0, 208, 255),
    ["Epic"] = Color3.fromRGB(217, 2, 255),
    ["Legendary"] = Color3.fromRGB(255, 226, 7),
    ["Mythical"] = Color3.fromRGB(255, 255, 255),
    ["Secret"] = Color3.fromRGB(255, 255, 255),
}

function createTracePart(player, CFRAME)
    local part = Instance.new("Part")
    part.CFrame = CFRAME
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0
    part.Size = Vector3.new(1,1,1)
    part.Parent = player.Character

    return part
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

function ChangeColor(Part,Value : Color3, Ignore : {[string] : boolean})
    Ignore = Ignore or {}
    --print("IGNORING: ", Ignore)
	for i, v : ParticleEmitter in pairs(Part:GetDescendants()) do
		if v.ClassName == "Beam" or v.ClassName == "ParticleEmitter" or v.ClassName == "PointLight" then
            if not Ignore[v.Name] then
                v.Color = ColorSequence.new(Value)
            end
		end
	end
end

function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

local function getNextHourTimestamp()
	local dateTable = os.date("!*t", os.time())

	dateTable.min = 0
	dateTable.sec = 0

	return os.time(dateTable) + 3600
end

function SummonController:Summon(Summoned : {[number] : string}, SkipCutscene : boolean)
    -- UI ---    
    local Amount = #Summoned
    local playerGui = player:WaitForChild("PlayerGui")
    local Core = playerGui:WaitForChild("Core")
    local SummonFrame = Core:WaitForChild("SummonContent")
    local Content = Core:WaitForChild("Content")
    local Gems = Content.SummonFrame.Interaction:WaitForChild("GemLabel")
    local AmountLabel = SummonFrame:WaitForChild("Amount")

    -- Data --
    local CameraCFrame,Camera = SummonModule:CameraGetCFrame()
    local DefualtCamera = workspace.Important.SummonCamera.CFrame
    CameraCFrame = DefualtCamera
    local relativeCFrame = CameraCFrame * CFrame.new(0,0,-3) * CFrame.Angles(0,math.rad(180),0)
    local AnimationIsDone = false
    local SummonedUnit
    local LastSummoned;
    local Paused = true
    local SummonMaid = Maid.new()
    local CameraDefualtTween;

    SummonModule:SetDepthOfField(true)
    SummonFrame.Visible = false

    local IsDone = false
    local TweenCam : Tween = TweenService:Create(Camera,TweenInfo.new(.5),{CFrame = workspace.Important.SummonCamera.CFrame})
    TweenCam:Play()

    TweenCam.Completed:Connect(function()
        IsDone = true
    end)
    -- local Dragonballs, newPos = SummonModule:PlayDragonBalls()

    repeat task.wait() until IsDone
    CutsceneController.SummonEvent:Fire(SkipCutscene)

    repeat
        task.wait()
    until CutsceneDone

    local function ShakeCamera(shakeCFrame)
        Camera.CFrame = Camera.CFrame * shakeCFrame
    end
    CameraCFrame,Camera = SummonModule:CameraGetCFrame()

    local function onMouseMove(mouse)
        -- Construct Vector2 objects for the mouse's position and screen size
        local position = Vector2.new(mouse.X, mouse.Y)
        local size = Vector2.new(mouse.ViewSizeX, mouse.ViewSizeY)
        -- A normalized position will map the top left (just under the topbar)
        -- to (0, 0) the bottom right to (1, 1), and the center to (0.5, 0.5).
        -- This is calculated by dividing the position by the total size.
        local normalizedPosition = position / size
        return normalizedPosition
    end

    local camshake = CameraShake.new(Enum.RenderPriority.Camera.Value, ShakeCamera)
    camshake:Start()

    function createTracePart(CFRAME)
        local part = Instance.new("Part")
        part.CFrame = CFRAME
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(1,1,1)
        part.Parent = workspace.Debris

        return part
    end

    local Tracer = createTracePart(CameraCFrame * CFrame.new(0,0,-6.5) * CFrame.Angles(0,math.rad(180),0))

    local function Next()
        LastSummoned = SummonedUnit
        Paused = false
        Tracer:ClearAllChildren()

        local TweenInf : Tween = TweenService:Create(LastSummoned.PrimaryPart,TweenInfo.new(.25),{CFrame = relativeCFrame * CFrame.new(0,-3,0)})
        TweenInf:Play()

        TweenInf.Completed:Connect(function()
            if LastSummoned then
                LastSummoned:Destroy()
            end
        end)
    end

    SummonMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            Next()
        end
    end))

    SummonMaid:GiveTask(RunService.RenderStepped:Connect(function()
        if not AnimationIsDone then return end
        local newCFrame = SummonModule:CameraGetCFrame()
        local mouseToScreen = onMouseMove(Mouse)
        SummonedUnit:PivotTo(newCFrame * CFrame.new(0,0,-3) * CFrame.Angles(0,math.rad(180 + mouseToScreen.X * 5),0))
    end))

    local function Scale(Model : Model, Value, _callback)
        for i = Model:GetScale(), Value, .01 do
            Model:ScaleTo(i)
            -- task.wait()
            RunService.Heartbeat:Wait()
        end

        if _callback then
            _callback()
        end
    end

    for currentPos,Unit in Summoned do
        SummonedUnit = SummonModule:GetUnit(Unit.Unit,CameraCFrame * CFrame.new(0,2,-3) * CFrame.Angles(0,math.rad(180),0))--createTracePart(player,CameraCFrame * CFrame.new(0,0,-3))
        local Particle = SummonModule:GetParticle("Summon")
        local backGroundParticle = SummonModule:GetParticle("BackVFX")
        local Animation = Animations:FindFirstChild(Unit.Unit .."Idle", true)
        local Settings = ProfileService:Get("Settings"):expect()
        local attachment = backGroundParticle.Attachment

        SummonedUnit:ScaleTo(0.01) --- Then tween the unit
        -- task.spawn(Scale,Su)
        
        attachment.Parent = Tracer --SummonedUnit.PrimaryPart
        -- attachment.CFrame = CFrame.new(0,0,3)
        -- Toggle(attachment, true)


        SummonedUnit.Parent = Camera
        Paused = true
        AnimationIsDone = false

        SummonModule:SetDepthOfField(true, 2.36)
        
        if Amount >= 10 then
            AmountLabel.Text = "Click to continue (" .. currentPos .."/" .. Amount .. ")" 
        else
            AmountLabel.Text = "Click to continue" 
        end
        
        SummonFrame.AutoSell.Visible = false
        Particle.upgrade.Parent = SummonedUnit.PrimaryPart
        
        if Animation then
            local Anim = SummonedUnit.Humanoid.Animator:LoadAnimation(Animation)
            Anim:Play()
        end

        local unitData = UnitModule[Unit.Unit]
        local unitRarity = Rarity[unitData.Rarity]

        local TweenInf = TweenService:Create(SummonedUnit.PrimaryPart,TweenInfo.new(.25),{CFrame = relativeCFrame})
        TweenInf:Play()

        if Settings.AutoSell[unitRarity] ~= nil and Settings.AutoSell[unitRarity] == true then
            -- print("This unit got auto sold")
            SummonFrame.AutoSell.Visible = true
        end

        SummonFrame.Visible = true
        SummonFrame.UnitName.Text = Unit.Unit
        SummonFrame.InfoFrame.UnitName.Text = Unit.Unit

        SummonFrame.Rarity.Text = Rarity[unitData.Rarity]
        SummonFrame.InfoFrame.Rarity.Text = Rarity[unitData.Rarity] .. " - " .. unitData.UnitType

        task.delay(.2,Scale,SummonedUnit, .3)
        ChangeColor(attachment, RarityColor[unitRarity])

        for name, Stat in Unit.Stats do
            local Label = SummonFrame.InfoFrame.Stats:FindFirstChild(name)
            if Label then
                local gradeValue, grade, Value = UnitManager:ConvertGrade(Unit, name)
                Label.Text = "("..Stat..") " .. name ..": " .. Value
            end
        end

        TweenInf.Completed:Connect(function(playbackState)
            AnimationIsDone = true
            SummonModule:Emit(SummonedUnit, 5)
            -- camshake:Shake(CameraShake.Presets.Summon)
        end)
        print("CurrentPos: ", currentPos, #Summoned)
        if Settings.AutoSell[unitRarity] ~= nil and Settings.AutoSell[unitRarity] == true then -- Might cause a problem later
            SummonService:SellUnits({Unit.Hash})
            task.delay(.5,function()
                if Paused and (#Summoned > 1 and currentPos < 8) then
                    Paused = false
                    Next()
                end
            end)
        end
        repeat task.wait() until not Paused
    end

    task.spawn(function() -- Update pity
        local SummonPity = ProfileService:Get("SummonPity"):expect()
        local GemsValue = ProfileService:Get("Gems"):expect()

        Gems.GemAmount.Text = GemsValue
        SummonController.UpdatePity("Legendary",SummonPity.Legendary, 100)
        SummonController.UpdatePity("Mythical",SummonPity.Mythic, 300)
    end)

    if CameraDefualtTween then
        CameraDefualtTween:Destroy()
    end

    -- Cutscene end here(from CutsceneController) --
    local ScarySky = ReplicatedStorage:FindFirstChild("ScarySky")
    Cutscene.DisableUI(player,"MovieMode", false)
    Cutscene.DisableUI(player,"Content", true)

    Cutscene:Enabled(false)

    if ScarySky then
        ScarySky.Parent = Lighting
    end

    ------------------------

    workspace.Summoning:WaitForChild("BigShenron"):PivotTo(CFrame.new(2406.634, -100.514, 85.828))
    SummonFrame.Visible = false
    CutsceneDone = false
    Camera:ClearAllChildren()
    SummonModule:SetDepthOfField(false)
    SummonMaid:Destroy()
end

local function UpdateSummon(Summons)
    local Content = Core:WaitForChild("Content")
    local SummonFrame = Content:WaitForChild("SummonFrame")
    local Chances = SummonFrame:WaitForChild("Chances")
    local Viewport = SummonFrame:WaitForChild("ViewportFrame")

    local SummonArea = ReplicatedStorage.SummonArea:Clone()        
    SummonArea.Parent = workspace

    local BaseSummonChances = {
        [1] = 49.9, -- Rare
        [2] = 35, -- Epic
        [3] = 13, -- Legendary
        [4] = 1, -- Mythical 
        [5] = 0.1, -- Secret
    }

    local BaseChances = {
        [1] = "Rare", -- Rare
        [2] = "Epic", -- Epic
        [3] = "Legendary", -- Legendary
        [4] = "Mythical", -- Mythical 
        [5] = "Secret", -- Secret
    }

    UIManager:ClearFrame("Model", Viewport.WorldModel)

    for Pos,Units in Summons do
        local Unit = SummonModule:GetUnit(Units, SummonArea[Pos].CFrame)
        Unit:SetAttribute("ActualName", Unit.Name)
        Unit.Name = "Unit"..Pos
        Unit.Parent = SummonArea

        Chances[Pos].Text = Units
        Chances[Pos].Procentage.Text = BaseSummonChances[Pos] .. "%"

        UIManager:AddEffectToText(Chances[Pos],BaseChances[Pos],.25,1)

        if Pos == 5 then
            for _,parts : BasePart in pairs(Unit:GetDescendants()) do
                if parts:IsA("BasePart") then
                    if parts:IsA("MeshPart") then
                        parts.TextureID = ""
                    end
                    parts.Color = Color3.fromRGB()
                end
            end
        end
    end

    local newCamera = workspace.CurrentCamera:Clone()
    newCamera.CameraType = Enum.CameraType.Scriptable
    newCamera.CFrame = SummonArea.Camera.CFrame

    SummonArea.Parent = Viewport.WorldModel
    newCamera.Parent = Viewport
    Viewport.CurrentCamera = newCamera

    for _, models in pairs(Viewport.WorldModel.SummonArea:GetChildren()) do
        local Humanoid = models:FindFirstChild("Humanoid")
        if Humanoid then
            local succ,err = pcall(function()
                local Animation = Animations:FindFirstChild(models:GetAttribute("ActualName") .."Idle", true)

                if Animation then
                    local Anim = Humanoid.Animator:LoadAnimation(Animation)
                    Anim:Play()
                    warn("Playing ".. models:GetAttribute("ActualName").. " Idle ")
                end
            end)

            if err then
                warn(err)
            elseif succ then
                -- print("Animation has been loaded and is playing")
            end
        end
    end
end

local function LoadSummonFrame(Frame)
    local currentSummon = SummonService:GetCurrentSummon()
    local Viewport = Frame:WaitForChild("ViewportFrame")

    currentSummon:andThen(function(Summons, seed)
        -- warn("THE SUMMONS --> ", Summons)
        UpdateSummon(Summons)

        task.spawn(function()
            local nextHourTimestamp = getNextHourTimestamp()
            local SummonFrame = Core.Content:WaitForChild("SummonFrame")
            -- local TimeFrame = SummonController:GetUI(Frame,"Time")
            local TimeLabel = SummonFrame:WaitForChild("Timer")
            local ExpBar = SummonFrame.Time:WaitForChild("ExpBar") --SummonController:GetUI(SummonFrame.Time,"ExpBar")
            local MaxTime = 60*60

            maid:GiveTask(RunService.Heartbeat:Connect(function()
                local currentTime = os.time()
                local timeLeft = nextHourTimestamp - currentTime

                ExpBar.Size = UDim2.new(timeLeft / MaxTime,0,1,0)

                if timeLeft <= 0 then
                    nextHourTimestamp = getNextHourTimestamp()
                    timeLeft = nextHourTimestamp - currentTime
                end

                TimeLabel.Text = "Expires in " .. formatTime(timeLeft)--timeLeft
            end))
        end)
    end):await()
end

function SummonController:GetUI(Parent, Name : string)
    for _,UI in pairs(Parent:GetDescendants()) do
        if UI.Name == Name then
            return UI
        end
    end
end

function SummonController.UpdatePity(Pity : string, newValue,MaxExp)
    local SummonFrame = Core.Content:WaitForChild("SummonFrame")
    local Pitybar = SummonFrame:WaitForChild(Pity.."Pity")
    local PityText = SummonFrame:WaitForChild(Pity.."PityText")
    -- local Exp_lb = SummonController:GetUI(Pitybar,"Exp")
    local ExpBar = SummonController:GetUI(Pitybar,"ExpBar")
    local Prop = {
        Size = UDim2.new(newValue / MaxExp,0,1,0)
    }
    local Tween = TweenService:Create(ExpBar,TweenInfo.new(1),Prop)
    Tween:Play()

    PityText.Text = " (" .. newValue .. "/" .. MaxExp ..")"
end

function SummonController.OpenSummon()
    local PurchaseIds = require(ReplicatedStorage.SharedPackage.PurchaseIds)
    local Content = Core:WaitForChild("Content")
    local SummonFrame = Content:WaitForChild("SummonFrame")
    local Interaction = SummonFrame:WaitForChild("Interaction")

    local Summon10 = Interaction:WaitForChild("Summon10")
    local Summon = Interaction:WaitForChild("Summon")
    local Gems = Interaction:WaitForChild("GemLabel")
    local SeeChances = SummonFrame:WaitForChild("SeeChances")
    local Chances = SummonFrame:WaitForChild("Chances")
    local Settings = ProfileService:Get("Settings"):expect()
    local ChancesOriginalSize = SeeChances.Size
    local bannerConfig = {
        .2,                             -- Background Transparency
        Color3.fromRGB(168, 0, 0),         -- Background Color
        0,                                 -- Content Transparency
        Color3.fromRGB(255, 255, 255), -- Content Color
    }

    local function GetProduct(Name)
        for ProductType, ProductTable in pairs(PurchaseIds) do
            for ProductName, ProductId in pairs(ProductTable) do
                if ProductName == Name then
                    return ProductType , ProductId
                end
            end
        end

        return nil
    end
    
    SummonFrame.ViewportFrame.WorldModel:ClearAllChildren()

    UIManager:UIOpened(SummonFrame, function()
        maid:Destroy()
        LobbyService:DialogMode(false) -- PromptParent.CFrame.Position
        warn("THE MAID SHOULD BE CLEANED")
    end)

    if maid then maid:Destroy() end
    maid = Maid.new()

    LoadSummonFrame(SummonFrame)
    local LuckOriginalSize = SummonFrame.LuckBoost.BtnFrame.Size
    local SuperLuckOriginalSize = SummonFrame.SuperLuckBoost.BtnFrame.Size
    
    _maid:AddMaid(SummonFrame.LuckBoost.BtnFrame.Btn,"Activated", SummonFrame.LuckBoost.BtnFrame.Btn.Activated:Connect(function()
        local _,ProductId = GetProduct("LuckBoost")
        MarketplaceService:PromptProductPurchase(player,ProductId)
    end))

    _maid:AddMaid(SummonFrame.SuperLuckBoost.BtnFrame.Btn,"Activated", SummonFrame.SuperLuckBoost.BtnFrame.Btn.Activated:Connect(function()
        local _,ProductId = GetProduct("SuperLuckBoost")
        MarketplaceService:PromptProductPurchase(player,ProductId)
    end))

    _maid:AddMaid(SeeChances,"Activated", SeeChances.Activated:Connect(function()
        Chances.Visible = not Chances.Visible
    end))

    UIManager:OnMouseChanged(SummonFrame.LuckBoost.BtnFrame,UDim2.fromScale(0.175,0.08), LuckOriginalSize)
    UIManager:OnMouseChanged(SummonFrame.SuperLuckBoost.BtnFrame,UDim2.fromScale(0.175,0.08), SuperLuckOriginalSize)

    UIManager:OnMouseChanged(SeeChances,UDim2.fromScale(0.175,0.08), ChancesOriginalSize)
    UIManager:AddButton(SeeChances,UDim2.fromScale(0.145,0.045),ChancesOriginalSize)

    task.spawn(function()
        local SummonPity = ProfileService:Get("SummonPity"):expect()
        local GemsValue = ProfileService:Get("Gems"):expect()

        Gems.GemAmount.Text = GemsValue
        SummonController.UpdatePity("Legendary",SummonPity.Legendary, 100)
        SummonController.UpdatePity("Mythical",SummonPity.Mythic, 300)
    end)

    -- warn("THE SETTINGS: ", )
    local AutoSellSettings = Settings.AutoSell
    local CutsceneBtn : TextButton = SummonFrame.SkipCutscene
    local SkipValue = Settings["SkipCutscene"]
    local SkipOriginalSize = CutsceneBtn.Size


    for _, Gradient in pairs(CutsceneBtn:GetDescendants())  do
        if Gradient:IsA("UIGradient") then
            Gradient.Enabled = SkipValue
        end
    end

    CutsceneBtn.Btn.Text = if SkipValue then "On" else "Off"

    _maid:AddMaid(CutsceneBtn,"Activated",CutsceneBtn.MouseButton1Up:Connect(function()
        SkipValue = not SkipValue

        CutsceneBtn.Btn.Text = if SkipValue then "On" else "Off"

        Shortcut:PlaySound("MouseClick", true)

        for _, Gradient in pairs(CutsceneBtn:GetDescendants())  do
            if Gradient:IsA("UIGradient") then
                Gradient.Enabled = SkipValue
            end
        end
        -- btns.Text = if Value then "On" else "Off"
        SummonService:EnableAutoSell(CutsceneBtn.Name, SkipValue):andThen(function(newSettings)
            Settings = newSettings
        end)
    end))

    UIManager:OnMouseChanged(CutsceneBtn,UDim2.fromScale(0.07,0.05), SkipOriginalSize,nil,nil,nil,nil,2)
    UIManager:AddButton(CutsceneBtn,UDim2.fromScale(0.035,0.025), SkipOriginalSize)

    for _,Frame : TextButton in pairs(SummonFrame.AutoSell:GetChildren()) do
        if (AutoSellSettings[Frame.Name] ~= nil) and Frame:IsA("TextButton") then
            local OrignalButtonSize = Frame.Size
            local Value = AutoSellSettings[Frame.Name]
            -- btns.Text = if Value then "On" else "Off"

            for _, Gradient in pairs(Frame:GetDescendants())  do
                if Gradient:IsA("UIGradient") then
                    Gradient.Enabled = Value
                end
            end

            if Frame.Name == "SkipCutscene" then
                Frame.Btn.Text = if Value then "On" else "Off"
            end

            _maid:AddMaid(Frame,"Activated",Frame.Activated:Connect(function()
                Value = not Value
                warn("THE MAID: ",_maid)
                if Frame.Name == "SkipCutscene" then
                    Frame.Btn.Text = if Value then "On" else "Off"
                end

                Shortcut:PlaySound("MouseClick", true)

                for _, Gradient in pairs(Frame:GetDescendants())  do
                    if Gradient:IsA("UIGradient") then
                        Gradient.Enabled = Value
                    end
                end
                -- btns.Text = if Value then "On" else "Off"
                SummonService:EnableAutoSell(Frame.Name, Value):andThen(function(newSettings)
                    Settings = newSettings
                end)
            end))

            UIManager:OnMouseChanged(Frame,(Frame:GetAttribute("SizeOnHover") or UDim2.fromScale(0.325,0.655)), OrignalButtonSize,nil,nil,nil,nil,2)
            UIManager:AddButton(Frame,UDim2.fromScale(0.24,0.6), OrignalButtonSize)
        end
    end

    local SummonOrignal = Summon.Size

    _maid:AddMaid(Summon,"Activated",Summon.Activated:Connect(function()
        SummonService:Summon(1):andThen(function(summoned, RetunedPrice)
            if summoned then
                Shortcut:PlaySound("MouseClick", true)
                SummonController:Summon(RetunedPrice,Settings.SkipCutscene)
            elseif RetunedPrice == "NoUnitSpace" then
                BannerNotify:Notify("NoUnitSpace","You inventory is full","",5,bannerConfig)
            elseif RetunedPrice == "NoGems" then
                BannerNotify:Notify("NoGems","You don't have enough gems","",5,bannerConfig)
            else
                warn("the summoning didn't work for some reason: ", summoned, RetunedPrice)
            end
        end)
    end))

    _maid:AddMaid(Summon10,"Activated",Summon10.Activated:Connect(function()
        SummonService:Summon(10):andThen(function(summoned, RetunedPrice)
            if summoned then
                Shortcut:PlaySound("MouseClick", true)
                SummonController:Summon(RetunedPrice, Settings.SkipCutscene)
            elseif RetunedPrice == "NoUnitSpace" then
                BannerNotify:Notify("NoUnitSpace","You inventory is full","",5,bannerConfig)
            elseif RetunedPrice == "NoGems" then
                BannerNotify:Notify("NoGems","You don't have enough gems","",5,bannerConfig)
            else
                warn("the summoning didn't work for some reason: ", summoned, RetunedPrice)
            end
        end)
    end))

    UIManager:OnMouseChanged(Summon10,UDim2.fromScale(0.95,0.3), SummonOrignal,nil,nil,nil,nil,2)
    UIManager:AddButton(Summon10,UDim2.fromScale(0.85,0.146), SummonOrignal)

    UIManager:OnMouseChanged(Summon,UDim2.fromScale(0.95,0.3), SummonOrignal,nil,nil,nil,nil,2)
    UIManager:AddButton(Summon,UDim2.fromScale(0.85,0.146), SummonOrignal)
end

function SummonController:KnitInit()
end

function SummonController:KnitStart()
    local playerGui = player:WaitForChild("PlayerGui")
    Core = playerGui:WaitForChild("Core")

    SummonService = Knit.GetService("SummonService")
    ProfileService = Knit.GetService("ProfileService")
    CutsceneController = Knit.GetController("CutsceneController")
    LobbyService = Knit.GetService("LobbyService")

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.KeyCode == Enum.KeyCode.F then
            -- SummonService:Trait()
        end
    end)
    
    CutsceneController.SummonCompleted:Connect(function()
        CutsceneDone = true
    end)

    SummonController.OpenRequestSummon:Connect(SummonController.OpenSummon)
    SummonService.SummonRotationUpdated:Connect(UpdateSummon)
end

return SummonController