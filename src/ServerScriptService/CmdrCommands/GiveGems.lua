return {
    Name = "GiveGems",
    Aliases = {"GiG"},
    Description = "Give player gems",
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
            Description = "The amount of gems"
        }
    };
}