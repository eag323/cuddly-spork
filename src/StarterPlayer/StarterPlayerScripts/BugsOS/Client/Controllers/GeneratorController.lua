--!strict

local FoodHarvestersApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("FoodHarvestersApp"))

local GeneratorController = {}
local context: { [string]: any }
local buyEquipRemote: RemoteEvent
local removeRemote: RemoteEvent
local buyEquipCondimentRemote: RemoteEvent
local removeCondimentRemote: RemoteEvent
local autoUpgradeCondimentsRemote: RemoteEvent

function GeneratorController.Init(initContext): ()
	context = initContext
	buyEquipRemote = context.Remotes.GeneratorBuyEquip
	removeRemote = context.Remotes.GeneratorRemove
	buyEquipCondimentRemote = context.Remotes.GeneratorBuyEquipCondiment
	removeCondimentRemote = context.Remotes.GeneratorRemoveCondiment
	autoUpgradeCondimentsRemote = context.Remotes.GeneratorAutoUpgradeCondiments
end

function GeneratorController.BuyEquip(slotIndex: number, harvesterId: string): ()
	buyEquipRemote:FireServer({ SlotIndex = slotIndex, HarvesterId = harvesterId })
end

function GeneratorController.Remove(slotIndex: number): ()
	removeRemote:FireServer({ SlotIndex = slotIndex })
end

function GeneratorController.BuyEquipCondiment(slotIndex: number, condimentId: string): ()
	buyEquipCondimentRemote:FireServer({ SlotIndex = slotIndex, CondimentId = condimentId })
end

function GeneratorController.RemoveCondiment(slotIndex: number, condimentSlotIndex: number): ()
	removeCondimentRemote:FireServer({ SlotIndex = slotIndex, CondimentSlotIndex = condimentSlotIndex })
end

function GeneratorController.AutoUpgradeCondiments(slotIndex: number): ()
	autoUpgradeCondimentsRemote:FireServer({ SlotIndex = slotIndex })
end

function GeneratorController.Refresh(): ()
	FoodHarvestersApp.Refresh(context)
end

function GeneratorController.Start(): () end

return GeneratorController
