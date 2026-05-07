--!strict

local CommonSpecies = require(script:WaitForChild("BugSpecies"):WaitForChild("CommonSpecies"))
local UncommonSpecies = require(script:WaitForChild("BugSpecies"):WaitForChild("UncommonSpecies"))
local RareSpecies = require(script:WaitForChild("BugSpecies"):WaitForChild("RareSpecies"))
local EpicSpecies = require(script:WaitForChild("BugSpecies"):WaitForChild("EpicSpecies"))
local LegendarySpecies = require(script:WaitForChild("BugSpecies"):WaitForChild("LegendarySpecies"))
local MythicSpecies = require(script:WaitForChild("BugSpecies"):WaitForChild("MythicSpecies"))

local function append(into, items)
	for _, item in ipairs(items) do
		table.insert(into, item)
	end
end

local allSpecies = {}
append(allSpecies, CommonSpecies)
append(allSpecies, UncommonSpecies)
append(allSpecies, RareSpecies)
append(allSpecies, EpicSpecies)
append(allSpecies, LegendarySpecies)
append(allSpecies, MythicSpecies)

local BugConfig = {
	Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
	RarityWeights = { Common = 100, Uncommon = 65, Rare = 35, Epic = 18, Legendary = 7, Mythic = 2 },
	BaseBugPoints = { Common = 1, Uncommon = 2, Rare = 4, Epic = 9, Legendary = 20, Mythic = 45 },
	Species = allSpecies,
	StatTypes = { "AllFood", "FoodPerSec", "ClickPower", "SellBonus", "NectarChance", "BugLuck", "MinigameSpawnChance", "MinigameTime", "ExpeditionSpeed", "OfflineEarnings" },
}

return BugConfig
