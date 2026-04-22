local ReplicatedStorage = game:GetService("ReplicatedStorage")





return {
    [1] = function(Waves) -- Speed
        if not Waves then Waves = {} end

        local Name = "Speed Demon"
        local Desc = "All Enemies gains +100% speed"
        local Rewards = {
            ["Coins"] = 50000,
            ["Gems"] = 1000,
            ["Exp"] = 5000,
            ["PossibleRewards"] = {
                {Name = "Cursed Finger", Percentage = 99, Amount = 3},
                {Name = "Nothing", Percentage = 1, Amount = 1},
            }
        }

        for wave,waveInfo in pairs(Waves) do
            for i = 1,#waveInfo do
                local unitInfo = waveInfo[i]
                
                unitInfo.Speed *= 2
            end
        end

        return Waves, Name, Rewards, Desc
    end,

    [2] = function(Waves) -- Shield
        if not Waves then Waves = {} end

        local Name = "Tank Warriors"
        local Desc = "All Enemies gets shield"
        local Rewards = {
            ["Coins"] = 50000,
            ["Gems"] = 1000,
            ["Exp"] = 5000,
            ["PossibleRewards"] = {
                {Name = "Cursed Finger", Percentage = 99, Amount = 3},
                {Name = "Scroll", Percentage = 99, Amount = 3},
                {Name = "Fish", Percentage = 99, Amount = 3},
                {Name = "Meat", Percentage = 99, Amount = 3},
                {Name = "Nothing", Percentage = 1, Amount = 1},
            }
        }

        for wave,waveInfo in pairs(Waves) do
            for i = 1,#waveInfo do
                local unitInfo = waveInfo[i]
                
                if not unitInfo.Shield then
                    unitInfo.Shield = 5
                end
                
            end
        end

        return Waves, Name, Rewards, Desc


    end,

    [3] = function(Waves) -- Regen health every sec
        if not Waves then Waves = {} end

        local Name = "Regen"
        local Desc = "All Enemies gets regen"
        local Rewards = {
            ["Coins"] = 50000,
            ["Gems"] = 1000,
            ["Exp"] = 5000,
            ["PossibleRewards"] = {
                {Name = "Cursed Finger", Percentage = 99, Amount = 3},
                {Name = "Scroll", Percentage = 99, Amount = 3},
                {Name = "Fish", Percentage = 99, Amount = 3},
                {Name = "Meat", Percentage = 99, Amount = 3},
                {Name = "Nothing", Percentage = 1, Amount = 1},
            }
        }

        local RegenPercent = 2

        for wave,waveInfo in pairs(Waves) do
            for i = 1,#waveInfo do
                local unitInfo = waveInfo[i]
                
                if not unitInfo.Regen then
                    unitInfo.Regen = true
                end

                if not unitInfo.RegenPercent then
                    unitInfo.RegenPercent = RegenPercent
                end
                
            end
        end

        return Waves, Name, Rewards, Desc
    end,

    [4] = function(Waves) -- 2x HP
        if not Waves then Waves = {} end
        local Name = "Tank Tankers"
        local Desc = "Enemies have 2x health"
        local Rewards = {
            ["Coins"] = 50000,
            ["Gems"] = 1000,
            ["Exp"] = 5000,
            ["PossibleRewards"] = {
                {Name = "Cursed Finger", Percentage = 99, Amount = 3},
                {Name = "Scroll", Percentage = 99, Amount = 3},
                {Name = "Fish", Percentage = 99, Amount = 3},
                {Name = "Meat", Percentage = 99, Amount = 3},
                {Name = "Nothing", Percentage = 1, Amount = 1},
            }
        }

        for wave,waveInfo in pairs(Waves) do
            for i = 1,#waveInfo do
                local unitInfo = waveInfo[i]

                unitInfo.HP *= 2

            end
        end

        return Waves, Name, Rewards, Desc
    end,

    [5] = function(Waves) -- Regen health every sec
        if not Waves then Waves = {} end
        local Name = "Short Sighted"
        local Desc = "All units could use some glasses"
        local Rewards = {
            ["Coins"] = 50000,
            ["Gems"] = 1000,
            ["Exp"] = 5000,
            ["PossibleRewards"] = {
                {Name = "Cursed Finger", Percentage = 99, Amount = 3},
                {Name = "Scroll", Percentage = 99, Amount = 3},
                {Name = "Fish", Percentage = 99, Amount = 3},
                {Name = "Meat", Percentage = 99, Amount = 3},
                {Name = "Nothing", Percentage = 1, Amount = 1},
            }
        }

        for _,Value in pairs(ReplicatedStorage.SharedBalancing:GetDescendants()) do
            if Value.Name == "Range" then
                Value.Value /= 2
            end
        end

        return Waves, Name, Rewards, Desc
    end,

    [6] = function(Waves) -- Regen health every sec
        if not Waves then Waves = {} end
        local Name = "Exploding Units"
        local Desc = "Enemies spawn and explod stunning nearby units"
        local Rewards = {
            ["Coins"] = 50000,
            ["Gems"] = 1000,
            ["Exp"] = 5000,
            ["PossibleRewards"] = {
                {Name = "Cursed Finger", Percentage = 99, Amount = 3},
                {Name = "Scroll", Percentage = 99, Amount = 3},
                {Name = "Fish", Percentage = 99, Amount = 3},
                {Name = "Meat", Percentage = 99, Amount = 3},
                {Name = "Nothing", Percentage = 1, Amount = 1},
            }
        }

        for wave,waveInfo in pairs(Waves) do
            for i = 1,#waveInfo do
                local unitInfo = waveInfo[i]
                
                if not unitInfo.Explode then
                    unitInfo.Explode = true
                end
                
            end
        end

        return Waves, Name, Rewards, Desc
    end
}