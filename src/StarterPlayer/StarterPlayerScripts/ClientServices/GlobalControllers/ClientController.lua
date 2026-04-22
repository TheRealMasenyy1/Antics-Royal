local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local PlaceIds = require(ReplicatedStorage.Shared.PlaceIds)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local ClientController = Knit.CreateController {
    Name = "ClientController",
}

local Camera = workspace.CurrentCamera
local PlayerService;
local UnitController;

-- Double jump settings
local canJump = true
local debounceTime = 0.5 -- Time between jumps

function ClientController:PlayAnimation(Name : string, AdjustSpeed : number)
    local findAnimation = ReplicatedStorage.Assets.Animations:FindFirstChild(Name, true)
    AdjustSpeed = AdjustSpeed or 1

    if findAnimation then
        local Animation : AnimationTrack = character.Humanoid.Animator:LoadAnimation(findAnimation)
        Animation:Play()
        Animation:AdjustSpeed(AdjustSpeed)
        -- Animation.Priority = 
    end
end

function ClientController:StopAnimation(Name : string)
    local Animator = character.Humanoid:FindFirstChild("Animator")

    if Animator then
        for _,animation in Animator:GetPlayingAnimationTracks() do
            if animation.Name == Name then
                animation:Stop()
            end
        end 
    end
end

function ClientController.ActionHandler(Action, InputState) -- and not player.Character:GetAttribute("IsBoosted")
    if Action == "Sprint" and game.PlaceId ~= 102414288850842 then 
        if InputState == Enum.UserInputState.Begin and character.Humanoid.MoveDirection.Magnitude > 0 then
            ClientController:PlayAnimation("Run")
            PlayerService:Sprint(true)
            TweenService:Create(Camera,TweenInfo.new(.5),{ FieldOfView = 80}):Play()
        else
            ClientController:StopAnimation("Run")
            PlayerService:Sprint(false)
            warn("RUN HAS BEEN DISABLED")
            TweenService:Create(Camera,TweenInfo.new(.5),{ FieldOfView = 70}):Play()
        end
    elseif Action == "Upgrade" and InputState == Enum.UserInputState.Begin then
        UnitController:UpgradeUnit()
    elseif Action == "SellUnit" and InputState == Enum.UserInputState.Begin then
        UnitController:SellUnit()
    end
end

function ClientController:KnitInit()
    task.spawn(function()
        repeat -- Starts the repeat loop
            local success = pcall(function() 
                StarterGui:SetCore("ResetButtonCallback", false) 
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
            end)
            task.wait(1) -- Cooldown to avoid freezing
        until success 
    end)
end

function ClientController:KnitStart()
    local jumpUsage = 1
    local Humanoid = player.Character:FindFirstChild("Humanoid")
    PlayerService = Knit.GetService("PlayerService")
    local _, err = pcall(function()
        UnitController = Knit.GetController("UnitController")
    end)

    ContextActionService:BindAction("Sprint",ClientController.ActionHandler, true, Enum.KeyCode.LeftShift)
    ContextActionService:BindAction("Upgrade",ClientController.ActionHandler, false, Enum.KeyCode.T)
    ContextActionService:BindAction("SellUnit",ClientController.ActionHandler, false, Enum.KeyCode.X)

    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.T then
            -- print("Pressed to T")
            PlayerService:TestExp()
        end

        if input.KeyCode == Enum.KeyCode.Space and not gp then
            if Humanoid then
                if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                    if jumpUsage >= 1 then
                        ClientController:PlayAnimation("DoubleJump")
                        jumpUsage -= 1

                        canJump = false
                        Humanoid.JumpHeight = 25
                        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping, true)
                        
                        task.delay(.1,function()
                            Humanoid:ChangeState(Enum.HumanoidStateType.Freefall, true)
                        end)
                    end
                end
            end
        end
    end)

    Humanoid.StateChanged:Connect(function(old, new)
        if Humanoid then
            if new == Enum.HumanoidStateType.Landed and jumpUsage <= 0 then
                Humanoid.JumpHeight = 0
                ClientController:PlayAnimation("Landing")
                jumpUsage = 1
                task.delay(debounceTime,function()
                    Humanoid.JumpHeight = 7.5
                end)
            end
        end
    end)


    local LastInputLog = os.clock()
    local TimeUntilSendToAFKWorld = 18

    UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
        LastInputLog = os.clock()
    end)

    RunService.Heartbeat:Connect(function(deltaTime)
        if (os.clock() - LastInputLog) >= (60*TimeUntilSendToAFKWorld) and (PlaceIds[game.PlaceId] == "Lobby" or PlaceIds[game.PlaceId] == "AFK") then -- 
            --  Send Request to move
            warn("10 SEC HAS PASSED SINCE THE LAST LOG")
            PlayerService:TeleportPlayerToAFK()
            LastInputLog = os.clock()
        end 
    end)

end

return ClientController