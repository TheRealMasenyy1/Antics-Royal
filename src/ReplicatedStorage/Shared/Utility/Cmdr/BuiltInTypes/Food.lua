local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Util = require(script.Parent.Parent.Shared.Util)
local Items = ReplicatedStorage.Assets.Items
local Storage = {}

local playerType = {
	Transform = function(text)
		local findPlayer = Util.MakeFuzzyFinder(Items.Food:GetChildren())

		return findPlayer(text)
	end,

	Validate = function(players)
		return #players > 0, "No player with that name could be found."
	end,

	Autocomplete = function(players)
		return Util.GetNames(players)
	end,

	Parse = function(players)
		return players[1]
	end,

	Default = function(player)
		return player.Name
	end,

	ArgumentOperatorAliases = {
		me = ".",
		all = "*",
		others = "**",
		random = "?",
	},
}

return function(cmdr)
	cmdr:RegisterType("food", playerType)
	cmdr:RegisterType(
		"foods",
		Util.MakeListableType(playerType, {
			Prefixes = "% food",
		})
	)
end
