--// Services
local BadgeService = game:GetService("BadgeService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Core
local Knit = require(ReplicatedStorage.Packages.Knit)
local ProfileService = Knit.CreateService{Name = "ProfileService", Client = {}}

--// Dependencies
local ULID = require(ReplicatedStorage.Shared.ULID)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local ProfileServiceModule = require(ReplicatedStorage.Shared.ProfileService)
local PurchaseIds = require(ReplicatedStorage.SharedPackage.PurchaseIds)
local FlagService
local IntermissionService;

--// Constants
local ProfileTemplate = {
	CmdrGroup = 0,
	Coins = 0,
	Gems = 100,
	Exp = 0,
	MaxExp = 50,
	Level = 1,
	MaxUnitsInventory = 100,

	TraitGems = 0,-- Used to roll traits
	RankGems = 0, -- Used to roll ranks
	HammerGems = 0, -- Ussed to nail down the stats

	IsBanned = false,
	LevelMilestone = {},
	Presets = {
		[1] = {
			TeamName = "Team One",
			Units = {
			}
		},
		[2] = {
			TeamName = "Team Two",
			Units = {
			}
		},
		[3] = {
			TeamName = "Team Three",
			Units = {
			},
		},
		[4] = {
			TeamName = "Team Four",
			Units = {
			}
		},
		[5] = {
			TeamName = "Team Five",
			Units = {
			}
		},
	};

	Worlds = {
		[1] = { -- Leaf Village
			Chapter = 1;
			MaxChapters = 6;
			Chapters = {
				[1] = {
					BestTime = 0,
					TotalCleared = 0,
					Cleared = false,
				},
				[2] = {
					BestTime = 0,
					TotalCleared = 0,
					Cleared = false,
				},
				[3] = {
					BestTime = 0,
					TotalCleared = 0,
					Cleared = false,
				},
				[4] = {
					BestTime = 0,
					TotalCleared = 0,
					Cleared = false,
				},
				[5] = {
					BestTime = 0,
					TotalCleared = 0,
					Cleared = false,
				},
				[6] = {
					BestTime = 0,
					TotalCleared = 0,
					Cleared = false,
				},
			},
			Cleared = false;
			Unlocked = true;
		},

		[2] = { -- Ruined City
			Chapter = 1;
			MaxChapters = 6;
			Chapters = {
				[1] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[2] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[3] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[4] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[5] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[6] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
			},
			Cleared = false;
			Unlocked = false;
		},

		[3] = { -- Ruined City
			Chapter = 1;
			MaxChapters = 6;
			Chapters = {
				[1] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[2] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[3] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[4] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[5] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[6] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
			},
			Cleared = false;
			Unlocked = false;
		},

		[4] = { -- Royal Village
			Chapter = 1;
			MaxChapters = 6;
			Chapters = {
				[1] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[2] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[3] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[4] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[5] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
				[6] = {
					BestTime = 0,
					TotalCleared = 0;
					Cleared = false,
				},
			},
			Cleared = false;
			Unlocked = false;
		}
	};

	Inventory = {
		Units = {

		},
		Items = {

		},

		Materials = {

		},

		Other = {
		},

		Emotes = {
			["Take The L Emote"] = true,
		},
	},

	Equipped = {},

	SummonPity = {
		Legendary = 0,
		Mythic = 0
	},

	Settings = {
		Music = true,
		SFX = true,
		TradeRequests = 1, -- [1: ON, 2: FRIENDS, 0: OFF]
		HideStats = false,
		SkipCutscene = false,
		AutoSell = {
			Rare = false,
			Epic = false,
			Legendary = false,
		},
		Graphics = {
            Current = 3, -- 1 = Low, 2 = Medium, 3 = High
			Destruction = 3, -- 1 = Off, 2 = Medium, 3 = High
            GlobalShadows = true,
            ShadowSoftness = .02
		}
	},

	RedeemedCodes = {}, -- Store all the used code here
	InGamePurchases = {},
	OwnedGamepasses = {},
	ActiveEffects = {},
	Statistics = {
		TotalWins = 0,
		TotalTimeInGame = 0,
		TotalSummons = 0,
		TotalCoins = 0,
		LastLogin = 0,
		Badges = {},
		StartingDayDailyLogin = 0,
		LastClaimedDayDailyLogin = 0,
		LastSummonHour = 0,
		GameInfo = {
            TotalKills = 0,
			TotalBossKilled = 0,
            TotalDeaths = 0, -- Lost
            TotalDamageDealt = 0,
			TotalWaves = 0,
		}
	},

	Quests = {
		DailyStartedAt = 0,
		WeeklyStartedAt = 0,
		WeeklyList = {}, -- Just generate one later
		DailyList = {}
	},

	AdminActions = {},

	Flags = {
		IsFirstTimePlayer = true,
		IsFirstTimeSummon = true,
		Tutorial = false, --! Or just set it to true
		JoinedGroup = false,
		IsPremium = false,
		IsVip = false,
	},

	Battlepass = {
		Level = 1, -- Every level unlock 1 free and premium
		Exp = 0,
		Season = 1,
		MaxExp = 100,
		Rewards = {
			Free = {},
			Premium = {}
		},
	},
}

local ProfileStore = ProfileServiceModule.GetProfileStore(
	"PlayerData.1", ProfileTemplate
)

--// Variables
local profiles = {}
local expectedProfileRelease = {}
local LobbyService;

--// Knit Events
ProfileService.Client.OnProfileUpdate = Knit.CreateSignal()
ProfileService.OnProfileUpdate = Signal.new()

--// Functions
local function deepCopy(t)
	local copy = table.clone(t)
	for k, v in copy do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		end
	end
	return copy
end

local function valueByPath(action, dataTable, path, newValue)
	local pathComponents = path:split(".")

	-- Navigate through the table using the path components
	local currentTable = dataTable
	for i = 1, #pathComponents do
		local component = pathComponents[i]
		if i == #pathComponents then
			-- If this is the last component in the path, take action on the value
			if action == "GET" then
				return currentTable[component]
			elseif action == "SET" then
				currentTable[component] = newValue
			end
		else
			-- Otherwise, move to the next nested table
			currentTable = currentTable[component]
		end
	end
end

local function processGlobalUpdate(player, payload)
	local itemsSortedByPath = {}
	for _, item in payload do
		if itemsSortedByPath[item.Path] == nil then
			itemsSortedByPath[item.Path] = {}
		end
		table.insert(itemsSortedByPath[item.Path], item)
	end

	for path, items in itemsSortedByPath do
		local newPath = path:split(".")
		table.remove(newPath, 1)
		newPath = table.concat(newPath, ".")

		ProfileService:Update(player, path:split(".")[1], function(data)
			for _, item in items do
				local newValue
				if #newPath == 0 then
					newValue = data
				else
					newValue = valueByPath("GET", data, newPath)
				end

				if item.Type == "Increment" then
					newValue += item.Value
				elseif item.Type == "Insert" then
					table.insert(newValue, item.Value)
				elseif item.Type == "Set" then
					newValue = item.Value
				end

				if #newPath == 0 then
					data = newValue
				else
					valueByPath("SET", data, newPath, newValue)
				end
			end
			return data
		end)
	end
	if ProfileService:Get(player, "IsBanned") == true then
		player:Kick("MANGOCHEAT // You have been permanently banned.")
	end
end

function registerPlayer(player)
	local profile = ProfileStore:LoadProfileAsync(
		tostring(player.UserId),
		"ForceLoad"
	)

	if profile ~= nil then
		profile:AddUserId(player.UserId)

		if profile.Data.Flags ~= nil and profile.Data.Flags.CheckedForFancyWormBug ~= true then
			profile.Data.Inventory.Units = TableUtil.Filter(profile.Data.Inventory.Units, function(unit)
				return unit.Unit ~= "FancyWorm"
			end)
			profile.Data.Equipped = TableUtil.Filter(profile.Data.Equipped, function(unit)
				return unit.Unit ~= "FancyWorm"
			end)
			profile.Data.Flags.CheckedForFancyWormBug = true
		end

		if game.PlaceId == 15485926725 then -- Testing Lobby
			if profile.Data.IsBanned == true then
				profile.Data.IsBanned = false
			end
		end

		profile:Reconcile()

		if MarketplaceService:UserOwnsGamePassAsync(player.UserId,PurchaseIds.Gamepasses.VIP) then
			local IsVIP = Instance.new("BoolValue")
			IsVIP.Name = "IsVIP"
			IsVIP.Parent = player
			IsVIP.Value = true
		end

		if profile.Data.Flags.IsFirstTimePlayer then
			IntermissionService.Client.ShowLoadingScreen:Fire(player,70814776537237, 1) 
			LobbyService:TeleportToPrivateServer({player},88664399104255)
		else
			warn("This is not the first time the player joins")
		end

		if profile.Data.Flags.Tutorial then
			task.spawn(function()
				repeat task.wait() until player.Character:FindFirstChild("Humanoid")
				LobbyService.Client.FirstTimeJoined:Fire(player)
			end)
		end

		if profile.Data.Flags ~= nil and profile.Data.Flags.IsFirstTimePlayer == false and profile.Data.Flags.NeedsToWatchUnderworldEventCutscene == false and profile.Data.Flags.HasWatchedUnderworldEventCutscene == false then
			profile.Data.Flags.NeedsToWatchUnderworldEventCutscene = true
		end
		profile:ListenToRelease(function()
			profiles[player] = nil
			if expectedProfileRelease[player] ~= nil then
				expectedProfileRelease[player] = nil
			else
				player:Kick("\nYour player data might've been loaded on another Roblox server.\nNo data was corrupted during this process, you may rejoin.")
			end
		end)

		if player:IsDescendantOf(Players) == true then
			profiles[player] = profile

			for _, update in profile.GlobalUpdates:GetActiveUpdates() do
				profile.GlobalUpdates:LockActiveUpdate(update[1])
			end
			for _, update in profile.GlobalUpdates:GetLockedUpdates() do
				processGlobalUpdate(player, update[2])
				profile.GlobalUpdates:ClearLockedUpdate(update[1])
			end

			profile.GlobalUpdates:ListenToNewActiveUpdate(function(update_id)
				profile.GlobalUpdates:LockActiveUpdate(update_id)
			end)
			profile.GlobalUpdates:ListenToNewLockedUpdate(function(update_id, update_data)
				processGlobalUpdate(player, update_data)
				profile.GlobalUpdates:ClearLockedUpdate(update_id)
			end)
		else
			profile:Release()
		end
	else
		player:Kick("\nYour player data could not be loaded due to unknown reasons.\nNo data was corrupted during this process, you may rejoin.")
	end
end

local function getData(player, dataName)
	if player == nil or dataName == nil then
		return
	end
	if profiles[player] == nil or profiles[player]["Data"] == nil then
		return
	end

	local data = profiles[player]["Data"][dataName]
	if data == nil then
		return
	end

	if type(data) == "table" then
		return deepCopy(data)
	else
		return data
	end
end

local function onProfileReady(player, isClient)
	local promise; promise = Promise.new(function(resolve, reject)
		if ProfileService:IsProfileReady(player) == true then
			resolve()
		else
			repeat task.wait() until player.Parent ~= Players or ProfileService:IsProfileReady(player) == true
			if player.Parent == Players then
				resolve(if isClient then nil else ProfileService:GetProfile(player))
			else
				promise:cancel()
			end
		end
	end)
	return promise
end

--== Server ==--

function ProfileService:Get(...)
	return getData(...)
end

function ProfileService:IsProfileReady(player)
	return profiles[player] ~= nil and profiles[player]["Data"] ~= nil
end

function ProfileService:OnProfileReady(...)
	return onProfileReady(...)
end

function ProfileService:Reset(player) --! Resets userData
	if not self:IsProfileReady(player) then
		return
	end

	profiles[player].Data = ProfileTemplate
	player:Kick()
end

function ProfileService:Update(player, dataName, updateFunction)
	if not self:IsProfileReady(player) then
		return warn("Profile isn't in the server", profiles)
	end

	profiles[player].Data[dataName] = updateFunction(profiles[player].Data[dataName])

	local value = profiles[player].Data[dataName]
	--self.OnProfileUpdate:Fire(player, dataName, value)
	--self.Client.OnProfileUpdate:Fire(player, dataName, value)
end

function ProfileService:GlobalUpdate(userId)
	local payload = {
		Data = {}
	}

	function payload:Increment(dataPath, value) -- Can only be used on numbers
		table.insert(self.Data, {
			Type = "Increment",
			Path = dataPath,
			Value = value
		})
	end
	function payload:Insert(dataPath, value) -- Can only be used on tables
		table.insert(self.Data, {
			Type = "Insert",
			Path = dataPath,
			Value = value
		})
	end
	function payload:Set(dataPath, value) -- Can be used on any value
		table.insert(self.Data, {
			Type = "Set",
			Path = dataPath,
			Value = value
		})
	end
	function payload:Publish()
		ProfileStore:GlobalUpdateProfileAsync(tostring(userId), function(global_updates)
			global_updates:AddActiveUpdate(self.Data)
		end)
	end

	return payload
end

function ProfileService:GetProfile(player)
	if self:IsProfileReady(player) then
		return deepCopy(profiles[player].Data)
	end
end

function ProfileService:ViewProfileAsync(userId)
	return ProfileStore:ViewProfileAsync(userId)
end

-- In most cases, this should never be used unless REQUIRED to force change data (this will kick the player from any session!)
-- look into using ProfileService:GlobalUpdate() and ProfileService:ViewProfileAsync()!
function ProfileService:LoadProfileAsync(userId)
	return ProfileStore:LoadProfileAsync(userId)
end

--== Client ==--

function ProfileService.Client:Get(...)
	return getData(...)
end

function ProfileService.Client:IsProfileReady(player)
	return profiles[player] ~= nil and profiles[player]["Data"] ~= nil
end

function ProfileService.Client:OnProfileReady(player)
	onProfileReady(player, true):expect()
	return
end

function ProfileService:AwardBadge(player, badgeId)
	if self:IsProfileReady(player) ~= true then
		self:OnProfileReady(player):await()
	end
	if not player:IsDescendantOf(game) or self:IsProfileReady(player) ~= true then
		return
	end

	if table.find(self:Get(player, "Badges"), badgeId) ~= nil then
		return
	end

	Promise.new(function()
		if not BadgeService:UserHasBadgeAsync(player.UserId, badgeId) then
			BadgeService:AwardBadge(player.UserId, badgeId)
			self:Update(player, "Badges", function(badges)
				table.insert(badges, badgeId)
				return badges
			end)
		end
	end)
end

function ProfileService:KnitStart()
	-- SERVICE REFERENCES
	-- FlagService = Knit.GetService("FlagService")
	local _ = pcall(function()
		IntermissionService = Knit.GetService("IntermissionService")
		LobbyService = Knit.GetService("LobbyService")
	end)

	for _, player in Players:GetPlayers() do
		registerPlayer(player)
	end
	Players.PlayerAdded:Connect(registerPlayer)

	Players.PlayerRemoving:Connect(function(player)
		warn("PLAYER HAS BEEN REMOVED HERE!!!")
		local profile = profiles[player]
		if profile ~= nil then
			task.wait()
			profile:Release()
			-- profiles[player] = nil
		end
	end)
end

return ProfileService
