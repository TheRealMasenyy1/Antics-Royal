local UI = {}

UI.__index = UI
local TweenService = game:GetService("TweenService")
function UI:Initialize(PlayerObject)
	PlayerObject.Player.PlayerGui:WaitForChild("Main")
	local UIObject = {
		DefaultHideablePositions = {};
		HiddenUI = {};
	}
	UIObject.Sounds = {}
	
	for i,v in pairs(UIObject.Sounds) do
		v.Parent = PlayerObject.Player.PlayerGui.Sounds
	end
	
	UI.Object = UIObject;
	UI.MainUI = PlayerObject.PlayerGui.Main

	for i,v in pairs(UI.MainUI:GetChildren()) do
		if v:GetAttribute("Hideable") then
			UIObject.DefaultHideablePositions[v] = v.Position;
		end
	end

	UI.PlayerObj = PlayerObject
	--//Bindable Setup
		
	local ClosedBind = Instance.new("BindableEvent")
	ClosedBind.Name = "ClosedBindable"
	ClosedBind.Parent = PlayerObject.Player.PlayerScripts.CustomListeners
	UI.UIClosed = ClosedBind.Event;
	UI.CloseBind = ClosedBind
	
	setmetatable(UIObject,UI)
	UI.Modules = {}
	function UI.PrimeUIModules()
		for i,v in pairs(script:GetChildren()) do
			if v:IsA("ModuleScript") then
				local Mod = require(v)
				UI.Modules[v.Name] = Mod
				if Mod["Init"] then
					local st = tick()
				
					Mod:Init(UI)
					
					--warn("Initiing " .. v.Name .. " took a total of ", tick() - st , " seconds")
				end
			end
		end
		for i,v in pairs(UIObject.MainUI:GetDescendants()) do
			if v:IsA("ImageButton") or v:IsA("TextButton") then
				UIObject:BindAnimation(v)
			end
		end
	end
	
	return UIObject,UI.PrimeUIModules
end

function UI:GetObject()
	return UI.Object;
end

function UI:Abbreviate(...)
	local AbModule = require(game.ReplicatedStorage.Modules.Utility.ValueFormatters)
	return AbModule.ToCommaSeparated(...)
end

local CreatedTweens = {};

function UI:BindAnimation(Button)
	
end

function UI:HoverIn()
	
end

function UI:HoverOut()
	
end

function UI:GetUI(UIName,SearchOrigin)
	SearchOrigin = SearchOrigin or self.MainUI
	
	return SearchOrigin:FindFirstChild(UIName)
end

local RunningTweens = {}
function UI:Open(GoalUI,Position)
	
	if not GoalUI then
		return 
	end
	if UI.CurrentOpen == GoalUI then
		self:Close(GoalUI)

		return
	elseif UI.CurrentOpen and UI.CurrentOpen ~= GoalUI then
		self:Close(UI.CurrentOpen)
	end
	UI.CurrentOpen = GoalUI;
	if Position then
		local Open =  UI.Object.Sounds.OpenSound
		Open:Play()
		if RunningTweens[GoalUI] then
			RunningTweens[GoalUI]:Cancel()
			RunningTweens[GoalUI] = nil
		end
		local Tween = TweenService:Create(GoalUI,TweenInfo.new(.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position = Position})
		Tween:Play()
		GoalUI.Visible = true;

		RunningTweens[GoalUI] = Tween
		--GoalUI:TweenPosition(Position,"Out","Bounce",1,true)
	end
	
end


function UI:LoadingInit()
	local Ids = require(script.Parent.IDS).LoadingIds
	self.TeleportFrames = {}
	local TeleportFrame = self.PlayerObj.Player.PlayerGui.HUD.Loading.Frame
	for i,v in pairs(Ids) do
		local Temp = TeleportFrame:WaitForChild("ImageLabel"):Clone()
		Temp.Name = tostring(i)
		Temp.Image = v
		Temp.Parent = TeleportFrame;
		Temp.Visible = false
		Temp.ZIndex = 500
		table.insert(self.TeleportFrames,Temp)
	end	
	TeleportFrame.ImageLabel:Destroy()
end

function UI:QueueLoad()
	local TeleportFrame = self.PlayerObj.Player.PlayerGui.HUD.Loading.Frame
	TeleportFrame.Visible = true
	TeleportFrame.Parent.Visible = true
	local Ready = false	
	for i,v in pairs(self.TeleportFrames) do
		v.Visible = true
		if i%3 == 0 then
			--wait();
			--game:GetService("RunService").RenderStepped:Wait()
		end
		task.wait(.01)
		--v.Visible = false;
	end
	TeleportFrame.BackgroundTransparency = 0;
	
	local function StopLoad()
		TeleportFrame.BackgroundTransparency = 1
		for i = #self.TeleportFrames,1,-1 do
			self.TeleportFrames[i].Visible = true;
			task.wait(.01)
			self.TeleportFrames[i].Visible = false;
		end
		
	end
	return StopLoad
end

function UI:Close(GoalUI,Position,Time)
	if not GoalUI then
		return 
	end
	
	if Position then
		
		if RunningTweens[GoalUI] then
			RunningTweens[GoalUI]:Cancel()
			RunningTweens[GoalUI] = nil
		end
		local Close =  UI.Object.Sounds.CloseSound
		Close:Play()
		local Tween = TweenService:Create(GoalUI,TweenInfo.new(Time or .5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Position = Position})
		Tween:Play()
		RunningTweens[GoalUI]= Tween
		Tween.Completed:Wait()
			GoalUI.Visible = false;
		--end)
		--wait(1)
	end
	self.CloseBind:Fire(GoalUI.Name)
	UI.CurrentOpen= nil;
end


function UI:PromptPurchase(UIName)
	
end

function UI:HideAllUI()
	for UiInstance,DefaultPosition in pairs(self.DefaultHideablePositions)  do
		self:HideUI(UiInstance);
	end
end

function UI:HideUI(Ui: GuiObject,GoalPosition: UDim2)
	if not self.HiddenUI[Ui] then
		self.HiddenUI[Ui] = true;
		GoalPosition =GoalPosition or Ui:GetAttribute("Goal") or UDim2.new(0,0,1.25,0) ;
		Ui:TweenPosition(GoalPosition,"Out","Back",.5,true);
		
	end
end

function UI:ShowUI(Ui:GuiObject, GoalPosition: UDim2)
	self.HiddenUI[Ui] = nil; 
	GoalPosition =GoalPosition or  self.DefaultHideablePositions[Ui];
	Ui:TweenPosition(GoalPosition,"Out","Bounce",1.5,true);
	
end

function UI:ShowAllUI()
	for UiInstance,DefaultPosition in pairs(self.DefaultHideablePositions)  do
		self:ShowUI(UiInstance);
	end
end

function UI:NotificationDisplay(Message,Duration)
	if not self.Modules or not self.Modules.Notifications then
		return
	end
	self.Modules.Notifications:Notify(Message,Duration)
end

return UI
