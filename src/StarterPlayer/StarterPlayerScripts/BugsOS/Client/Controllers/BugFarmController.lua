--!strict
local BugFarmController = {}
local contextRef

function BugFarmController.Init(context): ()
	contextRef = context
end

function BugFarmController.Start(): () end

local function getRemote(...: string)
	if not contextRef or not contextRef.Remotes then
		return nil
	end
	for i = 1, select("#", ...) do
		local key = select(i, ...)
		local remote = contextRef.Remotes[key]
		if remote then
			return remote
		end
	end
	return nil
end

local function fire(remoteNames: {string}, payload: {[string]: any}?): ()
	local remote = getRemote(table.unpack(remoteNames))
	if remote then
		remote:FireServer(payload or {})
	end
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

function BugFarmController.RecycleSelected(uids: {string}, confirmHighRarity: boolean?): ()
	fire({"BugFarm_Recycle", "Bug_Recycle", "BugRecycle"}, { Uids = uids, ConfirmHighRarity = confirmHighRarity == true })
end

function BugFarmController.Ascend(bugUid: string): ()
	fire({"BugFarm_Ascend"}, { Uid = bugUid })
end

function BugFarmController.PromptBuyExtraFarmerSlot(): ()
	fire({"BugFarm_PromptExtraFarmerSlotPurchase", "BugFarm_BuyExtraFarmerSlot", "BugFarmBuyExtraFarmerSlot"}, {})
end

return BugFarmController
