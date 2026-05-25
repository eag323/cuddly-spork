--!strict
local BugFarmController = {}
local contextRef
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local RemotesFolder = Shared:WaitForChild("Remotes")
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

function BugFarmController.Init(context): ()
	contextRef = context
end

function BugFarmController.Start(): () end

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
