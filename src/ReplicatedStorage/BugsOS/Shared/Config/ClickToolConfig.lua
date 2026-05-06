--!strict

local ClickToolConfig = {
	Tools = {
		{
			id = "bare_hands",
			displayName = "Bare Hands",
			baseCost = 10,
			foodPerClickPerLevel = 1,
			maxLevel = 10,
		},
		{
			id = "garden_glove",
			displayName = "Garden Glove",
			baseCost = 75,
			foodPerClickPerLevel = 5,
			maxLevel = 10,
		},
		{
			id = "hand_trowel",
			displayName = "Hand Trowel",
			baseCost = 500,
			foodPerClickPerLevel = 15,
			maxLevel = 10,
		},
		{
			id = "watering_can",
			displayName = "Watering Can",
			baseCost = 2_500,
			foodPerClickPerLevel = 35,
			maxLevel = 10,
		},
		{
			id = "pruning_shears",
			displayName = "Pruning Shears",
			baseCost = 12_000,
			foodPerClickPerLevel = 75,
			maxLevel = 10,
		},
	},
}

return ClickToolConfig
