--!strict

local EconomyConfig = {
	-- DEVELOPMENT ONLY: Set to false before real release/balance pass.
	DEV_MODE = true,
	-- DEVELOPMENT ONLY: Must be disabled before real release.
	DEV_CLICK_MULTIPLIER = 100,
	-- DEVELOPMENT ONLY: Must be disabled before real release.
	DEV_GENERATOR_MULTIPLIER = 10,
	-- DEVELOPMENT ONLY: Must be disabled before real release.
	DEV_MARKET_MULTIPLIER = 1,
	-- DEVELOPMENT ONLY: Force bug spawn interval for minigame balancing.
	DEV_FORCE_BUG_SPAWN_INTERVAL = 8,
	-- DEVELOPMENT ONLY: Enables verbose buff and Food/sec debug logs.
	DEV_DEBUG_BUFFS = false,
	-- DEVELOPMENT ONLY: Strongly boosts bug rarity rolls for testing reward visuals.
	DEV_INSANE_BUG_LUCK = true,
	-- DEVELOPMENT ONLY: Added bug luck amount when insane luck mode is enabled.
	DEV_INSANE_BUG_LUCK_AMOUNT = 25,
	-- DEVELOPMENT ONLY: Optional rarity override. Example: "Mythic".
	DEV_FORCE_RARITY = nil,
	-- DEVELOPMENT ONLY: Optional bonus quality override. Allowed: nil, "Good", "Great", "Perfect".
	DEV_FORCE_BONUS_QUALITY = nil,
}

return EconomyConfig
