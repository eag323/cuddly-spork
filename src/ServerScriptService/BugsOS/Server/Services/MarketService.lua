--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local ConfigFolder = SharedFolder:WaitForChild("Config")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")

local ServerFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server")
local ServicesFolder = ServerFolder:WaitForChild("Services")

local MarketplaceConfig = require(ConfigFolder:WaitForChild("MarketplaceConfig"))
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))
local BuffService = require(ServicesFolder:WaitForChild("BuffService"))
local StatsService = require(ServicesFolder:WaitForChild("StatsService"))
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

local UPDATE_INTERVAL_SECONDS = 30
local MIN_PRICE = 0.50
local MAX_PRICE = 3.00
local START_PRICE = 1.00
local HISTORY_LIMIT = 120
local MIN_TICK_CHANGE = 0.05
local MAX_TICK_CHANGE = 0.50

type PlayerData = { [string]: any }

local ALLOWED_SELL_PERCENTS: { [number]: boolean } = { [10] = true, [50] = true, [100] = true }

local MarketService = {}
local currentPrice = START_PRICE
local currentTrend = 0
local priceHistory: { number } = { START_PRICE }

local marketSellFoodRemote: RemoteEvent? = nil
local marketSetAutoSellEnabledRemote: RemoteEvent? = nil
local marketSetAutoSellTargetRemote: RemoteEvent? = nil
local marketPriceUpdatedRemote: RemoteEvent? = nil

local function roundToCents(value: number): number return math.round(value * 100) / 100 end
local function clampPrice(value: number): number return math.clamp(value, MIN_PRICE, MAX_PRICE) end

local function getOrCreateRemoteEvent(remoteName: string): RemoteEvent
	local existingRemote = RemotesFolder:FindFirstChild(remoteName)
	if existingRemote and existingRemote:IsA("RemoteEvent") then return existingRemote end
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = remoteName
	remoteEvent.Parent = RemotesFolder
	return remoteEvent
end

local function getPlayerData(player: Player): PlayerData? return ProfileService.GetPlayerData(player) end

local function ownsAutoSellPass(player: Player): boolean
	local gamepassId = MarketplaceConfig.AutoSellGamepassId or 0
	if type(gamepassId) ~= "number" or gamepassId <= 0 then return false end
	local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) end)
	return ok and owns == true
end

local function canUseAutoSell(player: Player, playerData: PlayerData): boolean
	if type(playerData.Purchases) ~= "table" then playerData.Purchases = {} end
	if playerData.Purchases.AutoSellOwned == true then return true end
	if ownsAutoSellPass(player) then
		playerData.Purchases.AutoSellOwned = true
		ProfileService.PatchPlayerState(player, { "Purchases", "AutoSellOwned" }, true)
		return true
	end
	if RunService:IsStudio() and MarketplaceConfig.AutoSellGamepassId == 0 then
		return false
	end
	return false
end

local function pushPriceHistory(price: number)
	table.insert(priceHistory, price)
	if #priceHistory > HISTORY_LIMIT then table.remove(priceHistory, 1) end
end

local function executeSell(player: Player, playerData: PlayerData, sellPercent: number)
	local currencies = playerData.Currencies
	if type(currencies) ~= "table" then return end
	local currentFood = currencies.Food
	local currentCoins = currencies.Coins
	if type(currentFood) ~= "number" or type(currentCoins) ~= "number" then return end
	local foodSold = math.floor((currentFood * sellPercent) / 100)
	if foodSold <= 0 then return end
	local sellBonus = BuffService.GetPlayerBuffs(player).SellBonus
	local coinsGained = roundToCents(foodSold * currentPrice * (1 + sellBonus))
	local newFood = currentFood - foodSold
	local newCoins = currentCoins + coinsGained
	currencies.Food = newFood
	currencies.Coins = newCoins
	ProfileService.PatchPlayerState(player, { "Currencies", "Food" }, newFood)
	ProfileService.PatchPlayerState(player, { "Currencies", "Coins" }, newCoins)
	StatsService.Increment(player, "TotalFoodSold", foodSold)
	StatsService.Increment(player, "TotalCoinsEarned", coinsGained)
	StatsService.Increment(player, "MarketSales", 1)
	if currentPrice > 2.9 then StatsService.Increment(player, "HighPriceSales", 1) end
end

local function runAutoSell()
	for _, player in ipairs(Players:GetPlayers()) do
		local playerData = getPlayerData(player)
		if playerData and canUseAutoSell(player, playerData) and type(playerData.Settings) == "table" then
			local enabled = playerData.Settings.AutoSellEnabled == true
			local target = tonumber(playerData.Settings.AutoSellTarget) or MAX_PRICE
			if enabled and currentPrice >= clampPrice(target) then executeSell(player, playerData, 100) end
		end
	end
end

local function updatePrice()
	local direction = math.random(0, 1) == 1 and 1 or -1
	local move = math.random(5, 50) / 100
	local nextPrice = roundToCents(clampPrice(currentPrice + direction * move))
	if nextPrice == currentPrice then
		if currentPrice <= MIN_PRICE then
			nextPrice = roundToCents(clampPrice(currentPrice + move))
		elseif currentPrice >= MAX_PRICE then
			nextPrice = roundToCents(clampPrice(currentPrice - move))
		end
	end
	currentTrend = nextPrice - currentPrice
	currentPrice = nextPrice
	pushPriceHistory(currentPrice)
	runAutoSell()
	if marketPriceUpdatedRemote then
		marketPriceUpdatedRemote:FireAllClients({ Price = currentPrice, History = table.clone(priceHistory), ServerTime = os.time() })
	end
end

local function onSellFoodRequested(player: Player, payload: { SellPercent: number }?)
	if type(payload) ~= "table" then return end
	local sellPercent = payload.SellPercent
	if type(sellPercent) ~= "number" or not ALLOWED_SELL_PERCENTS[sellPercent] then return end
	local playerData = getPlayerData(player)
	if not playerData then return end
	executeSell(player, playerData, sellPercent)
end

local function onSetAutoSellEnabled(player: Player, payload: { Enabled: boolean }?)
	local playerData = getPlayerData(player)
	if not playerData or type(payload) ~= "table" or type(payload.Enabled) ~= "boolean" then return end
	if not canUseAutoSell(player, playerData) then
		if type(playerData.Settings) == "table" and playerData.Settings.AutoSellEnabled == true then
			playerData.Settings.AutoSellEnabled = false
			ProfileService.PatchPlayerState(player, { "Settings", "AutoSellEnabled" }, false)
		end
		return
	end
	if type(playerData.Settings) ~= "table" then playerData.Settings = {} end
	playerData.Settings.AutoSellEnabled = payload.Enabled
	ProfileService.PatchPlayerState(player, { "Settings", "AutoSellEnabled" }, payload.Enabled)
end

local function onSetAutoSellTarget(player: Player, payload: { Target: number }?)
	local playerData = getPlayerData(player)
	if not playerData or type(payload) ~= "table" or type(payload.Target) ~= "number" then return end
	if not canUseAutoSell(player, playerData) then return end
	if type(playerData.Settings) ~= "table" then playerData.Settings = {} end
	local target = roundToCents(clampPrice(payload.Target))
	playerData.Settings.AutoSellTarget = target
	ProfileService.PatchPlayerState(player, { "Settings", "AutoSellTarget" }, target)
end

function MarketService.GetCurrentPrice(): number return currentPrice end
function MarketService.GetPriceHistory(): { number } return table.clone(priceHistory) end

function MarketService.Init()
	marketSellFoodRemote = getOrCreateRemoteEvent(RemoteNames.Market_SellFood)
	marketSetAutoSellEnabledRemote = getOrCreateRemoteEvent(RemoteNames.Market_SetAutoSellEnabled)
	marketSetAutoSellTargetRemote = getOrCreateRemoteEvent(RemoteNames.Market_SetAutoSellTarget)
	marketPriceUpdatedRemote = getOrCreateRemoteEvent(RemoteNames.Market_PriceUpdated)
end

function MarketService.Start()
	if marketSellFoodRemote then marketSellFoodRemote.OnServerEvent:Connect(onSellFoodRequested) end
	if marketSetAutoSellEnabledRemote then marketSetAutoSellEnabledRemote.OnServerEvent:Connect(onSetAutoSellEnabled) end
	if marketSetAutoSellTargetRemote then marketSetAutoSellTargetRemote.OnServerEvent:Connect(onSetAutoSellTarget) end
	task.spawn(function() while true do task.wait(UPDATE_INTERVAL_SECONDS) updatePrice() end end)
	if marketPriceUpdatedRemote then marketPriceUpdatedRemote:FireAllClients({ Price = currentPrice, History = table.clone(priceHistory), ServerTime = os.time() }) end
end

return MarketService
