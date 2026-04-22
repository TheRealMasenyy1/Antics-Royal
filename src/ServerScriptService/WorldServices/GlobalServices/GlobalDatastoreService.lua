--// Services
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Core
local Knit = require(ReplicatedStorage.Packages.Knit)
local GlobalDatastoreService = Knit.CreateService{Name = "GlobalDatastoreService"}

--// Dependencies
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Promise = require(ReplicatedStorage.Shared.Utility.PromiseTyped)
local ULID = require(ReplicatedStorage.Shared.ULID)
local Units = require(ReplicatedStorage.SharedPackage.Units)

--// Constants
local UnitsKey = "DevUnits.1"
local CodesKey = "DevCodes.1"
local GlobalDataStore = DataStoreService:GetGlobalDataStore()
local ShinyBucket = Random.new(3785442545 + os.time())

-- --// Variables
local unitsQueue = {}
local codesQueue = {}

local SummonService;
--// Functions
local function update(key, handler, datastore)
	if datastore == nil then
		datastore = GlobalDataStore
	end
	local status = Promise.retry(function()
		return Promise.new(function(resolve)
			local success = pcall(function()
				datastore:UpdateAsync(key, handler)
			end)
			if success then
				resolve()
			end
		end)
	end, 5):awaitStatus()
	return status == Promise.Status.Resolved
end

local function set(key, value, datastore)
	if datastore == nil then
		datastore = GlobalDataStore
	end
	local status = Promise.retry(function()
		return Promise.new(function(resolve)
			local success = pcall(function()
				datastore:SetAsync(key, value)
			end)
			if success then
				resolve()
			end
		end)
	end, 5):awaitStatus()
	return status == Promise.Status.Resolved
end

local function publishData(instant)
	if #unitsQueue > 0 then
		local success = update(UnitsKey, function(units)
			if units == nil then
				units = {}
			end
			for _, unitQuantities in unitsQueue do
				for unit, quantity in unitQuantities do
					if units[unit] == nil then
						units[unit] = 0
					end
					units[unit] += quantity
				end
			end
			return units
		end)
		if success then
			unitsQueue = {}
		end
		if instant ~= true then
			task.wait(7)
		end
	end
	if #codesQueue > 0 then
		local success = update(CodesKey, function(codes)
			if codes == nil then
				codes = {}
			end
			for _, code in codesQueue do
				if codes[code] == nil then
					codes[code] = 0
				end
				codes[code] += 1
			end
			return codes
		end)
		if success then
			codesQueue = {}
		end
		if instant ~= true then
			task.wait(7)
		end
	end
end


function GlobalDatastoreService:EvolveUnit(inputUnit, forceShiny, OldUnitdata, doNotAddToUnitsQuantity)
	if typeof(inputUnit) == "string" then
		local unitTable = {
			Hash = "U" .. ULID(),
			Level = OldUnitdata.Level,
			Exp = OldUnitdata.Exp,
			MaxExp = OldUnitdata.MaxExp,
			UnitType = Units[inputUnit].UnitType,
			Traits = OldUnitdata.Traits,
			Stats = OldUnitdata.Stats,
			Shiny = OldUnitdata.Shiny or false, 
			Unit = inputUnit,
		}
		if forceShiny == true then
			unitTable.Shiny = true
		elseif forceShiny == nil then
			local isShiny = ShinyBucket:NextInteger(1, 100) == 69
			if isShiny then
				unitTable.Shiny = true
			end
		end
		if doNotAddToUnitsQuantity ~= true then
			if unitTable.Shiny ~= true then
				table.insert(unitsQueue, {[inputUnit] = 1})
			else
				unitTable.Serial = self:IncrementShinyUnitQuantity(inputUnit)
			end
		end
		return unitTable
	elseif typeof(inputUnit) == "table" then
		local unitQuantities = {}
		local unitTables = TableUtil.Map(inputUnit, function(unit)
			local unitTable = {
				Hash = "U" .. ULID(),
				Level = OldUnitdata.Level,
				Exp = OldUnitdata.Exp,
				MaxExp = OldUnitdata.MaxExp,
				UnitType = Units[inputUnit].UnitType,
				Traits = OldUnitdata.Traits,
				Stats = OldUnitdata.Stats,
				Shiny = OldUnitdata.Shiny or false, 
				Unit = inputUnit
			}
			if forceShiny == true then
				unitTable.Shiny = true
			elseif forceShiny == nil then
				local isShiny = ShinyBucket:NextInteger(1, 100) == 69
				if isShiny then
					unitTable.Shiny = true
				end
			end

			if unitTable.Shiny ~= true then
				if unitQuantities[unit] == nil then
					unitQuantities[unit] = 0
				end
				unitQuantities[unit] += 1
			else
				unitTable.Serial = self:IncrementShinyUnitQuantity(unit)
			end
			return unitTable
		end)

		if doNotAddToUnitsQuantity ~= true then
			table.insert(unitsQueue, unitQuantities)
		end

		return unitTables
	end
end

function GlobalDatastoreService:CreateUnit(inputUnit, forceShiny, doNotAddToUnitsQuantity)
	if typeof(inputUnit) == "string" then
		local damage, cooldown, range = SummonService:GetRandomRanks();
		local unitTable = {
			Hash = "U" .. ULID(),
			Level = 1,
			Exp = 0,
			MaxExp = 100,
			UnitType = Units[inputUnit].UnitType,
			Shiny = false,
			Traits = {
				Name = "", 
				Level = 0,
			},
			Stats = {Damage = damage, Cooldown = cooldown, Range = range},
			Unit = inputUnit
		}
		if forceShiny == true then
			unitTable.Shiny = true
		elseif forceShiny == nil then
			local isShiny = ShinyBucket:NextInteger(1, 100) == 69
			if isShiny then
				unitTable.Shiny = true
			end
		end
		if doNotAddToUnitsQuantity ~= true then
			if unitTable.Shiny ~= true then
				table.insert(unitsQueue, {[inputUnit] = 1})
			else
				unitTable.Serial = self:IncrementShinyUnitQuantity(inputUnit)
			end
		end
		return unitTable
	elseif typeof(inputUnit) == "table" then
		local unitQuantities = {}
		local unitTables = TableUtil.Map(inputUnit, function(unit)
			local damage, cooldown, range = SummonService:GetRandomRanks();
			local unitTable = {
				Hash = "U" .. ULID(),
				Level = 1,
				Exp = 0,
				MaxExp = 100,
				UnitType = Units[unit].UnitType,
				Traits = {
					Name = "", 
					Level = 0,
				},
				Shiny = false,
				Stats = {Damage = damage, Cooldown = cooldown, Range = range},
				Unit = unit
			}
			if forceShiny == true then
				unitTable.Shiny = true
			elseif forceShiny == nil then
				local isShiny = ShinyBucket:NextInteger(1, 100) == 69
				if isShiny then
					unitTable.Shiny = true
				end
			end

			if unitTable.Shiny ~= true then
				if unitQuantities[unit] == nil then
					unitQuantities[unit] = 0
				end
				unitQuantities[unit] += 1
			else
				unitTable.Serial = self:IncrementShinyUnitQuantity(unit)
			end
			return unitTable
		end)

		if doNotAddToUnitsQuantity ~= true then
			table.insert(unitsQueue, unitQuantities)
		end

		return unitTables
	end
end


function GlobalDatastoreService:IncrementCodeUsage(code)
	table.insert(codesQueue, code:lower())
end

function GlobalDatastoreService:GetUnitQuantities()
	local promise = Promise.retry(function()
		return Promise.new(function(resolve)
			resolve(GlobalDataStore:GetAsync(UnitsKey))
		end)
	end, 3)
	local quantities = promise:expect()
	if promise:getStatus() == Promise.Status.Resolved then
		return quantities
	else
		return {}
	end
end

function GlobalDatastoreService:IncrementShinyUnitQuantity(unit)
	unit = `SHINY_{unit:lower()}`
	local quantity = 0
	update(UnitsKey, function(units)
		if units == nil then
			units = {}
		end
		if units[unit] == nil then
			units[unit] = 0
		end
		units[unit] += 1
		quantity = units[unit]
		return units
	end)
	return quantity
end

function GlobalDatastoreService:ForcePublishData(instant)
	publishData(instant)
end

function GlobalDatastoreService:KnitStart()
	Promise.new(function(resolve, reject, cancel)
		SummonService = Knit.GetService("SummonService")
	end):catch(function(err)
		warn("Service doesn't exists in this word")
	end)
	-- SERVICE REFERENCES
	
	if not RunService:IsStudio() then
		game:BindToClose(function()
			publishData(true)
			task.wait(1)
		end)
	end
	Promise.new(function()
		while true do
			task.wait(900) -- 15 minutes
			Promise.try(publishData)
		end
	end)
end

return GlobalDatastoreService