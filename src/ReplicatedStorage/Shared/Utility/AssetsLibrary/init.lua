--//Product Of Lone Engine
local AssetLibrary = {}
AssetLibrary.__index = AssetLibrary

AssetLibrary.Assets = {
	Animations = {};
	Sounds = {
		General = {
			Tap = 10406059946;			
		};
	};
	Images = {
		
		
		
	};
};
AssetLibrary.Instances = {}

function AssetLibrary:Initialize()
	local function PrimeTable(Table,Type)
		local Result = nil;
		for i,v in pairs(Table) do
			if type(v) == "table" then
				Result= PrimeTable(v,Type); 
			elseif type(v) == "number" then
				local Inst = Instance.new(Type)
				Inst[Type .. "Id"] = "rbxassetid://" .. v
				AssetLibrary.Instances[tostring(v)] = Inst
			end
		end
		return Result
	end
	PrimeTable(AssetLibrary.Assets.Animations,"Animation")
	PrimeTable(AssetLibrary.Assets.Sounds,"Sound")
end

function AssetLibrary:Preload()
	local Ids = {}
	local function SearchTable(Table,Type)
		local Result = nil;
		for i,v in pairs(Table) do
			if type(v) == "table" then
				Result= SearchTable(v,Type); 
			elseif type(v) == "number" then
				local Inst = Instance.new(Type)
				Inst[Type .. "Id"] = "rbxassetid://" .. v
				AssetLibrary.Instances[tostring(v)] = Inst
				table.insert(Ids,Inst)
			end
		end
		return Result
	end
	SearchTable(AssetLibrary.Assets.Animations,"Animation")
	SearchTable(AssetLibrary.Assets.Sounds,"Sound")
	local ContentProvider = game:GetService("ContentProvider")
	for i,v in pairs(game.StarterGui.ScreenGui:GetDescendants()) do
		if i%15 == 0 then
			wait()
		end
		if v:IsA("ImageButton") or v:IsA("ImageLabel") then
			table.insert(Ids,v);
		end
	end
	--local LoadingScreen = game.Players.LocalPlayer.PlayerGui.Loading
	local Increment = #Ids/8
	local StepTimeOut = 3;
	for i = Increment,#Ids,Increment do
		local Tab = {}
		for x = 1,Increment do
			table.insert(Tab,Ids[(i-x) + 1])
		end
		
		local Start = tick()
		local Done = false;
		
		coroutine.wrap(function()
			ContentProvider:PreloadAsync(Tab);
			Done = true;
			
		end)()
		repeat wait() until tick() - Start >= StepTimeOut or Done == true
		--LoadingScreen.Frame.AssetCount.Text  =("(" .. tostring(i) .. "/" .. tostring(#Ids) .. ")")
	end
	
	return true
	
end


function AssetLibrary:GetAssetIDByName(Name,Directory,Path)
	if not Name then
		return warn("Asset Acquisition Error: Name not provided")
	end
	local Start = self.Assets
	if Directory then
		Start = self.Assets[Directory]
		if not Start then
			return warn("Asset Acquisition Error: Attempt to access non-existent library")
		end
	end
	if Path then
		if type(Path) =="string" then
			Path = {Path}
		end
		for i,v in pairs(Path) do
			Start = Start[v];
		end
	end
	local Found = nil;
	local function SearchTable(Table)
		local Result = nil;
		for i,v in pairs(Table) do
			if type(v) == "table" then
				Result= SearchTable(v,Name); 
			elseif i == Name then
				Result = v
				break

			end
		end
		return Result
	end
	for i,v in pairs(Start) do
		if type(v) == 'table' then
			Found = SearchTable(v);
		elseif i == Name then
			Found = v
		end
		if Found then
			break;
		end
	end	

	return Found;
end

function AssetLibrary:GetAssetByName(Name,Directory,Path)
	local Found = self:GetAssetIDByName(Name,Directory,Path)
	local AssetInstance = self:GetAssetInstanceById(Found);

	return AssetInstance;
end

function AssetLibrary:GetAssetByPosition(Position,Directory,Path)
	local Start = self.Assets[Directory]
	if type(Path) =="string" then
		Path = {Path}
	end
	for i,v in pairs(Path) do
		Start = Start[v];
	end
	return Start[Position];
end

function AssetLibrary:GetAsset(Directory,Path)
	local Start = self.Assets[Directory]
	if type(Path) =="string" then
		Path = {Path}
	end
	for i,v in pairs(Path) do
		Start = Start[v];
	end
	return Start;
end

function AssetLibrary:GetAssetInstanceById(id: number)
	id = id or 0
	local Asset= AssetLibrary.Instances[tostring(id)]

	if not Asset then
		return warn("Asset not found")
	else
		return Asset
	end
end
return AssetLibrary
