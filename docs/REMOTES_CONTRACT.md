# Bugs.OS Remotes Contract

All valuable actions are server authoritative.

Client may request actions. Server validates and returns result through state patches, notifications, or direct responses.

Use this file to create:

```txt
ReplicatedStorage/BugsOS/Shared/Remotes/RemoteNames.lua
```

---

## Remote Design Rules

- Never trust client currency values.
- Never trust client item data.
- Never let client roll rewards.
- Never let client determine bug rarity.
- Never let client decide tournament points.
- Never save unfiltered chat.
- Validate ownership on every item action.
- Validate slot unlocks on every equip action.
- Validate cooldowns server-side.
- Use UIDs for unique item instances.
- Use config IDs for static definitions.

---

## Client to Server Remotes

### Click_Request

Payload:

```lua
{
    Timestamp = number?
}
```

Server validates:

- click cooldown if any
- player profile loaded
- active game state

Server result:

- adds Food
- rolls Nectar drop
- updates daily/achievement progress
- sends Currency_Updated or State_Patch

---

### Market_SellFood

Payload:

```lua
{
    Percent = number? -- 10, 50, or 100
    Amount = number? -- optional future direct amount
}
```

Server validates:

- Food balance
- current global market price
- percent is allowed

Server result:

- removes Food
- adds Coins
- updates leaderboard counters
- updates achievements

---

### Upgrade_BuyClickTool

Payload:

```lua
{
    ToolId = string
}
```

Server validates:

- ToolId exists
- level below max
- enough Coins

Server result:

- removes Coins
- increments tool level
- patches state

---

### Generator_Equip

Payload:

```lua
{
    SlotIndex = number,
    GeneratorId = string
}
```

Server validates:

- slot unlocked
- GeneratorId exists
- prestige unlock reached

Server result:

- replaces generator in slot
- deletes old generator from that slot
- resets slot level as intended

---

### Generator_Upgrade

Payload:

```lua
{
    SlotIndex = number
}
```

Server validates:

- slot has generator
- enough Coins

Server result:

- removes Coins
- increments generator level

---

### Generator_InsertCore

Payload:

```lua
{
    SlotIndex = number,
    CoreUid = string
}
```

Server validates:

- Prestige 7+
- generator slot exists and has generator
- core exists in player inventory
- core not locked into another slot
- slot unlocked

Server result:

- assigns CoreUid to generator slot

---

### Generator_RemoveCore

Payload:

```lua
{
    SlotIndex = number
}
```

Server validates:

- slot exists
- player owns current core

Server result:

- removes core assignment from generator slot

---

### Prestige_Request

Payload:

```lua
{}
```

Server validates:

- lifetime Food meets next prestige requirement

Server result:

- increments prestige
- resets Food, Coins, click tools, generators, generator levels
- keeps collection/social/cosmetic state

---

### Bug_AttemptCatch

Payload:

```lua
{
    BugSessionId = string,
    ClickPosition = Vector2?,
    ClientTimestamp = number?
}
```

Server validates:

- active bug session exists
- session belongs to player or server event scope
- timer not expired
- hit position if server can validate
- anti-spam cooldown

Server result:

- increments hit progress or applies miss penalty
- if caught, creates bug and awards Bug Points
- updates tournament/guild/leaderboards

---

### Bug_Equip

Payload:

```lua
{
    SlotIndex = number,
    BugUid = string
}
```

Server validates:

- bug exists
- slot unlocked
- player owns bug

Server result:

- equips bug

---

### Bug_Unequip

Payload:

```lua
{
    SlotIndex = number
}
```

---

### Bug_Lock

Payload:

```lua
{
    BugUid = string,
    Locked = boolean
}
```

---

### Bug_Favorite

Payload:

```lua
{
    BugUid = string,
    Favorited = boolean
}
```

---

### Bug_Sacrifice

Payload:

```lua
{
    BugUid = string
}
```

Server validates:

- bug exists
- not locked
- not favorited
- not equipped
- not listed on marketplace

Server result:

- deletes bug
- awards Bug Dust

---

### Bug_ApplyModifier

Payload:

```lua
{
    BugUid = string,
    ModifierId = string
}
```

Server validates:

- bug exists
- modifier exists
- bug does not already have modifier unless replacement is allowed
- enough Bug Dust

---

### Bug_RerollSecondaries

Payload:

```lua
{
    BugUid = string
}
```

Server validates:

- bug exists
- has secondary stats or is eligible
- enough Bug Dust

---

### Treasure_Equip

Payload:

```lua
{
    SlotIndex = number,
    TreasureUid = string
}
```

---

### Treasure_Unequip

Payload:

```lua
{
    SlotIndex = number
}
```

---

### Treasure_Sacrifice

Payload:

```lua
{
    TreasureUid = string
}
```

Server validates:

- treasure exists
- not locked/favorited
- not equipped
- not listed

---

### Expedition_Start

Payload:

```lua
{
    SlotIndex = number,
    ExpeditionId = string
}
```

Server validates:

- slot unlocked
- slot not active
- ExpeditionId exists
- prestige unlock reached

---

### Expedition_Claim

Payload:

```lua
{
    SlotIndex = number
}
```

Server validates:

- expedition active
- completion time reached

Server result:

- grants treasure
- rolls optional Generator Core
- clears expedition slot

---

### Expedition_InstantFinish

Payload:

```lua
{
    SlotIndex = number
}
```

Server validates:

- expedition active
- dev product purchase flow

---

### Core_Reroll

Payload:

```lua
{
    CoreUid = string,
    RerollType = string -- Secondary, FullValues
}
```

Server validates:

- Prestige 7+
- core exists
- enough Bug Dust
- RerollType allowed

Server result:

- creates new roll
- lets player keep old or take new if using confirmation flow

---

### Core_Upgrade

Payload:

```lua
{
    CoreUid = string
}
```

Server validates:

- Prestige 7+
- core exists
- upgrade tier below 5
- enough Bug Dust

---

### Core_Craft

Payload:

```lua
{
    RecipeId = string,
    CoreUids = {string}
}
```

Server validates:

- recipe exists
- player owns cores
- cores not locked/favorited/equipped/listed
- enough Bug Dust

---

### Core_Sacrifice

Payload:

```lua
{
    CoreUid = string
}
```

---

### Marketplace_ListItem

Payload:

```lua
{
    ItemType = string, -- Bug, Treasure, Core
    ItemUid = string,
    Price = number
}
```

Server validates:

- item exists
- player owns item
- item is Epic+
- item not locked/favorited/equipped
- item not already listed
- price valid
- listing limit not exceeded

---

### Marketplace_BuyListing

Payload:

```lua
{
    ListingId = string
}
```

Server validates:

- listing exists
- listing not expired
- buyer has enough Nectar
- buyer is not seller if disallowed

Server result:

- removes Nectar from buyer
- transfers item to buyer
- seller receives Nectar minus 10% tax
- listing removed

---

### Marketplace_CancelListing

Payload:

```lua
{
    ListingId = string
}
```

Server validates:

- seller owns listing

---

### Guild_Create

Payload:

```lua
{
    Name = string,
    Tag = string
}
```

Server validates:

- player not already in guild
- name/tag allowed
- name/tag filtered
- creation cost if any

---

### Guild_Join

Payload:

```lua
{
    GuildId = string
}
```

Server validates:

- guild exists
- member cap not reached
- invite/open requirements

---

### Guild_Leave

Payload:

```lua
{}
```

---

### Guild_Kick

Payload:

```lua
{
    TargetUserId = number
}
```

Server validates:

- caller is owner/officer
- target lower role
- target in guild

---

### Guild_Promote

Payload:

```lua
{
    TargetUserId = number
}
```

Server validates:

- caller permission

---

### Guild_Demote

Payload:

```lua
{
    TargetUserId = number
}
```

---

### Guild_SendChat

Payload:

```lua
{
    Message = string
}
```

Server validates:

- player is in guild
- cooldown
- message length
- Roblox text filtering

Server result:

- broadcasts filtered text to guild members only
- stores recent filtered message only

---

### Guild_ContributeResearch

Payload:

```lua
{
    ResearchId = string,
    Currency = string,
    Amount = number
}
```

Server validates:

- player in guild
- research exists
- contribution type allowed
- enough currency or contribution resource

---

### Guild_ClaimQuestReward

Payload:

```lua
{
    QuestId = string
}
```

Server validates:

- guild quest complete
- reward not already claimed

---

### Achievement_Claim

Payload:

```lua
{
    AchievementId = string
}
```

Server validates:

- achievement complete
- not already claimed

---

### Tournament_ClaimReward

Payload:

```lua
{
    TournamentId = string
}
```

Server validates:

- tournament ended
- player eligible
- reward not already claimed

---

### Cosmetic_Equip

Payload:

```lua
{
    CosmeticType = string,
    CosmeticId = string
}
```

Server validates:

- player owns cosmetic
- cosmetic type valid

---

### Loadout_Save

Payload:

```lua
{
    LoadoutId = string,
    Name = string,
    Data = {
        EquippedBugs = {},
        EquippedTreasures = {},
        EquippedGenerators = {}
    }
}
```

Server validates:

- name length
- all UID references exist and are owned
- no duplicated UID abuse
- slots unlocked

---

### Loadout_Apply

Payload:

```lua
{
    LoadoutId = string
}
```

Server validates:

- loadout exists
- every UID still exists
- every slot still unlocked
- all pairings legal

---

### MysteryCache_Claim

Payload:

```lua
{
    CacheId = string
}
```

Server validates:

- cache active
- player eligible
- not already claimed

---

### ServerEvent_TriggerDevProduct

Payload:

```lua
{}
```

Actual grant should happen through MarketplaceService.ProcessReceipt, not from this remote alone.

---

## Server to Client Remotes

### State_Patch

Payload:

```lua
{
    Path = {string},
    Value = any
}
```

Used for patching changed state.

---

### State_FullSync

Payload:

```lua
{
    PlayerData = table
}
```

Sent after profile load or major recovery.

---

### Currency_Updated

Payload:

```lua
{
    Food = number?,
    Coins = number?,
    Nectar = number?,
    BugDust = number?
}
```

---

### Notification_Push

Payload:

```lua
{
    Type = string,
    Title = string,
    Message = string,
    IconId = string?,
    Duration = number?
}
```

---

### Bug_Spawned

Payload:

```lua
{
    BugSessionId = string,
    Rarity = string,
    Species = string?,
    Behavior = string,
    Duration = number,
    HitsNeeded = number
}
```

---

### Bug_Captured

Payload:

```lua
{
    BugUid = string,
    BugData = table,
    BugPoints = number,
    PerfectCatch = boolean
}
```

---

### Bug_Escaped

Payload:

```lua
{
    BugSessionId = string,
    RecoveryAvailable = boolean,
    RecoveryProductId = number?
}
```

---

### Market_PriceUpdated

Payload:

```lua
{
    Price = number,
    History = {number},
    NextUpdate = number
}
```

---

### Leaderboard_Updated

Payload:

```lua
{
    BoardId = string,
    Entries = {}
}
```

---

### Guild_Updated

Payload:

```lua
{
    GuildData = table
}
```

---

### GuildChat_Message

Payload:

```lua
{
    UserId = number,
    DisplayName = string,
    Message = string,
    SentAt = number
}
```

---

### Tournament_Updated

Payload:

```lua
{
    TournamentId = string,
    PlayerScore = number,
    GuildScore = number?,
    TimeRemaining = number
}
```

---

### Achievement_Unlocked

Payload:

```lua
{
    AchievementId = string
}
```

---

### ServerEvent_Started

Payload:

```lua
{
    EventId = string,
    EndsAt = number,
    Effects = table
}
```

---

### MysteryCache_Spawned

Payload:

```lua
{
    CacheId = string,
    CacheType = string,
    ExpiresAt = number
}
```

---

## Remote Naming Convention

Use:

```txt
System_Action
```

Examples:

```txt
Market_SellFood
Bug_AttemptCatch
Guild_SendChat
Core_Reroll
```
