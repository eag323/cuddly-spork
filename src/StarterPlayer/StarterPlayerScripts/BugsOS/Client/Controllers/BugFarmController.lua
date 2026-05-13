--!strict
local BugFarmController = {}
local contextRef

function BugFarmController.Init(context): ()
	contextRef = context
end

function BugFarmController.Start(): () end

local function fire(remoteName: string, payload: {[string]: any}): ()
	local remote = contextRef.Remotes[remoteName]
	if remote then
		remote:FireServer(payload)
	end
end

function BugFarmController.EquipFarmer(bugUid: string, slotIndex: number?): ()
	fire("BugFarmEquipFarmer", { Uid = bugUid, SlotIndex = slotIndex })
end

function BugFarmController.UnequipFarmer(slotIndex: number): ()
	fire("BugFarmUnequipFarmer", { SlotIndex = slotIndex })
end

function BugFarmController.EquipCombat(bugUid: string, slotIndex: number?): ()
	fire("BugFarmEquipCombat", { Uid = bugUid, SlotIndex = slotIndex })
end

function BugFarmController.UnequipCombat(slotIndex: number): ()
	fire("BugFarmUnequipCombat", { SlotIndex = slotIndex })
end

function BugFarmController.ToggleLock(bugUid: string): ()
	fire("BugToggleLock", { Uid = bugUid })
end

function BugFarmController.RecycleSelected(uids: {string}): ()
	fire("BugRecycle", { Uids = uids })
end

function BugFarmController.PromptBuyExtraFarmerSlot(): ()
	fire("BugFarmBuyExtraFarmerSlot", {})
end

return BugFarmController
