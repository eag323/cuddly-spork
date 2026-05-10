--!strict

local MarketEventConfig = {}

MarketEventConfig.RollIntervalSeconds = 600
MarketEventConfig.DefaultHeadline = "ANTX ▲ 2.4%  |  HIVECO ▼ 1.1%  |  NECTR ▲ 5.8%  |  BugMart reports record larva demand  |  BeetleBay trading volume spikes  |  Queen Futures steady"
MarketEventConfig.NormalMinPrice = 0.50
MarketEventConfig.NormalMaxPrice = 3.00
MarketEventConfig.RareMaxPrice = 5.00
MarketEventConfig.NormalMoveMin = 0.05
MarketEventConfig.NormalMoveMax = 0.50

MarketEventConfig.Events = {
	{
		Id = "PicnicRush",
		Name = "Picnic Rush",
		Description = "BREAKING: Backyard picnic discovered. Food demand surging.",
		DurationSeconds = 180,
		UpChance = 0.75,
		MoveMin = 0.08,
		MoveMax = 0.65,
		Weight = 30,
	},
	{
		Id = "Rainstorm",
		Name = "Rainstorm",
		Description = "ALERT: Rainstorm flooding tunnels. Food transport slowing.",
		DurationSeconds = 180,
		DownChance = 0.75,
		MoveMin = 0.08,
		MoveMax = 0.65,
		Weight = 30,
	},
	{
		Id = "QueenFeast",
		Name = "Queen Feast",
		Description = "Queen colony feast announced. Food demand rising.",
		DurationSeconds = 120,
		UpChance = 0.75,
		MoveMin = 0.08,
		MoveMax = 0.60,
		Weight = 20,
	},
	{
		Id = "AntStrike",
		Name = "Ant Strike",
		Description = "Worker ants on strike. Market supply disrupted.",
		DurationSeconds = 180,
		MoveMin = 0.25,
		MoveMax = 0.80,
		HighVolatility = true,
		Weight = 15,
	},
	{
		Id = "NectarBloom",
		Name = "Nectar Bloom",
		Description = "Nectar bloom draws traders away from food.",
		DurationSeconds = 120,
		DownChance = 0.70,
		MoveMin = 0.08,
		MoveMax = 0.55,
		Weight = 20,
	},
	{
		Id = "GoldenPicnic",
		Name = "Golden Picnic",
		Description = "RARE EVENT: Golden picnic found. Food prices uncapped for a limited time.",
		DurationSeconds = 120,
		UpChance = 0.85,
		MoveMin = 0.20,
		MoveMax = 0.85,
		MaxCap = 5.00,
		Weight = 2,
		Rare = true,
	},
}

return MarketEventConfig
