--!strict

local Players = game:GetService("Players")

local DesktopController = {}

local context: { [string]: any }

function DesktopController.Init(initContext): ()
	context = initContext
end

function DesktopController.Start(): ()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BugsOSDesktop"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local desktopBackground = Instance.new("TextButton")
	desktopBackground.Name = "DesktopBackground"
	desktopBackground.Size = UDim2.fromScale(1, 1)
	desktopBackground.BackgroundColor3 = Color3.fromRGB(35, 73, 122)
	desktopBackground.BorderSizePixel = 0
	desktopBackground.Text = ""
	desktopBackground.AutoButtonColor = false
	desktopBackground.Parent = screenGui

	desktopBackground.Activated:Connect(function()
		context.Remotes.ClickRequest:FireServer()
	end)

	local appsLayer = Instance.new("Frame")
	appsLayer.Name = "AppsLayer"
	appsLayer.Size = UDim2.fromScale(1, 1)
	appsLayer.BackgroundTransparency = 1
	appsLayer.Parent = screenGui

	local hudLayer = Instance.new("Frame")
	hudLayer.Name = "HUDLayer"
	hudLayer.Size = UDim2.fromScale(1, 1)
	hudLayer.BackgroundTransparency = 1
	hudLayer.Parent = screenGui

	local taskbar = Instance.new("Frame")
	taskbar.Name = "Taskbar"
	taskbar.AnchorPoint = Vector2.new(0.5, 1)
	taskbar.Position = UDim2.fromScale(0.5, 1)
	taskbar.Size = UDim2.new(1, 0, 0, 46)
	taskbar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	taskbar.BorderSizePixel = 0
	taskbar.Parent = screenGui

	context.UI.ScreenGui = screenGui
	context.UI.AppsLayer = appsLayer
	context.UI.HUDLayer = hudLayer
	context.UI.Taskbar = taskbar
end

return DesktopController
