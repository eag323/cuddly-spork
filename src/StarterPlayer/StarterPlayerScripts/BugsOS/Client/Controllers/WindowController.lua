--!strict

local AppRegistry = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("AppRegistry"))
local DesktopIcon = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("DesktopIcon"))
local TaskbarButton = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("TaskbarButton"))

local WindowController = {}
local context
local openApps: {[string]: boolean} = {}
local registryById: {[string]: any} = {}
local taskbarButtons: {[string]: TextButton} = {}
local taskbarSetActive: {[string]: (boolean) -> ()} = {}
local zCounter = 20

function WindowController.Init(c)
	context = c
	for _, app in ipairs(AppRegistry) do
		registryById[app.Id] = app
	end
	context.WindowManager = WindowController
end

function WindowController.Focus(id: string)
	if not openApps[id] then
		return
	end
	zCounter += 1
	local app = registryById[id]
	if app and app.Module and app.Module.SetZIndex then
		app.Module.SetZIndex(zCounter)
	end
end

function WindowController.Open(id: string)
	local app = registryById[id]
	if not app then return end
	if openApps[id] and not app.AllowDuplicate then
		WindowController.Focus(id)
		return
	end
	app.Module.Mount(context.UI.AppsLayer, context)
	openApps[id] = true
	if taskbarButtons[id] then
		taskbarSetActive[id](true)
	end
	WindowController.Focus(id)
end

function WindowController.Close(id: string)
	local app = registryById[id]
	if not app then return end
	app.Module.Unmount()
	openApps[id] = nil
	if taskbarButtons[id] then
		taskbarSetActive[id](false)
	end
end

function WindowController.Start()
	local desktopIcons = Instance.new("Frame")
	desktopIcons.Name = "DesktopIcons"
	desktopIcons.Size = UDim2.new(1, -308, 1, -74)
	desktopIcons.Position = UDim2.fromOffset(12, 12)
	desktopIcons.BackgroundTransparency = 1
	desktopIcons.Parent = context.UI.HUDLayer
	local iconsLayout = Instance.new("UIGridLayout")
	iconsLayout.CellSize = UDim2.fromOffset(92, 92)
	iconsLayout.CellPadding = UDim2.fromOffset(8, 10)
	iconsLayout.FillDirectionMaxCells = 6
	iconsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	iconsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	iconsLayout.Parent = desktopIcons

	local holder = Instance.new("ScrollingFrame")
	holder.Name = "TaskbarButtons"
	holder.Size = UDim2.new(1, -392, 1, -12)
	holder.Position = UDim2.fromOffset(88, 6)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ScrollBarThickness = 4
	holder.ScrollingDirection = Enum.ScrollingDirection.X
	holder.Parent = context.UI.Taskbar
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 3)
	layout.Parent = holder
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		holder.CanvasSize = UDim2.fromOffset(layout.AbsoluteContentSize.X + 8, 0)
	end)

	for _, app in ipairs(AppRegistry) do
		if app.UnlockedByDefault then
			DesktopIcon.Create(desktopIcons, app.Title, app.IconImage, function()
				WindowController.Open(app.Id)
			end)
		end
		local btn, setActive = TaskbarButton.Create(holder, app.Title, function()
			if openApps[app.Id] then
				WindowController.Focus(app.Id)
			else
				WindowController.Open(app.Id)
			end
		end)
		taskbarButtons[app.Id] = btn
		taskbarSetActive[app.Id] = setActive
	end
end

return WindowController
