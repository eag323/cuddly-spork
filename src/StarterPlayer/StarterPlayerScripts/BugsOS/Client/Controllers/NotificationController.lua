--!strict

local NotificationController = {}
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local contextRef = nil
local notificationsRoot: Frame? = nil
local activeCards = {}
local lastShownByKey = {}

local TYPE_COLORS = {
	Info = Color3.fromRGB(60, 130, 220),
	Warning = Color3.fromRGB(220, 170, 60),
	Success = Color3.fromRGB(60, 175, 85),
	Error = Color3.fromRGB(200, 70, 70),
}

local function ensureRootGui(): Frame
	if notificationsRoot and notificationsRoot.Parent then
		return notificationsRoot
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = playerGui:FindFirstChild("BugsOSNotifications") :: ScreenGui
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "BugsOSNotifications"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = playerGui
	end

	local root = screenGui:FindFirstChild("NotificationsRoot") :: Frame
	if not root then
		root = Instance.new("Frame")
		root.Name = "NotificationsRoot"
		root.BackgroundTransparency = 1
		root.Size = UDim2.fromOffset(320, 320)
		root.Position = UDim2.new(1, -340, 0, 24)
		root.Parent = screenGui

		local listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 8)
		listLayout.Parent = root
	end

	notificationsRoot = root
	return root
end

local function showNotification(message: string, notificationType: string): ()
	local key = notificationType .. "::" .. message
	local now = os.clock()
	if lastShownByKey[key] and (now - lastShownByKey[key]) <= 0.75 then
		return
	end
	lastShownByKey[key] = now
	local root = ensureRootGui()
	local card = Instance.new("TextLabel")
	card.BackgroundColor3 = TYPE_COLORS[notificationType] or TYPE_COLORS.Info
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.Size = UDim2.fromOffset(300, 36)
	card.TextColor3 = Color3.new(1, 1, 1)
	card.Font = Enum.Font.Gotham
	card.TextSize = 14
	card.TextXAlignment = Enum.TextXAlignment.Left
	card.Text = "  " .. message
	card.LayoutOrder = -(math.floor(now * 1000))
	card.Parent = root
	table.insert(activeCards, card)
	while #activeCards > 4 do
		local oldest = table.remove(activeCards, 1)
		if oldest and oldest.Parent then oldest:Destroy() end
	end

	task.delay(3, function()
		if not card.Parent then
			return
		end
		local tween = TweenService:Create(card, TweenInfo.new(0.3), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		tween:Play()
		tween.Completed:Wait()
		for i, c in ipairs(activeCards) do if c == card then table.remove(activeCards, i) break end end
		card:Destroy()
	end)
end

function NotificationController.Init(context): ()
	contextRef = context
end

function NotificationController.Show(message: string, notificationType: string): ()
	showNotification(message, notificationType)
end

function NotificationController.Start(): ()
	if not contextRef or not contextRef.Remotes or not contextRef.Remotes.NotificationPush then
		return
	end

	contextRef.Remotes.NotificationPush.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end

		local message = payload.Message
		if type(message) ~= "string" or message == "" then
			return
		end

		local notificationType = payload.Type
		if type(notificationType) ~= "string" then
			notificationType = "Info"
		end

		showNotification(message, notificationType)
	end)
end

return NotificationController
