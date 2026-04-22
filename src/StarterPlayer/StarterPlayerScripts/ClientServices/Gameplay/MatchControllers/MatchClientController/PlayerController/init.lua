local PlayerClass = {}
--print("playercontrolelr required")
local Network = require(game.ReplicatedStorage.Shared.Utility.Network)
-- local AssetLibrary = require(game.ReplicatedStorage.Shared.Utility.AssetLibrary)

PlayerClass.__index = PlayerClass
local VerifiedInfo = {}
PlayerClass.Object = nil;
PlayerClass.new = function(Player)
	--//Object Creation
	--print("Making player obj")
	local PlayerObject = {}
	PlayerObject.Player = Player
	
	--[[repeat task.wait() until workspace:GetAttribute("Region") 
	
	local DataPacket;
	local Success,result
	repeat
		Success, result = pcall(function()
			PlayerObject.Data = Network:InvokeServer("RequestData")
		end)
		task.wait(1)
	until Success]]
	
	
	
	PlayerObject.RegistrationInfo = {}
	PlayerClass.Object = PlayerObject
	PlayerObject.PlayerGui = Player.PlayerGui
	setmetatable(PlayerObject,PlayerClass)
	
	PlayerObject:InitUI(PlayerObject)
	
	repeat wait() until Player.Character
	PlayerObject.Character = Player.Character
		
	--//Input requires character so we will put it post character declaration
	PlayerObject.Input = require(script.Input).Initialize(PlayerObject)
	
	--[[local S--printingAnimation = AssetLibrary:GetAssetByPosition(1, "Animations", {"Movement", "S--printing"})
	PlayerObject.MobilityInfo.CachedAnimations['S--printing'] = AssetLibrary:LoadAnimation(PlayerObject.Character.Humanoid, S--printingAnimation)]]

	local Humanoid = Player.Character:WaitForChild('Humanoid')
	Humanoid.Died:Connect(function()
		
	end)
	PlayerObject.PrimeFunc()
	--Network:FireServer("LoadingComplete")	
	
	--[[local ExperienceNotificationService = game:GetService("ExperienceNotificationService")

	-- Function to check whether the player can be prompted to enable notifications
	local function canPromptOptIn()
		local success, canPrompt = pcall(function()
			return ExperienceNotificationService:CanPromptOptInAsync()
		end)
		return success and canPrompt
	end

	local canPrompt = canPromptOptIn()
	if canPrompt then
		local success, errorMessage = pcall(function()
			ExperienceNotificationService:PromptOptIn()
		end)
	end

	-- Listen to opt-in prompt closed event 
	ExperienceNotificationService.OptInPromptClosed:Connect(function()
		--print("Opt-in prompt closed")
	end)]]

	-- for i,v in pairs(game.ReplicatedStorage.Modules.GameModules.Client:GetChildren()) do
	-- 	if require(v)["Init"] then
	-- 		require(v):Init(PlayerObject)
	-- 	end
	-- end
	
	--print("ObjectMAde")
	return PlayerObject
end

function PlayerClass:InitUI()
	--//UI Initialization
	self.UI,self.PrimeFunc = require(script.UI):Initialize(self)
end

function PlayerClass:GetObject()
	if not PlayerClass.Object then
		repeat wait() until PlayerClass.Object
	end
	return PlayerClass.Object
end

local Init = false
Network:BindEvents({
	["UpdateRegistrationInfo"] = function(Info)
		
	end,
	["SetMaxWalkSpeed"] = function(Cap)
		local PlayerObject = PlayerClass:GetObject()
		PlayerObject.Input.Movement:SetMaxWalkSpeed(Cap) 
	end,
	
})

return PlayerClass
