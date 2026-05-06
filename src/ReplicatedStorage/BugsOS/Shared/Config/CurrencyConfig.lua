--!strict

local CurrencyConfig = {
	Currencies = {
		food = {
			id = "food",
			displayName = "Food",
			description = "Primary collected resource.",
		},
		coins = {
			id = "coins",
			displayName = "Coins",
			description = "Primary upgrade currency earned from selling Food.",
		},
	},
}

return CurrencyConfig
