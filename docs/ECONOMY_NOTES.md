# Bugs.OS Economy Notes

This document tracks economy formulas, balancing assumptions, and live tuning notes.

## Economy Philosophy

Bugs.OS should feel satisfying early with big numbers, while maintaining long-term chase goals through collection, optimization, guilds, cosmetics, events, and trading.

Core principles:

- Early progression should feel fast and exciting.
- Prestige should feel meaningful.
- Collection items should hold long-term value.
- Trading should be Nectar-based and player-driven.
- High-end perfect rolls should be extremely rare.
- Cosmetics should be a strong monetization pillar without destroying fairness.
- Stat bonuses from cosmetics and colony skins should stay small.

---

## Currencies

### Food

Main resource.

No storage cap.

Used to sell for Coins.

### Coins

Used for click tools and generator upgrades.

### Nectar

Trading/premium currency.

Used for Marketplace and cosmetics.

### Bug Dust

Optimization and sacrifice currency.

Used for modifiers, rerolls, upgrades, and core crafting.

---

## Food to Coins Formula

```txt
CoinsGained = FoodSold * CurrentMarketPrice * (1 + TotalSellBonus)
```

CurrentMarketPrice:

- min $0.50
- max $3.00
- updates every 30 seconds
- global across all servers

Sell Bonus affects only personal coin gain, not global price.

---

## Prestige Multipliers

| Prestige | Multiplier |
|---|---:|
| P1 | 1.1x |
| P2 | 1.2x |
| P3 | 1.3x |
| P4 | 1.4x |
| P5 | 1.5x |
| P6 | 1.6x |
| P7 | 1.7x |
| P8 | 1.8x |
| P9 | 1.9x |
| P10 | 2.0x |
| P11+ | +5x per level |

P11+ examples:

- P11 = 7x
- P12 = 12x
- P13 = 17x

---

## Prestige Requirements

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

## Food/sec Target Curve

| Goal | End-of-Prestige Food/sec Target |
|---|---|
| Before P1 | 500K to 800K/sec |
| Before P2 | 3M to 6M/sec |
| Before P3 | 15M to 30M/sec |
| Before P4 | 75M to 150M/sec |
| Before P5 | 300M to 700M/sec |
| Before P6 | 1B to 2.5B/sec |
| Before P7 | 5B to 12B/sec |
| Before P8 | 25B to 60B/sec |
| Before P9 | 100B to 250B/sec |
| Before P10 | 500B to 1.2T/sec |

---

## Click Tool Formula

```txt
ToolLevelCost = BaseCost * Level^2
```

Level is the next level being purchased.

Each tool has 10 levels.

Fully maxed raw base click power:

```txt
208,260 Food/click
```

before prestige, bug, treasure, generator, core, and event multipliers.

---

## Generator Formula

```txt
Food/sec = BaseFoodPerSec * Level^1.55 * PrestigeMultiplier * Buffs
UpgradeCost = BaseUpgradeCost * Level^2.05
```

Generator bonuses do not scale with level.

Special Generator Cores unlock at Prestige 7.

---

## Generator Bonus Ranges

| Class | Bonus Range |
|---|---:|
| Snack | +3% to +8% |
| Fruit | +6% to +12% |
| Sandwich | +10% to +18% |
| Dessert | +15% to +25% |
| Picnic | +20% to +35% |
| Garden | +30% to +45% |
| Feast | +40% to +60% |

---

## Bug Stat Roll Philosophy

Higher percentage rolls are rarer.

100%+ stat bugs should be very rare and highly valuable.

High-value stat distribution concept:

| Range | Chance |
|---|---:|
| 50% to 70% | 90% |
| 70% to 80% | 7.5% |
| 80% to 95% | 2% |
| 95%+ | 0.5% |

Inside each band, higher values should be rarer than lower values.

Rough primary ranges:

- Epic: 20% to 40%
- Legendary: 40% to 75%
- Mythic: 75% to 130%

Rough secondary ranges:

- Common: 1% to 3%
- Rare: 2% to 6%
- Epic: 5% to 12%
- Legendary: 10% to 22%
- Mythic: 18% to 40%

Example estimated odds of exact +130% All Earnings Mythic bug:

- Mythic spawn: 1%
- All Earnings primary: 10%
- 95%+ god roll band: 0.5%
- exact top value within band: extremely rare

Rough estimate:

```txt
around 1 in 10M to 25M bug spawns
```

depending on the final roll curve.

---

## Bug Secondary Chances

| Rarity | Primary | Secondary 1 | Secondary 2 | Secondary 3 |
|---|---:|---:|---:|---:|
| Common | Guaranteed | 5% | 0% | 0% |
| Rare | Guaranteed | 15% | 2% | 0% |
| Epic | Guaranteed | 35% | 10% | 1% |
| Legendary | Guaranteed | 60% | 25% | 5% |
| Mythic | Guaranteed | 85% | 45% | 15% |

---

## Bug Spawn Rates

Base spawn chance:

```txt
2% per second
```

Spawn pity:

```txt
+0.15% additive per second without spawn
```

Final spawn chance:

```txt
FinalChance = BaseChance * (1 + TotalSpawnBonus)
```

Rarity:

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

---

## Bug Points

Bug Points are the main competitive metric.

Base points:

| Rarity | Points |
|---|---:|
| Common | 1 |
| Rare | 3 |
| Epic | 10 |
| Legendary | 35 |
| Mythic | 150 |

Potential bonuses:

- +25% for perfect catch
- +25% for no misses
- +15% for weak point hits
- behavior difficulty bonus

Behavior bonus examples:

| Behavior | Bonus |
|---|---:|
| Wanderer | 0% |
| Zig-Zagger | +10% |
| Dasher | +15% |
| Cloaker | +25% |
| Reactive | +35% |

---

## Bug Dust Economy

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

Expected hourly Dust:

| Stage | Expected Dust/hr |
|---|---:|
| Early P6 to P7 | 1,000 to 4,000 |
| Mid P8 to P9 | 5,000 to 15,000 |
| Late P10+ | 20,000 to 60,000 |
| Endgame optimized | 75,000+ |

---

## Generator Core Economy

Core drop chance:

| Expedition | Core Drop Chance |
|---|---:|
| Backyard Dig | 0% |
| Rotten Log Search | 5% |
| Garden Tunnel | 12% |
| Ancient Burrow | 20% |
| Queen’s Vault | 35% |

Base core rarity distribution:

| Rarity | Chance |
|---|---:|
| Common | 55% |
| Rare | 30% |
| Epic | 12% |
| Legendary | 2.5% |
| Mythic | 0.5% |

Queen’s Vault adjusted distribution:

| Rarity | Chance |
|---|---:|
| Common | 25% |
| Rare | 35% |
| Epic | 25% |
| Legendary | 10% |
| Mythic | 5% |

Core reroll costs:

| Attempt | Cost |
|---|---:|
| 1 | 2,500 |
| 2 | 5,000 |
| 3 | 10,000 |
| 4 | 20,000 |
| 5+ | doubles |

Core upgrade costs:

| Tier | Cost | Effect Boost |
|---|---:|---:|
| 1 | 5,000 | +3% |
| 2 | 10,000 | +3% |
| 3 | 20,000 | +4% |
| 4 | 40,000 | +5% |
| 5 | 80,000 | +5% |

Targeted crafting costs:

| Target | Cost |
|---|---|
| Rare | 5,000 Dust + 3 Common |
| Epic | 20,000 Dust + 3 Rare |
| Legendary | 75,000 Dust + 3 Epic |
| Mythic | 250,000 Dust + 3 Legendary |

---

## Marketplace Economy

Marketplace currency:

- Nectar only

Tax:

```txt
10% Nectar on successful sale
```

Allowed items:

- Epic+ bugs
- Epic+ treasures
- Epic+ cores

Listings:

- 24 hour duration
- base 5 active listings

Potential future systems:

- price history
- watchlist
- auctions
- bulk listings

---

## Cosmetic Economy

Desktop and colony cosmetics are a major monetization pillar.

Cosmetics can be:

- bought
- earned from events
- won from tournaments
- unlocked through achievements
- found in Mystery Caches

Colony skins may grant small bonuses only.

Suggested bonus range:

```txt
+1% to +3%
```

Avoid large paid stat advantages.

---

## Server Event Economy

Random server event dev product:

- triggers random event only
- player cannot choose exact event
- server cooldown required
- should feel exciting but not abusable

Events:

- Bug Swarm
- Market Surge
- Nectar Storm
- System Corruption
- Expedition Rush

---

## Weekly Event Economy

Each weekly event should include:

- special bug
- special treasure
- event rewards
- optional cosmetics

Event items should be collectible and useful, but not mandatory meta items.

---

## Tuning Warnings

Watch for:

- leaderboard write spam
- too much Nectar inflation
- Bug Dust inflation
- market price manipulation
- paid cosmetics becoming too strong
- guild perks becoming mandatory
- event bugs invalidating normal bugs
- core exponent stacking breaking progression
