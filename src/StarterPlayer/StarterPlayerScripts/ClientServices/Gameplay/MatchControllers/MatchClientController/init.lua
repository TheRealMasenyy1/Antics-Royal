local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerController = require(script.PlayerController)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local TweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local ClientController = Knit.CreateController {
    Name = "MatchClientController",
}

local Camera = workspace.CurrentCamera
local MatchService;

-- Double jump settings
local canJump = true
local debounceTime = 0.5 -- Time between jumps
local PlayerObj;

function ClientController:KnitStart()
	local ProfileService = Knit.GetService("ProfileService")
    local loaded = false
	task.spawn(function()
		-- repeat
  --           task.wait()
  --           loaded = ProfileService:IsProfileReady():expect()
		-- 	print("Has the data loaded", loaded)
  --       until loaded
        PlayerObj = PlayerController.new(player)
    end)
end

return ClientController
