--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local context = {
	State = {
		PlayerData = nil,
		Market = {
			Price = 1,
			History = { 1 },
		},
	},
	UI = {},
	Remotes = {
		ClickRequest = RemotesFolder:WaitForChild(RemoteNames.Click_Request) :: RemoteEvent,
		StateFullSync = RemotesFolder:WaitForChild(RemoteNames.State_FullSync) :: RemoteEvent,
		StatePatch = RemotesFolder:WaitForChild(RemoteNames.State_Patch) :: RemoteEvent,
		MarketSellFood = RemotesFolder:WaitForChild(RemoteNames.Market_SellFood) :: RemoteEvent,
		MarketPriceUpdated = RemotesFolder:WaitForChild(RemoteNames.Market_PriceUpdated) :: RemoteEvent,
		UpgradeBuyClickTool = RemotesFolder:WaitForChild(RemoteNames.Upgrade_BuyClickTool) :: RemoteEvent,
		GeneratorUpgrade = RemotesFolder:WaitForChild(RemoteNames.Generator_Upgrade) :: RemoteEvent,
	},
	Controllers = {},
}

context.Controllers.Window = WindowController
context.Controllers.CurrencyHUD = CurrencyHUDController
context.Controllers.Market = MarketController
context.Controllers.Upgrade = UpgradeController
context.Controllers.Generator = GeneratorController

DesktopController.Init(context)
WindowController.Init(context)
CurrencyHUDController.Init(context)
MarketController.Init(context)
UpgradeController.Init(context)
GeneratorController.Init(context)

DesktopController.Start()
WindowController.Start()
CurrencyHUDController.Start()
MarketController.Start()
UpgradeController.Start()
GeneratorController.Start()
