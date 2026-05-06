# Bugs.OS Game Bible

## Game Overview

Bugs.OS is a Roblox idle, clicker, collection, social, and trading game where the player manages a bug colony through a retro desktop operating system interface.

The player collects Food, sells Food for Coins through Market.exe, upgrades clicking and Food Harvesters, catches bugs through desktop minigames, equips bugs and treasures for buffs, joins guilds, competes in bug point tournaments, customizes their desktop and colony, and prestiges for permanent multipliers.

The desktop background is also the world map. Other players in the same server appear as visible colonies on the desktop map.

No real Windows branding, logos, names, or copyrighted icon designs should be used. The style is inspired by old operating systems, not copied from them.

Avoid em dashes in all user-facing text.

---

## Core Fantasy

The player runs a bug colony through an old operating system. Every feature feels like opening an app or interacting with a desktop program.

Apps include:

- Market.exe
- Upgrades.exe
- Food Harvesters.exe
- Bug Farm.exe
- Expeditions.exe
- Marketplace.exe
- Bugdex.exe
- Guilds.exe
- Leaderboards.exe
- Achievements.exe
- Tournament.exe
- Profile.exe
- Settings.exe

---

## Core Loop

1. Player clicks the desktop/world background to collect Food.
2. Food Harvesters generate passive Food/sec.
3. Player sells Food through Market.exe for Coins.
4. Player spends Coins on click tools and Food Harvester upgrades.
5. Random bug minigames appear on the desktop.
6. Player catches bugs, earns Bug Points, and collects bugs.
7. Player equips bugs in Bug Farm slots for buffs.
8. Player runs Expeditions to earn treasures and Generator Cores.
9. Player equips treasures and Generator Cores to optimize builds.
10. Player joins guilds, contributes to quests and research, and competes in tournaments.
11. Player prestiges after lifetime Food milestones for permanent multipliers.
12. Player customizes desktop, colony skin, profile, titles, and cosmetics.

---

## Currencies

### Food

Main collected resource.

Sources:

- Clicking
- Food Harvesters
- Offline earnings
- Bonuses

Uses:

- Sold for Coins through Market.exe

No Food storage cap.

### Coins

Main upgrade currency.

Sources:

- Selling Food

Uses:

- Click tool upgrades
- Generator upgrades

### Nectar

Premium and trading currency.

Sources:

- Rare click drops
- Marketplace sales
- Events
- Achievements
- Possible premium purchase

Uses:

- Marketplace purchases
- Cosmetics
- Possible premium systems

Nectar Chance bonuses are multiplicative increases to the base drop chance.

Example:

Base Nectar drop chance is 0.10%.

+50% Nectar Chance makes it 0.15%, not 50.10%.

### Bug Dust

Sacrifice and optimization currency.

Sources:

- Sacrificing bugs
- Sacrificing treasures
- Sacrificing Generator Cores
- Events and achievements

Uses:

- Bug modifiers
- Secondary stat rerolls
- Generator Core rerolling
- Generator Core upgrading
- Generator Core crafting

---

## Prestige

Prestige is called:

- Prestige 1
- Prestige 2
- Prestige 3

No special prestige name and no prestige currency.

Prestige requirement is based on lifetime total Food collected, not Food collected during current run.

### Prestige Multipliers

- P1 = 1.1x
- P2 = 1.2x
- P3 = 1.3x
- P4 = 1.4x
- P5 = 1.5x
- P6 = 1.6x
- P7 = 1.7x
- P8 = 1.8x
- P9 = 1.9x
- P10 = 2.0x
- P11+ adds +5x per prestige level

Examples:

- P10 = 2x
- P11 = 7x
- P12 = 12x
- P13 = 17x

### Prestige Resets

Prestige resets:

- Food
- Coins
- Click power upgrades
- Equipped generators
- Generator levels

Prestige keeps:

- Bugs
- Treasures
- Nectar
- Bug Dust
- Robux-purchased slots
- Cosmetics
- Achievements
- Bugdex discoveries
- Guild membership
- Titles
- Desktop cosmetics
- Colony skins

### Draft Requirements

| Prestige | Lifetime Food Required |
|---|---:|
| P1 | 50M |
| P2 | 750M |
| P3 | 7.5B |
| P4 | 60B |
| P5 | 400B |
| P6 | 2.5T |
| P7 | 15T |
| P8 | 90T |
| P9 | 500T |
| P10 | 3Qa |

---

## System Unlocks

| Prestige | Unlocks |
|---|---|
| P0 | Desktop, clicking, Market.exe, Snack generators, 3 generator slots, 5 bug slots, 5 treasure slots |
| P1 | Fruit generators, +1 generator slot, +1 bug slot |
| P2 | Expeditions, first expedition slot, Backyard Dig, +1 generator slot, +1 bug slot |
| P3 | Sandwich generators, Rotten Log Search, +1 generator slot, +1 bug slot |
| P4 | Bug and Treasure Marketplace, +1 generator slot, +1 bug slot |
| P5 | Dessert generators, Garden Tunnel, +1 generator slot, +1 bug slot |
| P6 | Bug Dust sacrifice system, +1 generator slot, +1 bug slot |
| P7 | Picnic generators, Generator Cores, Core slots, Special Generator Upgrades, Ancient Burrow, +1 generator slot, +1 bug slot |
| P8 | Advanced Bug Farm, loadouts, +1 generator slot, +1 bug slot |
| P9 | Garden generators, +1 generator slot, +1 bug slot |
| P10 | Feast generators, Queen’s Vault, final base-game class unlock, +1 generator slot, +1 bug slot |

---

## Market.exe

Food is sold for Coins through Market.exe.

The global Food price is shared across every player in every server.

Rules:

- Price updates every 30 seconds
- Minimum price: $0.50
- Maximum price: $3.00
- Price moves like a fake stock chart
- Price does not fully reroll every tick
- Market shows a stock ticker style history chart

Coin formula:

```txt
CoinsGained = FoodSold * CurrentMarketPrice * (1 + TotalSellBonus)
```

Sell Bonus affects personal Coins received, not global market price.

Sell buttons:

- Sell 10%
- Sell 50%
- Sell All

Auto-Sell Gamepass:

- One gamepass
- Player sets minimum target price from $0.50 to $3.00
- Auto-sells all Food when current price is at or above target
- Has on/off toggle
- Shows recent sale feedback

Example:

```txt
Auto-Sell: ON
Target: $2.50
Auto-sold 4.2M Food at $2.60
```

---

## Upgrades.exe

Click tools are garden-tool themed.

Rules:

- All tools visible from start
- Tools are not prestige-unlocked
- Each tool has 10 levels
- Each level adds fixed Food/click
- Coins are used to upgrade tools
- Highest tool is capped at +5,000 Food/click per level

Approved tools:

| Tool | Food/click Per Level | Max Base Food/click |
|---|---:|---:|
| Bare Hands | +1 | +10 |
| Garden Glove | +5 | +50 |
| Hand Trowel | +15 | +150 |
| Watering Can | +35 | +350 |
| Pruning Shears | +75 | +750 |
| Garden Hoe | +150 | +1,500 |
| Rake | +300 | +3,000 |
| Shovel | +600 | +6,000 |
| Wheelbarrow | +1,000 | +10,000 |
| Sprinkler | +1,500 | +15,000 |
| Fertilizer Spreader | +2,000 | +20,000 |
| Compost Wand | +2,750 | +27,500 |
| Golden Spade | +3,500 | +35,000 |
| Crystal Cultivator | +4,250 | +42,500 |
| Royal Harvester | +5,000 | +50,000 |

Fully maxed raw base click power is 208,260 Food/click before multipliers.

Cost formula:

```txt
ToolLevelCost = BaseCost * Level^2
```

Approved base costs:

| Tool | Base Cost |
|---|---:|
| Bare Hands | 10 |
| Garden Glove | 75 |
| Hand Trowel | 500 |
| Watering Can | 2,500 |
| Pruning Shears | 12,000 |
| Garden Hoe | 60,000 |
| Rake | 300,000 |
| Shovel | 1,500,000 |
| Wheelbarrow | 7,500,000 |
| Sprinkler | 35,000,000 |
| Fertilizer Spreader | 175,000,000 |
| Compost Wand | 850,000,000 |
| Golden Spade | 4,000,000,000 |
| Crystal Cultivator | 20,000,000,000 |
| Royal Harvester | 100,000,000,000 |

---

## Food Harvesters.exe

Food Harvesters generate passive Food/sec.

Rules:

- Slot-based
- No generator inventory
- Replacing a generator permanently deletes current generator from slot
- Generators have levels only
- No owned amount stacking
- One generator per slot
- Each generator has one fixed bonus at most
- One generator per class can have no bonus and higher raw Food/sec
- Generator bonuses only active while equipped
- Bonuses do not scale with level
- Food/sec scales with level

Formula:

```txt
Food/sec = BaseFoodPerSec * Level^1.55 * PrestigeMultiplier * Buffs
UpgradeCost = BaseUpgradeCost * Level^2.05
```

Generator classes:

- Snack at P0
- Fruit at P1
- Sandwich at P3
- Dessert at P5
- Picnic at P7
- Garden at P9
- Feast at P10

---

## Generator Cores

Unlock at Prestige 7.

Each equipped generator gains one Core slot.

Generator Cores are rare equippable modifiers for generators. They are chase items that add build depth.

Sources:

- Expeditions
- Weekly events
- Marketplace
- Future crafting

Cores have:

- Core identity
- Rarity
- Primary effect
- Optional secondary effect
- Optional conditional effect
- Upgrade tier
- Reroll count

Core rarity:

- Common
- Rare
- Epic
- Legendary
- Mythic

Core systems:

- Drops
- Rerolling with Bug Dust
- Upgrading with Bug Dust
- Crafting with Bug Dust and duplicate cores
- Sacrificing cores for Bug Dust

Only Epic+ cores can be listed on the Marketplace.

---

## Bugs

Bugs are collectible buff items.

They do not produce Food directly. They provide stat bonuses when equipped.

Every bug has:

- Species
- Rarity
- Primary stat
- Optional secondary stats
- Attribute-based name
- Stat values
- Lock/favorite state
- Optional modifier

Bug stat types:

| Stat | Attribute Name | Meaning |
|---|---|---|
| All Earnings | Enchanted | Boosts overall Food earnings |
| Food/sec | Huge | Boosts passive Food/sec |
| Click Power | Mighty | Boosts Food per click |
| Sell Bonus | Merchant | Boosts Coins earned when selling Food |
| Nectar Chance | Golden | Boosts rare Nectar drop chance from clicking |
| Bug Luck | Lucky | Improves chances of better bug outcomes |
| Minigame Spawn Chance | Luring | Makes bug minigames appear more often |
| Minigame Time | Swift | Gives more time during bug minigames |
| Expedition Speed | Adventurous | Reduces expedition timers |
| Offline Earnings | Tireless | Improves offline Food generation |

Bug name format:

```txt
[Primary Attribute] [Secondary Attribute] [Species]
```

Example:

```txt
Enchanted Huge Crystal Ant
```

Bug species:

| Rarity | Species |
|---|---|
| Common | Worker Ant, House Fly, Pill Bug, Garden Aphid, Tiny Termite, Field Cricket, Fruit Gnat, Small Moth |
| Rare | Ladybug, Honey Bee, Firefly, Grasshopper, Stink Bug, Earwig, Carpenter Ant, Leafhopper |
| Epic | Rhinoceros Beetle, Jumping Spider, Praying Mantis, Dragonfly, Velvet Ant, Cicada, Dung Beetle, Tarantula Hawk Wasp |
| Legendary | Atlas Moth, Hercules Beetle, Orchid Mantis, Emperor Scorpion, Goliath Beetle, Luna Moth, Jewel Beetle, Assassin Bug |
| Mythic | Crystal Ant, Golden Scarab, Royal Stag Beetle, Phantom Mantis, Ancient Dragonfly, Celestial Firefly, Obsidian Widow, Prismatic Beetle |

---

## Bug Farm

Player starts with 5 bug slots.

Player gains +1 bug slot per prestige.

Player can buy up to 10 extra Bug Farm slots.

Extra Bug Farm slots cost 49 Robux each.

Bug slots determine which bugs provide active bonuses.

---

## Bug Minigame

Approved MVP minigame:

Catch the Bug.

A bug randomly spawns on the desktop/world background and moves around. Player must click it enough times before timer runs out.

Rarity difficulty:

| Rarity | Timer | Hits Needed | Movement |
|---|---:|---:|---|
| Common | 12s | 1 | Slow, large hitbox |
| Rare | 10s | 2 | Medium speed |
| Epic | 8s | 3 | Fast with turns |
| Legendary | 6s | 4 | Small hitbox, fake-outs |
| Mythic | 5s | 5 | Very fast, hiding |

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

Precision hit system:

- Click must land in hitbox
- Misses apply short penalty
- Weak points may appear on Epic+ bugs
- Perfect catch grants bonus Bug Dust and Bug Points

Failed Epic+ bugs can trigger recovery dev products:

| Rarity | Recovery Price |
|---|---:|
| Epic | 19 Robux |
| Legendary | 49 Robux |
| Mythic | 99 Robux |

Recovery applies only to the exact failed bug event and expires after a short time, suggested 60 seconds.

---

## Bug Spawn System

Every second, server rolls bug spawn chance.

Base spawn chance:

```txt
2% per second
```

Formula:

```txt
FinalChance = BaseChance * (1 + TotalSpawnBonus)
```

Max one active bug at a time for MVP.

Spawn pity:

Every second without a bug spawn adds +0.15% additive spawn chance.

Rarity table:

| Rarity | Chance |
|---|---:|
| Common | 60% |
| Rare | 25% |
| Epic | 10% |
| Legendary | 4% |
| Mythic | 1% |

Rarity pity:

- 10 bugs without Epic+ guarantees next bug is Epic+
- 25 bugs without Legendary+ guarantees next bug is Legendary+
- 75 bugs without Mythic guarantees next bug is Mythic

Catch streak:

- 3 catches: +5% spawn bonus
- 5 catches: +10% spawn bonus
- 10 catches: +20% spawn bonus

Fail protection:

- Failing a bug gives temporary +25% next spawn boost
- Failing Epic+ guarantees next bug is Rare+

---

## Bug Points

Bug Points are the main competitive metric for bug minigames, leaderboards, guild contribution, and weekend tournaments.

Base points:

| Rarity | Points |
|---|---:|
| Common | 1 |
| Rare | 3 |
| Epic | 10 |
| Legendary | 35 |
| Mythic | 150 |

Bonuses:

- Perfect catch
- No misses
- Weak point hits
- Behavior difficulty

Bug Points replace Minigame Wins on leaderboards.

---

## Bugdex

Bugdex permanently tracks bugs discovered.

Tracks:

- Species discovered
- Best stat roll by species
- Total catches by species
- Attributes discovered
- Variants discovered
- Milestones claimed

Rewards:

- Species completion rewards
- Rarity completion rewards
- Milestone rewards
- Attribute collection rewards
- Future set bonuses

Bugdex does not reset on prestige.

---

## Treasures

Treasures are equippable buff artifacts earned through Expeditions.

Rules:

- Exactly one stat per treasure
- Treasure type always has same stat type
- Values roll within rarity range
- Mythic treasures max at 50%
- One treasure per stat type per rarity
- 10 stat types * 5 rarities = 50 treasures
- Duplicate treasures allowed
- Can be locked/favorited
- Can be sacrificed for Bug Dust

Treasure slots:

- Start with 5
- Up to 5 extra slots can be bought
- Extra treasure slots cost 99 Robux each

Only Epic+ treasures can be listed on Marketplace.

---

## Expeditions

Expeditions are timed missions that always reward treasures and may reward Generator Cores.

Player starts with 1 Expedition slot.

Player unlocks +1 Expedition slot per prestige, up to 5 earned slots.

Player can buy up to 5 additional slots.

Extra Expedition slots cost 99 Robux each.

Expeditions:

| Expedition | Unlock | Duration | Reward Identity |
|---|---|---|---|
| Backyard Dig | Prestige 2 | 30 min | Early common treasure farming |
| Rotten Log Search | Prestige 3 | 2 hr | Common/Rare treasure farming with small Epic chance |
| Garden Tunnel | Prestige 5 | 6 hr | Rare minimum, good Epic chance |
| Ancient Burrow | Prestige 7 | 12 hr | Epic-focused, small Legendary/Mythic chance |
| Queen’s Vault | Prestige 10 | 24 hr | Epic+ minimum, best Mythic chance |

Instant finish dev product prices:

| Duration | Price |
|---|---:|
| 30 min | 9 Robux |
| 2 hr | 19 Robux |
| 6 hr | 39 Robux |
| 12 hr | 69 Robux |
| 24 hr | 99 Robux |

---

## Marketplace.exe

Global listing-based trading system using Nectar.

Allowed items:

- Epic+ bugs
- Epic+ treasures
- Epic+ Generator Cores

Not allowed:

- Common or Rare items
- Locked items
- Favorited items

Rules:

- 24 hour listings
- 10% Nectar tax on successful sales
- Base active listing limit: 5
- Expired listings return to seller
- No direct player-to-player trading in 1.0

Listing data shows:

- Item icon
- Name
- Rarity
- Full stats
- Seller
- Price
- Time remaining

---

## Leaderboards

Leaderboards have all-time, weekly, and daily versions where relevant.

Player leaderboards:

- Lifetime Food
- Best Food/sec snapshot
- Coins
- Bug Points

Guild leaderboards:

- Guild Total Food
- Guild Bug Points

Food/sec should use highest verified server snapshot, not constant second-by-second updates.

---

## Guilds

Guilds launch in 1.0.

Features:

- Create guild
- Join guild
- Leave guild
- Roles
- Guild chat
- Guild perks
- Guild quests
- Guild research
- Guild leaderboards
- Guild contribution tracking

Roles:

- Owner
- Officer
- Member

Base member cap: 20.

Guild perks should be moderate and not make solo play feel invalid.

Guild XP comes from:

- Bug Points
- Guild quests
- Tournament placement
- Daily member activity

Guild level rewards may include:

- Small All Food boosts
- Minigame Spawn bonuses
- Expedition Speed bonuses
- Bug Luck
- Nectar Chance
- Member cap increases
- Cosmetic guild aura
- Emblem customization

---

## Guild Chat

Guild chat is guild-only.

Rules:

- Only guild members can send/read
- Roblox text filtering required
- Never store unfiltered text
- Recent chat only
- Cooldown to prevent spam
- Officer+ can mute or kick

Guild chat appears in Guilds.exe and optional chat dock.

---

## Guild Quests

Guild quests launch in 1.0.

Types:

- Daily quests
- Weekly quests

Examples:

- Earn Bug Points
- Catch Epic+ bugs
- Complete expeditions
- Earn Food
- Contribute resources

Rewards:

- Guild XP
- Bug Dust
- Nectar
- Temporary guild buffs

---

## Guild Research

Guild members contribute resources to research nodes.

Contribution types:

- Food
- Bug Points
- Bug Dust

Research examples:

- Swarm Efficiency: +2% All Food
- Expedition Routing: +5% Expedition Speed
- Pheromone Tracking: +3% Bug Spawn
- Colony Commerce: +3% Sell Bonus

Research bonuses should be moderate and collaborative.

Guild wars and guild events are future updates, not 1.0.

---

## Achievements

Achievements launch in 1.0.

Categories:

- Clicking
- Food earned
- Coins earned
- Prestige reached
- Bugs caught
- Rare bugs caught
- Bug Points
- Expeditions completed
- Treasures found
- Generator Cores found
- Marketplace sales
- Guild contribution
- Tournaments
- Events

Rewards:

- Coins
- Nectar
- Bug Dust
- Titles
- Cosmetics
- Small permanent bonuses

---

## Weekend Tournament

Main tournament type for 1.0:

Bug Hunt Tournament.

Schedule:

- Starts Friday evening
- Ends Sunday night
- Runs every weekend

Metric:

Bug Points earned during the tournament window.

Player and guild tournament scores are separate from lifetime values.

Rewards:

Player:

- Rank 1: exclusive title, large Nectar, Bug Dust
- Top 10: Nectar and Bug Dust
- Top 100: Bug Dust
- Participation: small Bug Dust

Guild:

- Rank 1: exclusive guild badge
- Top 3: Guild XP
- Top 10: temporary guild buff

---

## Desktop World Map

The desktop background acts as the server world layer.

It shows:

- Player colonies
- Wandering bugs
- Mystery caches
- Event effects
- Ambient props

Each player is represented by a colony.

Clicking a colony opens that player’s profile.

Colonies show:

- Player name
- Title
- Guild tag
- Colony skin
- Prestige badge

---

## Desktop Customization

Desktop customization is a major cosmetic and monetization pillar.

Players can customize:

- Wallpaper
- Taskbar skin
- Window skin
- Cursor
- Notification style
- Desktop effects
- Sounds

Cosmetics can be:

- Earned from events
- Bought with Robux
- Earned from achievements
- Won from tournaments
- Found in Mystery Caches

---

## Colony Skins

Players can collect and equip colony skins.

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

Colony skins are cosmetic-first.

They may grant very small bonuses only.

Example:

- +2% All Food
- +3% Bug Points
- +2% Nectar Chance

Avoid large pay-to-win bonuses.

---

## Player Profiles

Profile opens when:

- Clicking player colony
- Clicking leaderboard entry
- Hovering leaderboard name
- Clicking guild member
- Clicking marketplace seller

Profile shows:

- Colony skin
- Title
- Guild
- Prestige
- Lifetime Food
- Bug Points
- Favorite bug showcase
- Tournament history
- Achievement badges

---

## Titles

Titles are earned from:

- Achievements
- Tournaments
- Events
- Guild milestones
- Rare bug catches

Examples:

- Mythic Hunter
- Market Mogul
- Swarm Master
- Tournament Champion
- Bug Archivist
- Guild Founder

---

## Weekly Events

Each week should have:

- Special event bug
- Special event treasure
- Event theme
- Event rewards

Optional event content:

- Wallpaper
- Title
- Colony skin
- Mystery cache skin
- Guild quest theme

Goal:

Give players a reason to return every week.

Event items should be collectible and useful, but not mandatory meta items.

---

## Mystery Caches

Mystery caches are rare clickable desktop anomalies.

Examples:

- Corrupted File
- Encrypted Folder
- Strange Attachment
- Lost Data Cache
- Golden Cache
- Glitched Cache

Rewards:

- Bug Dust
- Nectar
- Event items
- Cosmetics
- Expedition boosts
- Small chance at bugs, treasures, or cores

---

## Server-Wide Random Events

Server-wide random events launch in 1.0.

Examples:

- Bug Swarm: increased bug spawn rate
- Market Surge: market price floor raised
- Nectar Storm: boosted Nectar chance
- System Corruption: increased Legendary/Mythic chance
- Expedition Rush: expedition speed boost

Events are announced through OS popup alerts.

Dev product:

Trigger Random Server Event

Rules:

- Player cannot choose exact event
- Event is random
- Prevent spam with cooldowns
- Effects apply server-wide

---

## Loadouts

Players can save and swap loadouts.

Loadouts may include:

- Bugs
- Treasures
- Generators
- Generator Cores

Important safety rule:

Loadouts save UID references only.

Never duplicate item data inside loadouts.

Before applying loadout, server validates:

- Player owns item
- Item exists
- Slot is unlocked
- Item is not already invalid
- Generator/core pair is legal

This prevents dupes, abuse, and data loss.

---

## Monetization

Gamepasses:

- Auto-Sell
- Extra generator slots
- Extra Bug Farm slots
- Extra treasure slots
- Extra Expedition slots
- Cosmetic packs

Dev products:

- Failed Epic+ bug recovery
- Expedition instant finish
- Trigger Random Server Event
- Possible cosmetic crates later

Cosmetics:

- Desktop skins
- Colony skins
- Window skins
- Cursors
- Notification effects
- Profile frames
- Titles

Monetization should feel valuable but not destroy fairness.

---

## Future Update Ideas

Not 1.0:

- Bug Ascension
- Guild wars
- Guild raids
- Guild events
- Auction house
- Core fusion
- Core sets
- Bug set bonuses expansion
- Hidden discovery mechanics
- More weekly event systems
