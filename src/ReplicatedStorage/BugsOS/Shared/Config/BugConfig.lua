--!strict

local BugConfig = {
	Rarities = { "Common", "Rare", "Epic", "Legendary", "Mythic" },
	RarityWeights = { Common = 60, Rare = 25, Epic = 10, Legendary = 4, Mythic = 1 },
	BaseBugPoints = { Common = 1, Rare = 3, Epic = 10, Legendary = 35, Mythic = 150 },
	Species = {
		{ id = "worker_ant", displayName = "Worker Ant", rarity = "Common", baseTimer = 14, hitsRequired = 1, behaviorPool = { "Wanderer" } },
		{ id = "house_fly", displayName = "House Fly", rarity = "Common", baseTimer = 13, hitsRequired = 1, behaviorPool = { "Wanderer" } },
		{ id = "ladybug", displayName = "Ladybug", rarity = "Rare", baseTimer = 12, hitsRequired = 2, behaviorPool = { "Wanderer", "ZigZagger" } },
		{ id = "honey_bee", displayName = "Honey Bee", rarity = "Rare", baseTimer = 11, hitsRequired = 2, behaviorPool = { "ZigZagger" } },
		{ id = "rhinoceros_beetle", displayName = "Rhinoceros Beetle", rarity = "Epic", baseTimer = 10, hitsRequired = 3, behaviorPool = { "ZigZagger" } },
	},
	StatTypes = { "AllFood", "FoodPerSec", "ClickPower", "SellBonus", "NectarChance", "BugLuck", "MinigameSpawnChance", "MinigameTime", "ExpeditionSpeed", "OfflineEarnings" },
}

return BugConfig
