--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local UtilFolder = SharedFolder:WaitForChild("Util")

local NumberUtil = require(UtilFolder:WaitForChild("NumberUtil"))
local UITheme = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UITheme"))
local UIAssets = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIAssets"))

local DesktopController = {}

local context: { [string]: any }

local BACKGROUND_PRESS_SCALE = 0.985
local BACKGROUND_PRESS_DURATION = 0.08
local FLOAT_RISE_PIXELS = 54
local FLOAT_LIFETIME = 0.55
local FLOAT_X_OFFSET = 18
local FLOAT_Y_OFFSET = 10
local AMBIENT_PARTICLE_COUNT = 14

local rng = Random.new()
local latestClickMousePosition = Vector2.zero

local warnedWallpaper = false

local function createTaskbarImageButton(parent: Instance, name: string, buttonSize: UDim2, buttonPosition: UDim2, text: string)
	local button = Instance.new("ImageButton")
	button.Name = name
	button.Size = buttonSize
	button.Position = buttonPosition
	button.BackgroundTransparency = 1
	button.Image = UIAssets.TaskbarTabDefaultImage
	button.ScaleType = Enum.ScaleType.Slice
	button.SliceCenter = UIAssets.SliceCenter
	button.AutoButtonColor = false
	button.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -8, 1, 0)
	label.Position = UDim2.fromOffset(4, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(0, 0, 0)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Font = UITheme.Font
	label.TextSize = 14
	label.Parent = button

	return button, label
end

local function spawnFloatingText(parent: Instance, clickPos: Vector2, text: string): ()
	local floatText = Instance.new("TextLabel")
	floatText.Name = "FoodClickFloat"
	floatText.AnchorPoint = Vector2.new(0.5, 0.5)
	floatText.Size = UDim2.fromOffset(112, 26)
	floatText.BackgroundTransparency = 1
	floatText.Text = text
	floatText.Font = Enum.Font.GothamBold
	floatText.TextSize = 20
	floatText.TextColor3 = Color3.fromRGB(255, 240, 135)
	floatText.TextStrokeTransparency = 0.35
	floatText.ZIndex = 3

	local offsetX = rng:NextNumber(-FLOAT_X_OFFSET, FLOAT_X_OFFSET)
	local offsetY = rng:NextNumber(-FLOAT_Y_OFFSET, FLOAT_Y_OFFSET)
	floatText.Position = UDim2.fromOffset(clickPos.X + offsetX, clickPos.Y + offsetY)
	floatText.Parent = parent

	local goal = {
		Position = floatText.Position - UDim2.fromOffset(0, FLOAT_RISE_PIXELS),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}

	TweenService:Create(floatText, TweenInfo.new(FLOAT_LIFETIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
	Debris:AddItem(floatText, FLOAT_LIFETIME + 0.1)
end

local function createAmbientParticles(worldLayer: Frame): ()
	for _ = 1, AMBIENT_PARTICLE_COUNT do
		local particle = Instance.new("Frame")
		particle.Name = "AmbientParticle"
		local size = rng:NextInteger(2, 5)
		particle.Size = UDim2.fromOffset(size, size)
		particle.BackgroundColor3 = Color3.fromRGB(220, 239, 255)
		particle.BackgroundTransparency = 0.75
		particle.BorderSizePixel = 0
		particle.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
		particle.Parent = worldLayer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		task.spawn(function()
			while particle.Parent do
				local nextPos = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
				local duration = rng:NextNumber(6, 11)
				TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = nextPos }):Play()
				task.wait(duration)
			end
		end)
	end
end

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
	desktopBackground.BackgroundColor3 = Color3.fromRGB(34, 85, 34)
	desktopBackground.BorderSizePixel = 0
	desktopBackground.Text = ""
	desktopBackground.AutoButtonColor = false
	desktopBackground.Parent = screenGui

	local wallpaper = Instance.new("ImageLabel")
	wallpaper.Name = "Wallpaper"
	wallpaper.Size = UDim2.new(1, 0, 1, -46)
	wallpaper.Position = UDim2.fromOffset(0, 0)
	wallpaper.BackgroundTransparency = 1
	wallpaper.ScaleType = Enum.ScaleType.Crop
	wallpaper.ZIndex = 0
	local wallpaperImage = UIAssets.DesktopWallpaperImage
	if type(wallpaperImage) == "string" and wallpaperImage ~= "" and wallpaperImage ~= "rbxassetid://0" then
		wallpaper.Image = wallpaperImage
	else
		if not warnedWallpaper then
			warn("[BugsOS] Missing or invalid wallpaper asset id. Using fallback background color.")
			warnedWallpaper = true
		end
	end
	wallpaper.Parent = desktopBackground

	local worldLayer = Instance.new("Frame")
	worldLayer.Name = "WorldLayer"
	worldLayer.Size = UDim2.fromScale(1, 1)
	worldLayer.BackgroundTransparency = 1
	worldLayer.Parent = desktopBackground
	createAmbientParticles(worldLayer)

	local backgroundScale = Instance.new("UIScale")
	backgroundScale.Scale = 1
	backgroundScale.Parent = desktopBackground

	desktopBackground.Activated:Connect(function()
		context.State.LastClickAt = os.clock()
		latestClickMousePosition = UserInputService:GetMouseLocation()
		context.Remotes.ClickRequest:FireServer()

		local pressTween = TweenService:Create(backgroundScale, TweenInfo.new(BACKGROUND_PRESS_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = BACKGROUND_PRESS_SCALE })
		local releaseTween = TweenService:Create(backgroundScale, TweenInfo.new(BACKGROUND_PRESS_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
		pressTween.Completed:Once(function() releaseTween:Play() end)
		pressTween:Play()

	end)

	context.Remotes.ClickResult.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end

		local foodGained = payload.FoodGained
		if type(foodGained) ~= "number" then
			return
		end

		local formattedFoodGained = NumberUtil.FormatNumber(foodGained)
		spawnFloatingText(screenGui, latestClickMousePosition, "+" .. formattedFoodGained .. " Food")
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
	taskbar.BackgroundTransparency = 1
	taskbar.BorderSizePixel = 0
	taskbar.Parent = screenGui

	local taskbarSkin = Instance.new("ImageLabel")
	taskbarSkin.Name = "TaskbarSkin"
	taskbarSkin.Size = UDim2.fromScale(1, 1)
	taskbarSkin.BackgroundTransparency = 1
	taskbarSkin.Image = UIAssets.TaskbarBackgroundImage
	taskbarSkin.ScaleType = Enum.ScaleType.Slice
	taskbarSkin.SliceCenter = UIAssets.SliceCenter
	taskbarSkin.Parent = taskbar

	local startButton, _startLabel = createTaskbarImageButton(
		taskbar,
		"StartButton",
		UDim2.fromOffset(108, 30),
		UDim2.fromOffset(8, 8),
		"🐞 Start"
	)
	startButton.MouseButton1Down:Connect(function()
		startButton.Image = UIAssets.TaskbarTabPressedImage
	end)
	startButton.MouseButton1Up:Connect(function()
		startButton.Image = UIAssets.TaskbarTabDefaultImage
	end)

	context.UI.ShowConfirmPopup = function(message: string, onConfirm)
		local popup = Instance.new("Frame")
		popup.Size = UDim2.fromOffset(320, 140)
		popup.Position = UDim2.fromScale(0.5, 0.45)
		popup.AnchorPoint = Vector2.new(0.5, 0.5)
		popup.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		popup.Parent = screenGui
		popup.ZIndex = 10

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 0, 70)
		label.Position = UDim2.fromOffset(10, 12)
		label.BackgroundTransparency = 1
		label.TextWrapped = true
		label.Text = message
		label.TextColor3 = Color3.new(1, 1, 1)
		label.ZIndex = 11
		label.Parent = popup

		local yes = Instance.new("TextButton")
		yes.Size = UDim2.fromOffset(120, 34)
		yes.Position = UDim2.fromOffset(24, 92)
		yes.Text = "Confirm"
		yes.Parent = popup
		yes.ZIndex = 11
		yes.Activated:Connect(function() popup:Destroy(); onConfirm() end)

		local no = Instance.new("TextButton")
		no.Size = UDim2.fromOffset(120, 34)
		no.Position = UDim2.fromOffset(176, 92)
		no.Text = "Cancel"
		no.Parent = popup
		no.ZIndex = 11
		no.Activated:Connect(function() popup:Destroy() end)
	end

	context.UI.ScreenGui = screenGui
	context.UI.WorldLayer = worldLayer
	context.UI.AppsLayer = appsLayer
	context.UI.HUDLayer = hudLayer
	context.UI.Taskbar = taskbar
end

return DesktopController
