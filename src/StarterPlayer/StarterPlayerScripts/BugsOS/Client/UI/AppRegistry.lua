--!strict

local Apps = script.Parent:WaitForChild("Apps")

local AppRegistry = {
	{ Id = "Achievements", Title = "Achievements.exe", Icon = "🏆", WindowSize = UDim2.fromOffset(900, 600), Module = require(Apps:WaitForChild("AchievementsApp")), UnlockedByDefault = true, AllowDuplicate = false },
	{ Id = "Market", Title = "Market.exe", Icon = "🐟", WindowSize = UDim2.fromOffset(560, 380), Module = require(Apps:WaitForChild("MarketApp")), UnlockedByDefault = true, AllowDuplicate = false },
	{ Id = "Upgrades", Title = "Upgrades.exe", Icon = "🛠", WindowSize = UDim2.fromOffset(780, 620), Module = require(Apps:WaitForChild("UpgradesApp")), UnlockedByDefault = true, AllowDuplicate = false },
	{ Id = "FoodHarvesters", Title = "Food Harvesters.exe", Icon = "⚙", WindowSize = UDim2.fromOffset(900, 650), Module = require(Apps:WaitForChild("FoodHarvestersApp")), UnlockedByDefault = true, AllowDuplicate = false },
	{ Id = "BugFarm", Title = "Bug Farm.exe", Icon = "🐞", WindowSize = UDim2.fromOffset(900, 620), Module = require(Apps:WaitForChild("BugFarmApp")), UnlockedByDefault = true, AllowDuplicate = false },
	{ Id = "Bugdex", Title = "Bugdex.exe", Icon = "📘", WindowSize = UDim2.fromOffset(900, 620), Module = require(Apps:WaitForChild("BugdexApp")), UnlockedByDefault = true, AllowDuplicate = false },
	{ Id = "Prestige", Title = "Prestige.exe", Icon = "⭐", WindowSize = UDim2.fromOffset(520, 320), Module = require(Apps:WaitForChild("PrestigeApp")), UnlockedByDefault = true, AllowDuplicate = false },
}

return AppRegistry
