--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local EquipmentConfig = require(Config:WaitForChild("EquipmentConfig"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local EquipmentService = {}

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
	local chance = tonumber(EquipmentConfig.DropChancesByEnemyTier[enemyTier or "CommonEnemy"]) or 0
	if math.random() >= chance then
		return nil
	end

	local item = EquipmentConfig.RollEquipment(Random.new(), enemyTier)
	if not EquipmentService.AddEquipment(player, item) then
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
