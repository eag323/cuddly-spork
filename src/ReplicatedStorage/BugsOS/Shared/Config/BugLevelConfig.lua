--!strict

local BugLevelConfig = {}

BugLevelConfig.MaxLevel = 30
BugLevelConfig.BaseXpPerLevel = 100
BugLevelConfig.XpGrowth = 1.18
BugLevelConfig.CombatStatGrowthPerLevel = 0.025

function BugLevelConfig.GetXpRequiredForLevel(level: number): number
	local clampedLevel = math.max(1, math.min(BugLevelConfig.MaxLevel, math.floor(tonumber(level) or 1)))
	if clampedLevel >= BugLevelConfig.MaxLevel then
		return 0
	end
	return math.max(1, math.floor(BugLevelConfig.BaseXpPerLevel * (BugLevelConfig.XpGrowth ^ (clampedLevel - 1)) + 0.5))
end

function BugLevelConfig.GetTotalXpForLevel(level: number): number
	local clampedLevel = math.max(1, math.min(BugLevelConfig.MaxLevel, math.floor(tonumber(level) or 1)))
	local totalXp = 0
	for currentLevel = 1, clampedLevel - 1 do
		totalXp += BugLevelConfig.GetXpRequiredForLevel(currentLevel)
	end
	return totalXp
end

function BugLevelConfig.GetLevelFromXp(totalXp: number): number
	local remainingXp = math.max(0, math.floor(tonumber(totalXp) or 0))
	local level = 1
	while level < BugLevelConfig.MaxLevel do
		local required = BugLevelConfig.GetXpRequiredForLevel(level)
		if remainingXp < required then
			break
		end
		remainingXp -= required
		level += 1
	end
	return level
end

function BugLevelConfig.GetLevelProgress(totalXp: number)
	local safeTotalXp = math.max(0, math.floor(tonumber(totalXp) or 0))
	local level = BugLevelConfig.GetLevelFromXp(safeTotalXp)
	local levelStartXp = BugLevelConfig.GetTotalXpForLevel(level)
	local required = BugLevelConfig.GetXpRequiredForLevel(level)
	local current = math.max(0, safeTotalXp - levelStartXp)
	if level >= BugLevelConfig.MaxLevel then
		current = 0
		required = 0
	end
	local percent = required > 0 and math.clamp(current / required, 0, 1) or 1
	return {
		Level = level,
		Current = current,
		Required = required,
		Percent = percent,
	}
end

function BugLevelConfig.GetCombatLevelMultiplier(level: number): number
	local clampedLevel = math.max(1, math.min(BugLevelConfig.MaxLevel, math.floor(tonumber(level) or 1)))
	return 1 + ((clampedLevel - 1) * BugLevelConfig.CombatStatGrowthPerLevel)
end

return BugLevelConfig
