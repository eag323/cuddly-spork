--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
if playerGui:GetAttribute("BugsOSClientInitialized") then
	warn("[BugsOS] Client already initialized; skipping duplicate Main.client.lua startup.")
	return
end
playerGui:SetAttribute("BugsOSClientInitialized", true)

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

local ControllersFolder = script.Parent:WaitForChild("Controllers")
local DesktopController = require(ControllersFolder:WaitForChild("DesktopController"))
local WindowController = require(ControllersFolder:WaitForChild("WindowController"))
local CurrencyHUDController = require(ControllersFolder:WaitForChild("CurrencyHUDController"))
local MarketController = require(ControllersFolder:WaitForChild("MarketController"))
local UpgradeController = require(ControllersFolder:WaitForChild("UpgradeController"))
local GeneratorController = require(ControllersFolder:WaitForChild("GeneratorController"))
local NotificationController = require(ControllersFolder:WaitForChild("NotificationController"))
local BugMinigameController = require(ControllersFolder:WaitForChild("BugMinigameController"))

local context = { State = { PlayerData = nil, Market = { Price = 1, History = { 1 } } }, UI = {}, Remotes = {
	ClickRequest = RemotesFolder:WaitForChild(RemoteNames.Click_Request), ClickResult = RemotesFolder:WaitForChild(RemoteNames.Click_Result),
	StateFullSync = RemotesFolder:WaitForChild(RemoteNames.State_FullSync), StatePatch = RemotesFolder:WaitForChild(RemoteNames.State_Patch),
	MarketSellFood = RemotesFolder:WaitForChild(RemoteNames.Market_SellFood), MarketPriceUpdated = RemotesFolder:WaitForChild(RemoteNames.Market_PriceUpdated),
	UpgradeBuyClickTool = RemotesFolder:WaitForChild(RemoteNames.Upgrade_BuyClickTool), GeneratorUpgrade = RemotesFolder:WaitForChild(RemoteNames.Generator_Upgrade),
	GeneratorEquip = RemotesFolder:WaitForChild(RemoteNames.Generator_Equip), PrestigeRequest = RemotesFolder:WaitForChild(RemoteNames.Prestige_Request),
	NotificationPush = RemotesFolder:WaitForChild(RemoteNames.Notification_Push),
	BugSpawned = RemotesFolder:WaitForChild(RemoteNames.Bug_Spawned), BugCaptured = RemotesFolder:WaitForChild(RemoteNames.Bug_Captured),
	BugEscaped = RemotesFolder:WaitForChild(RemoteNames.Bug_Escaped), BugAttemptCatch = RemotesFolder:WaitForChild(RemoteNames.Bug_AttemptCatch),
}, Controllers = {} }

context.Controllers.Window = WindowController
context.Controllers.CurrencyHUD = CurrencyHUDController
context.Controllers.Market = MarketController
context.Controllers.Upgrade = UpgradeController
context.Controllers.Generator = GeneratorController
context.Controllers.Notification = NotificationController
context.Controllers.BugMinigame = BugMinigameController

DesktopController.Init(context); WindowController.Init(context); CurrencyHUDController.Init(context); MarketController.Init(context)
UpgradeController.Init(context); GeneratorController.Init(context); NotificationController.Init(context); BugMinigameController.Init(context)

DesktopController.Start(); WindowController.Start(); CurrencyHUDController.Start(); MarketController.Start()
UpgradeController.Start(); GeneratorController.Start(); NotificationController.Start(); BugMinigameController.Start()
