local ServerBuildManager = {}
local Network = require(game.ReplicatedStorage.Shared.Utility.Network)

ServerBuildManager.__index = ServerBuildManager

ServerBuildManager.Builds = {}

function ServerBuildManager:Init() 
	
	-- local cooldowns = {}
	-- Network:BindEvents({
	-- 	["AttemptUnitPlacement"] = function(Player,Unit,Frame)
	-- 		if not cooldowns[Player] then
	-- 			cooldowns[Player] = 0 
	-- 		end
	-- 		if tick() - cooldowns[Player] < .5 then
	-- 			return
	-- 		end
	-- 		cooldowns[Player] = tick()
	-- 		--print(Player,Unit,Frame)
	-- 		ServerBuildManager:PlaceUnit(Unit,Frame,Player)
	-- 	end,
	-- })
end


function ServerBuildManager:PlaceUnit(Unit,Frame,Owner)
	local Pack = {
		Model = game.ReplicatedStorage.Units:FindFirstChild(Unit):Clone();
		Location = Frame;
		Owner = Owner;
		TimePlace = workspace:GetServerTimeNow();
		Info = {}; -- stats of unit and stuff for server if needed
	};
	
	
	Pack.Model.Parent = workspace.Gameplay.Mobs
	Pack.Model:PivotTo(Frame);
	
	setmetatable(ServerBuildManager,Pack)
	Network:FireAllClients("PlaceUnit",Unit,Pack.Model)
end



return ServerBuildManager
