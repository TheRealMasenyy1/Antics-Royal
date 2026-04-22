--// Services
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Core
local Knit = require(ReplicatedStorage.Packages.Knit)
local ProductService = Knit.CreateService{Name = "ProductService", Client = {}}

--// Dependencies
local PurchaseIds = require(ReplicatedStorage.SharedPackage.PurchaseIds)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local PlaceIds = require(ReplicatedStorage.Shared.PlaceIds)
local GlobalDatastoreService, ProfileService, LobbyService, FlagService
local BannerNotify = require(ReplicatedStorage.Shared.Utility.BannerNotificationModule)

--// Constants
local default = {
	.3, 							-- Background Transparency
	Color3.fromRGB(27, 61, 255), 		-- Background Color
	
	0, 								-- Content Transparency
	Color3.fromRGB(255, 255, 255), 	-- Content Color
}

local Failed = {
	.3, 							-- Background Transparency
	Color3.fromRGB(255), 		-- Background Color
	
	0, 								-- Content Transparency
	Color3.fromRGB(255, 255, 255), 	-- Content Color
}

--// Variables

--// Knit Events

--// Functions

local functions = {
	[PurchaseIds.Products.InventoryStorage] = {Type = "Product", Call = function(player)
		ProfileService:Update(player, "MaxUnitsInventory", function(maxUnitsInventory)
			return maxUnitsInventory + 100
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Products.GoldBundle30000] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Amount = 30000

		BannerNotify:Notify('Gold granted','You have been granted ' .. Amount .. ' Gold',"", 5, default, player)
		PlayerService:GiveCoin(player,Amount)
	end},

	[PurchaseIds.Products.GoldBundle13000] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Amount = 13000

		BannerNotify:Notify('Gold granted','You have been granted ' .. Amount .. ' Gold',"", 5, default, player)
		PlayerService:GiveCoin(player, Amount)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Products.GoldBundle5000] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Amount = 5000

		BannerNotify:Notify('Gold granted','You have been granted ' .. Amount .. ' Gold',"", 5, default, player)
		PlayerService:GiveCoin(player,Amount)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Products.GoldBundle500] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Amount = 500

		BannerNotify:Notify('Gold granted','You have been granted ' .. Amount .. ' Gold',"", 5, default, player)
		PlayerService:GiveCoin(player,Amount)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Products.GemsBundle11000] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Amount = 11000

		BannerNotify:Notify('Gold granted','You have been granted ' .. Amount .. ' Gems',"", 5, default, player)
		PlayerService:GiveGems(player,Amount)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Products.GemsBundle5000] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Amount = 5000

		BannerNotify:Notify('Gems granted','You have been granted ' .. Amount .. ' Gems',"", 5, default, player)
		PlayerService:GiveGems(player,Amount)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Products.GemsBundle2000] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Amount = 2000

		BannerNotify:Notify('Gems granted','You have been granted ' .. Amount .. ' Gems',"", 5, default, player)
		PlayerService:GiveGems(player,Amount)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Gamepasses.BattlePassSeasonOne] = {Type = "Gamepass", Call = function(player)
		local OwnedGamepasses = ProfileService:Get(player,"OwnedGamepasses")
		local PlayerService = Knit.GetService("PlayerService")

		print("OwnedGamepasses: ", OwnedGamepasses, PurchaseIds.Gamepasses.BattlePassSeasonOne)

		if not table.find(OwnedGamepasses,PurchaseIds.Gamepasses.BattlePassSeasonOne) then
			BannerNotify:Notify('Premium battlepass','You have been granted access to the premium battlepass',"", 5, default, player)
			table.insert(OwnedGamepasses,PurchaseIds.Gamepasses.BattlePassSeasonOne)
			ProfileService:Update(player,"OwnedGamepasses", function()
				return OwnedGamepasses
			end)

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		BannerNotify:Notify('Purchase Failed','Failed the purchase',"", 5, Failed, player)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end},

	[PurchaseIds.Products.SuperLuckBoost] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")

		BannerNotify:Notify('Super Luck Potion granted','You have been granted a SUPER Luck potion',"", 5, default, player)
		PlayerService:GiveItem(player,"Items","Super Luck Boost", 1)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Products.LuckBoost] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Amount = 300

		BannerNotify:Notify('Luck Potion granted','You have been granted a Luck potion',"", 5, default, player)
		PlayerService:GiveItem(player,"Items","Luck Boost", 1)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Products.GemsBundle300] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Amount = 300

		BannerNotify:Notify('Gems granted','You have been granted ' .. Amount .. ' Gems',"", 5, default, player)
		PlayerService:GiveGems(player,Amount)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},

	[PurchaseIds.Products.Skip10Level] = {Type = "Product", Call = function(player)
		local PlayerService = Knit.GetService("PlayerService")
		local Battlepass = ProfileService:Get(player,"Battlepass")

		BannerNotify:Notify('Skip 10 Battlepass Level','You have skipped 10 level ' .. Battlepass.Level .. ' -> ' .. (Battlepass.Level + 10),"", 5, default, player)
		PlayerService:Skip10Level(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end},
	
	[PurchaseIds.Products.Emote1] = {Type = "Product", Call = function(player)
        local Given = false

        ProfileService:Update(player, "Inventory", function(inventory)
            local Emotes = inventory.Emotes
            local EmotesFolder = ReplicatedStorage.Assets.Animations.Emotes

            while not Given do
                local newEmote = EmotesFolder:GetChildren()[math.random(1, #EmotesFolder:GetChildren())]

                if not Emotes[newEmote.Name] then
                    inventory.Emotes[newEmote.Name] = true
                    Given = true
                    break;
                end
                task.wait()
            end

            return inventory
        end)

        if Given then
            warn("New emote given to player")
            return Enum.ProductPurchaseDecision.PurchaseGranted
        else
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
	end},
}

local function fail(receipt, reason)
	-- Incase any warn print fails, still need to return the fail enum
	local success = pcall(function()
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		warn(`ProductService: Failed to process product ID {receipt.ProductId} for {if player then player.Name else "Offline Player"} ({receipt.PlayerId}): {reason}`)
	end)
	if not success then
		warn("ProductService: Could not generate fail description.")
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function processReceipt(receipt)
	-- Get player
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if player == nil or player.Parent ~= Players then
		return
	end

	-- Await profile to be ready
	ProfileService:OnProfileReady(player):await()

	-- Check if product was already granted
	local InGamePurchases = ProfileService:Get(player, "InGamePurchases")
	local productPurchases = TableUtil.Filter(InGamePurchases, function(purchase)
		return purchase.Type == "Product"
	end)
	local foundProduct = TableUtil.Find(productPurchases, function(purchase)
		return purchase.PurchaseId == receipt.PurchaseId
	end)
	if foundProduct ~= nil then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Run associated function
	if functions[receipt.ProductId] ~= nil then
		local success, returnValue = pcall(functions[receipt.ProductId].Call, player, receipt.ProductId)
		if success then
			ProfileService:Update(player, "InGamePurchases", function(InGamePurchases)
				table.insert(InGamePurchases, {
					Type = "Product",
					Id = receipt.ProductId,
					Price = receipt.CurrencySpent,
					PurchaseId = receipt.PurchaseId
				})
				return InGamePurchases
			end)
			return returnValue
		else
			return fail(receipt, "Function failed: " .. returnValue)
		end
	else
		return fail(receipt, "No function associated with product ID.")
	end
end

local function activateGamepass(player, gamepassId, isPurchase)
	local success, reason = pcall(functions[gamepassId].Call, player, gamepassId)
	if success then
		if isPurchase then
			if reason == Enum.ProductPurchaseDecision.PurchaseGranted then
				ProfileService:Update(player, "InGamePurchases", function(InGamePurchases)
					table.insert(InGamePurchases, {
						Type = "Gamepass",
						Id = gamepassId
					})
					return InGamePurchases
				end)
				return
			else
				warn(`ProductService: Failed to process gamepass ID {gamepassId} for {player.Name} ({player.UserId}): Function did not return PurchaseGranted enum.`)
				return
			end
		end
	else
		warn(`ProductService: Failed to process gamepass ID {gamepassId} for {player.Name} ({player.UserId}): {reason}`)
		return
	end
end

function ProductService:Emulate(player, productId)
	if functions[productId] ~= nil then
		local success, reason = pcall(functions[productId].Call, player, productId)
		if success then
			if reason ~= Enum.ProductPurchaseDecision.PurchaseGranted then
				warn(`ProductService: Failed to emulate ID {productId} for {player.Name} ({player.UserId}): Function did not return PurchaseGranted enum.`)
			end
		else
			warn(`ProductService: Failed to emulate ID {productId} for {player.Name} ({player.UserId}): {reason}`)
		end
	else
		warn(`ProductService: Failed to emulate ID {productId} for {player.Name} ({player.UserId}): No function associated with given ID.`)
		return
	end
end

local function Find(TABLE,VALUE)
	for Pos, value in TABLE do
		print(typeof(value), value, typeof(VALUE), VALUE, value == VALUE)
		if value == VALUE then
			return Pos, value
		end
	end

	return nil
end

function GetPlayerPurchase(player, Id : string)
	local OwnedGamepasses = ProfileService:Get(player,"OwnedGamepasses")
	local InGamePurchases = ProfileService:Get(player,"InGamePurchases")
	local PosInGamepasses = table.find(OwnedGamepasses, tonumber(Id))
	local PosInGamePurchases = table.find(InGamePurchases , tonumber(Id))

	-- warn("Check if Owned: ", PosInGamePurchases, PosInGamepasses, OwnedGamepasses, InGamePurchases, PurchaseIds.Gamepasses.BattlePassSeasonOne)
	if PosInGamepasses then
        return true, "Gamepass"
    end

	if PosInGamePurchases then
        return true, "Product"
    end

    return false
end

function ProductService:GetPlayerPurchase(player, Id : string)
    return GetPlayerPurchase(player,Id)
end

function ProductService.Client:GetPlayerPurchase(player, Id : string)
    return GetPlayerPurchase(player,Id)
end

function ProductService.Client:Emulate(player,productId)
    ProductService:Emulate(player, productId)
end

function ProductService.Client:IsPlayerVIP(player, somePlayer)
	if typeof(somePlayer) ~= "Instance" or somePlayer:IsA("Player") == false or somePlayer.Parent ~= Players then
		return false
	end
	if ProfileService:IsProfileReady(somePlayer) ~= true then
		for _ = 1, 10 do
			if ProfileService:IsProfileReady(somePlayer) == true then
				break
			end
			task.wait(1)
		end
		if ProfileService:IsProfileReady(somePlayer) ~= true then
			return false
		end
	end

	local ownedGamepasses = ProfileService:Get(somePlayer, "OwnedGamepasses")
	return table.find(ownedGamepasses, PurchaseIds.Gamepasses.VIP) ~= nil
end

function ProductService:KnitStart()
	-- SERVICE REFERENCES
	GlobalDatastoreService = Knit.GetService("GlobalDatastoreService")
	ProfileService = Knit.GetService("ProfileService")
	-- FlagService = Knit.GetService("FlagService")
	
	if game.PlaceId == PlaceIds.Lobby then
		LobbyService = Knit.GetService("LobbyService")
	end

	Players.PlayerAdded:Connect(function(player)
		ProfileService:OnProfileReady(player):andThen(function()
			local InGamePurchases = ProfileService:Get(player, "InGamePurchases")
			local OwnedGamepasses = ProfileService:Get(player, "OwnedGamepasses")
			local functionGamepassIds = TableUtil.Keys(TableUtil.Filter(functions, function(f)
				return f.Type == "Gamepass"
			end))
			for _, id in functionGamepassIds do
				local success, playerOwnsGamepass = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
				end)
				if success and playerOwnsGamepass then
					if table.find(OwnedGamepasses, id) == nil then
						ProfileService:Update(player, "OwnedGamepasses", function(ownedGamepasses)
							table.insert(ownedGamepasses, id)
							return ownedGamepasses
						end)
					end

					if TableUtil.Find(InGamePurchases, function(purchase)
						return purchase.Type == "Gamepass" and purchase.Id == id
					end) == nil and functions[id].ActivateOnce == true then
						activateGamepass(player, id, true)
					elseif functions[id].ActivateOnce ~= true then
						activateGamepass(player, id, false)
					end
				end
			end
			for _, purchase in InGamePurchases do
				if purchase.Type == "Gamepass" and functions[purchase.Id] ~= nil and functions[purchase.Id].Type == "Gamepass" and functions[purchase.Id].ActivateOnce ~= true then
					activateGamepass(player, purchase.Id, false)
				end
			end

			-- Account for any gamepasses that don't have a function
			for _, id in TableUtil.Filter(PurchaseIds.Gamepasses, function(id)
				return table.find(functionGamepassIds, id) == nil
			end) do
				if table.find(OwnedGamepasses, id) == nil then
					local success, playerOwnsGamepass = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
					end)
					if success and playerOwnsGamepass then
						ProfileService:Update(player, "OwnedGamepasses", function(ownedGamepasses)
							table.insert(ownedGamepasses, id)
							return ownedGamepasses
						end)
					end
				end
			end
		end):catch(function() end)
	end)

	MarketplaceService.ProcessReceipt = function(receipt)
		local success, result = pcall(function()
			return processReceipt(receipt)
		end)
		if not success then
			warn("ProductService: Failed to process receipt: " .. result)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		else
			return result
		end
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if wasPurchased then
			if ProfileService:IsProfileReady(player) then
				-- Run associated function
				if functions[gamepassId] ~= nil then
					if functions[gamepassId].ActivateOnce == true then
						local InGamePurchases = ProfileService:Get(player, "InGamePurchases")
						local gamepassPurchases = TableUtil.Filter(InGamePurchases, function(purchase)
							return purchase.Type == "Gamepass"
						end)
						local foundGamepass = TableUtil.Find(gamepassPurchases, function(purchase)
							return purchase.PurchaseId == gamepassId
						end)
						if foundGamepass == nil then
							activateGamepass(player, gamepassId, true)
						else
							warn(`ProductService: Failed to process gamepass ID {gamepassId} for {player.Name} ({player.UserId}): Gamepass had already been bought previously.`)
						end
					elseif functions[gamepassId].ActivateOnce ~= true then
						activateGamepass(player, gamepassId, false)
					end
				else
					warn(`ProductService: Failed to process gamepass ID {gamepassId} for {player.Name} ({player.UserId}): No function associated with gamepass ID.`)
					return
				end
			else
				warn(`ProductService: Failed to process gamepass ID {gamepassId} for {player.Name} ({player.UserId}): Profile was not loaded.`)
				return
			end
		end
	end)
end
return ProductService