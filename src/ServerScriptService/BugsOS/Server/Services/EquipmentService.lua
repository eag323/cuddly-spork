--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local EquipmentConfig = require(Config:WaitForChild("EquipmentConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local EquipmentService = {}

local RARITY_RANKS = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
}

local function getDropChance(enemyTier: string?): number
	if EconomyConfig.DEV_MODE and EconomyConfig.DEV_FORCE_EQUIPMENT_DROPS then
		return tonumber(EconomyConfig.DEV_EQUIPMENT_DROP_CHANCE) or 1
	end
	return tonumber(EquipmentConfig.DropChancesByEnemyTier[enemyTier or "CommonEnemy"]) or 0
end

local function applyDevMinimums(item: { [string]: any }): ()
	if not EconomyConfig.DEV_MODE then
		return
	end

	local minRarity = EconomyConfig.DEV_EQUIPMENT_DROP_MIN_RARITY
	if type(minRarity) == "string" and RARITY_RANKS[minRarity] then
		local currentRarity = tostring(item.Rarity or "Common")
		if (RARITY_RANKS[currentRarity] or 0) < RARITY_RANKS[minRarity] then
			item.Rarity = minRarity
		end
	end

	local minStars = tonumber(EconomyConfig.DEV_EQUIPMENT_DROP_MIN_STARS)
	if minStars then
		item.Stars = math.max(tonumber(item.Stars) or 1, math.clamp(math.floor(minStars), 1, 6))
	end
end

local function summarizeEquipment(item: { [string]: any }): string
	return string.format(
		"%s slot=%s rarity=%s stars=%s uid=%s",
		EquipmentConfig.GetDisplayName(item),
		tostring(item.Slot or "?"),
		tostring(item.Rarity or "Common"),
		tostring(item.Stars or 1),
		tostring(item.Uid or "")
	)
end

local function ensureEquipmentData(playerData: { [string]: any }): { [string]: any }
	playerData.Equipment = playerData.Equipment or {}
	local equipment = playerData.Equipment
	equipment.Inventory = equipment.Inventory or {}
	equipment.Equipped = equipment.Equipped or {}
	for _, slot in EquipmentConfig.Slots do
		if equipment.Equipped[slot] == nil then
			equipment.Equipped[slot] = nil
		end
	end
	return equipment
end

local function getInventoryCount(inventory: { [string]: any }): number
	local count = 0
	for _uid, _item in inventory do
		count += 1
	end
	return count
end

local function generateUid(inventory: { [string]: any }): string
	local uid = "eq_" .. HttpService:GenerateGUID(false)
	while inventory[uid] ~= nil do
		uid = "eq_" .. HttpService:GenerateGUID(false)
	end
	return uid
end

function EquipmentService.AddEquipment(player: Player, item: { [string]: any }): boolean
	local playerData = ProfileService.GetPlayerData(player)
	if not playerData then
		return false
	end

	local equipment = ensureEquipmentData(playerData)
	local inventory = equipment.Inventory
	if getInventoryCount(inventory) >= EquipmentConfig.MaxInventory then
		warn(string.format("[EquipmentService] Inventory full for %s; equipment drop skipped", player.Name))
		return false
	end

	local uid = tostring(item.Uid or "")
	if uid == "" or inventory[uid] ~= nil then
		uid = generateUid(inventory)
		item.Uid = uid
	end

	inventory[uid] = item
	ProfileService.PatchPlayerState(player, { "Equipment" }, equipment)
	return true
end

function EquipmentService.RollAndGrant(player: Player, enemyTier: string?): { [string]: any }?
	local tierKey = enemyTier or "CommonEnemy"
	local chance = getDropChance(tierKey)
	local roll = math.random()
	local passed = roll < chance
	print(string.format(
		"[EquipmentService] Drop roll %s tier=%s chance=%.2f roll=%.2f result=%s",
		player.Name,
		tostring(tierKey),
		chance,
		roll,
		passed and "DROP" or "NO_DROP"
	))

	if not passed then
		return nil
	end

	local item = EquipmentConfig.RollEquipment(Random.new(), tierKey)
	applyDevMinimums(item)
	print("[EquipmentService] Generated equipment", summarizeEquipment(item))
	if not EquipmentService.AddEquipment(player, item) then
		warn(string.format("[EquipmentService] Inventory full; could not grant equipment to %s", player.Name))
		return nil
	end

	print(string.format(
		"[EquipmentService] Granted equipment %s %s %s★ to %s",
		EquipmentConfig.GetDisplayName(item),
		tostring(item.Rarity or "Common"),
		tostring(item.Stars or 1),
		player.Name
	))
	return item
end

function EquipmentService.Init(): ()
	print("[EquipmentService] Init complete")
end

return EquipmentService
