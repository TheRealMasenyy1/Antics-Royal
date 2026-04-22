local UserInputService = game:GetService("UserInputService")
local ItemsModule = {}

ItemsModule.Items = {
    ["Cursed Finger"] = {
        ImageId = "rbxassetid://115465484565285",
        Rarity = "Rare",
        Desc = "Used to feed your units",
        ImageSize = UDim2.fromScale(.7, .8);
        Type = "Food",
        Exp = 150 -- You gain 50 exp per Meat
    }, 

    ["Luck Boost"] = {
        ImageId = "rbxassetid://135621795004888",
        Rarity = "Epic",
        Desc = "Gives you a 50% luck boost whilst summoning",
        ImageSize = UDim2.fromScale(.8, .8);
        Type = "Items",
        ItemType = "LuckBoost",
        Usable = true,
    }, 

    ["Super Luck Boost"] = {
        ImageId = "rbxassetid://106099738733502",
        Rarity = "Legendary",
        Desc = "Gives you a 100% luck boost whilst summoning",
        Type = "Items",
        ItemType = "LuckBoost",
        Usable = true,
    },

    ["Meat"] = {
        ImageId = "rbxassetid://139186705982165",
        Rarity = "Rare",
        Desc = "Used to feed your units",
        Type = "Food",
        Exp = 75 -- You gain 50 exp per Meat
    },

    ["Gems"] = {
        ImageId = "rbxassetid://112320386335605",
        Desc = "Used to summon units.",
        Rarity = "Rare",
    },

    ["Coins"] = {
        ImageId = "rbxassetid://125232489777922",
        Rarity = "Rare",
    },

    ["Fish"] = {
        ImageId = "rbxassetid://125882444429566",
        Rarity = "Rare",
        Desc = "Used to feed your units",
        Type = "Food",
        Exp = 75,
    },

    ["Noodle"] = {
        ImageId = "rbxassetid://102750517383612",
        Rarity = "Rare",
        Desc = "Used to feed your units",
        Type = "Food",
        Exp = 100 -- You gain 50 exp per Meat
    },

    ["Scroll"] = {
        ImageId = "rbxassetid://113212680793229",
        Rarity = "Rare",
        Desc = "Used to feed your units",
        Type = "Food",
        Exp = 150, -- You gain 50 exp per Meat
    },

    ["Trait Crystal"] = {
        ImageId = "rbxassetid://133699080843954",
        Rarity = "Mythical",
        Type = "Items",
        ForEvolve = false,
    },

    ["Titan Crystal"] = {
        ImageId = "rbxassetid://118042032563503",
        Rarity = "Mythical",
        Desc = "Used to grant your units a trait",
        ImageSize = UDim2.fromScale(.7, .8);
        Type = "Items",
        ForEvolve = false,
    },

    ["Dice"] = {
        ImageId = "rbxassetid://95661105345071",
        Rarity = "Mythical",
        Desc = "Used to grant your units stats a rank",
        ImageSize = UDim2.fromScale(.7, .8);
        Type = "Items",
        ForEvolve = false,
    },

    ["Hammer"] = {
        ImageId = "rbxassetid://100569255260647",
        Rarity = "Mythical",
        Desc = "Used to grant your units stats a rank",
        ImageSize = UDim2.fromScale(.8, .8);
        Type = "Items",
        ForEvolve = false,
    },

}

ItemsModule.Materials = {
    ["1 Star"] = {
        ImageId = "rbxassetid://0",
        Rarity = "Rare",
        Type = "Material"
    },

    ["2 Star"] = {
        ImageId = "rbxassetid://0",
        Rarity = "Rare",
        Type = "Material"
    },

    ["3 Star"] = {
        ImageId = "rbxassetid://0",
        Rarity = "Rare",
        Type = "Material"
    },

    ["4 Star"] = {
        ImageId = "rbxassetid://0",
        Rarity = "Rare",
        Type = "Material"
    },

    ["5 Star"] = {
        ImageId = "rbxassetid://0",
        Rarity = "Rare",
        Type = "Material"
    },

    ["6 Star"] = {
        ImageId = "rbxassetid://0",
        Rarity = "Rare",
        Type = "Material"
    },

    ["7 Star"] = {
        ImageId = "rbxassetid://0",
        Rarity = "Rare",
        Type = "Material"
    },

    ["Warrior Belt"] = {
        ImageId = "rbxassetid://0",
        Rarity = "Mythical",
        Desc = "Used to evolve warrior",
        IsThreeD = true,
        Type = "Material"
    },
}

ItemsModule.TraitIcons = {
    ["Ferocity 1"] = {
        ImageId = "rbxassetid://89135604885660",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Ferocity 2"] = {
        ImageId = "rbxassetid://90052853220570",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Ferocity 3"] = {
        ImageId = "rbxassetid://136471736770340",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Haste 1"] = {
        ImageId = "rbxassetid://120292280913332",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Haste 2"] = {
        ImageId = "rbxassetid://99922243177480",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Haste 3"] = {
        ImageId = "rbxassetid://94778872976870",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Hawkeye 1"] = {
        ImageId = "rbxassetid://73355041858894",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Hawkeye 2"] = {
        ImageId = "rbxassetid://114277958055248",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Hawkeye 3"] = {
        ImageId = "rbxassetid://81429482426509",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Critical 1"] = {
        ImageId = "rbxassetid://125550851533875",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Critical 2"] = {
        ImageId = "rbxassetid://90923895812016",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },

    ["Critical 3"] = {
        ImageId = "rbxassetid://107969581017799",
        ImageSize = UDim2.fromScale(),
        IconSize = UDim2.fromScale(0.466,0.348)
    },
}

function ItemsModule:GetItem(ItemName : string) -- Returns, TYPE, RARITY, IMAGE
    local Type
    local Rarity
    local ImageId

    for Name, itemTable in pairs(ItemsModule.Items) do
        if Name == ItemName then
            Type = "Items"
            Rarity = itemTable.Rarity
            ImageId = itemTable.ImageId
        end
    end

    for Name, itemTable in pairs(ItemsModule.Materials) do
        if Name == ItemName then
            Type = "Materials"
            Rarity = itemTable.Rarity
            ImageId = itemTable.ImageId
        end
    end

    return Type, Rarity, ImageId
end

return ItemsModule