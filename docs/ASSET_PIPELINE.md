# Bugs.OS Asset Pipeline

## Recommended Workflow

Use GPT Image as the concept and batch production tool, then clean up and standardize final assets manually.

Pipeline:

```txt
GPT Image → Select Best → Refine → Aseprite Cleanup → Roblox Import
```

Do not expect AI output to be final game-ready every time.

---

## Recommended Tools

### GPT Image

Use for:

- concept art
- icon batches
- bug sprites
- treasure icons
- generator icons
- colony skin concepts
- wallpaper concepts
- event packs

### Aseprite

Use for:

- cleanup
- pixel consistency
- palette control
- resizing
- sprite sheets
- transparent exports

### Figma

Use for:

- UI layout mockups
- app window layouts
- desktop mockups

### Roblox Studio

Use for:

- final testing
- scaling
- import
- UI integration

---

## Art Direction

Global prompt style:

```txt
Pixel art, retro operating system game UI style, bright readable colors, chunky silhouettes, minimal detail, playful but clean, transparent background, Roblox friendly, high contrast, subtle shading, slightly nostalgic desktop aesthetic
```

---

## Recommended Sizes

| Asset Type | Recommended Size |
|---|---:|
| UI icons | 64x64 |
| Inventory items | 96x96 |
| Bug sprites | 64x64 or 96x96 |
| Desktop app icons | 64x64 |
| Event banners | 512x256 |
| Wallpapers | 1920x1080 source |
| Colony skins | 128x128 or larger depending on map scale |

---

## Folder Structure

```txt
assets/
  ui/
  app-icons/
  currency/
  click-tools/
  generators/
  bugs/
  treasures/
  generator-cores/
  colonies/
  cosmetics/
  events/
  mystery-caches/
  profiles/
  guilds/
  references/
```

---

## File Naming Rules

Use lowercase with underscores for exported asset files.

Examples:

```txt
food_icon.png
coin_icon.png
market_exe_icon.png
worker_ant_common.png
crystal_ant_mythic.png
plain_cracker_generator.png
heart_of_the_hive_treasure.png
overclock_core_legendary.png
mushroom_colony_skin.png
```

Config IDs can use PascalCase:

```txt
PlainCracker
HeartOfTheHive
OverclockCore
CrystalAnt
```

---

## First Asset Batch

Do this first. Do not create everything immediately.

```txt
Food icon
Coin icon
Nectar icon
Bug Dust icon
Desktop wallpaper
Taskbar
Window frame
Market.exe icon
Upgrades.exe icon
Food Harvesters.exe icon
3 bugs
3 generators
Default colony
```

---

## Master Asset List

### Core Desktop UI

- Desktop wallpaper default
- Taskbar background
- Taskbar buttons
- Window frame
- Window title bar
- Window close button
- Window minimize button
- Window resize handle
- Popup frame
- Tooltip frame
- Notification popup frame
- Scrollbars
- Tabs
- Checkboxes
- Dropdown menus
- Search bar
- Progress bars

States needed:

- normal
- hover
- pressed
- disabled
- selected

---

## App Icons

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
- Settings.exe
- Profile.exe
- Cosmetics.exe
- Loadouts.exe
- Daily Programs.exe

---

## Currency Icons

- Food
- Coins
- Nectar
- Bug Dust
- Guild XP
- Tournament Points
- Event Currency placeholder

---

## Click Tool Icons

- Bare Hands
- Garden Glove
- Hand Trowel
- Watering Can
- Pruning Shears
- Garden Hoe
- Rake
- Shovel
- Wheelbarrow
- Sprinkler
- Fertilizer Spreader
- Compost Wand
- Golden Spade
- Crystal Cultivator
- Royal Harvester

---

## Generator Icons

Snack:

- Plain Cracker
- Potato Chip
- Cookie Crumb
- Pretzel Bite
- Cheese Puff

Fruit:

- Apple Slice
- Banana Peel
- Strawberry
- Orange Wedge
- Watermelon Chunk

Sandwich:

- Bread Slice
- Cheese Slice
- Lunch Meat
- Peanut Butter
- Full Sandwich

Dessert:

- Chocolate Bar
- Candy Piece
- Cake Slice
- Donut
- Ice Cream Scoop

Picnic:

- Picnic Basket
- Hot Dog Bun
- Burger Scrap
- Lemonade Cup
- Corn Cob

Garden:

- Compost Pile
- Sunflower Seeds
- Carrot
- Tomato
- Mushroom Patch

Feast:

- Feast Platter
- Pizza Slice
- Turkey Leg
- Pie Slice
- Royal Banquet

---

## Bug Sprites

Common:

- Worker Ant
- House Fly
- Pill Bug
- Garden Aphid
- Tiny Termite
- Field Cricket
- Fruit Gnat
- Small Moth

Rare:

- Ladybug
- Honey Bee
- Firefly
- Grasshopper
- Stink Bug
- Earwig
- Carpenter Ant
- Leafhopper

Epic:

- Rhinoceros Beetle
- Jumping Spider
- Praying Mantis
- Dragonfly
- Velvet Ant
- Cicada
- Dung Beetle
- Tarantula Hawk Wasp

Legendary:

- Atlas Moth
- Hercules Beetle
- Orchid Mantis
- Emperor Scorpion
- Goliath Beetle
- Luna Moth
- Jewel Beetle
- Assassin Bug

Mythic:

- Crystal Ant
- Golden Scarab
- Royal Stag Beetle
- Phantom Mantis
- Ancient Dragonfly
- Celestial Firefly
- Obsidian Widow
- Prismatic Beetle

---

## Bug Mutation Overlays

Future-ready overlays:

- Golden
- Crystalized
- Corrupted
- Radioactive
- Glitched
- Frozen
- Overgrown
- Void

---

## Treasure Icons

Common:

- Cracked Colony Core
- Pebble Gear
- Rusty Hand Charm
- Tarnished Trade Token
- Dried Nectar Bead
- Lucky Pebble Idol
- Faint Pheromone Lure
- Tiny Hourglass Shell
- Mud Compass
- Worn Sleep Cocoon

Rare:

- Amber Colony Core
- Leafwork Gear
- Bronze Claw Charm
- Merchant Beetle Coin
- Nectar Drop Pendant
- Ladybug Luck Idol
- Pheromone Crystal
- Silver Sand Shell
- Rootbound Compass
- Moonlit Cocoon

Epic:

- Royal Colony Core
- Silkspun Gear
- Iron Mandible Charm
- Golden Market Token
- Blooming Nectar Pendant
- Scarab Luck Idol
- Greater Pheromone Prism
- Chrono Shell
- Burrower's Compass
- Dream Cocoon

Legendary:

- Queen's Colony Core
- Ancient Harvest Gear
- Titan Claw Charm
- Crowned Trade Medallion
- Royal Nectar Chalice
- Oracle Scarab Idol
- Royal Pheromone Beacon
- Timekeeper Cocoon
- Crystal Tunnel Compass
- Starwoven Sleep Cocoon

Mythic:

- Heart of the Hive
- Prismatic Harvest Engine
- Celestial Mandible Charm
- Emperor's Market Seal
- Eternal Nectar Vessel
- Fatebound Scarab Idol
- Cosmic Pheromone Beacon
- Hourglass of the Ancient Queen
- Worldroot Compass
- Dream of the Sleeping Swarm

---

## Generator Core Icons

Create by category first:

- Output cores
- Scaling cores
- Conversion cores
- Amplifier cores
- Synergy cores
- Conditional cores
- Mythic anomaly cores

Then create specific Core icons as needed.

---

## Colony Assets

Base:

- Default colony
- Colony outline
- Prestige visual stages
- Guild badge slot
- Player title banner

Colony skins:

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

Decorations:

- Flags
- Banners
- Lights
- Mushrooms
- Crystals
- Flowers
- Holograms
- Bug statues

---

## World and Map Assets

- Grass patches
- Flowers
- Rocks
- Tiny trees
- Desktop clutter
- Leaves
- Puddles
- Crystals
- Bug trails
- Ambient props

---

## Server Event Assets

Event banners:

- Bug Swarm
- Market Surge
- Nectar Storm
- System Corruption
- Expedition Rush

Event effects:

- screen tint
- particles
- desktop glitches
- spark effects
- rain effects
- fog overlays

---

## Mystery Cache Assets

- Corrupted File
- Encrypted Folder
- Strange Attachment
- Lost Data Cache
- Golden Cache
- Glitched Cache

---

## Achievement and Title Assets

Achievement categories:

- clicking
- prestige
- bugs
- guilds
- marketplace
- events
- tournaments

Title badges:

- Mythic Hunter
- Market Mogul
- Swarm Master
- Tournament Champion
- Bug Archivist
- Guild Founder

---

## Guild Assets

- Guild emblems
- Guild banners
- Guild level badges
- Guild quest icons
- Guild research icons
- Guild rank icons

---

## Weekly Event Assets

Each weekly event should have:

- 1 to 3 bugs
- 1 treasure
- 1 wallpaper
- 1 banner
- 1 title
- optional colony skin

Event themes:

- Halloween
- Winter
- Spring
- Summer
- Corruption
- Cyber
- Nature
- Festival
- Retro OS

---

## Cursor and FX Assets

- Default cursor
- Golden cursor
- Glitched cursor
- Crystal cursor
- Click particles
- Hit effects
- Weak point markers
- Perfect catch effects

---

## Notification Assets

- Rare bug popup
- Tournament popup
- Guild alert
- Achievement unlock
- Event announcement
- Marketplace sale popup

---

## Leaderboard and Profile Assets

- Profile frame
- Leaderboard frames
- Prestige icons
- Rank borders
- Tournament badges
- Player showcase panel

---

## Prompt Templates

### Currency Icon Prompt

```txt
Pixel art currency icons for a bug colony operating system game, food icon, coin icon, nectar droplet, bug dust vial, bright readable colors, transparent background, retro game UI style, chunky silhouettes
```

### Common Bug Batch Prompt

```txt
Pixel art bug sprites, common insect creatures for a retro operating system idle game, worker ant, house fly, pill bug, garden aphid, simple readable silhouettes, cute but slightly realistic, transparent background
```

### Mythic Bug Batch Prompt

```txt
Pixel art mythic insect creatures for a retro operating system idle game, glowing magical bug designs, crystal ant, golden scarab, phantom mantis, prismatic beetle, highly readable silhouettes, transparent background
```

### Generator Batch Prompt

```txt
Pixel art snack food generator icons for a bug colony idle game, plain cracker, potato chip, cookie crumb, pretzel bite, cheese puff, bright readable colors, chunky silhouettes, transparent background
```

### Treasure Batch Prompt

```txt
Pixel art mythic treasure artifact icons for a bug colony operating system game, glowing magical relics, cosmic pheromone beacon, prismatic harvest engine, worldroot compass, readable silhouettes, transparent background
```

### Colony Skin Prompt

```txt
Pixel art bug colony bases for a retro operating system idle game, mushroom colony, crystal hive, cyber nest, bright readable colors, stylized but clean, top-down perspective, transparent background
```

---

## Production Rule

Do not generate hundreds of final assets before the first playable prototype feels good.

Build prototype art first, then expand.
