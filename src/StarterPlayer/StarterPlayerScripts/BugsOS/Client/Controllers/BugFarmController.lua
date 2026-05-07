--!strict
local BugFarmController = {}
local contextRef

function BugFarmController.Init(context): ()
	contextRef = context
end

function BugFarmController.Start(): () end

function BugFarmController.Equip(slotIndex: number, bugUid: string): ()
	local bugEquipRemote = contextRef.Remotes.BugEquip
	bugEquipRemote:FireServer({ SlotIndex = slotIndex, BugUid = bugUid })
end

function BugFarmController.Unequip(slotIndex: number): ()
	local bugUnequipRemote = contextRef.Remotes.BugUnequip
	bugUnequipRemote:FireServer({ SlotIndex = slotIndex })
end

function BugFarmController.ToggleLock(bugUid: string): ()
	local bugLockRemote = contextRef.Remotes.BugLock
	bugLockRemote:FireServer({ BugUid = bugUid })
end

function BugFarmController.Sacrifice(bugUid: string): ()
	local bugSacrificeRemote = contextRef.Remotes.BugSacrifice
	bugSacrificeRemote:FireServer({ BugUid = bugUid })
end

return BugFarmController
