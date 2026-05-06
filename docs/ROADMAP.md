# Bugs.OS Development Roadmap

## Development Philosophy

Build a 10-minute fun prototype first.

Do not build the full live-service game before proving the core loop.

Primary risk is scope creep, not lack of ideas.

---

## Milestone 0: Repo and Documentation

Goal:

Create a source of truth for Codex and development.

Build:

- GitHub repo
- docs folder
- src folder
- assets folder
- references folder
- prompts folder

Docs:

- GAME_BIBLE.md
- SYSTEMS.md
- PROJECT_MAP.md
- REMOTES_CONTRACT.md
- STATE_SCHEMA.md
- ECONOMY_NOTES.md
- UI_STYLE_GUIDE.md
- ASSET_PIPELINE.md
- ROADMAP.md

Completion criteria:

- Codex can read docs and scaffold modules
- repo structure is stable
- Roblox Studio project can sync scripts

---

## Milestone 1: First 10-Minute Prototype

Goal:

Playable economy loop.

Build only:

- Desktop shell
- Food currency
- Click background for Food
- Coins currency
- Market.exe sell Food for Coins
- Upgrades.exe click tools
- 3 starter generators
- Prestige 1
- Basic save/load

Starter generators:

- Plain Cracker
- Potato Chip
- Cookie Crumb

Do not build yet:

- guilds
- marketplace
- cores
- events
- weekly event bugs
- full asset library

Completion criteria:

- player can click, earn Food, sell Food, buy upgrades, equip/upgrade generators, and prestige once
- save/load works
- first 10 minutes feel satisfying

---

## Milestone 2: Bug Gameplay

Goal:

Add active engagement loop.

Build:

- Bug spawn system
- Catch the Bug minigame
- Bug rarity roll
- Bug Points
- Bug inventory
- Bug Farm slots
- Basic Bugdex

Completion criteria:

- bugs spawn on desktop/world
- player can catch bugs
- player earns Bug Points
- bugs are saved as unique instances
- bugs can be equipped for buffs

---

## Milestone 3: Progression Expansion

Goal:

Expand idle/collection depth.

Build:

- Prestige 1 to 10
- All generator classes
- Expeditions
- Treasures
- Bug Dust
- Achievements
- Daily Programs
- Loadouts

Completion criteria:

- player has multi-day progression
- expeditions reward treasures
- unwanted items can be sacrificed
- achievements reward progress
- loadouts safely swap UID references

---

## Milestone 4: Social Layer

Goal:

Make the game feel alive.

Build:

- Desktop background as world map
- Player colonies
- Colony profiles
- Guilds
- Guild chat
- Guild quests
- Guild research
- Leaderboards
- Titles
- Profiles

Completion criteria:

- players see other colonies in server
- clicking a colony opens profile
- guilds can form and chat
- guild members can contribute to quests/research
- leaderboards display player and guild ranks

---

## Milestone 5: Live-Service Systems

Goal:

Launch retention systems.

Build:

- Weekend Bug Hunt tournament
- Weekly event bugs
- Weekly event treasures
- Mystery caches
- Server-wide random events
- Random event dev product
- Marketplace
- Desktop customization
- Colony skins

Completion criteria:

- weekly and weekend systems create return reasons
- marketplace supports Epic+ bugs, treasures, and cores
- server-wide events feel exciting
- cosmetics can be equipped and displayed

---

## Milestone 6: Late-Game Depth

Goal:

Add optimization chase systems.

Build:

- Generator Cores
- Core drops
- Core UI
- Core rerolling
- Core upgrading
- Core crafting
- Advanced Bugdex rewards

Completion criteria:

- Prestige 7 unlock feels meaningful
- cores become endgame chase items
- duplicates have value through Bug Dust
- core marketplace works

---

## Milestone 7: Polish and Launch Prep

Goal:

Make game feel premium and stable.

Build:

- UI polish
- sound design
- animations
- tutorial
- onboarding
- analytics
- bug fixes
- economy tuning
- performance optimization

Completion criteria:

- first session is clear
- no major data issues
- no obvious exploit routes
- UI looks cohesive
- performance is stable

---

## Recommended Codex Task Order

1. Scaffold repo folders.
2. Create shared config modules.
3. Create default player data schema.
4. Create ProfileService wrapper.
5. Create CurrencyService.
6. Create ClickService.
7. Create MarketService.
8. Create UpgradeService.
9. Create GeneratorService.
10. Create PrestigeService.
11. Create DesktopController and WindowController.
12. Create CurrencyHUDController.
13. Create MarketApp.
14. Create UpgradesApp.
15. Create FoodHarvestersApp.
16. Add save/load testing.
17. Add bug spawn system.
18. Add minigame.
19. Add bug inventory.
20. Add Bug Farm.
21. Add Bugdex.
22. Add expeditions.
23. Add treasures.
24. Add Bug Dust.
25. Add guilds.
26. Add leaderboards.
27. Add tournaments.
28. Add marketplace.
29. Add cosmetics.
30. Add cores.

---

## Asset Production Order

Phase 1:

- window frame
- taskbar
- buttons
- desktop wallpaper
- Food icon
- Coin icon
- Nectar icon
- Bug Dust icon
- Market.exe icon
- Upgrades.exe icon
- Food Harvesters.exe icon
- 3 generator icons
- 3 bug sprites
- default colony

Phase 2:

- remaining app icons
- all Snack/Fruit/Sandwich generators
- Common and Rare bug sprites
- first treasure set

Phase 3:

- all generators
- all bug sprites
- all treasures
- profile/guild/leaderboard UI assets
- server event banners
- mystery caches

Phase 4:

- weekly event assets
- cosmetics
- colony skins
- desktop customization packs

---

## Scope Control Rules

Do not add more core systems before Milestone 1 is fun.

Do not polish every asset before the prototype works.

Do not let Codex implement broad vague tasks.

Always give Codex targeted tasks with:

- files to edit
- system requirements
- validation rules
- expected output

---

## First Codex Prompt

```txt
Read docs/GAME_BIBLE.md, docs/STATE_SCHEMA.md, docs/PROJECT_MAP.md, and docs/REMOTES_CONTRACT.md.

Then create the initial Bugs.OS Roblox Luau module scaffold under src/.

Do not implement advanced systems yet.

Create:
- Config modules
- Utility modules
- RemoteNames.lua
- Server service modules
- Client controller modules
- UI app placeholder modules

Each module should return a table and include TODO comments describing responsibilities.
```

---

## Second Codex Prompt

```txt
Implement ProfileService and default player data schema from docs/STATE_SCHEMA.md.

Requirements:
- server authoritative
- safe default data
- version field
- helper to get player data
- helper to patch player state to client
- no gameplay logic yet
```
