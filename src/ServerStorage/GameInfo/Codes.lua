return {
    ["Release!"] = {
        Reward = {
            Exp = 550;
            Coin = 11000;
            Gems = 12000;
            Items = {
                {Name = "Fish", Amount = 5, ItemType = "Items"}
            }
        },

        Duration = {year=2024, month=12, day=13, hour=14, min=0, sec=0}; --! Hours is +1 by default, Set this to nil to remove the duration
    }
} :: {[string] : { Reward : {}, Duration : {year: number , month : number, day : number, hour : number}}}