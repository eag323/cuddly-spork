--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local ConfigFolder = SharedFolder:WaitForChild("Config")
local ConfigsFolder = SharedFolder:WaitForChild("Configs")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")

local ServerFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server")
local ServicesFolder = ServerFolder:WaitForChild("Services")

local MarketplaceConfig = require(ConfigFolder:WaitForChild("MarketplaceConfig"))
local MarketEventConfig = require(ConfigsFolder:WaitForChild("MarketEventConfig"))
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))
local BuffService = require(ServicesFolder:WaitForChild("BuffService"))
local StatsService = require(ServicesFolder:WaitForChild("StatsService"))
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

local UPDATE_INTERVAL_SECONDS = 30
local MIN_PRICE = 0.50
local MAX_PRICE = 3.00
local START_PRICE = 1.00
local HISTORY_LIMIT = 120

type PlayerData = { [string]: any }

local ALLOWED_SELL_PERCENTS: { [number]: boolean } = { [10] = true, [50] = true, [100] = true }

local MarketService = {}
local currentPrice = START_PRICE
local currentTrend = 0
local priceHistory: { number } = { START_PRICE }
local activeMarketEvent: { [string]: any }? = nil
local nextEventRollAt = os.time() + MarketEventConfig.RollIntervalSeconds
local lastAnnouncedEventEndsAt: number? = nil

local marketSellFoodRemote: RemoteEvent? = nil
local marketSetAutoSellEnabledRemote: RemoteEvent? = nil
local marketSetAutoSellTargetRemote: RemoteEvent? = nil
local marketPriceUpdatedRemote: RemoteEvent? = nil

local function roundToCents(value: number): number return math.round(value * 100) / 100 end
local function clampPrice(value: number): number return math.clamp(value, MIN_PRICE, MAX_PRICE) end
local function getCurrentCap(): number
	if activeMarketEvent and type(activeMarketEvent.MaxCap) == "number" then return activeMarketEvent.MaxCap end
	return MAX_PRICE
end
local function clampPriceWithActiveCap(value: number): number return math.clamp(value, MIN_PRICE, getCurrentCap()) end

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

local function chooseRandomEvent()
	local events = MarketEventConfig.Events
	local totalWeight = 0
	for _, eventDef in ipairs(events) do
		totalWeight += (eventDef.Weight or 1)
	end
	local roll = math.random() * totalWeight
	local running = 0
	for _, eventDef in ipairs(events) do
		running += (eventDef.Weight or 1)
		if roll <= running then return eventDef end
	end
	return events[1]
end

local function getActiveEventState()
	if not activeMarketEvent then return nil end
	return {
		Id = activeMarketEvent.Id,
		Name = activeMarketEvent.Name,
		Description = activeMarketEvent.Description,
		EndsAt = activeMarketEvent.EndsAt,
		TickerHeadline = activeMarketEvent.Description,
		MaxCap = getCurrentCap(),
		Rare = activeMarketEvent.Rare == true,
	}
end

local function maybeStartEvent()
	local now = os.time()
	if activeMarketEvent and now < (activeMarketEvent.EndsAt or 0) then return end
	if now < nextEventRollAt then return end
	nextEventRollAt = now + MarketEventConfig.RollIntervalSeconds
	local eventDef = chooseRandomEvent()
	if not eventDef then return end
	activeMarketEvent = table.clone(eventDef)
	activeMarketEvent.EndsAt = now + (eventDef.DurationSeconds or 180)
end

local function updatePrice()
	maybeStartEvent()
	if activeMarketEvent and os.time() >= (activeMarketEvent.EndsAt or 0) then
		activeMarketEvent = nil
	end
	local eventState = activeMarketEvent
	local upChance = 0.5
	local downChance = 0.5
	local moveMin = MarketEventConfig.NormalMoveMin
	local moveMax = MarketEventConfig.NormalMoveMax
	if eventState then
		upChance = eventState.UpChance or upChance
		downChance = eventState.DownChance or downChance
		moveMin = eventState.MoveMin or moveMin
		moveMax = eventState.MoveMax or moveMax
	end
	local direction = math.random() < upChance and 1 or -1
	if downChance > upChance then
		direction = math.random() < downChance and -1 or 1
	end
	local move = math.random(math.floor(moveMin * 100), math.floor(moveMax * 100)) / 100
	local nextPrice = roundToCents(clampPriceWithActiveCap(currentPrice + direction * move))
	if nextPrice == currentPrice then
		if currentPrice <= MIN_PRICE then
			nextPrice = roundToCents(clampPriceWithActiveCap(currentPrice + move))
		elseif currentPrice >= getCurrentCap() then
			nextPrice = roundToCents(clampPriceWithActiveCap(currentPrice - move))
		end
	end
	if not eventState and nextPrice > MAX_PRICE then
		nextPrice = roundToCents(math.max(MAX_PRICE, currentPrice - move))
	end
	currentTrend = nextPrice - currentPrice
	currentPrice = nextPrice
	pushPriceHistory(currentPrice)
	runAutoSell()
	if marketPriceUpdatedRemote then
		local payload = { Price = currentPrice, History = table.clone(priceHistory), ServerTime = os.time(), ActiveEvent = getActiveEventState(), MarketCap = getCurrentCap(), TickerHeadline = (getActiveEventState() and getActiveEventState().TickerHeadline) or MarketEventConfig.DefaultHeadline }
		marketPriceUpdatedRemote:FireAllClients(payload)
		if eventState and lastAnnouncedEventEndsAt ~= eventState.EndsAt then
			lastAnnouncedEventEndsAt = eventState.EndsAt
			if eventState.Rare == true then
				getOrCreateRemoteEvent(RemoteNames.Notification_Push):FireAllClients({ Message = "Rare market event started: Golden Picnic", Type = "Warning", EventId = "market_rare_" .. tostring(eventState.EndsAt) })
			else
				getOrCreateRemoteEvent(RemoteNames.Notification_Push):FireAllClients({ Message = string.format("Market event started: %s", eventState.Name), Type = "Info", EventId = "market_evt_" .. tostring(eventState.EndsAt) })
			end
		end
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
	if marketPriceUpdatedRemote then marketPriceUpdatedRemote:FireAllClients({ Price = currentPrice, History = table.clone(priceHistory), ServerTime = os.time(), ActiveEvent = getActiveEventState(), MarketCap = getCurrentCap(), TickerHeadline = MarketEventConfig.DefaultHeadline }) end
end

return MarketService
