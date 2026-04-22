return {
    Name = "UnlockMap",
    Aliases = {"unlmap"},
    Description = "Unlock a map",
    Group = "Admin",
    Args = {
        {
            Name = "player",
            Type = "player",
            Description = "Player to kick"
        },

        {
            Name = "Map",
            Type = "map",
            Description = "Enter the Map name"
        },

        {
            Name = "Chapter?",
            Type = "number",
            Description = "Enter chapter to unlock"
        }
    };
}