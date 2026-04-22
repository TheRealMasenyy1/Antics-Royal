local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local BannerNotify = require(ReplicatedStorage.Shared.Utility.BannerNotificationModule)
local RemoteManager = require(ReplicatedStorage.RemoteManager)

return function (context, forPlayer)
	local Teams = {
		["Blue"] = workspace.Gameplay.Blue.Spawner.CFrame,
		["Red"] = workspace.Gameplay.Red.Spawner.CFrame
	}
	
	for Team, CFRAME in Teams do
		for i = 1, 1 do
			RemoteManager:Fire("SpawnNpc",Team, "Thorfinn", CFRAME + Vector3.new(0,0, 2 * i))
		end
	end
    return "Match has been started"
end 
