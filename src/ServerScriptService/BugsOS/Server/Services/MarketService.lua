--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerScriptService = game:GetService("ServerScriptService")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")

local ServerFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server")
local ServicesFolder = ServerFolder:WaitForChild("Services")

local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))
local BuffService = require(ServicesFolder:WaitForChild("BuffService"))
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

type PlayerData = { [string]: any }

type SellPayload = {
	SellPercent: number,
}

local UPDATE_INTERVAL_SECONDS = 30
local MIN_PRICE = 0.50
local MAX_PRICE = 3.00
local START_PRICE = 1.00
local HISTORY_LIMIT = 120

local ALLOWED_SELL_PERCENTS: { [number]: boolean } = {
	[10] = true,
	[50] = true,
	[100] = true,
}

local MarketService = {}

local currentPrice = START_PRICE
local currentTrend = 0
local priceHistory: { number } = { START_PRICE }

local marketSellFoodRemote: RemoteEvent? = nil
local marketPriceUpdatedRemote: RemoteEvent? = nil

local function roundToCents(value: number): number
	return math.round(value * 100) / 100
end

local function clampPrice(value: number): number
	return math.clamp(value, MIN_PRICE, MAX_PRICE)
end

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

local function pushPriceHistory(price: number): ()
	table.insert(priceHistory, price)
	if #priceHistory > HISTORY_LIMIT then
		table.remove(priceHistory, 1)
	end
end

local function getPlayerData(player: Player): PlayerData?
	return ProfileService.GetPlayerData(player)
end

local function updatePrice(): ()
	local trendAdjustment = (math.random() - 0.5) * 0.04
	currentTrend = math.clamp(currentTrend + trendAdjustment, -0.08, 0.08)

	local randomNoise = (math.random() - 0.5) * 0.06
	local nextPrice = clampPrice(currentPrice + currentTrend + randomNoise)
	nextPrice = roundToCents(nextPrice)

	if nextPrice == currentPrice then
		return
	end

	currentPrice = nextPrice
	pushPriceHistory(currentPrice)

	if marketPriceUpdatedRemote then
		marketPriceUpdatedRemote:FireAllClients({
			Price = currentPrice,
			History = table.clone(priceHistory),
			ServerTime = os.time(),
		})
	end
end

local function onSellFoodRequested(player: Player, payload: SellPayload?): ()
	if type(payload) ~= "table" then
		return
	end

	local sellPercent = payload.SellPercent
	if type(sellPercent) ~= "number" or not ALLOWED_SELL_PERCENTS[sellPercent] then
		return
	end

	local playerData = getPlayerData(player)
	if not playerData then
		return
	end

	local currencies = playerData.Currencies
	if type(currencies) ~= "table" then
		return
	end

	local currentFood = currencies.Food
	local currentCoins = currencies.Coins
	if type(currentFood) ~= "number" or type(currentCoins) ~= "number" then
		return
	end

	local foodSold = math.floor((currentFood * sellPercent) / 100)
	if foodSold <= 0 then
		return
	end

	local buffs = BuffService.GetPlayerBuffs(player)
	local sellBonus = buffs.SellBonus
	local coinsGained = foodSold * currentPrice * (1 + sellBonus)
	print(string.format("[MarketService] Sell bonus applied for %s: %.3f", player.Name, sellBonus))
	coinsGained = roundToCents(coinsGained)

	local newFood = currentFood - foodSold
	local newCoins = currentCoins + coinsGained

	currencies.Food = newFood
	currencies.Coins = newCoins

	ProfileService.PatchPlayerState(player, { "Currencies", "Food" }, newFood)
	ProfileService.PatchPlayerState(player, { "Currencies", "Coins" }, newCoins)
end

function MarketService.GetCurrentPrice(): number
	return currentPrice
end

function MarketService.GetPriceHistory(): { number }
	return table.clone(priceHistory)
end

function MarketService.Init(): ()
	marketSellFoodRemote = getOrCreateRemoteEvent(RemoteNames.Market_SellFood)
	marketPriceUpdatedRemote = getOrCreateRemoteEvent(RemoteNames.Market_PriceUpdated)
end

function MarketService.Start(): ()
	if marketSellFoodRemote then
		marketSellFoodRemote.OnServerEvent:Connect(onSellFoodRequested)
	end

	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL_SECONDS)
			updatePrice()
		end
	end)

	if marketPriceUpdatedRemote then
		marketPriceUpdatedRemote:FireAllClients({
			Price = currentPrice,
			History = table.clone(priceHistory),
			ServerTime = os.time(),
		})
	end
end

return MarketService
