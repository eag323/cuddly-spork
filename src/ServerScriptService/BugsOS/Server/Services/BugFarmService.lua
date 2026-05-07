--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local RemoteNames = require(Remotes:WaitForChild("RemoteNames"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local BugFarmService = {}
local remotes = {}
local dustByRarity = { Common = 50, Rare = 200, Epic = 1000, Legendary = 5000, Mythic = 25000 }

local function ensureRemote(name: string): RemoteEvent
	local existing = Remotes:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then return existing end
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = Remotes
	return re
end

local function notify(player: Player, message: string, t: string)
	if remotes.NotificationPush then
		remotes.NotificationPush:FireClient(player, { Message = message, Type = t })
	end
end

local function isEquipped(data, bugUid: string): boolean
	for _, uid in pairs(data.Bugs.Equipped or {}) do
		if uid == bugUid then return true end
	end
	return false
end

function BugFarmService.Init(): ()
	remotes.BugEquip = ensureRemote(RemoteNames.Bug_Equip)
	remotes.BugUnequip = ensureRemote(RemoteNames.Bug_Unequip)
	remotes.BugLock = ensureRemote(RemoteNames.Bug_Lock)
	remotes.BugSacrifice = ensureRemote(RemoteNames.Bug_Sacrifice)
	remotes.NotificationPush = ensureRemote(RemoteNames.Notification_Push)
end

function BugFarmService.Start(): ()
	local bugEquipRemote = remotes.BugEquip
	local bugUnequipRemote = remotes.BugUnequip
	local bugLockRemote = remotes.BugLock
	local bugSacrificeRemote = remotes.BugSacrifice

	bugEquipRemote.OnServerEvent:Connect(function(player, payload)
		local d = ProfileService.GetPlayerData(player)
		if not d or type(payload) ~= "table" then notify(player, "Invalid bug equip action.", "Warning") return end
		local slotIndex = payload.SlotIndex
		local bugUid = payload.BugUid
		if type(slotIndex) ~= "number" or type(bugUid) ~= "string" then notify(player, "Invalid bug equip action.", "Warning") return end
		d.Bugs = d.Bugs or { Inventory = {}, Equipped = {}, SlotsUnlocked = 5 }
		if slotIndex < 1 or slotIndex > (d.Bugs.SlotsUnlocked or 0) then notify(player, "Slot is locked.", "Warning") return end
		if not d.Bugs.Inventory[bugUid] then notify(player, "Bug not found.", "Warning") return end
		if isEquipped(d, bugUid) then notify(player, "Bug already equipped.", "Warning") return end
		d.Bugs.Equipped[slotIndex] = bugUid
		ProfileService.PatchPlayerState(player, { "Bugs" }, d.Bugs)
		notify(player, "Bug equipped.", "Success")
	end)

	bugUnequipRemote.OnServerEvent:Connect(function(player, payload)
		local d = ProfileService.GetPlayerData(player)
		if not d or type(payload) ~= "table" then notify(player, "Invalid bug unequip action.", "Warning") return end
		local slotIndex = payload.SlotIndex
		if type(slotIndex) ~= "number" then notify(player, "Invalid bug unequip action.", "Warning") return end
		d.Bugs = d.Bugs or { Inventory = {}, Equipped = {}, SlotsUnlocked = 5 }
		local slotsUnlocked = tonumber(d.Bugs.SlotsUnlocked) or 5
		if slotIndex < 1 or slotIndex > slotsUnlocked then notify(player, "Invalid slot index.", "Warning") return end
		if d.Bugs.Equipped == nil then d.Bugs.Equipped = {} end
		d.Bugs.Equipped[slotIndex] = nil
		ProfileService.PatchPlayerState(player, { "Bugs" }, d.Bugs)
		notify(player, "Bug unequipped.", "Success")
	end)

	bugLockRemote.OnServerEvent:Connect(function(player, payload)
		local d = ProfileService.GetPlayerData(player)
		if not d or type(payload) ~= "table" then notify(player, "Invalid bug lock action.", "Warning") return end
		local bugUid = payload.BugUid
		if type(bugUid) ~= "string" then notify(player, "Invalid bug lock action.", "Warning") return end
		d.Bugs = d.Bugs or { Inventory = {}, Equipped = {}, SlotsUnlocked = 5 }
		local bug = d.Bugs.Inventory and d.Bugs.Inventory[bugUid]
		if not bug then notify(player, "Bug not found.", "Warning") return end
		bug.Locked = not (bug.Locked == true)
		ProfileService.PatchPlayerState(player, { "Bugs" }, d.Bugs)
	end)

	bugSacrificeRemote.OnServerEvent:Connect(function(player, payload)
		local d = ProfileService.GetPlayerData(player)
		if not d or type(payload) ~= "table" then notify(player, "Invalid sacrifice action.", "Warning") return end
		local bugUid = payload.BugUid
		if type(bugUid) ~= "string" then notify(player, "Invalid sacrifice action.", "Warning") return end
		d.Bugs = d.Bugs or { Inventory = {}, Equipped = {}, SlotsUnlocked = 5 }
		local bug = d.Bugs.Inventory and d.Bugs.Inventory[bugUid]
		if not bug then notify(player, "Bug not found.", "Warning") return end
		if bug.Locked or bug.Favorited then notify(player, "Cannot sacrifice locked or favorited bug.", "Warning") return end
		if isEquipped(d, bugUid) then notify(player, "Cannot sacrifice equipped bug.", "Warning") return end
		local dust = dustByRarity[bug.Rarity] or 0
		d.Bugs.Inventory[bugUid] = nil
		d.Currencies = d.Currencies or {}
		d.Currencies.BugDust = (d.Currencies.BugDust or 0) + dust
		ProfileService.PatchPlayerState(player, { "Bugs" }, d.Bugs)
		ProfileService.PatchPlayerState(player, { "Currencies", "BugDust" }, d.Currencies.BugDust)
		notify(player, string.format("Sacrificed bug for %d Bug Dust.", dust), "Success")
	end)
end

return BugFarmService
