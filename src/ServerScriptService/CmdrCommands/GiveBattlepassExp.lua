return {
    Name = "GiveBattlepassExp",
    Aliases = {"gbp"},
    Description = "Gives the player x amount of Battlepass exp",
    Group = "Admin",
    Args = {
        {
            Name = "players",
            Type = "player",
            Description = "The player to give Battlepass exp to."
        },

        {
            Name = "Exp",
            Type = "number",
            Description = "The player to give Battlepass exp to."
        }
    };
}