return {
    Name = "GiveFood",
    Aliases = {"Gitfd"},
    Description = "Kick the player",
    Group = "Admin",
    Args = {
        {
            Name = "player",
            Type = "player",
            Description = "Player to kick"
        },

        {
            Name = "Food",
            Type = "food",
            Description = "The Item to give player"
        },

        {
            Name = "Amount",
            Type = "number",
            Description = "The Item of said Item"
        }
    };
}