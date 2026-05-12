--!strict

local Players = game:GetService("Players")
local RobloxMarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local ConfigFolder = SharedFolder:WaitForChild("Config")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")

local GeneratorConfig = require(ConfigFolder:WaitForChild("GeneratorConfig"))
local EconomyConfig = require(ConfigFolder:WaitForChild("EconomyConfig"))
local MarketplaceConfig = require(ConfigFolder:WaitForChild("MarketplaceConfig"))
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

local ServicesFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server"):WaitForChild("Services")
local CurrencyService = require(ServicesFolder:WaitForChild("CurrencyService"))
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))
local PrestigeService = require(ServicesFolder:WaitForChild("PrestigeService"))
local BuffService = require(ServicesFolder:WaitForChild("BuffService"))

local GeneratorService = {}
local STARTING_SLOTS = 3
local PASSIVE_TICK_SECONDS = 1

local generatorBuyEquipRemote: RemoteEvent? = nil
local generatorEquipLegacyRemote: RemoteEvent? = nil
local generatorRemoveRemote: RemoteEvent? = nil
local generatorCondimentRemote: RemoteEvent? = nil
local generatorRemoveCondimentRemote: RemoteEvent? = nil
local generatorAutoUpgradeRemote: RemoteEvent? = nil
local generatorUpgradeRemote: RemoteEvent? = nil -- deprecated compatibility
local generatorPromptExtraSlotPurchaseRemote: RemoteEvent? = nil
local notificationPushRemote: RemoteEvent? = nil
local passiveLoopRunning = false
local EXTRA_SLOT_CAP = 10

local harvesterById = if type(GeneratorConfig.Harvesters) == "table" then GeneratorConfig.Harvesters else {}
local condimentById = if type(GeneratorConfig.Condiments) == "table" then GeneratorConfig.Condiments else {}
local classById = {}
for _, classInfo in ipairs(GeneratorConfig.Classes or {}) do
	if type(classInfo) == "table" and type(classInfo.id) == "string" then
		classById[classInfo.id] = classInfo
	end
end

local function getOrCreateRemoteEvent(remoteName: string): RemoteEvent
	local existing = RemotesFolder:FindFirstChild(remoteName)
	if existing and existing:IsA("RemoteEvent") then return existing end
	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = RemotesFolder
	return remote
end

local function pushNotification(player: Player, message: string, notificationType: string)
	if notificationPushRemote then
		notificationPushRemote:FireClient(player, { Message = message, Type = notificationType })
	end
end

local function ensureGeneratorDataShape(playerData)
	if type(playerData.Generators) ~= "table" then
		playerData.Generators = { SlotsUnlocked = STARTING_SLOTS, Equipped = {} }
	end
	if type(playerData.Generators.SlotsUnlocked) ~= "number" then playerData.Generators.SlotsUnlocked = STARTING_SLOTS end
	if type(playerData.Generators.ExtraSlotsPurchased) ~= "number" then playerData.Generators.ExtraSlotsPurchased = 0 end
	playerData.Generators.ExtraSlotsPurchased = math.clamp(math.floor(playerData.Generators.ExtraSlotsPurchased), 0, EXTRA_SLOT_CAP)
	playerData.Generators.SlotsUnlocked = STARTING_SLOTS + playerData.Generators.ExtraSlotsPurchased
	if type(playerData.Generators.Equipped) ~= "table" then playerData.Generators.Equipped = {} end
	for slotIndex, slotData in pairs(playerData.Generators.Equipped) do
		if type(slotIndex) == "number" and type(slotData) == "table" then
			if type(slotData.GeneratorId) ~= "string" or not harvesterById[slotData.GeneratorId] then
				playerData.Generators.Equipped[slotIndex] = nil
			else
				if type(slotData.Condiments) ~= "table" then slotData.Condiments = {} end
				local cleaned = {}
				for _, condimentId in ipairs(slotData.Condiments) do if type(condimentId) == "string" and condimentById[condimentId] then table.insert(cleaned, condimentId) end end
				slotData.Condiments = cleaned
				slotData.Level = nil
			end
		end
	end
end

local function sortedCondimentsAsc()
	local condiments = GeneratorConfig.GetCondimentsSorted()
	table.sort(condiments, function(a, b)
		local aps = tonumber(a.foodPerSec) or 0
		local bps = tonumber(b.foodPerSec) or 0
		if aps == bps then return (tonumber(a.cost) or 0) < (tonumber(b.cost) or 0) end
		return aps < bps
	end)
	return condiments
end

local function patchGenerators(player, generatorsData)
	ProfileService.PatchPlayerState(player, { "Generators" }, generatorsData)
end

local function validateSlot(playerData, slotIndex)
	if type(slotIndex) ~= "number" then return nil, "Invalid slot." end
	slotIndex = math.floor(slotIndex)
	local unlocked = playerData.Generators.SlotsUnlocked
	if slotIndex < 1 or slotIndex > unlocked then return nil, "Slot is locked." end
	return slotIndex, nil
end

local function computeSlotFoodPerSecond(slotData)
	if type(slotData) ~= "table" or type(slotData.GeneratorId) ~= "string" then return 0 end
	local harvester = harvesterById[slotData.GeneratorId]
	if not harvester then return 0 end
	local base = tonumber(harvester.baseFoodPerSec) or 0
	local condimentTotal = 0
	local condiments = if type(slotData.Condiments) == "table" then slotData.Condiments else {}
	for _, condimentId in ipairs(condiments) do
		local condiment = condimentById[condimentId]
		if condiment then condimentTotal += tonumber(condiment.foodPerSec) or 0 end
	end
	local condimentMultiplier = 1
	local buffType = harvester.buffType
	if buffType == "CondimentOutput" then condimentMultiplier += tonumber(harvester.buffValue) or 0 end
	return base + (condimentTotal * condimentMultiplier)
end

local function onBuyEquip(player, payload)
	local data = ProfileService.GetPlayerData(player); if not data then return end
	ensureGeneratorDataShape(data)
	if type(payload) ~= "table" then return end
	local slotIndex, slotErr = validateSlot(data, payload.SlotIndex); if not slotIndex then pushNotification(player, "Could not equip harvester: " .. slotErr, "Warning"); return end
	local harvesterId = payload.HarvesterId
	local harvester = if type(harvesterId) == "string" then harvesterById[harvesterId] else nil
	if not harvester then pushNotification(player, "Could not equip harvester: unknown harvester.", "Warning"); return end
	local playerPrestige = tonumber((data.Prestige and data.Prestige.Level) or data.PrestigeLevel) or 0
	local classInfo = classById[harvester.classId]
	local requiredPrestige = tonumber(classInfo and classInfo.unlockPrestige) or 0
	if playerPrestige < requiredPrestige then
		pushNotification(player, string.format("Reach Prestige %d to unlock %s harvesters.", requiredPrestige, classInfo and classInfo.displayName or "this class"), "Warning")
		return
	end
	if data.Generators.Equipped[slotIndex] then pushNotification(player, "Could not equip harvester: slot occupied.", "Warning"); return end
	local cost = tonumber(harvester.cost) or math.huge
	if not CurrencyService.RemoveCurrency(player, "Coins", cost) then pushNotification(player, "Not enough coins.", "Warning"); return end
	data.Generators.Equipped[slotIndex] = { GeneratorId = harvesterId, Condiments = {} }
	patchGenerators(player, data.Generators)
	pushNotification(player, "Harvester equipped.", "Success")
end

local function onRemove(player, payload)
	local data = ProfileService.GetPlayerData(player); if not data then return end
	ensureGeneratorDataShape(data)
	local slotIndex, slotErr = validateSlot(data, payload and payload.SlotIndex); if not slotIndex then pushNotification(player, "Could not remove harvester: " .. slotErr, "Warning"); return end
	data.Generators.Equipped[slotIndex] = nil
	patchGenerators(player, data.Generators)
	pushNotification(player, "Harvester removed.", "Success")
end

local function onBuyEquipCondiment(player, payload)
	local data = ProfileService.GetPlayerData(player); if not data then return end
	ensureGeneratorDataShape(data)
	if type(payload) ~= "table" then return end
	local slotIndex, slotErr = validateSlot(data, payload.SlotIndex); if not slotIndex then pushNotification(player, "Could not equip condiment: " .. slotErr, "Warning"); return end
	local slotData = data.Generators.Equipped[slotIndex]
	if type(slotData) ~= "table" then pushNotification(player, "Could not equip condiment: empty slot.", "Warning"); return end
	local harvester = harvesterById[slotData.GeneratorId]; if not harvester then return end
	if type(slotData.Condiments) ~= "table" then slotData.Condiments = {} end
	local maxSlots = tonumber(harvester.condimentSlots) or 0
	if #slotData.Condiments >= maxSlots then pushNotification(player, "Condiment slots are full.", "Warning"); return end
	local condimentId = payload.CondimentId
	local condiment = if type(condimentId) == "string" then condimentById[condimentId] else nil
	if not condiment then pushNotification(player, "Could not equip condiment: unknown condiment.", "Warning"); return end
	local cost = tonumber(condiment.cost) or math.huge
	if not CurrencyService.RemoveCurrency(player, "Coins", cost) then pushNotification(player, "Not enough coins.", "Warning"); return end
	table.insert(slotData.Condiments, condimentId)
	patchGenerators(player, data.Generators)
	pushNotification(player, "Condiment equipped.", "Success")
end

local function onAutoUpgrade(player, payload)
	local data = ProfileService.GetPlayerData(player); if not data then return end
	ensureGeneratorDataShape(data)
	local slotIndex, slotErr = validateSlot(data, payload and payload.SlotIndex); if not slotIndex then pushNotification(player, "Could not upgrade condiments: " .. slotErr, "Warning"); return end
	local slotData = data.Generators.Equipped[slotIndex]
	if type(slotData) ~= "table" then pushNotification(player, "Could not upgrade condiments: empty slot.", "Warning"); return end
	local harvester = harvesterById[slotData.GeneratorId]; if not harvester then return end
	if type(slotData.Condiments) ~= "table" then slotData.Condiments = {} end
	local upgrades = 0
	local maxSlots = tonumber(harvester.condimentSlots) or 0
	while #slotData.Condiments < maxSlots do
		local coins = tonumber((((data.Currencies or {}).Coins))) or 0
		local best = GeneratorConfig.GetBestAffordableCondiment(coins)
		if not best then break end
		local cost = tonumber(best.cost) or math.huge
		if not CurrencyService.RemoveCurrency(player, "Coins", cost) then break end
		table.insert(slotData.Condiments, best.id)
		upgrades += 1
	end
	while #slotData.Condiments > 0 do
		local weakestIndex = nil
		local weakestValue = math.huge
		for idx, condimentId in ipairs(slotData.Condiments) do
			local condiment = condimentById[condimentId]
			local value = tonumber(condiment and condiment.foodPerSec) or 0
			if value < weakestValue then
				weakestValue = value
				weakestIndex = idx
			end
		end
		if not weakestIndex then break end
		local coins = tonumber((((data.Currencies or {}).Coins))) or 0
		local candidate = nil
		for _, condiment in ipairs(sortedCondimentsAsc()) do
			local cCost = tonumber(condiment.cost) or math.huge
			local cValue = tonumber(condiment.foodPerSec) or 0
			if cCost <= coins and cValue > weakestValue then
				candidate = condiment
			end
		end
		if not candidate then break end
		local cost = tonumber(candidate.cost) or math.huge
		if not CurrencyService.RemoveCurrency(player, "Coins", cost) then break end
		slotData.Condiments[weakestIndex] = candidate.id
		upgrades += 1
	end
	if upgrades > 0 then
		patchGenerators(player, data.Generators)
		pushNotification(player, "Condiments upgraded.", "Success")
	else
		local maxValue = 0
		for _, condiment in pairs(condimentById) do
			maxValue = math.max(maxValue, tonumber(condiment.foodPerSec) or 0)
		end
		local allBest = #slotData.Condiments >= maxSlots and maxSlots > 0
		if allBest then
			for _, condimentId in ipairs(slotData.Condiments) do
				local condiment = condimentById[condimentId]
				local value = tonumber(condiment and condiment.foodPerSec) or 0
				if value < maxValue then
					allBest = false
					break
				end
			end
		end
		if allBest then
			pushNotification(player, "Already using best condiments.", "Info")
		else
			pushNotification(player, "Not enough coins.", "Warning")
		end
	end
end

local function onPromptExtraSlotPurchase(player)
	local data = ProfileService.GetPlayerData(player); if not data then return end
	ensureGeneratorDataShape(data)
	local productId = tonumber(MarketplaceConfig.ExtraHarvesterSlotProductId) or 0
	if productId <= 0 then
		pushNotification(player, "Extra slot product is not configured.", "Warning")
		return
	end
	if data.Generators.ExtraSlotsPurchased >= EXTRA_SLOT_CAP then
		pushNotification(player, "You already own the max extra slots.", "Warning")
		return
	end
	RobloxMarketplaceService:PromptProductPurchase(player, productId)
end

local function processReceipt(receiptInfo)
	local productId = tonumber(MarketplaceConfig.ExtraHarvesterSlotProductId) or 0
	if productId <= 0 or receiptInfo.ProductId ~= productId then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local data = ProfileService.GetPlayerData(player)
	if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end
	ensureGeneratorDataShape(data)
	if data.Generators.ExtraSlotsPurchased < EXTRA_SLOT_CAP then
		data.Generators.ExtraSlotsPurchased += 1
		data.Generators.SlotsUnlocked = STARTING_SLOTS + data.Generators.ExtraSlotsPurchased
		patchGenerators(player, data.Generators)
		pushNotification(player, "Extra harvester slot unlocked.", "Success")
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onRemoveCondiment(player, payload)
	local data = ProfileService.GetPlayerData(player); if not data then return end
	ensureGeneratorDataShape(data)
	if type(payload) ~= "table" then return end
	local slotIndex, slotErr = validateSlot(data, payload.SlotIndex); if not slotIndex then pushNotification(player, "Could not remove condiment: " .. slotErr, "Warning"); return end
	local slotData = data.Generators.Equipped[slotIndex]
	if type(slotData) ~= "table" then pushNotification(player, "Could not remove condiment: empty slot.", "Warning"); return end
	if type(slotData.Condiments) ~= "table" then slotData.Condiments = {} end
	local condimentSlotIndex = tonumber(payload.CondimentSlotIndex)
	if not condimentSlotIndex then pushNotification(player, "Could not remove condiment: invalid slot.", "Warning"); return end
	condimentSlotIndex = math.floor(condimentSlotIndex)
	if condimentSlotIndex < 1 or condimentSlotIndex > #slotData.Condiments then pushNotification(player, "Could not remove condiment: invalid slot.", "Warning"); return end
	table.remove(slotData.Condiments, condimentSlotIndex)
	patchGenerators(player, data.Generators)
end

function GeneratorService.CalculateTotalFoodPerSecond(player)
	local data = ProfileService.GetPlayerData(player); if not data then return 0 end
	ensureGeneratorDataShape(data)
	local total = 0
	for slotIndex = 1, data.Generators.SlotsUnlocked do total += computeSlotFoodPerSecond(data.Generators.Equipped[slotIndex]) end
	total *= PrestigeService.GetFoodMultiplier(player)
	-- BuffService applies global FoodPerSec/AllEarnings style multipliers.
	total *= BuffService.GetMultiplier(player, "AllFood")
	total *= BuffService.GetMultiplier(player, "FoodPerSec")
	if EconomyConfig.DEV_MODE then total *= EconomyConfig.DEV_GENERATOR_MULTIPLIER end
	return total
end

local function startPassiveLoop()
	if passiveLoopRunning then return end
	passiveLoopRunning = true
	task.spawn(function()
		while true do
			task.wait(PASSIVE_TICK_SECONDS)
			for _, player in ipairs(Players:GetPlayers()) do
				local foodPerSecond = GeneratorService.CalculateTotalFoodPerSecond(player)
				if foodPerSecond > 0 then CurrencyService.AddFood(player, foodPerSecond * PASSIVE_TICK_SECONDS) end
			end
		end
	end)
end

function GeneratorService.Init()
	if type(GeneratorConfig.Classes) ~= "table" then warn("[GeneratorService] GeneratorConfig.Classes missing; class-filtered UI may be unavailable") end
	if type(GeneratorConfig.Harvesters) ~= "table" then warn("[GeneratorService] GeneratorConfig.Harvesters missing; harvesters disabled") end
	if type(GeneratorConfig.Condiments) ~= "table" then warn("[GeneratorService] GeneratorConfig.Condiments missing; condiments disabled") end
	if GeneratorConfig.Generators and GeneratorConfig.Harvesters and GeneratorConfig.Generators ~= GeneratorConfig.Harvesters then
		warn("[GeneratorService] GeneratorConfig.Generators is not aliased to Harvesters")
	end
	generatorBuyEquipRemote = getOrCreateRemoteEvent(RemoteNames.Generator_BuyEquip or "Generator_BuyEquip")
	generatorEquipLegacyRemote = getOrCreateRemoteEvent(RemoteNames.Generator_Equip or "Generator_Equip")
	generatorRemoveRemote = getOrCreateRemoteEvent(RemoteNames.Generator_Remove or "Generator_Remove")
	generatorCondimentRemote = getOrCreateRemoteEvent(RemoteNames.Generator_BuyEquipCondiment or "Generator_BuyEquipCondiment")
	generatorRemoveCondimentRemote = getOrCreateRemoteEvent(RemoteNames.Generator_RemoveCondiment or "Generator_RemoveCondiment")
	generatorAutoUpgradeRemote = getOrCreateRemoteEvent(RemoteNames.Generator_AutoUpgradeCondiments or "Generator_AutoUpgradeCondiments")
	generatorUpgradeRemote = getOrCreateRemoteEvent(RemoteNames.Generator_Upgrade or "Generator_Upgrade")
	generatorPromptExtraSlotPurchaseRemote = getOrCreateRemoteEvent(RemoteNames.Generator_PromptExtraSlotPurchase or "Generator_PromptExtraSlotPurchase")
	notificationPushRemote = getOrCreateRemoteEvent(RemoteNames.Notification_Push or "Notification_Push")
	RobloxMarketplaceService.ProcessReceipt = processReceipt
end

function GeneratorService.Start()
	if generatorBuyEquipRemote then generatorBuyEquipRemote.OnServerEvent:Connect(onBuyEquip) end
	if generatorEquipLegacyRemote then generatorEquipLegacyRemote.OnServerEvent:Connect(onBuyEquip) end
	if generatorRemoveRemote then generatorRemoveRemote.OnServerEvent:Connect(onRemove) end
	if generatorCondimentRemote then generatorCondimentRemote.OnServerEvent:Connect(onBuyEquipCondiment) end
	if generatorRemoveCondimentRemote then generatorRemoveCondimentRemote.OnServerEvent:Connect(onRemoveCondiment) end
	if generatorAutoUpgradeRemote then generatorAutoUpgradeRemote.OnServerEvent:Connect(onAutoUpgrade) end
	if generatorUpgradeRemote then generatorUpgradeRemote.OnServerEvent:Connect(onAutoUpgrade) end
	if generatorPromptExtraSlotPurchaseRemote then generatorPromptExtraSlotPurchaseRemote.OnServerEvent:Connect(onPromptExtraSlotPurchase) end
	startPassiveLoop()
end

return GeneratorService
