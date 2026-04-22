local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Units = require(ReplicatedStorage.SharedPackage.Units)
local Mutex = require(ReplicatedStorage.Shared.Utility.Mutex)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Grades = require(ReplicatedStorage.SharedPackage.Grades)

local SummonService = Knit.CreateService {
    Name = "SummonService",
}

SummonService.Client.SummonRotationUpdated = Knit.CreateSignal()

local ProfileService;
local GlobalDatastoreService;
local PlayerService;
local InventoryService;
local EffectService;

local Bucket = Random.new(4574835973 + os.time())

local BaseSummonChances = {
	[1] = 49.9, -- Rare
	[2] = 35, -- Epic
	[3] = 13, -- Legendary
	[4] = 1, -- Mythical 
	[5] = 0.1, -- Secret
}

local SellPriceOfRarity = {
	[1] = 100, -- Rare
	[2] = 250, -- Epic
	[3] = 1500, -- Legendary
	[4] = 2000, -- Mythical 
	[5] = 3500, -- Secret
}

local waitUntilReset = 60 * 60
local LastRotation; -- Last time the rotation was updated

local function obfuscateSeed(seed)
	local obfuscatedSeed = 0
	local multiplier = 541403248
	local adder = 842216239

	obfuscatedSeed = (seed * multiplier) + adder

	obfuscatedSeed = (obfuscatedSeed + (obfuscatedSeed % 100)) * 3.152

	local maxValue = 9007199254740991
	obfuscatedSeed = ((obfuscatedSeed % (2 * maxValue)) - maxValue)

	return obfuscatedSeed
end

local function getNextDayTimestamp()
    local dateTable = os.date("!*t", os.time())

    dateTable.day = 0
    dateTable.hour = dateTable.hour + 1
    dateTable.min = 0
    dateTable.sec = 0

    return os.time(dateTable)
end

local function getCurrentShipmentRotation()
	local dateTable = os.date("!*t", os.time())
	local seed = os.time{year=dateTable.year, month=dateTable.month, day=dateTable.day, hour=dateTable.hour}
	local shipmentBucket = Random.new(obfuscateSeed(seed))

	local unitsByRarity = {}
	local chosenUnits = {}
	
	for id, unit in Units do
		if unit.Summonable ~= true then
			continue
		end

		if unitsByRarity[unit.Rarity] == nil then
			unitsByRarity[unit.Rarity] = {}
		end
		table.insert(unitsByRarity[unit.Rarity], id)
	end

	for i = 1, #BaseSummonChances do
		chosenUnits[i] = unitsByRarity[i][shipmentBucket:NextInteger(1, #unitsByRarity[i])]
	end

	warn("CHOOSENUNITS: ", chosenUnits)
	return chosenUnits,math.max(getNextDayTimestamp() - os.time(), 0)
end

function SummonService:SelectItemByPercentage(items)
    local totalPercentage = 0
    for _, item in ipairs(items) do
        totalPercentage = totalPercentage + item.Percentage
    end
    
	local randomPercentage = math.random() * 100 
    local accumulatedPercentage = 0
    
    for _, item in ipairs(items) do
        accumulatedPercentage = accumulatedPercentage + item.Percentage
        if randomPercentage <= accumulatedPercentage then
            return item
        end
    end
    
    return nil
end


local function getCurrentUnixHour()
	return math.floor(os.time() / 3600)
end

function SummonService:GetUnit(UnitData, UnitHash : string)
	for pos, data in UnitData do
		if data.Hash == UnitHash then
            return data,pos
        end
	end
end

function SummonService.Client:Trait(player, UnitHash : string)
    local Unit_Stats = Grades.TraitsRarity
	local Inventory = ProfileService:Get(player,"Inventory")
	local Equipped = ProfileService:Get(player,"Equipped")
	local TitanCrystal = PlayerService:GetItem(player,"Items","Titan Crystal")
	local TraitGems = if typeof(TitanCrystal) == "table" then TitanCrystal.Amount else 0
	local AmountToUpgrade = 1
	local UnitInInventory,UnitInEquipped = SummonService:GetUnit(Inventory.Units,UnitHash), SummonService:GetUnit(Equipped,UnitHash)

	if TraitGems < AmountToUpgrade then return "Not enough Trait gems!" end

	local Trait = SummonService:SelectItemByPercentage(Unit_Stats)
	local TraitName = string.sub(Trait.Name,1, Trait.Name:len()-2)
	local TraitLevel = string.sub(Trait.Name,Trait.Name:len(),Trait.Name:len())

	if UnitInInventory then
		UnitInInventory.Traits.Name = TraitName
		UnitInInventory.Traits.Level = tonumber(TraitLevel)
	end

	if UnitInEquipped then
		UnitInEquipped.Traits.Name = TraitName
		UnitInEquipped.Traits.Level = tonumber(TraitLevel)
	end

	ProfileService:Update(player,"Inventory",function()
		return Inventory
	end)

	ProfileService:Update(player,"Equipped",function()
		return Equipped
	end)

	PlayerService:GiveItem(player,"Items","Titan Crystal",-AmountToUpgrade)
	InventoryService.Client.UnitEquipped:Fire(player,Equipped)

	return TraitName, TraitLevel, UnitInInventory
end

function SummonService.Client:EvolveUnit(player, UnitHash)
	local Inventory = ProfileService:Get(player,"Inventory")
	local Equipped = ProfileService:Get(player,"Equipped")
	local UnitInInventory,PositionInInv = SummonService:GetUnit(Inventory.Units,UnitHash) 
	local UnitInEquipped, PositionInEquipped = SummonService:GetUnit(Equipped,UnitHash)
	local UnitData = Units[UnitInInventory.Unit]
	local ItemToEvolve = UnitData.ItemToEvolve
	local RequiredToEvolve = UnitData.RequiredToEvolve
	local Item = PlayerService:GetItem(player,"Materials", ItemToEvolve)
	local newUnitData;
	local Evolved = false
	--- Check requirements first and then apply

	-- print(UnitData)
	if Item.Amount >= RequiredToEvolve then
		local newEvolve = GlobalDatastoreService:EvolveUnit(UnitInInventory.Unit.."(Evolved)", UnitInInventory.Shiny, UnitInInventory)
		
		if UnitInInventory then
			Evolved = true
			newUnitData = newEvolve
			Inventory.Units[PositionInInv] = newEvolve
		end
	
		if UnitInEquipped then
			Equipped[PositionInEquipped] = newEvolve
		end

		ProfileService:Update(player,"Equipped",function()
			return Equipped
		end)

		ProfileService:Update(player,"Inventory",function()
			return Inventory
		end)
		
		PlayerService.Client.UpdateEquipped:Fire(player)
		PlayerService:GiveItem(player,"Items",ItemToEvolve,-RequiredToEvolve)
	end

	return Evolved, newUnitData
end

function SummonService:GetRandomRanks()
    local Unit_Stats = Grades.RanksRarity

	local Damage = SummonService:SelectItemByPercentage(Unit_Stats)
	local Cooldown = SummonService:SelectItemByPercentage(Unit_Stats)
	local Range = SummonService:SelectItemByPercentage(Unit_Stats)

	return Damage.Name, Cooldown.Name, Range.Name
end

function SummonService.Client:Ranks(player, UnitHash : string, PinnedStats : {[number] : string})
    local Unit_Stats = Grades.RanksRarity
	local Inventory = ProfileService:Get(player,"Inventory")
	local Equipped = ProfileService:Get(player,"Equipped")
	local Dice = PlayerService:GetItem(player,"Items","Dice")
	local Hammer = PlayerService:GetItem(player,"Items","Hammer")
	local RankGems = if typeof(Dice) == "table" then Dice.Amount else 0
	local HammerAmount = if typeof(Hammer) == "number" then Hammer.Amount else 0
	local AmountToUpgrade = 1
	local UnitInInventory,UnitInEquipped = SummonService:GetUnit(Inventory.Units,UnitHash), SummonService:GetUnit(Equipped,UnitHash)

	if RankGems < AmountToUpgrade then return warn("Not enough Rank gems!") end
	if HammerAmount < #PinnedStats then return warn("Not enough Rank Hammers!") end

	local Damage = if not table.find(PinnedStats,"Damage") then SummonService:SelectItemByPercentage(Unit_Stats).Name else UnitInInventory.Stats.Damage 
	local Range = if not table.find(PinnedStats,"Range") then SummonService:SelectItemByPercentage(Unit_Stats).Name else UnitInInventory.Stats.Range
	local Cooldown = if not table.find(PinnedStats,"Cooldown") then SummonService:SelectItemByPercentage(Unit_Stats).Name else UnitInInventory.Stats.Cooldown

	warn("What was pinned: ", PinnedStats, table.find(PinnedStats,"Range"))

	if UnitInInventory then
		UnitInInventory.Stats.Damage = Damage 
		UnitInInventory.Stats.Range = Range
		UnitInInventory.Stats.Cooldown = Cooldown
	end

	if UnitInEquipped then
		UnitInEquipped.Stats.Damage = Damage
		UnitInEquipped.Stats.Range = Range
		UnitInEquipped.Stats.Cooldown = Cooldown
	end

	ProfileService:Update(player,"Inventory",function()
		return Inventory
	end)

	ProfileService:Update(player,"Equipped",function()
		return Equipped
	end)

	PlayerService:GiveItem(player,"Items","Dice",-AmountToUpgrade)

	if #PinnedStats > 0 then
		PlayerService:GiveItem(player,"Items","Hammer",-#PinnedStats)
	end

	return Damage,Range,Cooldown
end

function SummonService.SummonRotation()
	Promise.new(function()
		local lastHour = nil 
		while true do
			local dateTable = os.date("!*t", os.time())
			if dateTable.min == 0 and dateTable.sec == 0 and (lastHour == nil or dateTable.hour ~= lastHour) then
				lastHour = dateTable.hour
				getCurrentShipmentRotation()
				-- SummonService.Client.SummonRotationUpdated:FireAll(getCurrentShipmentRotation())
			end
			task.wait(1)
		end
	end)
end

function SummonService.Client:GetCurrentSummon(player)
	return getCurrentShipmentRotation()
end

function SummonService.Client:SellUnits(player, unitHashes: {string})
	-- Validate input
	print("Trying to sell --> ", unitHashes)
	if ProfileService:IsProfileReady(player) ~= true then
		return false
	end
	if typeof(unitHashes) ~= "table" then
		return false
	end
	if not TableUtil.Every(unitHashes, function(value)
		return typeof(value) == "string"
	end) then
		return false
	end

	print("Selling --> ", unitHashes)

	local Inventory = ProfileService:Get(player, "Inventory")
	local Equipped = ProfileService:Get(player, "Equipped")

	-- Validate hash existance
	local validHashes = {}
	for _, hash in unitHashes do
		if TableUtil.Find(Inventory.Units, function(unit)
			return unit.Hash == hash
		end) ~= nil then
			table.insert(validHashes, hash)
		end
	end

	if #validHashes ~= #unitHashes then
		return false
	end

	-- Validate hash is not Pilot
	for _, hash in validHashes do
		local unit = TableUtil.Find(Inventory.Units, function(unit)
			return unit.Hash == hash
		end)
		-- if unit ~= nil then
		-- 	if unit.Unit == "Pilot" then
		-- 		FlagService.Client.AddPrompt:Fire(player, "Ok", {
		-- 			Subtitle = "You are unable to sell your starter unit! (Pilot)"
		-- 		})
		-- 		return false
		-- 	elseif unit.UserLock == true then
		-- 		FlagService.Client.AddPrompt:Fire(player, "Ok", {
		-- 			Subtitle = "One of the selected units is user-locked!"
		-- 		})
		-- 		return false
		-- 	end
		-- end
	end
	
	-- Modify data
	local newUnits = {}
	local totalCoins = 0
	for _, unit in Inventory.Units do
		if table.find(validHashes, unit.Hash) == nil then
			table.insert(newUnits, unit)
		else
			totalCoins += SellPriceOfRarity[Units[unit.Unit].Rarity]
		end
	end
	Equipped = TableUtil.Filter(Equipped, function(unit)
		return table.find(validHashes, unit.Hash) == nil
	end)

	print("newUnits: ", newUnits)
	-- Publish modified data
	ProfileService:Update(player, "Inventory", function(inventory)
		inventory.Units = newUnits
		return inventory
	end)
	ProfileService:Update(player, "Equipped", function(equipped)
		return Equipped
	end)
	ProfileService:Update(player, "Coins", function(Coins)
		local TotalAmount = Coins + totalCoins
		PlayerService.Client.UpdateCoins:Fire(player, TotalAmount)
		return TotalAmount
	end)
	ProfileService:Update(player, "Statistics", function(statistics)
		statistics.TotalCoins += totalCoins
		return statistics
	end)
	return true,newUnits
end

function SummonService.Client:EnableAutoSell(player, Settings, Value)
	local newSettings = {}
	ProfileService:Update(player,"Settings",function(Sett)
		if Sett.AutoSell[Settings] ~= nil then
			Sett.AutoSell[Settings] = Value
		end

		if Sett[Settings] ~= nil then
			Sett[Settings] = Value
		end

		newSettings = Sett
		warn("The new settings",Settings, Value, Sett)
		return Sett
	end)

	return newSettings
end

local SummonOne = 50
local SummonTen = SummonOne * 10

function SummonService.Client:Summon(player, ...)
	return Mutex.get(player):Wrap(function(amount)
		-- Validate input
		if ProfileService:IsProfileReady(player) ~= true then
			return false
		end

		if typeof(amount) ~= "number" then
			return false, "NoGems"
		end
		if amount ~= 1 and amount ~= 10 then
			return false, "NoGems"
		end

		-- Validate scrap
		local Gems = ProfileService:Get(player, "Gems")
		if (amount == 1 and Gems < SummonOne) or (amount == 10 and Gems < SummonTen) then
			return false, "NoGems"
		end

		-- Validate inventory space
		local inventory = ProfileService:Get(player, "Inventory")
		local maxUnitsInventory = ProfileService:Get(player, "MaxUnitsInventory")
		if #inventory.Units + amount > maxUnitsInventory then
			local bannerConfig = {
				.2,                             -- Background Transparency
				Color3.fromRGB(255, 0, 0),         -- Background Color
				0,                                 -- Content Transparency
				Color3.fromRGB(244, 244, 244), -- Content Color
			}

			-- ReplicatedStorage.BannerNotify:FireClient(player,"NoUnitSpace","You inventory is full","",5,bannerConfig)
			return false, "NoUnitSpace"
		end

		-- Take scrap
		if amount == 1 then
			ProfileService:Update(player, "Gems", function(gems)
				local TotalAmount = gems - SummonOne
				PlayerService.Client.UpdateGems:Fire(player, TotalAmount)
				return TotalAmount
			end)
		elseif amount == 10 then
			ProfileService:Update(player, "Gems", function(gems)
				local TotalAmount = gems - SummonTen
				PlayerService.Client.UpdateGems:Fire(player, TotalAmount)
				return TotalAmount
			end)
		end

		-- Update quests
		-- QuestService:AddToQuestType(player, "Shipment", amount)
		ProfileService:Update(player, "Statistics", function(statistics)
			statistics.TotalSummons += amount
			return statistics
		end)

		-- Update pity
		local shipmentPity = ProfileService:Get(player, "SummonPity")
		local lastShipmentHour = ProfileService:Get(player, "Statistics").LastSummonHour
		local currentShipmentHour = getCurrentUnixHour()
		print(lastShipmentHour , currentShipmentHour)
		if lastShipmentHour < currentShipmentHour then
			shipmentPity.Legendary = 0
			shipmentPity.Mythic = 0
			ProfileService:Update(player, "Statistics", function(statistics)
				statistics.LastSummonHour = currentShipmentHour
				return statistics
			end)
		end

		-- Ship
		local luckChanceMultiplier = 1
		if EffectService:IsPlayerEffectActive(player, "Super Luck Boost") then
			luckChanceMultiplier *= 3
		end
		if EffectService:IsPlayerEffectActive(player, "Luck Boost") then
			luckChanceMultiplier *= 2
		end

		local totalChance = 0
		local chances = {}
		for prize, chance in BaseSummonChances do
			local newChance = chance
			if prize >= 4 then --? it will only boost for => epic, legendary, or mythic
				newChance *= luckChanceMultiplier
			end
			chances[prize] = newChance
			totalChance += newChance
		end

		local possiblePrizes = getCurrentShipmentRotation()

		local playerRarityPrizes = {}
		for i = 1, amount do
			if shipmentPity.Mythic >= 300 then
				table.insert(playerRarityPrizes, 6)
				shipmentPity.Mythic = 0
				continue
			elseif shipmentPity.Legendary >= 100 then
				table.insert(playerRarityPrizes, 5)
				shipmentPity.Legendary = 0
				continue
			end
			shipmentPity.Legendary += 1
			shipmentPity.Mythic += 1

			local percentage = Bucket:NextNumber(0, totalChance)
			local cumulativeChance = 0
			for prize, chance in chances do
				if percentage <= cumulativeChance + chance then
					table.insert(playerRarityPrizes, prize)
					if prize == 5 then
						shipmentPity.Legendary = 0
					elseif prize == 6 then
						shipmentPity.Mythic = 0
					end
					break
				end
				cumulativeChance += chance
			end
		end

		ProfileService:Update(player, "SummonPity", function()
			return shipmentPity
		end)
		
		local playerPrizes = {}
		local returnedPrizes = {}
		for _, rarity in playerRarityPrizes do
			table.insert(playerPrizes, possiblePrizes[rarity])
		end

		ProfileService:Update(player, "Inventory", function(inventory)
			for _, prize in GlobalDatastoreService:CreateUnit(playerPrizes) do
				table.insert(inventory.Units, prize)
				table.insert(returnedPrizes, prize)
			end
			return inventory
		end)

		return true, returnedPrizes
	end)(...)
end


function SummonService:KnitInit()

end

function SummonService:KnitStart()
    warn("THE SUMMONSERVICE: ", getCurrentShipmentRotation())
	ProfileService = Knit.GetService("ProfileService")
	PlayerService = Knit.GetService("PlayerService")
	GlobalDatastoreService = Knit.GetService("GlobalDatastoreService")
	InventoryService = Knit.GetService("InventoryService")
	EffectService = Knit.GetService("EffectService")

	task.spawn(function()
		SummonService.SummonRotation()
	end)
end

return SummonService