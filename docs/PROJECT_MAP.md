# Bugs.OS Project Map

This document defines the expected repository and Roblox script structure.

## Repository Structure

```txt
BugsOS/
  docs/
  src/
  assets/
  references/
  prompts/
```

## Roblox Source Structure

```txt
src/
  ReplicatedStorage/
    BugsOS/
      Shared/
        Config/
        Util/
        Remotes/

  ServerScriptService/
    BugsOS/
      Server/
        Services/
        Main.server.lua

  StarterPlayer/
    StarterPlayerScripts/
      BugsOS/
        Client/
          Controllers/
          UI/
          Main.client.lua
```

---

## Shared Config Modules

Path:

```txt
src/ReplicatedStorage/BugsOS/Shared/Config/
```

Expected files:

```txt
CurrencyConfig.lua
PrestigeConfig.lua
ClickToolConfig.lua
GeneratorConfig.lua
BugConfig.lua
TreasureConfig.lua
ExpeditionConfig.lua
CoreConfig.lua
MarketplaceConfig.lua
LeaderboardConfig.lua
GuildConfig.lua
GuildQuestConfig.lua
GuildResearchConfig.lua
AchievementConfig.lua
TournamentConfig.lua
CosmeticConfig.lua
ServerEventConfig.lua
MysteryCacheConfig.lua
DailyProgramConfig.lua
```

Purpose:

- Store static game values
- Never store player state
- Used by server services and client UI
- Source of truth for IDs and balancing values

---

## Shared Utility Modules

Path:

```txt
src/ReplicatedStorage/BugsOS/Shared/Util/
```

Expected files:

```txt
NumberFormatter.lua
WeightedRandom.lua
StatMath.lua
TimeUtil.lua
TableUtil.lua
UidUtil.lua
Signal.lua
```

Purpose:

- Reusable helpers
- No server-only dependencies unless clearly named

---

## Remote Names

Path:

```txt
src/ReplicatedStorage/BugsOS/Shared/Remotes/RemoteNames.lua
```

Purpose:

- Central list of RemoteEvent/RemoteFunction names
- Prevent typo bugs
- Referenced by server and client

---

## Server Services

Path:

```txt
src/ServerScriptService/BugsOS/Server/Services/
```

Expected files:

```txt
ProfileService.lua
CurrencyService.lua
ClickService.lua
MarketService.lua
UpgradeService.lua
GeneratorService.lua
PrestigeService.lua
BugSpawnService.lua
BugInventoryService.lua
BugFarmService.lua
BugdexService.lua
ExpeditionService.lua
TreasureService.lua
GeneratorCoreService.lua
BugDustService.lua
MarketplaceService.lua
LeaderboardService.lua
GuildService.lua
GuildChatService.lua
GuildQuestService.lua
GuildResearchService.lua
AchievementService.lua
TournamentService.lua
CosmeticService.lua
ProfileDisplayService.lua
ServerEventService.lua
MysteryCacheService.lua
DailyProgramService.lua
LoadoutService.lua
MonetizationService.lua
```

---

## Client Controllers

Path:

```txt
src/StarterPlayer/StarterPlayerScripts/BugsOS/Client/Controllers/
```

Expected files:

```txt
DesktopController.lua
WindowController.lua
CurrencyHUDController.lua
MarketController.lua
UpgradeController.lua
GeneratorController.lua
BugMinigameController.lua
BugFarmController.lua
BugdexController.lua
ExpeditionController.lua
MarketplaceController.lua
LeaderboardController.lua
GuildController.lua
GuildChatController.lua
AchievementController.lua
TournamentController.lua
ProfileController.lua
CosmeticController.lua
ServerEventController.lua
MysteryCacheController.lua
DailyProgramController.lua
LoadoutController.lua
NotificationController.lua
```

Purpose:

- Listen to player input
- Open/close apps
- Render UI state
- Fire remote requests
- Receive server patches
- Never decide rewards or currency changes

---

## Client UI Components

Path:

```txt
src/StarterPlayer/StarterPlayerScripts/BugsOS/Client/UI/Components/
```

Expected files:

```txt
Window.lua
Button.lua
IconButton.lua
StatRow.lua
ItemCard.lua
ProgressBar.lua
ConfirmModal.lua
Tooltip.lua
SearchBar.lua
Dropdown.lua
Tabs.lua
Notification.lua
ProfileCard.lua
RarityFrame.lua
```

Purpose:

- Reusable UI components
- Consistent retro OS styling

---

## Client UI Apps

Path:

```txt
src/StarterPlayer/StarterPlayerScripts/BugsOS/Client/UI/Apps/
```

Expected files:

```txt
MarketApp.lua
UpgradesApp.lua
FoodHarvestersApp.lua
BugFarmApp.lua
BugdexApp.lua
ExpeditionsApp.lua
MarketplaceApp.lua
LeaderboardsApp.lua
GuildsApp.lua
AchievementsApp.lua
TournamentApp.lua
ProfileApp.lua
SettingsApp.lua
CosmeticsApp.lua
DailyProgramsApp.lua
LoadoutsApp.lua
```

---

## Startup Flow

1. Main.server.lua initializes server services.
2. Services register remotes.
3. Player joins.
4. ProfileService loads data.
5. Server sends initial state patch to client.
6. Main.client.lua starts controllers.
7. DesktopController creates shell.
8. CurrencyHUDController displays currencies.
9. Apps open via desktop icons/taskbar.

---

## Service Responsibility Summary

### ProfileService

- Load/save player data
- Apply default schema
- Handle migrations
- Provide safe data access
- Patch state to client

### CurrencyService

- Add/remove currencies
- Validate balances
- Update leaderboard counters when appropriate

### ClickService

- Handle click requests
- Calculate Food per click
- Roll Nectar drops

### MarketService

- Global market price
- Sell Food for Coins
- Auto-Sell

### UpgradeService

- Click tool levels
- Purchase validation
- Cost calculation

### GeneratorService

- Equipped generator slots
- Generator upgrades
- Food/sec calculation
- Generator bonuses

### PrestigeService

- Lifetime Food requirements
- Prestige resets
- Multiplier calculation

### BugSpawnService

- Spawn timers
- Spawn pity
- Rarity pity
- Active bug sessions

### BugInventoryService

- Create bug instances
- Roll stats
- Lock/favorite
- Sacrifice validation

### BugFarmService

- Equip/unequip bugs
- Calculate active bug buffs

### BugdexService

- Discover species
- Track best rolls
- Grant collection rewards

### ExpeditionService

- Start/claim expeditions
- Timer validation
- Treasure and Core rewards

### TreasureService

- Create treasures
- Equip/unequip
- Sacrifice

### GeneratorCoreService

- Create cores
- Equip/unequip
- Reroll
- Upgrade
- Craft
- Sacrifice

### BugDustService

- Sacrifice values
- Dust spending validation

### MarketplaceService

- List items
- Buy listings
- Cancel listings
- Expire listings
- Nectar tax

### LeaderboardService

- OrderedDataStore writes
- Daily/weekly/all-time keys
- Throttle writes

### GuildService

- Create/join/leave guilds
- Roles
- Membership
- Guild data

### GuildChatService

- Filtered guild chat
- Recent chat history
- Cooldowns

### GuildQuestService

- Daily/weekly quest generation
- Contribution progress
- Quest rewards

### GuildResearchService

- Contributions
- Research progress
- Guild-wide perks

### AchievementService

- Progress achievements
- Claim rewards
- Unlock titles/cosmetics

### TournamentService

- Weekend Bug Hunt
- Player/guild tournament scores
- Rewards

### CosmeticService

- Desktop skins
- Colony skins
- Cursors
- Profile frames
- Equipped cosmetics

### ProfileDisplayService

- Public profile cards
- Colony click profile data
- Leaderboard hover data

### ServerEventService

- Random server-wide events
- Dev product event trigger
- Cooldowns

### MysteryCacheService

- Spawn rare caches
- Grant cache rewards

### DailyProgramService

- Daily/weekly objective programs
- Rewards

### LoadoutService

- Save/load UID references
- Validate before applying
- Prevent dupes/data loss

### MonetizationService

- Gamepasses
- Dev products
- Purchases
