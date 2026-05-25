--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")
local ConfigFolder = SharedFolder:WaitForChild("Config")

local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))
local EconomyConfig = require(ConfigFolder:WaitForChild("EconomyConfig"))
local BugConfig = require(ConfigFolder:WaitForChild("BugConfig"))

type PlayerData = { [string]: any }

local DATA_VERSION = 1

local ProfileService = {}

local playerDataByUserId: { [number]: PlayerData } = {}
local statePatchRemote: RemoteEvent? = nil
local stateFullSyncRemote: RemoteEvent? = nil
local saveInFlightByUserId: { [number]: boolean } = {}

local AUTOSAVE_INTERVAL_SECONDS = 60

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end

	local cloned = {}
	for key, nestedValue in value do
		cloned[key] = deepCopy(nestedValue)
	end

	return cloned
end

local DEFAULT_PLAYER_DATA: PlayerData = {
	Version = DATA_VERSION,

	Currencies = {
		Food = 0,
		Coins = 0,
		Nectar = 0,
		BugDust = 0,
		BugEssence = 0,
		LifetimeFood = 0,
	},

	Progression = {
		Prestige = 0,
		LastLogin = 0,
		TotalPlayTime = 0,
	},

	ClickTools = {},

	Generators = {
		SlotsUnlocked = 3,
		ExtraSlotsPurchased = 0,
		Equipped = {},
	},

	Bugs = {
		Inventory = {},
		FarmerSlots = {},
		CombatSlots = {},
		ExtraFarmerSlotsPurchased = 0,
	},

	Treasures = {
		Inventory = {},
		Equipped = {},
		SlotsUnlocked = 5,
	},

	GeneratorCores = {
		Inventory = {},
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
		Active = {},
	},

	Guild = {
		GuildId = nil,
		Role = nil,
		ContributionFood = 0,
		ContributionBugPoints = 0,
	},

	Stats = {},

	Achievements = {
		Progress = {},
		Claimed = {},
		NotifiedCompleted = {},
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
			ColonySkins = { Default = true },
			ColonyAuras = { None = true },
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
			ColonySkin = "Default",
			ColonyAura = "None",
			ProfileFrame = "DefaultProfileFrame",
			Title = nil,
		},
	},

	Loadouts = {},

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
	},
}

local function getOrCreateRemoteEvent(remoteName: string): RemoteEvent
	local existingRemote = RemotesFolder:FindFirstChild(remoteName)
	if existingRemote and existingRemote:IsA("RemoteEvent") then
		return existingRemote
	end

	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = remoteName
	remoteEvent.Parent = RemotesFolder

	return remoteEvent
end

local function loadDefaultPlayerData(_player: Player): PlayerData
	-- TODO: Replace with persistent profile load when datastore/profile layer is added.
	return deepCopy(DEFAULT_PLAYER_DATA)
end

local function maybeGrantAscensionTestKit(playerData: PlayerData): ()
	if not (EconomyConfig.DEV_MODE and EconomyConfig.DEV_GRANT_ASCENSION_TEST_KIT) then
		return
	end

	playerData.Currencies = playerData.Currencies or {}
	local targetEssence = math.max(0, tonumber(EconomyConfig.DEV_TEST_BUG_ESSENCE) or 0)
	playerData.Currencies.BugEssence = math.max(targetEssence, tonumber(playerData.Currencies.BugEssence) or 0)

	playerData.Bugs = playerData.Bugs or {}
	playerData.Bugs.Inventory = playerData.Bugs.Inventory or {}
	local inventory = playerData.Bugs.Inventory
	local currentCount = 0
	for _uid, _bug in inventory do
		currentCount += 1
	end

	local bugIds = {}
	for bugId, _bugData in BugConfig.Bugs do
		table.insert(bugIds, bugId)
	end
	if #bugIds == 0 then
		return
	end

	local desiredCount = math.max(0, tonumber(EconomyConfig.DEV_TEST_RANDOM_BUG_COUNT) or 0)
	local maxOwnedBugs = math.max(0, tonumber(BugConfig.MaxOwnedBugs) or 0)
	local targetInventoryCount = math.min(maxOwnedBugs, math.max(currentCount, desiredCount))
	local createCount = targetInventoryCount - currentCount
	for index = 1, createCount do
		local bugId = bugIds[math.random(1, #bugIds)]
		local uid = string.format("dev_bug_%d_%06d", currentCount + index, math.random(0, 999999))
		while inventory[uid] ~= nil do
			uid = string.format("dev_bug_%d_%06d", currentCount + index, math.random(0, 999999))
		end
		inventory[uid] = {
			Uid = uid,
			BugId = bugId,
			Locked = false,
			Ascension = 0,
		}
	end
end

local function normalizeCosmetics(playerData: PlayerData): ()
	playerData.Cosmetics = playerData.Cosmetics or {}
	playerData.Cosmetics.Owned = playerData.Cosmetics.Owned or {}
	playerData.Cosmetics.Equipped = playerData.Cosmetics.Equipped or {}

	local owned = playerData.Cosmetics.Owned
	local equipped = playerData.Cosmetics.Equipped

	owned.ColonySkins = owned.ColonySkins or {}
	owned.ColonyAuras = owned.ColonyAuras or {}

	owned.ColonySkins.Default = true
	owned.ColonyAuras.None = true

	if equipped.ColonySkin == nil or equipped.ColonySkin == "DefaultColony" then
		equipped.ColonySkin = "Default"
	end
	if equipped.ColonyAura == nil then
		equipped.ColonyAura = "None"
	end
end

function ProfileService.GetPlayerData(player: Player): PlayerData?
	return playerDataByUserId[player.UserId]
end

function ProfileService.PatchPlayerState(player: Player, path: { string }, value: any): ()
	if not statePatchRemote then
		return
	end

	statePatchRemote:FireClient(player, {
		Path = path,
		Value = value,
	})
end

local function syncPlayer(player: Player): ()
	local playerData = loadDefaultPlayerData(player)
	normalizeCosmetics(playerData)
	maybeGrantAscensionTestKit(playerData)
	playerDataByUserId[player.UserId] = playerData

	if stateFullSyncRemote then
		stateFullSyncRemote:FireClient(player, {
			PlayerData = playerData,
		})
	end
end

local function savePlayerData(player: Player): boolean
	local userId = player.UserId
	if saveInFlightByUserId[userId] then
		return false
	end

	local playerData = playerDataByUserId[userId]
	if not playerData then
		return false
	end

	saveInFlightByUserId[userId] = true
	local ok, _err = pcall(function()
		-- Placeholder for persistent profile save.
		local _snapshot = deepCopy(playerData)
	end)
	saveInFlightByUserId[userId] = nil

	if ok then
		print(string.format("[ProfileService] Saved player %s", player.Name))
	end

	return ok
end

local function autosaveLoop(): ()
	while true do
		task.wait(AUTOSAVE_INTERVAL_SECONDS)
		for _, player in Players:GetPlayers() do
			savePlayerData(player)
		end
	end
end

local function onPlayerRemoving(player: Player): ()
	savePlayerData(player)
	playerDataByUserId[player.UserId] = nil
	saveInFlightByUserId[player.UserId] = nil
end

function ProfileService.Init(): ()
	local statePatchName = RemoteNames.State_Patch or "State_Patch"
	local stateFullSyncName = RemoteNames.State_FullSync or "State_FullSync"

	statePatchRemote = getOrCreateRemoteEvent(statePatchName)
	stateFullSyncRemote = getOrCreateRemoteEvent(stateFullSyncName)
end

function ProfileService.Start(): ()
	Players.PlayerAdded:Connect(syncPlayer)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		syncPlayer(player)
	end

	task.spawn(autosaveLoop)
end

return ProfileService
