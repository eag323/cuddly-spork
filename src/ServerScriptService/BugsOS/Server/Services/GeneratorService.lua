--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local ConfigFolder = SharedFolder:WaitForChild("Config")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")

local GeneratorConfig = require(ConfigFolder:WaitForChild("GeneratorConfig"))
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

local ServerScriptService = game:GetService("ServerScriptService")
local BugsOSServerFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server")
local ServicesFolder = BugsOSServerFolder:WaitForChild("Services")

local CurrencyService = require(ServicesFolder:WaitForChild("CurrencyService"))
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))

type PlayerData = { [string]: any }

type GeneratorConfigEntry = {
	id: string,
	classId: string,
	baseFoodPerSec: number?,
	baseUpgradeCost: number?,
}

local GeneratorService = {}

local STARTING_SLOTS = 3
local MAX_EQUIPPABLE_SNACK_GENERATORS = 3
local PASSIVE_TICK_SECONDS = 1
local DEFAULT_BASE_FOOD_PER_SEC = 1
local DEFAULT_BASE_UPGRADE_COST = 10

local generatorEquipRemote: RemoteEvent? = nil
local generatorUpgradeRemote: RemoteEvent? = nil
local snackGeneratorById: { [string]: GeneratorConfigEntry } = {}
local passiveLoopRunning = false

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

local function getPlayerData(player: Player): PlayerData?
	return ProfileService.GetPlayerData(player)
end

local function patchFood(player: Player, food: number): ()
	ProfileService.PatchPlayerState(player, { "Currencies", "Food" }, food)
end

local function patchGeneratorSlot(player: Player, slotIndex: number, slotValue: any): ()
	ProfileService.PatchPlayerState(player, { "Generators", "Equipped", tostring(slotIndex) }, slotValue)
end

local function ensureGeneratorDataShape(playerData: PlayerData): ()
	if type(playerData.Generators) ~= "table" then
		playerData.Generators = {
			SlotsUnlocked = STARTING_SLOTS,
			Equipped = {},
		}
	end

	if type(playerData.Generators.SlotsUnlocked) ~= "number" then
		playerData.Generators.SlotsUnlocked = STARTING_SLOTS
	end

	if type(playerData.Generators.Equipped) ~= "table" then
		playerData.Generators.Equipped = {}
	end
end

local function sanitizeLevel(value: any): number
	if type(value) ~= "number" then
		return 1
	end
	if value < 1 then
		return 1
	end
	if value ~= value or value == math.huge or value == -math.huge then
		return 1
	end

	return math.floor(value)
end

local function getPrestigeMultiplier(playerData: PlayerData): number
	local progression = playerData.Progression
	if type(progression) ~= "table" then
		return 1
	end

	local prestige = progression.Prestige
	if type(prestige) ~= "number" or prestige < 0 then
		return 1
	end

	return 1 + (0.1 * prestige)
end

local function computeGeneratorFoodPerSecond(playerData: PlayerData, slotData: any): number
	if type(slotData) ~= "table" then
		return 0
	end

	local generatorId = slotData.GeneratorId
	if type(generatorId) ~= "string" then
		return 0
	end

	local generatorDef = snackGeneratorById[generatorId]
	if not generatorDef then
		return 0
	end

	local level = sanitizeLevel(slotData.Level)
	local baseFoodPerSec = generatorDef.baseFoodPerSec or DEFAULT_BASE_FOOD_PER_SEC
	local prestigeMultiplier = getPrestigeMultiplier(playerData)

	return baseFoodPerSec * (level ^ 1.55) * prestigeMultiplier
end

local function computeUpgradeCost(slotData: any): number
	if type(slotData) ~= "table" then
		return math.huge
	end

	local generatorId = slotData.GeneratorId
	if type(generatorId) ~= "string" then
		return math.huge
	end

	local generatorDef = snackGeneratorById[generatorId]
	if not generatorDef then
		return math.huge
	end

	local level = sanitizeLevel(slotData.Level)
	local baseUpgradeCost = generatorDef.baseUpgradeCost or DEFAULT_BASE_UPGRADE_COST

	return baseUpgradeCost * (level ^ 2.05)
end

local function onGeneratorEquip(player: Player, payload: any): ()
	if type(payload) ~= "table" then
		return
	end

	local slotIndex = payload.SlotIndex
	local generatorId = payload.GeneratorId
	if type(slotIndex) ~= "number" or type(generatorId) ~= "string" then
		return
	end

	slotIndex = math.floor(slotIndex)
	if slotIndex < 1 or slotIndex > MAX_EQUIPPABLE_SNACK_GENERATORS then
		return
	end

	local generatorDef = snackGeneratorById[generatorId]
	if not generatorDef then
		return
	end

	local playerData = getPlayerData(player)
	if not playerData then
		return
	end

	ensureGeneratorDataShape(playerData)
	local slotsUnlocked = playerData.Generators.SlotsUnlocked
	if type(slotsUnlocked) ~= "number" or slotIndex > slotsUnlocked then
		return
	end

	local newSlotData = {
		GeneratorId = generatorId,
		Level = 1,
		CoreUid = nil,
	}

	playerData.Generators.Equipped[slotIndex] = newSlotData
	patchGeneratorSlot(player, slotIndex, newSlotData)
end

local function onGeneratorUpgrade(player: Player, payload: any): ()
	if type(payload) ~= "table" then
		return
	end

	local slotIndex = payload.SlotIndex
	if type(slotIndex) ~= "number" then
		return
	end

	slotIndex = math.floor(slotIndex)
	if slotIndex < 1 or slotIndex > MAX_EQUIPPABLE_SNACK_GENERATORS then
		return
	end

	local playerData = getPlayerData(player)
	if not playerData then
		return
	end

	ensureGeneratorDataShape(playerData)
	local slotData = playerData.Generators.Equipped[slotIndex]
	if type(slotData) ~= "table" then
		return
	end

	local upgradeCost = computeUpgradeCost(slotData)
	if upgradeCost <= 0 or upgradeCost == math.huge then
		return
	end

	if not CurrencyService.RemoveCurrency(player, "Coins", upgradeCost) then
		return
	end

	slotData.Level = sanitizeLevel(slotData.Level) + 1
	patchGeneratorSlot(player, slotIndex, slotData)
end

local function buildGeneratorLookups(): ()
	snackGeneratorById = {}

	local generators = GeneratorConfig.Generators
	if type(generators) ~= "table" then
		return
	end

	for _, generator in generators do
		local entry = generator :: GeneratorConfigEntry
		if type(entry.id) == "string" and entry.classId == "snack" then
			snackGeneratorById[entry.id] = entry
		end
	end
end

local function runPassiveFoodLoop(): ()
	if passiveLoopRunning then
		return
	end

	passiveLoopRunning = true
	task.spawn(function()
		while passiveLoopRunning do
			task.wait(PASSIVE_TICK_SECONDS)

			for _, player in Players:GetPlayers() do
				local playerData = getPlayerData(player)
				if playerData then
					ensureGeneratorDataShape(playerData)

					local totalFoodPerSecond = 0
					for slotIndex = 1, MAX_EQUIPPABLE_SNACK_GENERATORS do
						local slotData = playerData.Generators.Equipped[slotIndex]
						totalFoodPerSecond += computeGeneratorFoodPerSecond(playerData, slotData)
					end

					if totalFoodPerSecond > 0 and CurrencyService.AddFood(player, totalFoodPerSecond) then
						patchFood(player, playerData.Currencies.Food)
					end
				end
			end
		end
	end)
end

function GeneratorService.Init(): ()
	buildGeneratorLookups()
	generatorEquipRemote = getOrCreateRemoteEvent(RemoteNames.Generator_Equip or "Generator_Equip")
	generatorUpgradeRemote = getOrCreateRemoteEvent(RemoteNames.Generator_Upgrade or "Generator_Upgrade")
end

function GeneratorService.Start(): ()
	if generatorEquipRemote then
		generatorEquipRemote.OnServerEvent:Connect(onGeneratorEquip)
	end

	if generatorUpgradeRemote then
		generatorUpgradeRemote.OnServerEvent:Connect(onGeneratorUpgrade)
	end

	runPassiveFoodLoop()
end

return GeneratorService
