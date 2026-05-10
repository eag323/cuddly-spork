--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))


local REMOTE_WAIT_TIMEOUT_SECONDS = 10

local function waitForRemote(remotesFolder: Instance, remoteName: string): RemoteEvent?
	local remote = remotesFolder:WaitForChild(remoteName, REMOTE_WAIT_TIMEOUT_SECONDS)
	if not remote then
		warn(string.format("[BugsOS] Missing remote '%s' after %ds; aborting client startup.", remoteName, REMOTE_WAIT_TIMEOUT_SECONDS))
		return nil
	end
	return remote :: RemoteEvent
end

local ControllersFolder = script.Parent:WaitForChild("Controllers")
local DesktopController = require(ControllersFolder:WaitForChild("DesktopController"))
local WindowController = require(ControllersFolder:WaitForChild("WindowController"))
local CurrencyHUDController = require(ControllersFolder:WaitForChild("CurrencyHUDController"))
local MarketController = require(ControllersFolder:WaitForChild("MarketController"))
local UpgradeController = require(ControllersFolder:WaitForChild("UpgradeController"))
local GeneratorController = require(ControllersFolder:WaitForChild("GeneratorController"))
local NotificationController = require(ControllersFolder:WaitForChild("NotificationController"))
local BugMinigameController = require(ControllersFolder:WaitForChild("BugMinigameController"))
local BugFarmController = require(ControllersFolder:WaitForChild("BugFarmController"))
local ColonyMapController = require(ControllersFolder:WaitForChild("ColonyMapController"))
local BootSequenceController = require(ControllersFolder:WaitForChild("BootSequenceController"))

local requiredRemoteNames = {
	ClickRequest = RemoteNames.Click_Request,
	ClickResult = RemoteNames.Click_Result,
	StateFullSync = RemoteNames.State_FullSync,
	StatePatch = RemoteNames.State_Patch,
	MarketSellFood = RemoteNames.Market_SellFood,
	MarketPriceUpdated = RemoteNames.Market_PriceUpdated,
	UpgradeBuyClickTool = RemoteNames.Upgrade_BuyClickTool,
	GeneratorUpgrade = RemoteNames.Generator_Upgrade,
	GeneratorEquip = RemoteNames.Generator_Equip,
	PrestigeRequest = RemoteNames.Prestige_Request,
	NotificationPush = RemoteNames.Notification_Push,
	BugSpawned = RemoteNames.Bug_Spawned,
	BugCaptured = RemoteNames.Bug_Captured,
	BugEscaped = RemoteNames.Bug_Escaped,
	BugAttemptCatch = RemoteNames.Bug_AttemptCatch,
	BugHitUpdate = RemoteNames.Bug_HitUpdate,
	BugEquip = RemoteNames.Bug_Equip,
	BugUnequip = RemoteNames.Bug_Unequip,
	BugLock = RemoteNames.Bug_Lock,
	BugSacrifice = RemoteNames.Bug_Sacrifice,
	AchievementClaim = RemoteNames.Achievement_Claim,
}

local remotes = {}
for key, remoteName in pairs(requiredRemoteNames) do
	local remote = waitForRemote(RemotesFolder, remoteName)
	if not remote then
		return
	end
	remotes[key] = remote
end

local context = { State = { PlayerData = nil, Market = { Price = 1, History = { 1 } } }, UI = {}, Remotes = remotes, Controllers = {}, Events = {} }

context.Events.StateChanged = Instance.new("BindableEvent")

context.Controllers.Window = WindowController
context.Controllers.CurrencyHUD = CurrencyHUDController
context.Controllers.Market = MarketController
context.Controllers.Upgrade = UpgradeController
context.Controllers.Generator = GeneratorController
context.Controllers.Notification = NotificationController
context.Controllers.BugMinigame = BugMinigameController
context.Controllers.BugFarm = BugFarmController
context.Controllers.ColonyMap = ColonyMapController
context.Controllers.BootSequence = BootSequenceController

DesktopController.Init(context); WindowController.Init(context); CurrencyHUDController.Init(context); MarketController.Init(context)
UpgradeController.Init(context); GeneratorController.Init(context); NotificationController.Init(context); BugMinigameController.Init(context); BugFarmController.Init(context)
ColonyMapController.Init(context)
BootSequenceController.Init(context)

DesktopController.Start(); WindowController.Start(); CurrencyHUDController.Start(); MarketController.Start()
UpgradeController.Start(); GeneratorController.Start(); NotificationController.Start(); BugMinigameController.Start(); BugFarmController.Start()
ColonyMapController.Start()
BootSequenceController.Start()
