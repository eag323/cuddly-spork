--!strict

local UpgradesApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("UpgradesApp"))

local UpgradeController = {}

local context: { [string]: any }

function UpgradeController.Init(initContext): ()
	context = initContext
end

function UpgradeController.BuyTool(toolId: string): ()
	context.Remotes.UpgradeBuyClickTool:FireServer({ ToolId = toolId })
end

function UpgradeController.Refresh(): ()
	UpgradesApp.Refresh(context)
end

function UpgradeController.Start(): () end

return UpgradeController
