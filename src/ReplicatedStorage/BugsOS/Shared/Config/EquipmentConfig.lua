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

-- Equipment art is centralized here so reward tiles and saved/generated items
-- resolve the same non-bug images. Replace any blank strings with uploaded
-- Roblox equipment/set art IDs as they become available.
EquipmentConfig.DefaultIconsBySlot = {
	Weapon = "",
	Helmet = "",
	Chestplate = "",
	Boots = "",
	Charm = "",
}

EquipmentConfig.IconsByItemKey = {
	-- Example future key: ["Power Weapon"] = "rbxassetid://...",
}

EquipmentConfig.IconsBySlotVariant = {
	Weapon = {},
	Helmet = {},
	Chestplate = {},
	Boots = {},
	Charm = {},
}

EquipmentConfig.SetIcons = {
	Power = "",
	Guard = "",
	Speed = "",
	Precision = "",
	Resistance = "",
	Critical = "",
	Vitality = "",
	Hunter = "",
	Essence = "",
	Fortune = "",
}

EquipmentConfig.SetIconColors = {
	Power = Color3.fromRGB(255, 92, 92),
	Guard = Color3.fromRGB(112, 176, 255),
	Speed = Color3.fromRGB(90, 235, 190),
	Precision = Color3.fromRGB(255, 204, 84),
	Resistance = Color3.fromRGB(180, 146, 255),
	Critical = Color3.fromRGB(255, 118, 188),
	Vitality = Color3.fromRGB(110, 235, 118),
	Hunter = Color3.fromRGB(232, 146, 76),
	Essence = Color3.fromRGB(94, 226, 216),
	Fortune = Color3.fromRGB(255, 226, 104),
}

EquipmentConfig.NeutralSetIcon = ""

EquipmentConfig.PlaceholderVisualsBySlot = {
	Weapon = { PlaceholderSymbol = "", PlaceholderLabel = "Weapon" },
	Helmet = { PlaceholderSymbol = "", PlaceholderLabel = "Helmet" },
	Chestplate = { PlaceholderSymbol = "", PlaceholderLabel = "Chestplate" },
	Boots = { PlaceholderSymbol = "", PlaceholderLabel = "Boots" },
	Charm = { PlaceholderSymbol = "", PlaceholderLabel = "Charm" },
}

-- Legacy aliases kept for current UI and older saved/generated equipment.
EquipmentConfig.IconsBySlot = EquipmentConfig.DefaultIconsBySlot
EquipmentConfig.IconsBySetAndSlot = {}
for _, setName in EquipmentConfig.SetNames do
	local slotIcons = {}
	for _, slot in EquipmentConfig.Slots do
		local variants = EquipmentConfig.IconsBySlotVariant[slot]
		slotIcons[slot] = (type(variants) == "table" and variants[setName]) or EquipmentConfig.DefaultIconsBySlot[slot] or ""
	end
	EquipmentConfig.IconsBySetAndSlot[setName] = slotIcons
end

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

local function isUsableImageAsset(assetId: any): boolean
	if type(assetId) ~= "string" then
		return false
	end
	local trimmed = string.gsub(assetId, "%s+", "")
	return trimmed ~= "" and trimmed ~= "rbxassetid://0" and trimmed ~= "0"
end

local function getItemKey(item: { [string]: any }?): string
	if type(item) ~= "table" then
		return ""
	end
	local key = item.ItemKey or item.Key or item.Id or item.Name or item.DisplayName
	if type(key) == "string" and key ~= "" then
		return key
	end
	local setName = tostring(item.SetName or "")
	local slot = tostring(item.Slot or "")
	if setName ~= "" and slot ~= "" then
		return setName .. " " .. slot
	end
	return ""
end

function EquipmentConfig.GetPlaceholderVisual(slot: string?): { PlaceholderSymbol: string, PlaceholderLabel: string }
	local visual = EquipmentConfig.PlaceholderVisualsBySlot[slot or ""]
	if visual then
		return visual
	end
	return {
		PlaceholderSymbol = "",
		PlaceholderLabel = tostring(slot or "Equipment"),
	}
end

function EquipmentConfig.GetSetIcon(setName: string?): string
	local normalizedSetName = tostring(setName or "")
	local icon = EquipmentConfig.SetIcons[normalizedSetName]
	if isUsableImageAsset(icon) then
		print(string.format("[EquipmentConfig] Resolved set icon set=%s source=set icon", normalizedSetName))
		return icon
	end
	if isUsableImageAsset(EquipmentConfig.NeutralSetIcon) then
		print(string.format("[EquipmentConfig] Resolved set icon set=%s source=neutral fallback", normalizedSetName))
		return EquipmentConfig.NeutralSetIcon
	end
	print(string.format("[EquipmentConfig] Resolved set icon set=%s source=none", normalizedSetName))
	return ""
end

function EquipmentConfig.GetSetIconColor(setName: string?): Color3
	return EquipmentConfig.SetIconColors[tostring(setName or "")] or Color3.fromRGB(198, 204, 216)
end

function EquipmentConfig.GetEquipmentIcon(item: { [string]: any }?): string
	local slot = ""
	local setName = ""
	if type(item) == "table" then
		slot = tostring(item.Slot or "")
		setName = tostring(item.SetName or "")
		local directIcon = item.Icon
		if isUsableImageAsset(directIcon) then
			print(string.format("[EquipmentConfig] Resolved equipment icon slot=%s set=%s source=item icon", slot, setName))
			return directIcon
		end

		local itemKey = getItemKey(item)
		local keyedIcon = EquipmentConfig.IconsByItemKey[itemKey]
		if isUsableImageAsset(keyedIcon) then
			print(string.format("[EquipmentConfig] Resolved equipment icon slot=%s set=%s source=item key %s", slot, setName, itemKey))
			return keyedIcon
		end

		local variants = EquipmentConfig.IconsBySlotVariant[slot]
		if type(variants) == "table" then
			local variantIcon = variants[setName] or variants[itemKey]
			if isUsableImageAsset(variantIcon) then
				print(string.format("[EquipmentConfig] Resolved equipment icon slot=%s set=%s source=slot variant", slot, setName))
				return variantIcon
			end
		end
	end

	local defaultIcon = EquipmentConfig.DefaultIconsBySlot[slot]
	if isUsableImageAsset(defaultIcon) then
		print(string.format("[EquipmentConfig] Resolved equipment icon slot=%s set=%s source=slot fallback", slot, setName))
		return defaultIcon
	end

	print(string.format("[EquipmentConfig] Resolved equipment icon slot=%s set=%s source=none", slot, setName))
	return ""
end

function EquipmentConfig.GetIcon(setName: string?, slot: string?): string
	return EquipmentConfig.GetEquipmentIcon({
		SetName = setName,
		Slot = slot,
	})
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
		ItemLevel = 0,
		CreatedAt = os.time(),
	}
end

function EquipmentConfig.GetDisplayName(item: { [string]: any }): string
	local setName = tostring(item.SetName or "Bug")
	local slot = tostring(item.Slot or "Equipment")
	return string.format("%s %s", setName, slot)
end

return EquipmentConfig
