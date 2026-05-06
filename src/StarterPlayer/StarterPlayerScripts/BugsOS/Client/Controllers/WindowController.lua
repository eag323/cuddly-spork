--!strict

local MarketApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("MarketApp"))
local UpgradesApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("UpgradesApp"))
local FoodHarvestersApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("FoodHarvestersApp"))

local WindowController = {}

local context: { [string]: any }
local openApps: { [string]: boolean } = {}

local APP_DEFS = {
	{ id = "Market", title = "Market.exe", app = MarketApp },
	{ id = "Upgrades", title = "Upgrades.exe", app = UpgradesApp },
	{ id = "FoodHarvesters", title = "Food Harvesters.exe", app = FoodHarvestersApp },
}

function WindowController.Init(initContext): ()
	context = initContext
end

function WindowController.Open(appId: string): ()
	if openApps[appId] then
		return
	end

	for _, appDef in APP_DEFS do
		if appDef.id == appId then
			appDef.app.Mount(context.UI.AppsLayer, context)
			openApps[appId] = true
			return
		end
	end
end

function WindowController.Close(appId: string): ()
	for _, appDef in APP_DEFS do
		if appDef.id == appId then
			appDef.app.Unmount()
			openApps[appId] = nil
			return
		end
	end
end

function WindowController.Start(): ()
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = context.UI.Taskbar

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = context.UI.Taskbar

	for _, appDef in APP_DEFS do
		local button = Instance.new("TextButton")
		button.Name = appDef.id .. "Button"
		button.Size = UDim2.fromOffset(150, 34)
		button.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextSize = 14
		button.Text = appDef.title
		button.Parent = context.UI.Taskbar

		button.Activated:Connect(function()
			if openApps[appDef.id] then
				WindowController.Close(appDef.id)
			else
				WindowController.Open(appDef.id)
			end
		end)
	end
end

return WindowController
