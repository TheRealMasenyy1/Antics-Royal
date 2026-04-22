local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local BannerNotify = require(ReplicatedStorage.Shared.Utility.BannerNotificationModule)

return function (context, forPlayer,  UnitName : any, IsShiny : number)
    local GlobalDataStoreService = Knit.GetService("GlobalDatastoreService")
    local ProfileService = Knit.GetService("ProfileService")
    local default = {
        .3, 							-- Background Transparency
        Color3.fromRGB(84, 255, 78), 		-- Background Color
        
        0, 								-- Content Transparency
        Color3.fromRGB(255, 255, 255), 	-- Content Color
    }

    -- BannerNotify:Notify("Gift from admin",'You have been given ' .. UnitName.Name,"",5,default,forPlayer)
    if forPlayer.Character and forPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local Unit = GlobalDataStoreService:CreateUnit(UnitName.Name, IsShiny, true)
        ProfileService:Update(forPlayer,"Inventory",function(Inventory)
            table.insert(Inventory.Units,Unit)
            warn("INVENTORY AFTER WE HAVE GIVEN THE UNIT: ", Inventory)
            return Inventory
        end)

        BannerNotify:Notify("Gift from admin",'You have been given ' .. UnitName.Name,"",5,default,forPlayer)
        return UnitName.Name .. " has been given to " .. forPlayer.Name
    elseif not forPlayer then
        return "Invalid player"
    end

    return "Could not get the exp"
end 
