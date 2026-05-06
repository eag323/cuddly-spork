--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")

local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

type PlayerData = { [string]: any }

local DATA_VERSION = 1

local ProfileService = {}

local playerDataByUserId: { [number]: PlayerData } = {}
local statePatchRemote: RemoteEvent? = nil
local stateFullSyncRemote: RemoteEvent? = nil

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
		Equipped = {},
	},

	Bugs = {
		Inventory = {},
		Equipped = {},
		SlotsUnlocked = 5,
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
	playerDataByUserId[player.UserId] = playerData

	if stateFullSyncRemote then
		stateFullSyncRemote:FireClient(player, {
			PlayerData = playerData,
		})
	end
end

local function onPlayerRemoving(player: Player): ()
	playerDataByUserId[player.UserId] = nil
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
end

return ProfileService
