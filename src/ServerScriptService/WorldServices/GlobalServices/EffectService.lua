--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Core
local Knit = require(ReplicatedStorage.Packages.Knit)
local EffectService = Knit.CreateService{Name = "EffectService", Client = {}}

--// Dependencies
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ProfileService

--// Constants
local BoostDurations = {
	["Luck Boost"] = 60 * 30,
	["Super Luck Boost"] = 60 * 30,
	-- ScrapBoost = 60 * 60
}

--// Variables
local pendingPlayerEffects = {}
local localPlayerEffects = {}
local PlayerService;

--// Knit Events
EffectService.Client.Effects = Knit.CreateProperty()

--// Functions
local function addToPlayerEffect(player, effect, duration)
	local playerEffects = localPlayerEffects[player] or {}
	playerEffects[effect] = playerEffects[effect] or {
		StartTime = os.time(),
		Duration = 0
	}
	playerEffects[effect].Duration += duration + 1

	pendingPlayerEffects[player][effect] = true
	localPlayerEffects[player] = playerEffects

	EffectService.Client.Effects:SetFor(player, localPlayerEffects[player]) --? Show Effect to the client
end

local function playerAdded(player)
	ProfileService:OnProfileReady(player):andThen(function(profile)
		localPlayerEffects[player] = {}
		pendingPlayerEffects[player] = {}
		for effect, value in profile.ActiveEffects do
			if value > 0 then
				addToPlayerEffect(player, effect, value)
			end
		end
	end)
end

local function initTimer()
	Promise.new(function()
		while true do
			task.wait(1)
			-- Player Effects
			for _, player in Players:GetPlayers() do
				if pendingPlayerEffects[player] == nil then
					continue
				end
			
				local playerEffects = localPlayerEffects[player] or {}
				for effect, value in playerEffects do
					if pendingPlayerEffects[player][effect] == true then
						-- Activate effect
						pendingPlayerEffects[player][effect] = false
					end

					if value.Duration - (os.time() - value.StartTime) <= 0 then
						-- Disable effect
						playerEffects[effect] = nil
						ProfileService:Update(player, "ActiveEffects", function(activeEffects)
							activeEffects[effect] = nil
							return activeEffects
						end)
						EffectService.Client.Effects:SetFor(player, playerEffects)
					end
				end
			end
		end
	end)
end

local function deepSearch(t, key_to_find)
	for key, value in pairs(t) do
		if value == key_to_find then -- value == key_to_find or
			return key, t, value
		end
		if typeof(value) == "table" then -- Original function always returned results of deepSearch here, but we should not return unless it is not nil.
			local a, b, c = deepSearch(value, key_to_find)
			if a then return a, b, c end
		end	
	end
	return nil
end

function EffectService.Client:ActivateBoost(player, boost)
	local Items = require(ReplicatedStorage.Shared.Items)
	local Item = Items.Items[boost] or Items.Materials[boost]
	local SimilarBoostExists = false
	if typeof(boost) ~= "string" then
		return
	end

	if BoostDurations[boost] == nil then
		return
	end
	
	local inventory = ProfileService:Get(player, "Inventory")
	local ActiveEffects = ProfileService:Get(player, "ActiveEffects")

	local _,PotionExists = deepSearch(inventory.Items, boost)

	if PotionExists and PotionExists.Amount > 0 then
		PlayerService:GiveItem(player,"Items",boost, -1)
		addToPlayerEffect(player, boost, BoostDurations[boost])
	end
end

function EffectService:IsPlayerEffectActive(player, effect)
	local playerEffects = localPlayerEffects[player] or {}
	return playerEffects[effect] ~= nil and playerEffects[effect].Duration > 0
end

function EffectService:KnitStart()
	-- SERVICE REFERENCES
	ProfileService = Knit.GetService("ProfileService")
	PlayerService = Knit.GetService("PlayerService")
	
	for _, player in Players:GetPlayers() do
		playerAdded(player)
	end
	Players.PlayerAdded:Connect(playerAdded)
	Players.PlayerRemoving:Connect(function(player)
		if pendingPlayerEffects[player] ~= nil then
			ProfileService:Update(player, "ActiveEffects", function(activeEffects)
				for effect, value in localPlayerEffects[player] do
					activeEffects[effect] = value.Duration - (os.time() - value.StartTime)
				end
				return activeEffects
			end)
			pendingPlayerEffects[player] = nil
		end
		if localPlayerEffects[player] ~= nil then
			localPlayerEffects[player] = nil
		end
	end)

	initTimer()
end

return EffectService