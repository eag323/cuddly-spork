--!strict

local EnemySpawnConfig = {
	SpawnIntervalSecondsMin = 10,
	SpawnIntervalSecondsMax = 20,
	EnemyLifetimeSeconds = 120,
	MaxActiveEnemiesPerPlayer = 1,
	DesktopMarginPixels = 80,
	EnemySizePixels = 76,
	AuraSizePixels = 108,

	-- Placeholder balance for v1; tune once we have live combat telemetry.
	Tiers = {
		CommonEnemy = {
			Weight = 70,
			StatMultiplier = 0.75,
			RewardBugEssence = { Min = 1, Max = 3 },
		},
		RareEnemy = {
			Weight = 23,
			StatMultiplier = 1.0,
			RewardBugEssence = { Min = 3, Max = 7 },
		},
		EliteEnemy = {
			Weight = 6,
			StatMultiplier = 1.35,
			RewardBugEssence = { Min = 8, Max = 15 },
		},
		MythicEnemy = {
			Weight = 1,
			StatMultiplier = 1.85,
			RewardBugEssence = { Min = 20, Max = 40 },
		},
	},
}

return EnemySpawnConfig
