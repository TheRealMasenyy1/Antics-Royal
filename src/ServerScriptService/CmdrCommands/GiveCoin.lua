return {
    Name = "GiveCoin",
    Aliases = {"GiC"},
    Description = "Give player coin",
    Group = "Admin",
    Args = {
        {
            Name = "player",
            Type = "player",
            Description = "Player that will receive"
        },
        {
            Name = "Amount",
            Type = "number",
            Description = "The amount of coin"
        }
    };
}