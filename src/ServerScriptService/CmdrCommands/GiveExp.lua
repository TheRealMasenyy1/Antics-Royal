return {
    Name = "GiveExp",
    Aliases = {"gxp"},
    Description = "Gives the player x amount of exp",
    Group = "Admin",
    Args = {
        {
            Name = "players",
            Type = "player",
            Description = "The player to give exp to."
        },

        {
            Name = "Exp",
            Type = "number",
            Description = "The player to give exp to."
        }
    };
}