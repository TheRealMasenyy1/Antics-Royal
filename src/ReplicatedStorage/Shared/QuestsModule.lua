local QuestsModule = {}

QuestsModule.Daily = {
    {
        Name = "Playtime I",
        Description = "Play at least 30 minute",
        Type = "Playtime",
        Amount = 0,
        MaxAmount = (60 * 30),
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Summoner I",
        Description = "Summon at least 5 times",
        Type = "Playtime",
        Amount = 0,
        MaxAmount = 5,
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Defeat I",
        Description = "Defeat 10 enemies in any mode",
        Type = "MobQuest",
        Amount = 0,
        MaxAmount = 10,
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Defeat II",
        Description = "Defeat 2 Bosses in any mode",
        Type = "BossQuest",
        Amount = 0,
        MaxAmount = 2,
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Perfectionist I",
        Description = "Complete all daily Quests",
        Type = "DailyQuests",
        Amount = 0,
        MaxAmount = "#",
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Gameplay I",
        Description = "Complete 5 waves in any mode",
        Type = "WaveQuest",
        Amount = 0,
        MaxAmount = 5,
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    }
}

QuestsModule.Weekly = {
    {
        Name = "Playtime III",
        Description = "Play at least 3 hours",
        Type = "Playtime",
        Amount = 0,
        MaxAmount = (60 * 60) * 3,
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Summoner III",
        Description = "Summon at least 15 times",
        Type = "Playtime",
        Amount = 0,
        MaxAmount = 15,
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Defeat III",
        Description = "Defeat 100 enemies in any mode",
        Type = "MobQuest",
        Amount = 0,
        MaxAmount = 100,
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Defeat III",
        Description = "Defeat 10 Bosses in any mode",
        Type = "BossQuest",
        Amount = 0,
        MaxAmount = 10,
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Perfectionist II",
        Description = "Complete all weekly Quests",
        Type = "WeeklyQuests",
        Amount = 0,
        MaxAmount = "#",
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    },

    {
        Name = "Gameplay II",
        Description = "Complete 50 waves in any mode",
        Type = "Waves",
        Amount = 0,
        MaxAmount = 5,
        Collected = false,
        Reward = { Exp = 50, Gems = 25, Coins = 500 }
    }
}

return QuestsModule