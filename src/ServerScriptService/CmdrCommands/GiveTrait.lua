return {
    Name = "GiveTrait",
    Aliases = {"gtt"},
    Description = "Gives the player x amount of traits",
    Group = "Admin",
    Args = {
        {
            Name = "players",
            Type = "player",
            Description = "The player to give exp to."
        },

        {
            Name = "Amount",
            Type = "number",
            Description = "The player to give exp to."
        }
    };
}