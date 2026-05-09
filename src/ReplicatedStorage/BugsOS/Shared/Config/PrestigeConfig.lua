--!strict

local PrestigeConfig = {}

PrestigeConfig.BaseRequirement = 50_000_000
PrestigeConfig.RequirementGrowth = 1.85
PrestigeConfig.MultiplierPerLevel = 0.1
PrestigeConfig.MaxRoadmapLevels = 100

function PrestigeConfig.GetRequiredLifetimeFood(nextPrestigeLevel: number): number
	if nextPrestigeLevel <= 1 then
		return PrestigeConfig.BaseRequirement
	end
	return math.floor(PrestigeConfig.BaseRequirement * (PrestigeConfig.RequirementGrowth ^ (nextPrestigeLevel - 1)))
end

function PrestigeConfig.GetMultiplier(prestigeLevel: number): number
	local level = math.max(0, prestigeLevel)
	return 1 + (level * PrestigeConfig.MultiplierPerLevel)
end

function PrestigeConfig.GetRoadmapRows(currentPrestige: number, count: number): { [number]: { level: number, multiplier: number, requiredLifetimeFood: number } }
	local rows = {}
	local rowCount = math.max(1, math.min(count, PrestigeConfig.MaxRoadmapLevels))
	for step = 1, rowCount do
		local level = currentPrestige + step
		table.insert(rows, {
			level = level,
			multiplier = PrestigeConfig.GetMultiplier(level),
			requiredLifetimeFood = PrestigeConfig.GetRequiredLifetimeFood(level),
		})
	end
	return rows
end

return PrestigeConfig
