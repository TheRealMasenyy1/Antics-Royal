return {
    Name = "GiveToolbarUnit",
    Aliases = {"GTU"},
    Description = "Give player a unit for testing!",
    Group = "Admin",
    Args = {
        {
            Name = "player",
            Type = "player",
            Description = "Player that will receive"
        },
        {
            Name = "Unit",
            Type = "unit",
            Description = "Enter the unit's name"
        },
        {
            Name = "Level?",
            Type = "number",
            Description = "Enter the units level"
        },

        {
            Name = "SlotPos?",
            Type = "number",
            Description = "Which Slot in the toolbar(e.g 0 sets it to the any available slot)"
        }
    };
}