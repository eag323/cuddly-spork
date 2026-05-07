--!strict
local TweenService = game:GetService("TweenService")

local BugMinigameController = {}
local context
local bugRoot
local activeId
local hitsRemaining = 0
local bugButton: TextButton?
local headerLabel: TextLabel?

local function clear()
	if bugRoot then
		bugRoot:Destroy()
		bugRoot = nil
	end
	bugButton = nil
	headerLabel = nil
	activeId = nil
	hitsRemaining = 0
end

local function updateHeader(displayName: string, rarity: string)
	if headerLabel then
		headerLabel.Text = string.format("%s [%s] Hits: %d", displayName, rarity, math.max(hitsRemaining, 0))
	end
end

local function hitFeedback(button: TextButton)
	local pulseUp = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(92, 92), BackgroundColor3 = Color3.fromRGB(145, 95, 95) })
	local pulseDown = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(84, 84), BackgroundColor3 = Color3.fromRGB(80, 40, 40) })
	pulseUp.Completed:Once(function() pulseDown:Play() end)
	pulseUp:Play()
end

local function startMovement(button: TextButton, behavior: string)
	task.spawn(function()
		task.wait(0.5)
		while button.Parent do
			local pos = UDim2.fromScale(math.random(20, 80) / 100, math.random(20, 75) / 100)
			local duration = 1.6
			if behavior == "ZigZagger" then duration = 1.0 end
			if behavior == "Dasher" then
				duration = 0.65
				task.wait(0.5)
			end
			TweenService:Create(button, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = pos }):Play()
			task.wait(duration)
		end
	end)
end

function BugMinigameController.Init(c)
	context = c
end

function BugMinigameController.Start()
	context.Remotes.BugSpawned.OnClientEvent:Connect(function(payload)
		clear()
		activeId = payload.ActiveBugId
		hitsRemaining = payload.HitsRequired
		local holder = Instance.new("Frame")
		holder.Name = "BugMinigame"
		holder.Size = UDim2.fromScale(1, 1)
		holder.BackgroundTransparency = 1
		holder.Parent = context.UI.WorldLayer
		bugRoot = holder

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(360, 24)
		label.Position = UDim2.fromOffset(12, 12)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.GothamSemibold
		label.TextSize = 15
		label.Parent = holder
		headerLabel = label
		updateHeader(payload.DisplayName, payload.Rarity)

		local timer = Instance.new("Frame")
		timer.Size = UDim2.fromOffset(320, 8)
		timer.Position = UDim2.fromOffset(12, 38)
		timer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		timer.Parent = holder
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = Color3.fromRGB(110, 230, 110)
		fill.Parent = timer

		local shadow = Instance.new("Frame")
		shadow.Size = UDim2.fromOffset(88, 88)
		shadow.Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(3, 4)
		shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		shadow.BackgroundTransparency = 0.5
		shadow.BorderSizePixel = 0
		shadow.Parent = holder
		local shadowCorner = Instance.new("UICorner")
		shadowCorner.CornerRadius = UDim.new(1, 0)
		shadowCorner.Parent = shadow

		local bug = Instance.new("TextButton")
		bug.Size = UDim2.fromOffset(84, 84)
		bug.Position = UDim2.fromScale(0.5, 0.5)
		bug.Text = "🐞"
		bug.TextScaled = true
		bug.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
		bug.Parent = holder
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = bug
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(235, 235, 210)
		stroke.Thickness = 2
		stroke.Parent = bug
		bugButton = bug

		bug.Activated:Connect(function()
			if not activeId then return end
			context.Remotes.BugAttemptCatch:FireServer({ ActiveBugId = activeId })
		end)

		startMovement(bug, payload.Behavior)
		local duration = payload.Duration or 8
		task.spawn(function()
			local s = os.clock()
			while holder.Parent do
				local t = math.clamp(1 - ((os.clock() - s) / duration), 0, 1)
				fill.Size = UDim2.fromScale(t, 1)
				if t <= 0 then break end
				task.wait(0.05)
			end
		end)
	end)

	context.Remotes.BugHitUpdate.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" or payload.ActiveBugId ~= activeId then return end
		if type(payload.HitsRemaining) == "number" then
			hitsRemaining = payload.HitsRemaining
		end
		if headerLabel and type(payload.HitsRequired) == "number" then
			local text = headerLabel.Text
			local name, rarity = text:match("^(.-) %[(.-)%]")
			if name and rarity then
				updateHeader(name, rarity)
			end
		end
		if bugButton then
			hitFeedback(bugButton)
		end
	end)

	context.Remotes.BugCaptured.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and context.Controllers.Notification then
			context.Controllers.Notification.Show(string.format("Caught %s %s +%s Bug Points", payload.Rarity or "Bug", payload.DisplayName or "Bug", tostring(payload.BugPointsAwarded or 0)), "Success")
		end
		clear()
	end)

	context.Remotes.BugEscaped.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and context.Controllers.Notification then
			context.Controllers.Notification.Show(string.format("%s escaped", payload.DisplayName or "Bug"), "Warning")
		end
		clear()
	end)
end

return BugMinigameController
