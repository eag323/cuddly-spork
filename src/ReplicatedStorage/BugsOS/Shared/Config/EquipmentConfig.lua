--!strict

local EquipmentConfig = {}

EquipmentConfig.MaxInventory = 300

EquipmentConfig.Slots = {
	"Weapon",
	"Helmet",
	"Chestplate",
	"Boots",
	"Charm",
}

EquipmentConfig.Rarities = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
}

EquipmentConfig.RarityColors = {
	Common = Color3.fromRGB(228, 228, 228),
	Uncommon = Color3.fromRGB(78, 214, 92),
	Rare = Color3.fromRGB(76, 154, 255),
	Epic = Color3.fromRGB(178, 92, 255),
	Legendary = Color3.fromRGB(255, 196, 66),
	Mythic = Color3.fromRGB(255, 88, 190),
}

EquipmentConfig.StarLevels = { 1, 2, 3, 4, 5, 6 }

EquipmentConfig.MainStatsBySlot = {
	Weapon = { "ATK", "CritRate", "CritDamage" },
	Helmet = { "HP", "DEF", "RES" },
	Chestplate = { "HP", "DEF", "ACC" },
	Boots = { "SPD", "HP", "DEF" },
	Charm = { "ACC", "RES", "CritRate", "CritDamage" },
}

EquipmentConfig.SubStatPool = {
	"HP",
	"ATK",
	"DEF",
	"SPD",
	"CritRate",
	"CritDamage",
	"ACC",
	"RES",
}

EquipmentConfig.SetNames = {
	"Power",
	"Guard",
	"Speed",
	"Precision",
	"Resistance",
	"Critical",
	"Vitality",
	"Hunter",
	"Essence",
	"Fortune",
}

EquipmentConfig.SetBonusMetadata = {
	Power = { Theme = "ATK" },
	Guard = { Theme = "DEF" },
	Speed = { Theme = "SPD" },
	Precision = { Theme = "ACC" },
	Resistance = { Theme = "RES" },
	Critical = { Theme = "Crit" },
	Vitality = { Theme = "HP" },
	Hunter = { Theme = "Enemy battles" },
	Essence = { Theme = "Bug Essence" },
	Fortune = { Theme = "Drops" },
}

EquipmentConfig.DefaultIconsBySlot = {
	Weapon = "rbxassetid://108634805180682",
	Helmet = "rbxassetid://118602110627798",
	Chestplate = "rbxassetid://87662023939534",
	Boots = "rbxassetid://88635696482091",
	Charm = "rbxassetid://108634805180682",
}

-- Legacy alias kept for current UI and older saved/generated equipment.
EquipmentConfig.IconsBySlot = EquipmentConfig.DefaultIconsBySlot

EquipmentConfig.IconsBySetAndSlot = {
	Power = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
	Guard = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
	Speed = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
	Precision = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
	Resistance = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
	Critical = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
	Vitality = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
	Hunter = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
	Essence = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
	Fortune = {
		Weapon = EquipmentConfig.DefaultIconsBySlot.Weapon,
		Helmet = EquipmentConfig.DefaultIconsBySlot.Helmet,
		Chestplate = EquipmentConfig.DefaultIconsBySlot.Chestplate,
		Boots = EquipmentConfig.DefaultIconsBySlot.Boots,
		Charm = EquipmentConfig.DefaultIconsBySlot.Charm,
	},
}

EquipmentConfig.DropChancesByEnemyTier = {
	CommonEnemy = 0.15,
	RareEnemy = 0.25,
	EliteEnemy = 0.45,
	MythicEnemy = 0.75,
}

EquipmentConfig.RarityWeightsByEnemyTier = {
	CommonEnemy = {
		Common = 78,
		Uncommon = 20,
		Rare = 2,
	},
	RareEnemy = {
		Common = 10,
		Uncommon = 55,
		Rare = 32,
		Epic = 3,
	},
	EliteEnemy = {
		Uncommon = 8,
		Rare = 58,
		Epic = 31,
		Legendary = 3,
	},
	MythicEnemy = {
		Rare = 6,
		Epic = 56,
		Legendary = 34,
		Mythic = 4,
	},
}

EquipmentConfig.StarWeightsByRarity = {
	Common = { [1] = 82, [2] = 18 },
	Uncommon = { [1] = 45, [2] = 45, [3] = 10 },
	Rare = { [2] = 52, [3] = 38, [4] = 10 },
	Epic = { [3] = 48, [4] = 40, [5] = 12 },
	Legendary = { [4] = 50, [5] = 38, [6] = 12 },
	Mythic = { [5] = 58, [6] = 42 },
}

local MAIN_STAT_BASE_VALUES = {
	HP = 48,
	ATK = 12,
	DEF = 10,
	SPD = 4,
	CritRate = 3,
	CritDamage = 8,
	ACC = 5,
	RES = 5,
}

local SUB_STAT_BASE_VALUES = {
	HP = 18,
	ATK = 5,
	DEF = 4,
	SPD = 2,
	CritRate = 1,
	CritDamage = 3,
	ACC = 2,
	RES = 2,
}

local RARITY_VALUE_MULTIPLIERS = {
	Common = 1.0,
	Uncommon = 1.2,
	Rare = 1.45,
	Epic = 1.75,
	Legendary = 2.1,
	Mythic = 2.55,
}

local RARITY_SUB_STAT_COUNTS = {
	Common = 1,
	Uncommon = 2,
	Rare = 2,
	Epic = 3,
	Legendary = 3,
	Mythic = 4,
}

local function nextNumber(rng: any): number
	if rng and typeof(rng) == "Random" then
		return rng:NextNumber()
	end
	return math.random()
end

local function nextInteger(rng: any, minValue: number, maxValue: number): number
	if rng and typeof(rng) == "Random" then
		return rng:NextInteger(minValue, maxValue)
	end
	return math.random(minValue, maxValue)
end

local function pickFromArray(values: { any }, rng: any): any
	return values[nextInteger(rng, 1, #values)]
end

local function pickWeighted(weights: { [any]: number }, rng: any): any
	local total = 0
	for _key, weight in weights do
		total += math.max(0, tonumber(weight) or 0)
	end
	if total <= 0 then
		return nil
	end

	local roll = nextNumber(rng) * total
	local cursor = 0
	for key, weight in weights do
		cursor += math.max(0, tonumber(weight) or 0)
		if roll <= cursor then
			return key
		end
	end
	return nil
end

local function statValue(stat: string, rarity: string, stars: number, isMain: boolean, rng: any): number
	local baseValues = isMain and MAIN_STAT_BASE_VALUES or SUB_STAT_BASE_VALUES
	local base = tonumber(baseValues[stat]) or 1
	local rarityMultiplier = tonumber(RARITY_VALUE_MULTIPLIERS[rarity]) or 1
	local starMultiplier = 1 + (math.max(1, stars) - 1) * (isMain and 0.28 or 0.18)
	local variance = 0.9 + (nextNumber(rng) * 0.2)
	return math.max(1, math.floor(base * rarityMultiplier * starMultiplier * variance + 0.5))
end

function EquipmentConfig.GetRarityColor(rarity: string): Color3
	return EquipmentConfig.RarityColors[rarity] or EquipmentConfig.RarityColors.Common
end

function EquipmentConfig.GetIcon(setName: string?, slot: string?): string
	local setIcons = EquipmentConfig.IconsBySetAndSlot[setName or ""]
	if setIcons then
		local setIcon = setIcons[slot or ""]
		if type(setIcon) == "string" and setIcon ~= "" then
			return setIcon
		end
	end

	local defaultIcon = EquipmentConfig.DefaultIconsBySlot[slot or ""]
	if type(defaultIcon) == "string" then
		return defaultIcon
	end
	return ""
end

function EquipmentConfig.GetRandomSlot(rng: any): string
	return pickFromArray(EquipmentConfig.Slots, rng)
end

function EquipmentConfig.GetRandomRarity(rng: any, tier: string?): string
	local weights = EquipmentConfig.RarityWeightsByEnemyTier[tier or "CommonEnemy"] or EquipmentConfig.RarityWeightsByEnemyTier.CommonEnemy
	return pickWeighted(weights, rng) or "Common"
end

function EquipmentConfig.GetRandomStars(rng: any, rarity: string): number
	local weights = EquipmentConfig.StarWeightsByRarity[rarity] or EquipmentConfig.StarWeightsByRarity.Common
	return pickWeighted(weights, rng) or 1
end

function EquipmentConfig.RollEquipment(rng: any, enemyTier: string?): { [string]: any }
	local slot = EquipmentConfig.GetRandomSlot(rng)
	local rarity = EquipmentConfig.GetRandomRarity(rng, enemyTier)
	local stars = EquipmentConfig.GetRandomStars(rng, rarity)
	local setName = pickFromArray(EquipmentConfig.SetNames, rng)
	local mainStatName = pickFromArray(EquipmentConfig.MainStatsBySlot[slot], rng)
	local subStats = {}
	local usedStats = { [mainStatName] = true }
	local subStatCount = math.max(1, math.min(#EquipmentConfig.SubStatPool, tonumber(RARITY_SUB_STAT_COUNTS[rarity]) or 1))

	for _index = 1, subStatCount do
		local statName = pickFromArray(EquipmentConfig.SubStatPool, rng)
		local guard = 0
		while usedStats[statName] and guard < 20 do
			statName = pickFromArray(EquipmentConfig.SubStatPool, rng)
			guard += 1
		end
		usedStats[statName] = true
		table.insert(subStats, {
			Stat = statName,
			Value = statValue(statName, rarity, stars, false, rng),
		})
	end

	return {
		Uid = "",
		Slot = slot,
		Rarity = rarity,
		Stars = stars,
		SetName = setName,
		MainStat = {
			Stat = mainStatName,
			Value = statValue(mainStatName, rarity, stars, true, rng),
		},
		SubStats = subStats,
		Icon = EquipmentConfig.GetIcon(setName, slot),
		CreatedAt = os.time(),
	}
end

function EquipmentConfig.GetDisplayName(item: { [string]: any }): string
	local setName = tostring(item.SetName or "Bug")
	local slot = tostring(item.Slot or "Equipment")
	return string.format("%s %s", setName, slot)
end

return EquipmentConfig
