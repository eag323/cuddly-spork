--!strict

local BugBonusConfig = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("EconomyConfig"))

type BonusDef = {
	Id: string,
	DisplayName: string,
	Category: string,
	Min: number,
	Max: number,
	ValueType: string,
}

type BonusRecord = {
	Id: string,
	DisplayName: string,
	Category: string,
	Value: number,
	ValueType: string,
	RollQuality: string,
}

local DEFINITIONS: {[string]: BonusDef} = {
	AllFood = { Id = "AllFood", DisplayName = "All Earnings", Category = "Farmer", Min = 0.10, Max = 1.30, ValueType = "Percent" },
	FoodPerSec = { Id = "FoodPerSec", DisplayName = "Food/sec", Category = "Farmer", Min = 0.10, Max = 1.30, ValueType = "Percent" },
	ClickPower = { Id = "ClickPower", DisplayName = "Click Power", Category = "Farmer", Min = 0.10, Max = 1.30, ValueType = "Percent" },
	SellBonus = { Id = "SellBonus", DisplayName = "Sell Bonus", Category = "Farmer", Min = 0.10, Max = 1.30, ValueType = "Percent" },
	BugLuck = { Id = "BugLuck", DisplayName = "Bug Luck", Category = "Farmer", Min = 0.10, Max = 0.40, ValueType = "Percent" },
	NectarChance = { Id = "NectarChance", DisplayName = "Nectar Chance", Category = "Farmer", Min = 0.10, Max = 1.00, ValueType = "Percent" },
	BugSpawnRate = { Id = "BugSpawnRate", DisplayName = "Bug Spawn Rate", Category = "Farmer", Min = 0.10, Max = 0.40, ValueType = "Percent" },
	MinigameTime = { Id = "MinigameTime", DisplayName = "Minigame Time", Category = "Farmer", Min = 0.05, Max = 0.30, ValueType = "Percent" },
	ExpeditionSpeed = { Id = "ExpeditionSpeed", DisplayName = "Expedition Speed", Category = "Farmer", Min = 0.05, Max = 0.25, ValueType = "Percent" },
	EquipmentDropRate = { Id = "EquipmentDropRate", DisplayName = "Equipment Drop Rate", Category = "Farmer", Min = 0.05, Max = 0.25, ValueType = "Percent" },
	BugEssenceGain = { Id = "BugEssenceGain", DisplayName = "Bug Essence Gain", Category = "Farmer", Min = 0.02, Max = 0.25, ValueType = "Percent" },
	BugDamage = { Id = "BugDamage", DisplayName = "Bug Damage", Category = "Combat", Min = 0.05, Max = 0.30, ValueType = "Percent" },
	BugHP = { Id = "BugHP", DisplayName = "Bug HP", Category = "Combat", Min = 0.10, Max = 0.50, ValueType = "Percent" },
	BossDamage = { Id = "BossDamage", DisplayName = "Boss Damage", Category = "Combat", Min = 0.10, Max = 0.50, ValueType = "Percent" },
}

BugBonusConfig.FarmerStatIds = { "AllFood", "FoodPerSec", "ClickPower", "SellBonus", "BugLuck", "NectarChance", "BugSpawnRate", "MinigameTime", "ExpeditionSpeed", "EquipmentDropRate", "BugEssenceGain" }
BugBonusConfig.CombatStatIds = { "BugDamage", "BugHP", "BossDamage" }
BugBonusConfig.AllStatIds = { "AllFood", "FoodPerSec", "ClickPower", "SellBonus", "BugLuck", "NectarChance", "BugSpawnRate", "MinigameTime", "ExpeditionSpeed", "EquipmentDropRate", "BugEssenceGain", "BugDamage", "BugHP", "BossDamage" }

local QUALITY_BANDS = {
	{ Name = "Normal", Chance = 0.9, Min = 0.00, Max = 0.60 },
	{ Name = "Good", Chance = 0.075, Min = 0.60, Max = 0.78 },
	{ Name = "Great", Chance = 0.02, Min = 0.78, Max = 0.93 },
	{ Name = "Perfect", Chance = 0.005, Min = 0.93, Max = 1.00 },
}

local RARITY_BIAS = { Common = 0.00, Uncommon = 0.04, Rare = 0.08, Epic = 0.12, Legendary = 0.16, Mythic = 0.20 }
local RARITY_ROLLS = { Common = { Min = 0, Max = 1, ChanceSecond = 0.5 }, Uncommon = { Min = 1, Max = 1 }, Rare = { Min = 1, Max = 2, ChanceSecond = 0.2 }, Epic = { Min = 2, Max = 2 }, Legendary = { Min = 2, Max = 2 }, Mythic = { Min = 3, Max = 3 } }

local ROLE_WEIGHTS = {
	Worker = { AllFood = 4, FoodPerSec = 4, ClickPower = 3.5, SellBonus = 3.5 },
	["Balanced Worker"] = { AllFood = 4, FoodPerSec = 4, ClickPower = 3.5, SellBonus = 3.5 },
	Tank = { BugHP = 4, BossDamage = 3, AllFood = 2.5 }, ["Shell Tank"] = { BugHP = 4, BossDamage = 3, AllFood = 2.5 }, ["Fortress Tank"] = { BugHP = 4, BossDamage = 3, AllFood = 2.5 }, ["Heavy Tank"] = { BugHP = 4, BossDamage = 3, AllFood = 2.5 }, ["Bulky Tank"] = { BugHP = 4, BossDamage = 3, AllFood = 2.5 }, Guardian = { BugHP = 4, BossDamage = 3, AllFood = 2.5 }, ["Resistant Guardian"] = { BugHP = 4, BossDamage = 3, AllFood = 2.5 },
	Assassin = { BugDamage = 4, BossDamage = 3.5, BugSpawnRate = 2.5 }, ["Glass Assassin"] = { BugDamage = 4, BossDamage = 3.5, BugSpawnRate = 2.5 }, ["Precision Assassin"] = { BugDamage = 4, BossDamage = 3.5, BugSpawnRate = 2.5 }, ["Aggressive Striker"] = { BugDamage = 4, BossDamage = 3.5, BugSpawnRate = 2.5 }, ["Fast Striker"] = { BugDamage = 4, BossDamage = 3.5, BugSpawnRate = 2.5 }, ["Speed Crit"] = { BugDamage = 4, BossDamage = 3.5, BugSpawnRate = 2.5 },
	Support = { MinigameTime = 3.5, BugLuck = 3.5, NectarChance = 3, BugHP = 2 }, ["Swift Support"] = { MinigameTime = 3.5, BugLuck = 3.5, NectarChance = 3, BugHP = 2 }, ["Utility Support"] = { MinigameTime = 3.5, BugLuck = 3.5, NectarChance = 3, BugHP = 2 }, ["Support Scout"] = { MinigameTime = 3.5, BugLuck = 3.5, NectarChance = 3, BugHP = 2 },
	Controller = { BugLuck = 3.5, BugSpawnRate = 3.5, BugDamage = 2.5, EquipmentDropRate = 2.5 }, Debuffer = { BugLuck = 3.5, BugSpawnRate = 3.5, BugDamage = 2.5, EquipmentDropRate = 2.5 }, ["Debuff Skirmisher"] = { BugLuck = 3.5, BugSpawnRate = 3.5, BugDamage = 2.5, EquipmentDropRate = 2.5 },
	Scout = { BugSpawnRate = 3.5, BugLuck = 3.5, MinigameTime = 3, ExpeditionSpeed = 2.5 }, ["Evasive Scout"] = { BugSpawnRate = 3.5, BugLuck = 3.5, MinigameTime = 3, ExpeditionSpeed = 2.5 },
}

function BugBonusConfig.GetDefinition(statId: string): BonusDef?
	return DEFINITIONS[statId]
end
function BugBonusConfig.GetDisplayName(statId: string): string
	local def = DEFINITIONS[statId]
	return (def and def.DisplayName) or statId
end
function BugBonusConfig.GetCategory(statId: string): string
	local def = DEFINITIONS[statId]
	return (def and def.Category) or "Farmer"
end
function BugBonusConfig.FormatBonus(bonus: any): string
	local def = DEFINITIONS[bonus and bonus.Id or ""]
	local name = (bonus and bonus.DisplayName) or (def and def.DisplayName) or "Bonus"
	local value = tonumber(bonus and bonus.Value) or 0
	return string.format("+%d%% %s", math.floor(value * 100 + 0.5), name)
end

local function pickQuality(rng: Random)
	if EconomyConfig.DEV_MODE == true then
		local forced = tostring(EconomyConfig.DEV_FORCE_BONUS_QUALITY or "")
		if forced ~= "" then
			for _, band in ipairs(QUALITY_BANDS) do
				if band.Name == forced then
					return band
				end
			end
		end
	end
	local roll = rng:NextNumber()
	local cursor = 0
	for _, band in ipairs(QUALITY_BANDS) do
		cursor += band.Chance
		if roll <= cursor then return band end
	end
	return QUALITY_BANDS[1]
end

local function getRollCount(rarity: string, rng: Random): number
	local cfg = RARITY_ROLLS[rarity] or RARITY_ROLLS.Common
	if cfg.Min == cfg.Max then return cfg.Min end
	if cfg.Max == 1 then return (rng:NextNumber() <= (cfg.ChanceSecond or 0)) and 1 or 0 end
	if cfg.Max == 2 then return 1 + ((rng:NextNumber() <= (cfg.ChanceSecond or 0)) and 1 or 0) end
	return cfg.Min
end

local function pickWeightedStat(rng: Random, role: string?, blocked: {[string]: boolean}): string?
	local roleWeights = (role and ROLE_WEIGHTS[role]) or nil
	local total = 0
	local entries = {}
	for _, statId in ipairs(BugBonusConfig.AllStatIds) do
		if not blocked[statId] then
			local w = 1
			if roleWeights and roleWeights[statId] then w = roleWeights[statId] end
			total += w
			table.insert(entries, { Id = statId, Weight = w })
		end
	end
	if total <= 0 then return nil end
	local roll = rng:NextNumber(0, total)
	local c = 0
	for _, e in ipairs(entries) do c += e.Weight if roll <= c then return e.Id end end
	return entries[#entries].Id
end

function BugBonusConfig.RollBonusStats(bugConfig: any, rarity: string): {BonusRecord}
	local rng = Random.new()
	local results = {}
	local used = {}
	local count = math.min(getRollCount(rarity, rng), #BugBonusConfig.AllStatIds)
	for _ = 1, count do
		local statId = pickWeightedStat(rng, bugConfig and bugConfig.role, used)
		if not statId then break end
		used[statId] = true
		local def = DEFINITIONS[statId]
		if def then
			local band = pickQuality(rng)
			local percentile = rng:NextNumber(band.Min, band.Max) + (RARITY_BIAS[rarity] or 0)
			percentile = math.clamp(percentile, 0, 1)
			local value = def.Min + ((def.Max - def.Min) * percentile)
			value = math.floor(value * 100 + 0.5) / 100
			table.insert(results, { Id = def.Id, DisplayName = def.DisplayName, Category = def.Category, Value = value, ValueType = def.ValueType, RollQuality = band.Name })
		end
	end
	return results
end

return BugBonusConfig
