--!strict

local AchievementConfig = {}

AchievementConfig.Sections = {
	"Clicking",
	"Food",
	"Market",
	"Bugs Caught",
	"Collection",
	"Rarity",
	"Bug Farm",
	"Upgrades",
	"Prestige",
}

AchievementConfig.Definitions = {
	{ id = "click_100", name = "First Clicks", description = "Click 100 times", section = "Clicking", stat = "TotalClicks", required = 100, reward = { Type = "Food", Amount = 500 } },
	{ id = "click_1000", name = "Clickstorm", description = "Click 1,000 times", section = "Clicking", stat = "TotalClicks", required = 1000, reward = { Type = "Coins", Amount = 250 } },
	{ id = "click_10000", name = "Desk Destroyer", description = "Click 10,000 times", section = "Clicking", stat = "TotalClicks", required = 10000, reward = { Type = "BugPoints", Amount = 300 } },
	{ id = "food_1000", name = "Snack Collector", description = "Earn 1,000 total Food", section = "Food", stat = "TotalFoodEarned", required = 1000, reward = { Type = "Coins", Amount = 150 } },
	{ id = "food_100k", name = "Pantry Builder", description = "Earn 100,000 total Food", section = "Food", stat = "TotalFoodEarned", required = 100000, reward = { Type = "BugPoints", Amount = 500 } },
	{ id = "market_first", name = "First Sale", description = "Sell Food at the Market", section = "Market", stat = "MarketSales", required = 1, reward = { Type = "Food", Amount = 2000 } },
	{ id = "market_10", name = "Regular Seller", description = "Make 10 Market sales", section = "Market", stat = "MarketSales", required = 10, reward = { Type = "Coins", Amount = 1000 } },
	{ id = "catch_1", name = "First Catch", description = "Catch your first bug", section = "Bugs Caught", stat = "BugsCaught", required = 1, reward = { Type = "BugPoints", Amount = 100 } },
	{ id = "catch_25", name = "Bug Hunter", description = "Catch 25 bugs", section = "Bugs Caught", stat = "BugsCaught", required = 25, reward = { Type = "Coins", Amount = 750 } },
	{ id = "discovery_10", name = "Budding Collector", description = "Discover 10 unique bugs", section = "Collection", stat = "UniqueBugsDiscovered", required = 10, reward = { Type = "Nectar", Amount = 20 } },
	{ id = "discovery_300", name = "System Naturalist", description = "Discover 300 unique bugs", section = "Collection", stat = "UniqueBugsDiscovered", required = 300, reward = { Type = "Title", Value = "System Naturalist" } },
	{ id = "rare_1", name = "Something Shiny", description = "Catch a Rare bug", section = "Rarity", stat = "RareBugsCaught", required = 1, reward = { Type = "Coins", Amount = 1200 } },
	{ id = "mythic_10", name = "Mythic Hoarder", description = "Catch 10 Mythic bugs", section = "Rarity", stat = "MythicBugsCaught", required = 10, reward = { Type = "Title", Value = "Mythic Hoarder" } },
	{ id = "sacrifice_10", name = "Bug Recycler", description = "Sacrifice 10 bugs", section = "Bug Farm", stat = "BugsSacrificed", required = 10, reward = { Type = "Item", Value = "Placeholder Core Cache" } },
	{ id = "upgrade_1", name = "First Upgrade", description = "Buy your first click upgrade", section = "Upgrades", stat = "ClickUpgradesBought", required = 1, reward = { Type = "Food", Amount = 10000 } },
	{ id = "prestige_1", name = "Rebooted", description = "Prestige for the first time", section = "Prestige", stat = "Prestiges", required = 1, reward = { Type = "Title", Value = "Rebooted" } },
}

return AchievementConfig
