--!strict

local FoodHarvestersApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("FoodHarvestersApp"))

local GeneratorController = {}

local context: { [string]: any }

function GeneratorController.Init(initContext): ()
	context = initContext
end

function GeneratorController.Upgrade(slotIndex: number): ()
	context.Remotes.GeneratorUpgrade:FireServer({ SlotIndex = slotIndex })
end

function GeneratorController.Refresh(): ()
	FoodHarvestersApp.Refresh(context)
end

function GeneratorController.Start(): () end

return GeneratorController
