# Bugs.OS Systems

This document describes every major gameplay system for Bugs.OS v1.0 and how systems connect.

## System Ownership Model

All gameplay rewards, rolls, currency changes, saves, marketplace actions, guild actions, tournament scores, and valuable inventory actions are server authoritative.

The client may request actions and render UI, but the server validates everything.

---

## Currency System

Currencies:

- Food
- Coins
- Nectar
- Bug Dust
- Guild XP
- Event Currency, future placeholder

Currency changes should flow through CurrencyService.

No script should directly mutate currency values without using server service helpers.

### Food

Food increases from:

- ClickService
- GeneratorService
- Offline earnings
- Rewards

Food is also added to LifetimeFood.

### Coins

Coins increase from MarketService when Food is sold.

### Nectar

Nectar increases from rare click drops, marketplace sales, events, achievements, and possibly purchases.

Nectar Chance bonuses multiply the base chance.

### Bug Dust

Bug Dust increases from sacrificing bugs, treasures, cores, and from rewards.

---

## Market.exe System

Market.exe converts Food into Coins.

Global market price:

- shared across every server
- updates every 30 seconds
- moves smoothly like a fake stock chart
- clamped from $0.50 to $3.00

Formula:

```txt
CoinsGained = FoodSold * CurrentMarketPrice * (1 + TotalSellBonus)
```

Sell buttons:

- Sell 10%
- Sell 50%
- Sell All

Auto-Sell Gamepass:

- one gamepass
- one target price
- on/off toggle
- sells all Food when current price is at or above target

---

## Click Tool Upgrade System

Click tools are permanent within a run but reset on prestige.

Rules:

- all visible from start
- 10 levels each
- coins spent to upgrade
- fixed Food/click per level
- prestige and buffs multiply total click output

Cost formula:

```txt
ToolLevelCost = BaseCost * Level^2
```

---

## Generator System

Food Harvesters are passive Food/sec sources.

Rules:

- slot-based
- no inventory
- one generator per slot
- replacing a generator deletes the old generator from the slot
- generators have levels only
- each generator has one fixed bonus at most
- bonuses only active while equipped
- generator levels reset on prestige

Formula:

```txt
Food/sec = BaseFoodPerSec * Level^1.55 * PrestigeMultiplier * Buffs
UpgradeCost = BaseUpgradeCost * Level^2.05
```

Classes:

- Snack
- Fruit
- Sandwich
- Dessert
- Picnic
- Garden
- Feast

---

## Prestige System

Prestige is based on lifetime Food.

Prestige resets active economy and keeps collection, premium, cosmetic, and social systems.

P1 to P10 multiplier increases by +0.1x per prestige.

P11+ adds +5x per prestige.

---

## Bug Spawn System

BugSpawnService rolls once per second while no bug is active.

Base chance:

```txt
2% per second
```

Modified by:

```txt
FinalChance = BaseChance * (1 + TotalSpawnBonus)
```

Spawn pity adds +0.15% additive chance each second without a spawn.

Only one active bug at a time for MVP.

---

## Catch the Bug Minigame

A bug appears on the desktop/world map. The player catches it by landing required clicks before time expires.

Difficulty scales by rarity:

- timer
- speed
- hitbox size
- movement pattern
- required hits
- decoys
- hiding behavior
- wrong-click penalties

Behavior types:

- Wanderer
- Zig-Zagger
- Dasher
- Orbiter
- Jumper
- Feinter
- Cloaker
- Splitter
- Phasing Bug
- Reactive Bug

Epic+ bugs may have weak points.

Perfect catches give extra rewards and Bug Point bonuses.

---

## Bug Points System

Bug Points are the core competitive metric.

Used for:

- minigame leaderboards
- weekend tournaments
- guild contribution
- guild XP
- achievements
- quests

Base points:

| Rarity | Points |
|---|---:|
| Common | 1 |
| Rare | 3 |
| Epic | 10 |
| Legendary | 35 |
| Mythic | 150 |

Multipliers may apply for:

- perfect catch
- no misses
- weak point hits
- behavior difficulty

---

## Bug Inventory System

Each bug is a unique instance with a UID.

Bug instance contains:

- species
- rarity
- primary stat
- secondary stats
- modifier
- lock/favorite state
- creation time

Bug stats are rolled server-side only.

Bug name is generated from attributes:

```txt
[Primary Attribute] [Secondary Attribute] [Species]
```

---

## Bug Farm System

Bug Farm slots determine which bugs are active.

Player starts with 5 bug slots.

Player gains +1 bug slot per prestige.

Player can buy up to 10 additional slots.

Extra Bug Farm slots cost 49 Robux each.

---

## Bug Dust System

Sources:

Bug sacrifice:

| Rarity | Dust |
|---|---:|
| Common | 50 |
| Rare | 200 |
| Epic | 1,000 |
| Legendary | 5,000 |
| Mythic | 25,000 |

Treasure sacrifice:

| Rarity | Dust |
|---|---:|
| Common | 25 |
| Rare | 100 |
| Epic | 500 |
| Legendary | 2,500 |
| Mythic | 10,000 |

Core sacrifice:

| Rarity | Dust |
|---|---:|
| Common | 200 |
| Rare | 1,000 |
| Epic | 5,000 |
| Legendary | 20,000 |
| Mythic | 100,000 |

Uses:

- bug modifiers
- secondary stat rerolls
- core rerolling
- core upgrading
- core crafting

---

## Bug Modifiers

Bug Dust can apply one modifier to a bug.

Early modifier list:

| Modifier | Effect |
|---|---|
| Shiny | Small boost to all stats on that bug |
| Mutated | Adds a small random extra secondary stat |
| Glitched | Boosts primary stat but lowers secondary stats |
| Stabilized | Protects secondary stat rerolls from rolling below current value |
| Overclocked | Stronger equipped effect, but only while online |

Modifier costs scale by bug rarity.

---

## Bugdex System

Permanent collection record.

Tracks:

- discovered species
- total catches
- best roll per species
- discovered attributes
- variants
- milestones

Rewards:

- species completion
- rarity completion
- milestone rewards
- attribute collection
- future set bonuses

---

## Treasure System

Treasures are equippable buff artifacts.

Rules:

- exactly one stat each
- value rolls within rarity range
- earned from expeditions
- can be equipped/unequipped freely
- can be locked/favorited
- can be sacrificed for Bug Dust
- Epic+ can be listed on Marketplace

Player starts with 5 treasure slots.

Up to 5 extra treasure slots can be bought for 99 Robux each.

---

## Expedition System

Expeditions are timed missions.

They always reward treasures and may reward Generator Cores.

Slots:

- starts with 1
- unlocks +1 per prestige up to 5 earned slots
- up to 5 additional Robux slots
- extra Expedition slots cost 99 Robux each

Expeditions:

| Expedition | Unlock | Duration |
|---|---|---|
| Backyard Dig | P2 | 30 min |
| Rotten Log Search | P3 | 2 hr |
| Garden Tunnel | P5 | 6 hr |
| Ancient Burrow | P7 | 12 hr |
| Queen’s Vault | P10 | 24 hr |

---

## Generator Core System

Unlocks at Prestige 7.

Each equipped generator gains one Core slot.

Core drop chance by expedition:

| Expedition | Core Drop Chance |
|---|---:|
| Backyard Dig | 0% |
| Rotten Log Search | 5% |
| Garden Tunnel | 12% |
| Ancient Burrow | 20% |
| Queen’s Vault | 35% |

Core rarity is rolled after a core drops.

Core systems:

- equip core
- remove core
- reroll secondary/conditional/value
- upgrade tier 0 to 5
- craft using duplicate cores and Bug Dust
- sacrifice for Bug Dust

Reroll cost doubles per attempt:

| Attempt | Cost |
|---|---:|
| 1 | 2,500 |
| 2 | 5,000 |
| 3 | 10,000 |
| 4 | 20,000 |
| 5+ | doubles |

Core upgrades:

| Tier | Cost | Effect Boost |
|---|---:|---:|
| 1 | 5,000 | +3% |
| 2 | 10,000 | +3% |
| 3 | 20,000 | +4% |
| 4 | 40,000 | +5% |
| 5 | 80,000 | +5% |

---

## Marketplace System

Marketplace.exe is a global listing system using Nectar.

Allowed:

- Epic+ bugs
- Epic+ treasures
- Epic+ cores

Not allowed:

- Common/Rare items
- locked items
- favorited items

Rules:

- 24 hour listing duration
- 10% Nectar tax on successful sale
- base 5 active listings
- expired listings return to seller
- no direct player-to-player trading in 1.0

---

## Leaderboard System

Player leaderboards:

- Lifetime Food
- Best Food/sec
- Coins
- Bug Points

Guild leaderboards:

- Guild Total Food
- Guild Bug Points

Scopes:

- all-time
- weekly
- daily where relevant

Food/sec is a server-verified snapshot, not a live per-second leaderboard write.

---

## Guild System

Guilds launch with 1.0.

Core features:

- create guild
- join guild
- leave guild
- owner/officer/member roles
- member cap
- guild chat
- guild quests
- guild perks
- guild research
- contribution tracking
- guild leaderboards

Base cap: 20 members.

Guild XP sources:

- Bug Points
- guild quests
- tournament placement
- daily activity

---

## Guild Chat

Guild chat is guild-only.

Rules:

- Roblox text filtering required
- never store unfiltered text
- cooldowns
- recent chat only
- officer+ moderation

---

## Guild Quest System

Quest types:

- daily guild quests
- weekly guild quests

Quest goals:

- earn Bug Points
- catch Epic+ bugs
- complete expeditions
- earn Food
- contribute resources

Rewards:

- Guild XP
- Bug Dust
- Nectar
- temporary guild buffs

---

## Guild Research System

Guild members contribute Food, Bug Points, and Bug Dust to unlock guild research.

Research bonuses should be moderate.

Examples:

- +2% All Food
- +5% Expedition Speed
- +3% Bug Spawn
- +3% Sell Bonus

---

## Achievement System

Achievement categories:

- clicking
- Food earned
- Coins earned
- prestige reached
- bugs caught
- rare bugs
- Bug Points
- expeditions
- treasures
- cores
- marketplace
- guild
- tournament
- event

Rewards:

- Coins
- Nectar
- Bug Dust
- Titles
- Cosmetics
- small permanent bonuses

---

## Weekend Tournament System

Weekend tournament is Bug Hunt.

Metric:

- Bug Points earned during tournament window

Schedule:

- Friday evening to Sunday night

Player and guild tournament scores are separate.

Uses OrderedDataStores for rankings.

---

## Desktop World Map

The desktop background is the world layer.

Server players show as colonies.

Clicking a colony opens the player profile.

World map may also show:

- bugs
- mystery caches
- event effects
- ambient props

---

## Desktop Customization

Cosmetic and monetization pillar.

Customizable:

- wallpaper
- taskbar
- window skin
- cursor
- notification style
- desktop effects
- sounds

---

## Colony Skins

Players collect colony skins.

Colony skins are cosmetic-first, with only small bonuses if any.

Examples:

- Mushroom Colony
- Crystal Hive
- Cyber Nest
- Rotten Colony
- Royal Colony
- Forest Colony
- Volcanic Colony
- Glitched Colony
- Frozen Colony
- Neon Colony

---

## Player Profiles and Titles

Profile opens from:

- colony click
- leaderboard name
- guild member
- marketplace seller

Profile shows:

- colony skin
- title
- guild
- prestige
- lifetime Food
- Bug Points
- favorite bug
- tournament history
- achievements

Titles are earned from achievements, events, tournaments, guild milestones, and rare catches.

---

## Weekly Event System

Every week should include:

- special event bug
- special event treasure
- event theme
- event rewards

Optional:

- event wallpaper
- title
- colony skin
- mystery cache skin
- guild quest theme

---

## Mystery Cache System

Mystery caches are rare clickable desktop anomalies.

Possible rewards:

- Bug Dust
- Nectar
- event items
- cosmetics
- expedition boosts
- small chance at bugs, treasures, or cores

---

## Server-Wide Random Events

Events:

- Bug Swarm
- Market Surge
- Nectar Storm
- System Corruption
- Expedition Rush

Dev product:

- Trigger Random Server Event

Rules:

- random only
- server cooldown
- server-wide effect
- OS popup announcement

---

## Loadout System

Loadouts save UID references only.

They may include:

- bug UID assignments
- treasure UID assignments
- generator IDs
- core UIDs

Never duplicate item instance data in loadouts.

Before applying a loadout, server validates ownership, slot unlocks, item existence, and legality.
