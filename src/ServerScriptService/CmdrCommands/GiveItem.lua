return {
    Name = "GiveItem",
    Aliases = {"Git"},
    Description = "Give the player any item(Don't use this right now)",
    Group = "Admin",
    Args = {
        {
            Name = "player",
            Type = "player",
            Description = "Player to kick"
        },

        {
            Name = "Catagory",
            Type = "inventorycatagory",
            Description = "catagory"
        },

        {
            Name = "Item",
            Type = "string",
            Description = "The Item to give player"
        },

        {
            Name = "Amount",
            Type = "number",
            Description = "The Item of said Item"
        }
    };
}