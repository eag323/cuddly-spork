--!strict

local BugAscensionConfig = {}

BugAscensionConfig.MaxRank = 5

BugAscensionConfig.CostsByRarity = {
	Common = {5, 10, 20, 40, 80},
	Uncommon = {10, 20, 40, 80, 160},
	Rare = {25, 50, 100, 200, 400},
	Epic = {75, 150, 300, 600, 1200},
	Legendary = {250, 500, 1000, 2000, 4000},
	Mythic = {1000, 2000, 4000, 8000, 16000},
}

-- Ascension currently scales combat stats only.
-- Farmer bonuses are intentionally excluded for now to avoid destabilizing economy progression.
BugAscensionConfig.CombatStatMultiplierPerRank = 0.10

function BugAscensionConfig.GetMaxRank()
	return BugAscensionConfig.MaxRank
end

function BugAscensionConfig.GetCost(rarity: string, currentRank: number)
	local costs = BugAscensionConfig.CostsByRarity[tostring(rarity)] or BugAscensionConfig.CostsByRarity.Common
	local rank = math.max(0, math.floor(tonumber(currentRank) or 0))
	if rank >= BugAscensionConfig.MaxRank then
		return nil
	end
	return costs[rank + 1]
end

function BugAscensionConfig.GetCombatMultiplier(rank: number)
	local clampedRank = math.max(0, math.min(BugAscensionConfig.MaxRank, math.floor(tonumber(rank) or 0)))
	return 1 + (clampedRank * BugAscensionConfig.CombatStatMultiplierPerRank)
end

function BugAscensionConfig.GetNextCombatMultiplier(currentRank: number)
	local rank = math.max(0, math.floor(tonumber(currentRank) or 0))
	return BugAscensionConfig.GetCombatMultiplier(math.min(BugAscensionConfig.MaxRank, rank + 1))
end

function BugAscensionConfig.GetDisplayRank(rank: number)
	local clampedRank = math.max(0, math.min(BugAscensionConfig.MaxRank, math.floor(tonumber(rank) or 0)))
	return string.format("Rank %d / %d", clampedRank, BugAscensionConfig.MaxRank)
end

return BugAscensionConfig
