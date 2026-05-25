--!strict
local BugFarmController = {}
local contextRef
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local RemotesFolder = Shared:WaitForChild("Remotes")
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))
local ascendResultConn = nil
local ascendResultHandlers: {((payload: {[string]: any}) -> ())} = {}
local combatTeamResultConn = nil
local combatTeamResultHandlers: {((payload: {[string]: any}) -> ())} = {}

function BugFarmController.Init(context): ()
	contextRef = context
end

local function getRemote(...: string)
	local tried = {}
	for i = 1, select("#", ...) do
		local key = select(i, ...)
		local canonicalKey = RemoteNames[key]
		local remote = nil

		if contextRef and contextRef.Remotes then
			remote = contextRef.Remotes[key]
			if not remote and canonicalKey then
				remote = contextRef.Remotes[canonicalKey]
			end
		end

		if not remote then
			remote = RemotesFolder:FindFirstChild(key)
		end
		if not remote and canonicalKey then
			remote = RemotesFolder:FindFirstChild(canonicalKey)
		end
		if not remote then
			remote = RemotesFolder:WaitForChild(key, 0.5)
		end
		if not remote and canonicalKey then
			remote = RemotesFolder:WaitForChild(canonicalKey, 0.5)
		end

		if remote and remote:IsA("RemoteEvent") then
			return remote
		end
		table.insert(tried, tostring(key))
		if canonicalKey and canonicalKey ~= key then
			table.insert(tried, tostring(canonicalKey))
		end
	end
	if #tried > 0 then
		warn(string.format("[BugFarmController] Missing remote for keys: %s", table.concat(tried, ", ")))
	end
	return nil
end

function BugFarmController.Start(): ()
	local remote = getRemote("BugFarm_AscendResult")
	if remote and not ascendResultConn then
		ascendResultConn = remote.OnClientEvent:Connect(function(payload)
			if type(payload) ~= "table" or not contextRef then return end
			local uid = payload.Uid
			local newRank = tonumber(payload.NewRank)
			local bugEssence = tonumber(payload.BugEssence)
			local playerData = ((contextRef.State or {}).PlayerData or {})
			local bugs = playerData.Bugs
			local inventory = bugs and bugs.Inventory
			if type(uid) == "string" and type(inventory) == "table" and type(inventory[uid]) == "table" and newRank ~= nil then
				inventory[uid].Ascension = newRank
			end
			if bugEssence ~= nil then
				playerData.Currencies = playerData.Currencies or {}
				playerData.Currencies.BugEssence = bugEssence
			end
			for _, handler in ipairs(ascendResultHandlers) do
				handler(payload)
			end
			if contextRef.Events and contextRef.Events.StateChanged then
				contextRef.Events.StateChanged:Fire()
			end
		end)
	end
	local combatTeamRemote = getRemote("BugFarm_CombatTeamResult")
	if combatTeamRemote and not combatTeamResultConn then
		combatTeamResultConn = combatTeamRemote.OnClientEvent:Connect(function(payload)
			if type(payload) ~= "table" or not contextRef then return end
			print("[BugFarmController] Combat team result", payload.Action, payload.Success, payload.Uid, payload.SlotIndex, payload.Reason)
			local playerData = ((contextRef.State or {}).PlayerData or {})
			playerData.Bugs = playerData.Bugs or {}
			if type(payload.Bugs) == "table" then
				playerData.Bugs = payload.Bugs
			elseif type(payload.CombatSlots) == "table" then
				playerData.Bugs.CombatSlots = payload.CombatSlots
			end
			for _, handler in ipairs(combatTeamResultHandlers) do
				handler(payload)
			end
			if contextRef.Events and contextRef.Events.StateChanged then
				contextRef.Events.StateChanged:Fire()
			end
		end)
	end
end

function BugFarmController.BindAscendResult(handler: (payload: {[string]: any}) -> ()): (() -> ())
	table.insert(ascendResultHandlers, handler)
	return function()
		for i, fn in ipairs(ascendResultHandlers) do
			if fn == handler then
				table.remove(ascendResultHandlers, i)
				break
			end
		end
	end
end

function BugFarmController.BindCombatTeamResult(handler: (payload: {[string]: any}) -> ()): (() -> ())
	table.insert(combatTeamResultHandlers, handler)
	return function()
		for i, fn in ipairs(combatTeamResultHandlers) do
			if fn == handler then
				table.remove(combatTeamResultHandlers, i)
				break
			end
		end
	end
end

local function fire(remoteNames: {string}, payload: {[string]: any}?): boolean
	local remote = getRemote(table.unpack(remoteNames))
	if remote then
		remote:FireServer(payload or {})
		return true
	end
	return false
end

function BugFarmController.EquipFarmer(bugUid: string, slotIndex: number?): ()
	fire({"BugFarm_EquipFarmer", "BugFarmEquipFarmer"}, { Uid = bugUid, SlotIndex = slotIndex })
end

function BugFarmController.UnequipFarmer(slotIndex: number): ()
	fire({"BugFarm_UnequipFarmer", "BugFarmUnequipFarmer"}, { SlotIndex = slotIndex })
end

function BugFarmController.EquipCombat(bugUid: string, slotIndex: number?): ()
	fire({"BugFarm_EquipCombat", "BugFarmEquipCombat"}, { Uid = bugUid, SlotIndex = slotIndex })
end

function BugFarmController.UnequipCombat(slotIndex: number): ()
	fire({"BugFarm_UnequipCombat", "BugFarmUnequipCombat"}, { SlotIndex = slotIndex })
end

function BugFarmController.ToggleLock(bugUid: string): ()
	fire({"BugFarm_ToggleLock", "Bug_ToggleLock", "BugToggleLock"}, { Uid = bugUid })
end

function BugFarmController.RenameBug(bugUid: string, newName: string): ()
	fire({"BugFarm_RenameBug"}, { Uid = bugUid, Name = newName })
end

function BugFarmController.Recycle(uids: {string}, confirmHighRarity: boolean?): ()
	fire({"BugFarm_Recycle", "Bug_Recycle", "BugRecycle"}, { Uids = uids, ConfirmHighRarity = confirmHighRarity == true })
end

function BugFarmController.RecycleSelected(uids: {string}, confirmHighRarity: boolean?): ()
	BugFarmController.Recycle(uids, confirmHighRarity)
end

function BugFarmController.Ascend(bugUid: string): ()
	print("[BugFarmController] Ascend requested", bugUid)
	local fired = fire({"BugFarm_Ascend"}, { Uid = bugUid })
	if not fired then
		warn("[BugFarmController] Ascend remote missing: BugFarm_Ascend")
	end
end

function BugFarmController.PromptExtraFarmerSlotPurchase(): ()
	fire({"BugFarm_PromptExtraFarmerSlotPurchase", "BugFarm_BuyExtraFarmerSlot", "BugFarmBuyExtraFarmerSlot"}, {})
end

function BugFarmController.PromptBuyExtraFarmerSlot(): ()
	BugFarmController.PromptExtraFarmerSlotPurchase()
end

return BugFarmController
