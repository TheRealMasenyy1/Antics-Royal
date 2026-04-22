--!nocheck

local Input= {}
--//Dependencies
local UIS = game:GetService("UserInputService")
local RepStorage = game:GetService("ReplicatedStorage")
local Network = require(game.ReplicatedStorage.Shared.Utility.Network)
local Toolbar = require(script.Parent.UI.Toolbar)

--//Declarations
local Player = game.Players.LocalPlayer
local InputLocked = false
local BuildManager = require(RepStorage.Shared.BuildManager);

Input.__index = Input
Input.AcceptedInputs = {
	[Enum.KeyCode.One] = "SelectUnit";
	[Enum.KeyCode.Two] = "SelectUnit";
	[Enum.KeyCode.Three] = "SelectUnit";
	[Enum.KeyCode.Four] = "SelectUnit";
	[Enum.KeyCode.Five] = "SelectUnit";

	[Enum.KeyCode.DPadLeft] = "CycleUnitLeft";
	[Enum.KeyCode.DPadRight] = "CycleUnitRight";


	
	[Enum.UserInputType.MouseButton1] = "LockInUnit";
	[Enum.KeyCode.Q] = "RotateLeft";
	[Enum.KeyCode.E] = "RotateRight";
	[Enum.KeyCode.ButtonL1] = "RotateLeftController";
	[Enum.KeyCode.ButtonR1] = "RotateRightController";
	
	[Enum.UserInputType.MouseButton2] = "CancelBuild";
	[Enum.KeyCode.ButtonB] = "CancelBuild";
	[Enum.KeyCode.ButtonR2] = "LockInUnit";
}


Input.EndSignals = {
	[Enum.KeyCode.ButtonL1] = "RotateLeftController";
	[Enum.KeyCode.ButtonR1] = "RotateRightController";

	--[Enum.KeyCode.ButtonL1] = "StopLeftRotate";
}
Input.DoubleTaps = {
	
}

Input.Initialize = function(PlayerObject)

	local InputObject = {}
	
	Input.PlayerObject = PlayerObject
	UIS.InputBegan:Connect(function(inp,proc)
		if proc then 
			return
		end
		local InputTypeFunction = Input.AcceptedInputs[inp.UserInputType];
		local InputKeyCodeFunction = Input.AcceptedInputs[inp.KeyCode]
		local InputDoubleTapFunction = Input.DoubleTaps[inp.KeyCode]

		if InputLocked == false then -- not proc and 
			if InputTypeFunction then
				local Args = {}
				Input[InputTypeFunction](Input,unpack(Args))
			elseif InputKeyCodeFunction then
				local Args = {inp.KeyCode.Name}
				Input[InputKeyCodeFunction](Input,unpack(Args))			
			elseif InputDoubleTapFunction then
				if tick() - InputDoubleTapFunction[1] < 0.25 then
					local Args = {}
					Input[InputDoubleTapFunction[2]](Input, unpack(Args))
				else
					InputDoubleTapFunction[1] = tick()
				end
			end
		end
	--	Network:FireServer("UpdatePreviousInput")
	end)

	UIS.InputEnded:Connect(function(inp,proc)
		local InputKeyCodeFunction = Input.EndSignals[inp.KeyCode]
		local InputTypeFunction = Input.AcceptedInputs[inp.UserInputType];

		if not proc and InputLocked == false then
			if InputKeyCodeFunction then
				local Args = {}
				Input[InputKeyCodeFunction](Input,unpack(Args))
			elseif InputTypeFunction then
				local Args = {}
				Input[InputTypeFunction](Input,unpack(Args))
				
			end
		end
	end)
	
	UIS.TouchTap:Connect(function(inp,proc)
		if not proc then
			if BuildManager:IsActive() then
				--print("tapped")

				BuildManager:LockInUnit()
			end

		end
	end)

	setmetatable(InputObject,Input)
		
		
	local function ToggleConsoleUI(State)
		for i,v in pairs(Player.PlayerGui.Main:GetDescendants()) do
			if v.Name == "Console" then
				v.Visible = State
			elseif v.Name == "PC" then
				v.Visible = not State
			end
		end
	end	
		
	UIS.GamepadConnected:Connect(function()
		ToggleConsoleUI(true)
	end)
	UIS.GamepadDisconnected:Connect(function()
		ToggleConsoleUI(false)
	end)	
	
	if UIS.GamepadEnabled then
		ToggleConsoleUI(true)
	end
		
	Network:BindEvents({
		["WaitOnMouse"] = function(Args)
			return Input:WaitOnMouse(Args,true);
		end,
		["WaitOnKey"] = function(Args)
			if Args.Mouse then
				return Input:WaitOnMouse(Args,true);
			else
				return Input:WaitOnKey(Args,true);
			end
		end,
		["GetMouseInfo"] = function()
			return Input:GetMouseData(true);
		end,

	})
	BuildManager:Init(PlayerObject)
	return InputObject,"Success"
end

local Step = 0;
function Input:CycleUnitLeft()
	if BuildManager:IsActive() then
		Step -=1 
	else
		Step = 1
	end
	if Step < 1 then
		Step = #self.PlayerObject.Units;
	end
	Input["SelectUnit" .. Step](Input);
	
end

function Input:CycleUnitRight()
	if BuildManager:IsActive() then
		Step +=1 
	else
		Step = #self.PlayerObject.Units;

	end
	if Step > #self.PlayerObject.Units then
		Step = 1;
	end
	Input["SelectUnit" .. Step](Input);

end

function Input:SelectUnit(Input)
	local Unit = "Leaf Ninja"
	local ToNumber = {
		["One"] = 1,
		["Two"] = 2,
		["Three"] = 3,
		["Four"] = 4,
		["Five"] = 5,
	}

	-- local Units = {
	-- 	{Level = 1; Unit = "Leaf Ninja"};
	-- 	{Level = 1; Unit = "Pirate King"};	
	-- 	{Level = 1; Unit = "Legendary Berserker"};	
	-- 	{Level = 1; Unit = "Lost Ninja"};	
	-- 	{Level = 1; Unit = "Curse King"};	
	-- }

	local Units = self.PlayerObject.Units

	local Key = ToNumber[Input]
	BuildManager:ChangeUnit(Units[Key].Unit)
end

function Input:RotateLeft()
	repeat
		BuildManager:IncrementRotate(3)
		task.wait()
	until not UIS:IsKeyDown(Enum.KeyCode.Q) and not UIS:IsKeyDown(Enum.KeyCode.ButtonL1)
end
function Input:RotateLeftController()
	if not self.LeftRotate then
		self.LeftRotate = true;
	else
		self.LeftRotate = nil;
	end
	repeat
		BuildManager:IncrementRotate(3)
		task.wait()
	until not self.LeftRotate
end

function Input:RotateRight()
	repeat
		BuildManager:IncrementRotate(-3)
		task.wait()
	until not UIS:IsKeyDown(Enum.KeyCode.E) and not UIS:IsKeyDown(Enum.KeyCode.ButtonR1)
end


function Input:RotateRightController()
	if not self.RightRotate then
		self.RightRotate = true;
	else
		self.RightRotate = nil;
	end
	repeat
		BuildManager:IncrementRotate(-3)
		task.wait()
	until not self.RightRotate
end

function Input:CancelBuild()
	BuildManager:EndBuildSession()
end

function Input:ToggleBuildMode()
	BuildManager:ToggleBuildMode()
end

function Input:LockInUnit()
	BuildManager:LockInUnit()
end

--@function WaitOnKey
--@desc Waits for a specified key press state and returns the mouse hit point.
--@param Args table A table containing function arguments.
--@field Button string The name of the key/button to wait for.
--@field Tap boolean If true, waits for a key tap (press and release). Default is false.
--@field State boolean The desired key state (pressed or not pressed). Default is false.
--@return table A table containing the mouse hit point under the 'Hit' field.
function Input:WaitOnKey(Args,ServerReq)
	local Button = Args.Button;

	if not Button then
		return warn("Attempt to wait on nonexistent key");
	end;

	local Tap = Args.Tap or false
	local State = Args.State or false;

	if Tap then
		repeat wait() until UIS:IsKeyDown(Button) == not State
	end

	repeat wait() until UIS:IsKeyDown(Button) == State;
	local Package = {Hit = Player:GetMouse().Hit}
	if ServerReq then
		Network:FireServer("PingKeyWait",Package)
	end
	return 
end

--@function GetMouseData
--@desc Retrieves information about the mouse, including hit point and target.
--@return table A table containing mouse data with 'Hit' and 'Target' fields.
function Input:GetMouseData(ServerReq)
	local Mouse = Player:GetMouse()
	local Package = {
		Hit = Mouse.Hit;
		Target = Mouse.Target;
		Camera = workspace.CurrentCamera.CFrame;
	}

	if ServerReq then
		Network:FireServer("PingMouseInfoReturn", Package)
	end

	return Package
end

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {workspace} -- livingfolder
rayParams.FilterType = Enum.RaycastFilterType.Include

function Input:CastMouseHit()
	local Mouse = Player:GetMouse()

	local rayResult = workspace:Raycast(Mouse.UnitRay.Origin, Mouse.UnitRay.Direction * 250, rayParams)
	local hitPart = rayResult and rayResult.Instance

	return {
		Hit = hitPart
	}
end


--@function WaitOnMouse
--@desc Waits for a specified mouse button condition to be met.
--@param Args table A table containing function arguments.
--@field Button Enum.UserInputType (Optional) The mouse button to wait for. Default is MouseButton1.
--@field Condition boolean or string (Optional) The desired mouse button condition. If "Click", waits for a click event. Default is false.
function Input:WaitOnMouse(Args,ServerReq)
	local Button = Args.Button or Enum.UserInputType.MouseButton1
	local Condition = Args.Condition or false
	if Condition == "Click" then
		self:WaitOnMouse({Button = Args.Button})
		Condition = true;
	end
	repeat wait() until UIS:IsMouseButtonPressed(Button) == Condition
	if ServerReq then
		Network:FireServer("PingMouseWait")
	end
	return
end

function Input:LockControls()
	InputLocked = true;
end
function Input:UnlockControls()
	InputLocked = false;
end
return Input
