# Bugs.OS UI Style Guide

## Core Direction

Bugs.OS uses a retro desktop operating system interface, inspired by old computer UI styles but not copied from real Windows branding.

The game should feel like the player is running a bug colony through a strange old OS.

Style goals:

- Pixel art
- Retro desktop UI
- Bright and readable
- Playful but clean
- Slightly nostalgic
- Chunky silhouettes
- Strong contrast
- Roblox-friendly

Avoid:

- real Windows logos
- copyrighted icon shapes
- overly dark UI
- cluttered panels
- tiny unreadable text
- em dashes in user-facing text

---

## Main UI Metaphor

Everything is an app or system window.

Examples:

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

---

## Desktop Shell

Required elements:

- Desktop background/world map
- Taskbar
- Start/menu button, original style only
- Desktop app icons
- Draggable windows
- Popups
- Notifications
- System alerts

The desktop background is also the world layer and shows colonies, bugs, mystery caches, and event effects.

---

## Visual Style

### Recommended Palette Direction

- warm greens
- soft yellows
- retro blues
- nectar gold
- bug greens
- warm browns
- glitch purples
- off-white panels

Avoid muddy realism.

---

## Fonts

Use clean, readable UI fonts.

Roblox-friendly options:

- Montserrat
- Gotham
- SourceSans

For pixel-style headers, use a pixel-like font only if readable.

Never sacrifice readability for theme.

---

## Window Design

Windows should feel like retro OS app panels.

Window structure:

- title bar
- app icon
- app title
- close button
- optional minimize button
- content area
- footer/action bar when needed

Recommended window behavior:

- draggable
- open/close
- bring to front
- app taskbar indicator
- avoid too many overlapping windows by default

---

## Buttons

Button states required:

- normal
- hover
- pressed
- disabled
- selected

Button style:

- chunky
- clear outline
- readable label
- simple hover feedback

---

## Rarity Colors

Use consistent rarity colors everywhere.

Suggested:

| Rarity | Color Direction |
|---|---|
| Common | gray/white |
| Rare | blue |
| Epic | purple |
| Legendary | gold |
| Mythic | rainbow/cosmic |

Rarity should appear in:

- item cards
- bug popups
- catch feed
- marketplace listings
- profile showcases
- Bugdex entries

---

## App Icon Rules

App icons should be:

- 64x64
- pixel art
- readable at small sizes
- transparent background
- no real OS icons
- consistent outline thickness

App icon list:

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

---

## HUD

Currency HUD should show:

- Food
- Coins
- Nectar
- Bug Dust

Prefer icon + number.

Keep labels minimal if icon is clear.

---

## Notifications

Notification types:

- bug spawn
- rare catch
- achievement unlock
- tournament update
- guild alert
- market sale
- server event
- mystery cache

Notification style:

- quick
- readable
- OS popup inspired
- strong icon
- not blocking unless important

---

## Desktop World Map

The map should support:

- player colonies
- colony skins
- guild tags
- player titles
- mystery caches
- event overlays
- bug minigame spawns
- ambient props

Colonies should be clickable.

Clicking a colony opens the player profile.

---

## Player Profile UI

Profile opens from:

- colony click
- leaderboard entry
- guild member
- marketplace seller

Profile shows:

- player name
- title
- guild
- prestige
- colony skin
- lifetime Food
- Bug Points
- favorite bug
- tournament history
- achievements

---

## Guild UI

Guilds.exe should include:

- overview tab
- members tab
- chat tab
- quests tab
- research tab
- leaderboard tab

Guild chat must be filtered and readable.

---

## Marketplace UI

Marketplace.exe layout:

Left panel:

- item type filter
- rarity filter
- stat filter
- search

Center panel:

- listings

Right panel:

- item details
- seller
- price
- buy button

Listings should clearly show:

- rarity
- stat value
- price
- time remaining

---

## Bugdex UI

Bugdex.exe layout:

- rarity tabs
- grid of bug entries
- detail panel
- completion progress
- milestone progress

Locked entries show silhouette and ???.

Perfect or high-roll bugs should have special outline or glow.

---

## Minigame UI

Catch the Bug should be readable and fair.

Required feedback:

- hit flash
- hit counter
- timer
- miss feedback
- perfect catch feedback
- rarity effects
- weak point marker for Epic+

Do not make hitboxes pixel-perfect.

---

## Desktop Customization UI

CosmeticsApp should let players equip:

- wallpaper
- taskbar skin
- window skin
- cursor
- notification skin
- desktop effect
- colony skin
- profile frame
- title

Cosmetics should preview before equipping.

---

## Copywriting Rules

Use short, clear text.

Avoid em dashes.

Use OS-style flavor.

Examples:

Good:

```txt
SYSTEM EVENT DETECTED
Bug Swarm active for 10 minutes
```

Good:

```txt
New Bug Discovered
Crystal Ant added to Bugdex
```

Avoid:

```txt
You have discovered a very rare bug that has now been added to your permanent collection database.
```

---

## UI Polish Priority

Build UI in this order:

1. Desktop shell
2. Currency HUD
3. Market.exe
4. Upgrades.exe
5. Food Harvesters.exe
6. Bug minigame
7. Bug Farm.exe
8. Bugdex.exe
9. Expeditions.exe
10. Guilds.exe
11. Leaderboards.exe
12. Tournament.exe
13. Marketplace.exe
14. Cosmetics/Profile polish
