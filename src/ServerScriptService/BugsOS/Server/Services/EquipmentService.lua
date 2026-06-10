--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local EquipmentConfig = require(Config:WaitForChild("EquipmentConfig"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local EquipmentService = {}

local function isDevDropModeEnabled(): boolean
	return EquipmentConfig.IsDevDropModeEnabled ~= nil and EquipmentConfig.IsDevDropModeEnabled()
end

local function getDropChance(enemyTier: string?): number
	local devMode = EquipmentConfig.DevDropMode
	if isDevDropModeEnabled() and type(devMode) == "table" and devMode.ForceEquipmentDrop then
		return 1
	end
	return tonumber(EquipmentConfig.DropChancesByEnemyTier[enemyTier or "CommonEnemy"]) or 0
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

function EquipmentService.RollAndGrantMany(player: Player, enemyTier: string?): { { [string]: any } }
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
		return {}
	end

	local rollCount = EquipmentConfig.GetEquipmentRollCountForEnemy(tierKey)
	local drops = {}
	for _index = 1, rollCount do
		local item = EquipmentConfig.RollEquipment(Random.new(), tierKey)
		print("[EquipmentService] Generated equipment", summarizeEquipment(item))
		if EquipmentService.AddEquipment(player, item) then
			print(string.format(
				"[EquipmentService] Granted equipment %s %s %s★ to %s",
				EquipmentConfig.GetDisplayName(item),
				tostring(item.Rarity or "Common"),
				tostring(item.Stars or 1),
				player.Name
			))
			table.insert(drops, item)
		else
			warn(string.format("[EquipmentService] Inventory full; could not grant equipment to %s", player.Name))
			break
		end
	end

	return drops
end

function EquipmentService.RollAndGrant(player: Player, enemyTier: string?): { [string]: any }?
	local drops = EquipmentService.RollAndGrantMany(player, enemyTier)
	return drops[1]
end

function EquipmentService.Init(): ()
	print("[EquipmentService] Init complete")
end

return EquipmentService
