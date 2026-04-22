--!nocheck
local Player = game.Players.LocalPlayer
local UserInputService = game:GetService('UserInputService')
local PlayerGui = Player:WaitForChild('PlayerGui')
local UGS = UserSettings():GetService("UserGameSettings")
local PlayerController = require(script.Parent)
local Network = require(game.ReplicatedStorage.Shared.Utility.Network)


local Camera = {}
Camera.__index = Camera

Camera.Init = function()
	--//Mouse Locking System
	local CamObj = {}
	CamObj.isShiftlocked = false	
	
	return setmetatable(CamObj, Camera)
end

function Camera:SetLockOnTarget(Tar)
	self.LockOnTarget = Tar
end

function Camera:ToggleShiftLock(state: boolean?)
	local MouseGui = PlayerGui:WaitForChild('Mouse')
	local PlayerModule: any? = require(Player:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'))
	
	local Mouse: any? = Player:GetMouse()
	local Cameras: any? = PlayerModule:GetCameras()	
	
	local CameraController: any? = Cameras.activeCameraController
	local MouseLockController: any? = Cameras.activeMouseLockController
	
	local Character = Player.Character
	local Humanoid = Character:WaitForChild('Humanoid')
	
	self.isShiftlocked = state or not self.isShiftlocked
	
	
	Network:FireServer("UpdateShiftStatus",self.isShiftlocked )

	if self.isShiftlocked then
		CameraController:SetIsMouseLocked(true)
			
		if Humanoid.WalkSpeed > 16 then
			UGS.RotationType = Enum.RotationType.MovementRelative
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		else
			UGS.RotationType = Enum.RotationType.CameraRelative
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end	
		--Mouse.Icon = 'rbxasset://textures/MouseLockedCursor.png'
		UserInputService.MouseIconEnabled = false
		MouseGui.Icon.Visible = true
		MouseGui.Icon.Position = UDim2.fromScale(0.55, 0.475)
	else
		CameraController:SetIsMouseLocked(false)
		UserInputService.MouseIconEnabled = true
		MouseGui.Icon.Visible = false
	end
end

function Camera:RequireCameraShaker()
	return require(script.CameraShaker)
end

function Camera:GetCameraShake()
	return script.CameraShaker
end

function Camera:Shake(Aggressiveness)
	
	--//Use Randomizer thing
	
	
end

return Camera