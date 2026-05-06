# Bugs.OS State Schema

This document defines player, guild, marketplace, tournament, and global state schemas.

All unique items use UIDs.

All static definitions use config IDs.

---

## PlayerData

```lua
PlayerData = {
    Version = 1,

    Currencies = {
        Food = 0,
        Coins = 0,
        Nectar = 0,
        BugDust = 0,
        LifetimeFood = 0,
    },

    Progression = {
        Prestige = 0,
        LastLogin = 0,
        TotalPlayTime = 0,
    },

    ClickTools = {
        -- [ToolId] = level
    },

    Generators = {
        SlotsUnlocked = 3,
        Equipped = {
            -- [slotIndex] = {
            --     GeneratorId = "PlainCracker",
            --     Level = 1,
            --     CoreUid = nil,
            -- }
        }
    },

    Bugs = {
        Inventory = {
            -- [uid] = BugInstance
        },
        Equipped = {
            -- [slotIndex] = bugUid
        },
        SlotsUnlocked = 5,
    },

    Treasures = {
        Inventory = {
            -- [uid] = TreasureInstance
        },
        Equipped = {
            -- [slotIndex] = treasureUid
        },
        SlotsUnlocked = 5,
    },

    GeneratorCores = {
        Inventory = {
            -- [uid] = CoreInstance
        }
    },

    Bugdex = {
        SpeciesDiscovered = {},
        BestRollBySpecies = {},
        TotalCaughtBySpecies = {},
        AttributesDiscovered = {},
        VariantsDiscovered = {},
        MilestonesClaimed = {},
    },

    Expeditions = {
        SlotsUnlocked = 1,
        Active = {
            -- [slotIndex] = ExpeditionRun
        }
    },

    Guild = {
        GuildId = nil,
        Role = nil,
        ContributionFood = 0,
        ContributionBugPoints = 0,
    },

    Achievements = {
        Progress = {},
        Claimed = {},
    },

    LeaderboardStats = {
        LifetimeFood = 0,
        BestFoodPerSec = 0,
        CoinsEarned = 0,
        BugPoints = 0,

        Daily = {},
        Weekly = {},
    },

    Tournament = {
        WeekendBugPoints = 0,
        LastRewardClaimedTournamentId = nil,
    },

    Cosmetics = {
        Owned = {
            Wallpapers = {},
            Taskbars = {},
            WindowSkins = {},
            Cursors = {},
            NotificationSkins = {},
            DesktopEffects = {},
            ColonySkins = {},
            ProfileFrames = {},
            Titles = {},
        },

        Equipped = {
            Wallpaper = "DefaultWallpaper",
            Taskbar = "DefaultTaskbar",
            WindowSkin = "DefaultWindowSkin",
            Cursor = "DefaultCursor",
            NotificationSkin = "DefaultNotification",
            DesktopEffect = nil,
            ColonySkin = "DefaultColony",
            ProfileFrame = "DefaultProfileFrame",
            Title = nil,
        }
    },

    Loadouts = {
        -- [LoadoutId] = Loadout
    },

    DailyPrograms = {
        Active = {},
        Claimed = {},
        LastReset = 0,
    },

    WeeklyEvents = {
        ActiveEventId = nil,
        Progress = {},
        Claimed = {},
    },

    Purchases = {
        ExtraGeneratorSlots = 0,
        ExtraBugSlots = 0,
        ExtraTreasureSlots = 0,
        ExtraExpeditionSlots = 0,
        AutoSellOwned = false,
    },

    Settings = {
        AutoSellEnabled = false,
        AutoSellTarget = 2.5,
    }
}
```

---

## BugInstance

```lua
BugInstance = {
    Uid = "bug_abc123",
    Species = "CrystalAnt",
    DisplayName = "Enchanted Huge Crystal Ant",
    Rarity = "Mythic",

    Primary = {
        Stat = "AllFood",
        Attribute = "Enchanted",
        Value = 0.875,
    },

    Secondaries = {
        {
            Stat = "FoodPerSec",
            Attribute = "Huge",
            Value = 0.22,
        }
    },

    Modifier = nil,
    Locked = false,
    Favorited = false,
    CreatedAt = 0,
}
```

---

## TreasureInstance

```lua
TreasureInstance = {
    Uid = "treasure_abc123",
    TreasureId = "HeartOfTheHive",
    Rarity = "Mythic",
    Stat = "AllFood",
    Value = 0.44,

    Locked = false,
    Favorited = false,
    CreatedAt = 0,
}
```

---

## CoreInstance

```lua
CoreInstance = {
    Uid = "core_abc123",
    CoreId = "OverclockCore",
    Rarity = "Legendary",

    PrimaryEffect = {
        Type = "GeneratorFoodPerSec",
        Value = 0.42,
    },

    SecondaryEffect = nil,
    ConditionalEffect = nil,

    UpgradeTier = 0,
    RerollCount = 0,

    Locked = false,
    Favorited = false,
    CreatedAt = 0,
}
```

---

## ExpeditionRun

```lua
ExpeditionRun = {
    ExpeditionId = "BackyardDig",
    StartedAt = 0,
    EndsAt = 0,
    InstantFinishProductId = nil,
}
```

---

## Loadout

Loadouts must save UID references only.

Never duplicate full item data inside loadouts.

```lua
Loadout = {
    LoadoutId = "loadout_1",
    Name = "Bug Hunter",

    EquippedBugs = {
        -- [slotIndex] = bugUid
    },

    EquippedTreasures = {
        -- [slotIndex] = treasureUid
    },

    EquippedGenerators = {
        -- [slotIndex] = {
        --     GeneratorId = "CornCob",
        --     CoreUid = "core_uid_1",
        -- }
    },

    UpdatedAt = 0,
}
```

---

## GuildData

Separate datastore.

```lua
GuildData = {
    Version = 1,

    GuildId = "guild_abc123",
    Name = "Bug Raiders",
    Tag = "BUG",
    OwnerUserId = 123,

    Members = {
        -- [userId] = {
        --   Role = "Owner",
        --   JoinedAt = 0,
        --   ContributionFood = 0,
        --   ContributionBugPoints = 0,
        --   LastActive = 0,
        -- }
    },

    Level = 1,
    XP = 0,
    PerksUnlocked = {},

    Quests = {
        Daily = {},
        Weekly = {},
        LastDailyReset = 0,
        LastWeeklyReset = 0,
    },

    Research = {
        Nodes = {
            -- [ResearchId] = {
            --   Level = 0,
            --   Progress = 0,
            -- }
        }
    },

    ChatLog = {
        -- recent filtered messages only
    },

    Cosmetics = {
        Emblem = nil,
        Banner = nil,
        Badge = nil,
    },

    CreatedAt = 0,
}
```

---

## GuildChatMessage

Store only filtered text.

```lua
GuildChatMessage = {
    UserId = 123,
    DisplayName = "Player",
    Message = "filtered text",
    SentAt = 0,
}
```

---

## MarketplaceListing

Separate global datastore.

```lua
MarketplaceListing = {
    ListingId = "listing_abc123",
    SellerUserId = 123,
    SellerName = "PlayerName",

    ItemType = "Bug",
    ItemData = {},

    Price = 1000,
    CreatedAt = 0,
    ExpiresAt = 0,
}
```

Important:

- ItemData is removed from seller inventory while listed.
- Buyer receives ItemData on purchase.
- Expired listing returns ItemData to seller.
- Seller receives Nectar minus tax on successful purchase.

---

## MarketState

Global market state.

```lua
MarketState = {
    Price = 1.72,
    LastUpdated = 0,
    NextUpdate = 0,
    Trend = 0.03,
    History = {
        -- last 30 to 60 prices
    }
}
```

---

## TournamentState

```lua
TournamentState = {
    TournamentId = "BugHunt_2026_W18",
    Type = "BugHunt",
    StartsAt = 0,
    EndsAt = 0,
    RewardsClaimed = {},
}
```

Player tournament score is stored in OrderedDataStore.

Guild tournament score is stored in OrderedDataStore.

---

## MysteryCache

```lua
MysteryCache = {
    CacheId = "cache_abc123",
    CacheType = "CorruptedFile",
    SpawnedAt = 0,
    ExpiresAt = 0,
    ClaimedBy = {},
}
```

---

## ServerEventState

```lua
ServerEventState = {
    EventId = "BugSwarm",
    StartedAt = 0,
    EndsAt = 0,
    TriggeredByUserId = nil,
    Effects = {},
}
```

---

## PublicProfileData

This is safe data shown to other players.

```lua
PublicProfileData = {
    UserId = 123,
    DisplayName = "Player",
    Prestige = 5,
    GuildName = "Bug Raiders",
    GuildTag = "BUG",
    Title = "Mythic Hunter",
    ColonySkin = "CrystalHive",
    ProfileFrame = "DefaultProfileFrame",

    LifetimeFood = 0,
    BugPoints = 0,
    BestFoodPerSec = 0,

    FavoriteBug = {
        Species = "CrystalAnt",
        Rarity = "Mythic",
        DisplayName = "Enchanted Crystal Ant",
    },

    TournamentHistory = {},
    AchievementBadges = {},
}
```

---

## Data Migration Notes

- Always include Version.
- Never remove old fields without migration logic.
- Add new fields with defaults.
- Keep inventory items keyed by UIDs.
- Keep static content keyed by config IDs.
- Loadout references must be cleaned if the referenced item no longer exists.
