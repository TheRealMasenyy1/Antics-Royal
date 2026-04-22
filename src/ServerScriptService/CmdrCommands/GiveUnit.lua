return {
    Name = "GiveUnit",
    Aliases = {"Gitut"},
    Description = "Gives the player a unit",
    Group = "Admin",
    Args = {
        {
            Name = "player",
            Type = "player",
            Description = "Player to kick"
        },

        {
            Name = "Unit",
            Type = "unit",
            Description = "The Item to give player"
        },

        {
            Name = "Shiny",
            Type = "boolean",
            Description = "The Item of said Item"
        }
    };
}