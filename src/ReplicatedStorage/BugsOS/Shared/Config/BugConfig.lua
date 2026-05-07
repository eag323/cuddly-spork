--!strict

local BugConfig = {
	Rarities = { "Common", "Rare", "Epic", "Legendary", "Mythic" },
	RarityWeights = { Common = 60, Rare = 25, Epic = 10, Legendary = 4, Mythic = 1 },
	BaseBugPoints = { Common = 1, Rare = 3, Epic = 10, Legendary = 35, Mythic = 150 },
	Species = {
		{ id = "worker_ant", displayName = "Worker Ant", rarity = "Common", baseTimer = 10, hitsRequired = 2, behaviorPool = { "Wanderer" } },
		{ id = "house_fly", displayName = "House Fly", rarity = "Rare", baseTimer = 9, hitsRequired = 3, behaviorPool = { "Wanderer", "ZigZagger" } },
		{ id = "ladybug", displayName = "Ladybug", rarity = "Epic", baseTimer = 8, hitsRequired = 4, behaviorPool = { "ZigZagger" } },
		{ id = "honey_bee", displayName = "Honey Bee", rarity = "Legendary", baseTimer = 7, hitsRequired = 5, behaviorPool = { "ZigZagger", "Dasher" } },
		{ id = "rhinoceros_beetle", displayName = "Rhinoceros Beetle", rarity = "Mythic", baseTimer = 7, hitsRequired = 6, behaviorPool = { "Dasher" } },
	},
	StatTypes = { "AllFood", "FoodPerSec", "ClickPower", "SellBonus", "NectarChance", "BugLuck", "MinigameSpawnChance", "MinigameTime", "ExpeditionSpeed", "OfflineEarnings" },
}

return BugConfig
