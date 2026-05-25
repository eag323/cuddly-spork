--!strict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local RemoteNames = require(Remotes:WaitForChild("RemoteNames"))
local BugConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugConfig"))
local MarketplaceConfig = require(Shared:WaitForChild("Config"):WaitForChild("MarketplaceConfig"))
local BugAscensionConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugAscensionConfig"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local BuffService = require(script.Parent:WaitForChild("BuffService"))

local BugFarmService = {}
local remotes = {}
local EXTRA_SLOT_CAP = 10

local function ensureRemote(name)
	local e = Remotes:FindFirstChild(name)
	if e and e:IsA("RemoteEvent") then return e end
	local re = Instance.new("RemoteEvent"); re.Name = name; re.Parent = Remotes; return re
end

local function notify(player, message, t)
	if remotes.NotificationPush then remotes.NotificationPush:FireClient(player, { Message = message, Type = t }) end
end

local function ensureData(d)
	d.Bugs = d.Bugs or {}
	d.Bugs.Inventory = d.Bugs.Inventory or {}
	d.Bugs.FarmerSlots = d.Bugs.FarmerSlots or {}
	d.Bugs.CombatSlots = d.Bugs.CombatSlots or {}
	d.Bugs.ExtraFarmerSlotsPurchased = math.max(0, tonumber(d.Bugs.ExtraFarmerSlotsPurchased) or 0)
	if type(d.Bugs.Equipped) == "table" then
		for i, uid in pairs(d.Bugs.Equipped) do
			if d.Bugs.FarmerSlots[i] == nil then d.Bugs.FarmerSlots[i] = uid end
		end
	end
	for uid, bug in pairs(d.Bugs.Inventory) do
		if type(bug) == "table" then
			bug.Uid = bug.Uid or uid
			bug.BugId = bug.BugId or bug.SpeciesId or bug.Species or "ant"
			if bug.Locked == nil then bug.Locked = false end
		end
	end
end

local function farmerSlotCount(d)
	local prestige = math.max(0, tonumber((((d.Progression or {}).Prestige))) or 0)
	return 5 + prestige + math.min(EXTRA_SLOT_CAP, d.Bugs.ExtraFarmerSlotsPurchased)
end

local function inSlots(slots, uid)
	for _, v in pairs(slots) do if v == uid then return true end end
	return false
end

local function firstEmpty(slots, count)
	for i=1,count do if slots[i] == nil then return i end end
	return nil
end

local function recycleValue(bug)
	local cfg = BugConfig.GetBug(bug.BugId) or BugConfig.Bugs[bug.BugId]
	if cfg and cfg.recycling and type(cfg.recycling.bugEssence) == "number" then return cfg.recycling.bugEssence end
	local fallback = { Common = 0, Uncommon = 1, Rare = 3, Epic = 10, Legendary = 40, Mythic = 150 }
	return fallback[tostring(bug.Rarity or "Common")] or 0
end

function BugFarmService.Init()
	remotes.EquipFarmer = ensureRemote(RemoteNames.BugFarm_EquipFarmer)
	remotes.UnequipFarmer = ensureRemote(RemoteNames.BugFarm_UnequipFarmer)
	remotes.EquipCombat = ensureRemote(RemoteNames.BugFarm_EquipCombat)
	remotes.UnequipCombat = ensureRemote(RemoteNames.BugFarm_UnequipCombat)
	remotes.ToggleLock = ensureRemote(RemoteNames.BugFarm_ToggleLock)
	remotes.RenameBug = ensureRemote(RemoteNames.BugFarm_RenameBug)
	remotes.Recycle = ensureRemote(RemoteNames.BugFarm_Recycle)
	remotes.Ascend = ensureRemote(RemoteNames.BugFarm_Ascend)
	-- Canonical remote expected by client startup checks.
	remotes.BuyExtraSlot = ensureRemote(RemoteNames.BugFarm_BuyExtraFarmerSlot)
	-- Backward compatibility for any legacy callers still firing the older prompt name.
	remotes.BuyExtraSlotLegacy = ensureRemote(RemoteNames.BugFarm_PromptExtraFarmerSlotPurchase)
	remotes.NotificationPush = ensureRemote(RemoteNames.Notification_Push)
end

function BugFarmService.Start()
	remotes.EquipFarmer.OnServerEvent:Connect(function(player, payload)
		local d = ProfileService.GetPlayerData(player); if not d or type(payload) ~= "table" then return end; ensureData(d)
		local uid = payload.Uid; if type(uid) ~= "string" or not d.Bugs.Inventory[uid] then return end
		if inSlots(d.Bugs.CombatSlots, uid) then notify(player, "This bug is already assigned to Combat Team.", "Warning"); return end
		if inSlots(d.Bugs.FarmerSlots, uid) then notify(player, "Bug is already farming.", "Info"); return end
		local count = farmerSlotCount(d)
		local idx = tonumber(payload.SlotIndex) or firstEmpty(d.Bugs.FarmerSlots, count)
		if not idx or idx < 1 or idx > count or d.Bugs.FarmerSlots[idx] then notify(player, "No farmer slots available.", "Warning"); return end
		d.Bugs.FarmerSlots[idx] = uid
		ProfileService.PatchPlayerState(player, {"Bugs"}, d.Bugs)
	end)
	remotes.UnequipFarmer.OnServerEvent:Connect(function(player,payload)
		local d=ProfileService.GetPlayerData(player); if not d or type(payload)~="table" then return end; ensureData(d)
		local i=tonumber(payload.SlotIndex); if not i then return end; d.Bugs.FarmerSlots[i]=nil; ProfileService.PatchPlayerState(player,{"Bugs"},d.Bugs)
	end)
	remotes.EquipCombat.OnServerEvent:Connect(function(player,payload)
		local d=ProfileService.GetPlayerData(player); if not d or type(payload)~="table" then return end; ensureData(d)
		local uid=payload.Uid; if type(uid)~="string" or not d.Bugs.Inventory[uid] then return end
		if inSlots(d.Bugs.FarmerSlots, uid) then notify(player, "This bug is already assigned to Farmers.", "Warning"); return end
		if inSlots(d.Bugs.CombatSlots, uid) then notify(player, "Bug is already on the Combat Team.", "Info"); return end
		local idx=tonumber(payload.SlotIndex) or firstEmpty(d.Bugs.CombatSlots, 5)
		if not idx or idx<1 or idx>5 or d.Bugs.CombatSlots[idx] then notify(player,"Combat Team is full.","Warning"); return end
		d.Bugs.CombatSlots[idx]=uid; ProfileService.PatchPlayerState(player,{"Bugs"},d.Bugs)
	end)
	remotes.UnequipCombat.OnServerEvent:Connect(function(player,payload)
		local d=ProfileService.GetPlayerData(player); if not d or type(payload)~="table" then return end; ensureData(d)
		local i=tonumber(payload.SlotIndex); if not i then return end; d.Bugs.CombatSlots[i]=nil; ProfileService.PatchPlayerState(player,{"Bugs"},d.Bugs)
	end)
	remotes.ToggleLock.OnServerEvent:Connect(function(player,payload)
		local d=ProfileService.GetPlayerData(player); if not d or type(payload)~="table" then return end; ensureData(d)
		local uid=payload.Uid; local bug=d.Bugs.Inventory[uid]; if type(uid)~="string" or not bug then return end
		bug.Locked = not (bug.Locked == true); ProfileService.PatchPlayerState(player,{"Bugs"},d.Bugs)
	end)
	remotes.RenameBug.OnServerEvent:Connect(function(player,payload)
		local d=ProfileService.GetPlayerData(player); if not d or type(payload)~="table" then return end; ensureData(d)
		local uid = payload.Uid
		local rawName = payload.Name
		local bug = d.Bugs.Inventory[uid]
		if type(uid) ~= "string" or not bug or type(rawName) ~= "string" then return end
		local cleaned = string.gsub(rawName, "^%s+", "")
		cleaned = string.gsub(cleaned, "%s+$", "")
		cleaned = string.sub(cleaned, 1, 24)
		cleaned = string.gsub(cleaned, "[^%w%s%p]", "")
		if cleaned == "" then
			bug.Nickname = nil
		else
			bug.Nickname = cleaned
		end
		ProfileService.PatchPlayerState(player,{"Bugs"},d.Bugs)
	end)
	remotes.Recycle.OnServerEvent:Connect(function(player,payload)
		local d=ProfileService.GetPlayerData(player); if not d or type(payload)~="table" or type(payload.Uids)~="table" then return end; ensureData(d)
		d.Currencies = d.Currencies or {}; d.Currencies.BugEssence = tonumber(d.Currencies.BugEssence) or 0
		local gain = 0
		for _,uid in ipairs(payload.Uids) do
			local bug = d.Bugs.Inventory[uid]
			if bug and not bug.Locked and not inSlots(d.Bugs.FarmerSlots, uid) and not inSlots(d.Bugs.CombatSlots, uid) then
				local cfg = BugConfig.GetBug(bug.BugId)
				local rarity = tostring((cfg and cfg.rarity) or bug.Rarity or "Common")
				if (rarity == "Legendary" or rarity == "Mythic") and payload.ConfirmHighRarity ~= true then
					continue
				end
				gain += recycleValue(bug); d.Bugs.Inventory[uid] = nil
			end
		end
		if gain > 0 then
			local bonus = BuffService.GetPlayerBuffs(player).BugEssenceGain or 0
			local finalGain = math.floor(gain * (1 + bonus) + 0.5)
			d.Currencies.BugEssence += finalGain
		end
		ProfileService.PatchPlayerState(player,{"Bugs"},d.Bugs)
		ProfileService.PatchPlayerState(player,{"Currencies","BugEssence"},d.Currencies.BugEssence)
	end)
	remotes.Ascend.OnServerEvent:Connect(function(player,payload)
		local playerName = if player then player.Name else "<nil>"
		local uid = if type(payload) == "table" then payload.Uid else nil
		print("[BugFarmService] Ascend request", playerName, uid)

		local d = ProfileService.GetPlayerData(player)
		if not d then
			warn("[BugFarmService] Ascend rejected: missing player data")
			return
		end
		if type(payload) ~= "table" then
			warn("[BugFarmService] Ascend rejected: invalid payload")
			return
		end

		ensureData(d)
		d.Currencies = d.Currencies or {}
		d.Currencies.BugEssence = tonumber(d.Currencies.BugEssence) or 0

		if type(uid) ~= "string" or uid == "" then
			warn("[BugFarmService] Ascend rejected: invalid uid")
			return
		end
		local bug = d.Bugs.Inventory[uid]
		if not bug then
			warn("[BugFarmService] Ascend rejected: bug not found", uid)
			return
		end

		local cfg = BugConfig.GetBug(bug.BugId)
		local maxRank = BugAscensionConfig.GetMaxRank()
		local rank = math.max(0, tonumber(bug.Ascension) or 0)
		if rank >= maxRank then
			warn("[BugFarmService] Ascend rejected: max rank", uid, rank)
			notify(player, "Max ascension reached.", "Info")
			return
		end
		local rarity = tostring((cfg and cfg.rarity) or bug.Rarity or "Common")
		local cost = tonumber(BugAscensionConfig.GetCost(rarity, rank))

		if cost == nil then
			warn("[BugFarmService] Ascend rejected: missing cost", uid, rarity, rank)
			notify(player, "Max ascension reached.", "Info")
			return
		end
		if cost <= 0 then
			warn("[BugFarmService] Ascend rejected: invalid cost", uid, cost)
			notify(player, "Ascension is unavailable for this bug right now.", "Warning")
			return
		end
		if d.Currencies.BugEssence < cost then
			warn("[BugFarmService] Ascend rejected: not enough essence", uid, d.Currencies.BugEssence, cost)
			notify(player, "Not enough Bug Essence.", "Warning")
			return
		end

		local oldRank = rank
		local newRank = rank + 1
		d.Currencies.BugEssence -= cost
		bug.Ascension = newRank

		ProfileService.PatchPlayerState(player,{"Bugs"},d.Bugs)
		ProfileService.PatchPlayerState(player,{"Currencies","BugEssence"},d.Currencies.BugEssence)
		notify(player, string.format("Bug ascended to Rank %d.", bug.Ascension), "Success")
		print("[BugFarmService] Ascend success", uid, oldRank, newRank, cost, d.Currencies.BugEssence)
	end)
	remotes.BuyExtraSlot.OnServerEvent:Connect(function(player)
		local d=ProfileService.GetPlayerData(player); if not d then return end; ensureData(d)
		local productId = tonumber(MarketplaceConfig.ExtraFarmerBugSlotProductId) or 0
		if productId <= 0 then notify(player, "Extra farmer slot product is not configured.", "Warning"); return end
		if d.Bugs.ExtraFarmerSlotsPurchased >= EXTRA_SLOT_CAP then notify(player, "You already own the max extra farmer slots.", "Info"); return end
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
	remotes.BuyExtraSlotLegacy.OnServerEvent:Connect(function(player)
		local d=ProfileService.GetPlayerData(player); if not d then return end; ensureData(d)
		local productId = tonumber(MarketplaceConfig.ExtraFarmerBugSlotProductId) or 0
		if productId <= 0 then notify(player, "Extra farmer slot product is not configured.", "Warning"); return end
		if d.Bugs.ExtraFarmerSlotsPurchased >= EXTRA_SLOT_CAP then notify(player, "You already own the max extra farmer slots.", "Info"); return end
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
	MarketplaceService.ProcessReceipt = function(receipt)
		local productId = tonumber(MarketplaceConfig.ExtraFarmerBugSlotProductId) or 0
		if productId <= 0 or receipt.ProductId ~= productId then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local p = Players:GetPlayerByUserId(receipt.PlayerId); if not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local d = ProfileService.GetPlayerData(p); if not d then return Enum.ProductPurchaseDecision.NotProcessedYet end; ensureData(d)
		if d.Bugs.ExtraFarmerSlotsPurchased < EXTRA_SLOT_CAP then d.Bugs.ExtraFarmerSlotsPurchased += 1; ProfileService.PatchPlayerState(p,{"Bugs"},d.Bugs) end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return BugFarmService
