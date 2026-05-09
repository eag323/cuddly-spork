--!strict

local AppRegistry = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("AppRegistry"))
local DesktopIcon = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("DesktopIcon"))
local TaskbarButton = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("TaskbarButton"))

local WindowController = {}
local context
local openApps: {[string]: boolean} = {}
local registryById: {[string]: any} = {}
local initializedById: {[string]: boolean} = {}
local taskbarButtons: {[string]: GuiButton} = {}
local taskbarSetActive: {[string]: (boolean) -> ()} = {}
local taskbarHolder: ScrollingFrame? = nil
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
	for appId, setActive in pairs(taskbarSetActive) do
		setActive(appId == id)
	end
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
	context.AppDependencies = { Root = context.UI.AppsLayer, Services = context.Services or {}, State = context.State, Controllers = context.Controllers or {}, Remotes = context.Remotes }
	if not initializedById[id] and app.Module and app.Module.Init then
		app.Module.Init(context)
		initializedById[id] = true
	end
	local ok, err = pcall(function()
		app.Module.Mount(context.UI.AppsLayer, context.AppDependencies)
	end)
	if not ok then
		warn(string.format("[BugsOS] Failed to mount app '%s': %s", id, tostring(err)))
		openApps[id] = nil
		return
	end
	openApps[id] = true
	if not taskbarButtons[id] and taskbarHolder then
		local btn, setActive = TaskbarButton.Create(taskbarHolder, app.Title, app.IconImage, false, function()
			if openApps[app.Id] then
				WindowController.Focus(app.Id)
			else
				WindowController.Open(app.Id)
			end
		end)
		taskbarButtons[id] = btn
		taskbarSetActive[id] = setActive
	end
	WindowController.Focus(id)
end

function WindowController.Close(id: string)
	local app = registryById[id]
	if not app then return end
	openApps[id] = nil
	local ok, err = pcall(function()
		app.Module.Unmount()
	end)
	if not ok then
		warn(string.format("[BugsOS] Failed to unmount app '%s': %s", id, tostring(err)))
	end
	if taskbarButtons[id] then
		taskbarButtons[id]:Destroy()
		taskbarButtons[id] = nil
		taskbarSetActive[id] = nil
	end
end

function WindowController.Start()
	local desktopIcons = Instance.new("Frame")
	desktopIcons.Name = "DesktopIcons"
	desktopIcons.Size = UDim2.new(1, -320, 1, -74)
	desktopIcons.Position = UDim2.fromOffset(12, 12)
	desktopIcons.BackgroundTransparency = 1
	desktopIcons.Parent = context.UI.HUDLayer
	local iconsLayout = Instance.new("UIGridLayout")
	iconsLayout.CellSize = UDim2.fromOffset(88, 96)
	iconsLayout.CellPadding = UDim2.fromOffset(10, 8)
	iconsLayout.FillDirection = Enum.FillDirection.Vertical
	iconsLayout.FillDirectionMaxCells = 8
	iconsLayout.StartCorner = Enum.StartCorner.TopLeft
	iconsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	iconsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	iconsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	iconsLayout.Parent = desktopIcons

	local holder = Instance.new("ScrollingFrame")
	holder.Name = "TaskbarButtons"
	holder.AnchorPoint = Vector2.new(0, 0.5)
	holder.Size = UDim2.new(1, -420, 0, 30)
	holder.Position = UDim2.new(0, 124, 0.5, 0)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ScrollBarThickness = 4
	holder.ScrollingDirection = Enum.ScrollingDirection.X
	holder.Parent = context.UI.Taskbar
	taskbarHolder = holder
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 4)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
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
	end
end

return WindowController
