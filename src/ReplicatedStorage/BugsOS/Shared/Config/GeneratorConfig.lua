--!strict

local GeneratorConfig = {
	Generators = {
		{
			id = "plain_cracker",
			displayName = "Plain Cracker",
			classId = "snack",
			baseFoodPerSec = 400,
			baseUpgradeCost = 25,
			bonus = nil,
		},
		{
			id = "potato_chip",
			displayName = "Potato Chip",
			classId = "snack",
			baseFoodPerSec = 260,
			baseUpgradeCost = 30,
			bonus = "ClickPower",
			bonusValue = 0.05,
		},
		{
			id = "cookie_crumb",
			displayName = "Cookie Crumb",
			classId = "snack",
			baseFoodPerSec = 230,
			baseUpgradeCost = 35,
			bonus = "SellBonus",
			bonusValue = 0.05,
		},
	},
}

return GeneratorConfig
