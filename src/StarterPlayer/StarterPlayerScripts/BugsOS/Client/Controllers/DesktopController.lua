--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local DesktopController = {}

local context: { [string]: any }

local BACKGROUND_PRESS_SCALE = 0.985
local BACKGROUND_PRESS_DURATION = 0.08
local FLOAT_RISE_PIXELS = 54
local FLOAT_LIFETIME = 0.55
local FLOAT_X_OFFSET = 18
local FLOAT_Y_OFFSET = 10

local rng = Random.new()

local function spawnFloatingText(parent: Instance, clickPos: Vector2): ()
	local floatText = Instance.new("TextLabel")
	floatText.Name = "FoodClickFloat"
	floatText.AnchorPoint = Vector2.new(0.5, 0.5)
	floatText.Size = UDim2.fromOffset(112, 26)
	floatText.BackgroundTransparency = 1
	floatText.Text = "+X Food"
	floatText.Font = Enum.Font.GothamBold
	floatText.TextSize = 20
	floatText.TextColor3 = Color3.fromRGB(255, 240, 135)
	floatText.TextStrokeTransparency = 0.35
	floatText.ZIndex = 2

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

	local backgroundScale = Instance.new("UIScale")
	backgroundScale.Scale = 1
	backgroundScale.Parent = desktopBackground

	desktopBackground.Activated:Connect(function()
		context.State.LastClickAt = os.clock()
		context.Remotes.ClickRequest:FireServer()

		local pressTween = TweenService:Create(backgroundScale, TweenInfo.new(BACKGROUND_PRESS_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = BACKGROUND_PRESS_SCALE,
		})
		local releaseTween = TweenService:Create(backgroundScale, TweenInfo.new(BACKGROUND_PRESS_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 1,
		})
		pressTween.Completed:Once(function()
			releaseTween:Play()
		end)
		pressTween:Play()

		local mousePos = UserInputService:GetMouseLocation()
		spawnFloatingText(screenGui, mousePos)
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
