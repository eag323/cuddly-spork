--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local BugConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugConfig"))
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))

local BugdexApp = {}

local windowRef
local root
local summaryLabel
local listFrame
local stateChangedConn

local rarityColors = {
	Common = Color3.fromRGB(185, 185, 185),
	Rare = Color3.fromRGB(88, 170, 255),
	Epic = Color3.fromRGB(187, 102, 255),
	Legendary = Color3.fromRGB(255, 176, 66),
	Mythic = Color3.fromRGB(255, 106, 174),
}

local function getRarityColor(rarity: string): Color3
	return rarityColors[rarity] or Color3.fromRGB(210, 210, 210)
end

local function refresh(context)
	if not root or not summaryLabel or not listFrame then
		return
	end

	for _, child in ipairs(listFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local playerData = context.State.PlayerData or {}
	local bugdexData = playerData.Bugdex or {}
	local totalsBySpecies = bugdexData.TotalCaughtBySpecies or {}
	local totalSpecies = #BugConfig.Species
	local discovered = 0
	local totalCaught = 0

	for _, species in ipairs(BugConfig.Species) do
		local count = tonumber(totalsBySpecies[species.id]) or 0
		if count > 0 then
			discovered += 1
		end
		totalCaught += count

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 56)
		row.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
		row.BorderSizePixel = 0
		row.Parent = listFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.5, -8, 0, 24)
		nameLabel.Position = UDim2.fromOffset(8, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextSize = 16
		nameLabel.Text = if count > 0 then tostring(species.displayName) else "???"
		nameLabel.Parent = row

		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(0.22, -8, 0, 24)
		rarityLabel.Position = UDim2.new(0.5, 0, 0, 6)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
		rarityLabel.TextColor3 = getRarityColor(species.rarity)
		rarityLabel.TextSize = 14
		rarityLabel.Text = tostring(species.rarity)
		rarityLabel.Parent = row

		local statusLabel = Instance.new("TextLabel")
		statusLabel.Size = UDim2.new(0.28, -8, 0, 24)
		statusLabel.Position = UDim2.new(0.72, 0, 0, 6)
		statusLabel.BackgroundTransparency = 1
		statusLabel.TextXAlignment = Enum.TextXAlignment.Left
		statusLabel.TextSize = 14
		statusLabel.Text = if count > 0 then "Discovered" else "Locked"
		statusLabel.TextColor3 = if count > 0 then Color3.fromRGB(159, 255, 159) else Color3.fromRGB(140, 140, 140)
		statusLabel.Parent = row

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, -16, 0, 18)
		countLabel.Position = UDim2.fromOffset(8, 32)
		countLabel.BackgroundTransparency = 1
		countLabel.TextXAlignment = Enum.TextXAlignment.Left
		countLabel.TextColor3 = Color3.fromRGB(205, 205, 205)
		countLabel.TextSize = 13
		countLabel.Text = string.format("Caught: %s", NumberUtil.FormatNumber(count))
		countLabel.Parent = row

		if count <= 0 then
			row.BackgroundTransparency = 0.35
			nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			countLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		end
	end

	summaryLabel.Text = string.format(
		"Discovered %s / %s    Total Caught %s",
		NumberUtil.FormatNumber(discovered),
		NumberUtil.FormatNumber(totalSpecies),
		NumberUtil.FormatNumber(totalCaught)
	)

	local layout = listFrame:FindFirstChildOfClass("UIListLayout")
	if layout then
		listFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 10)
	end
end

function BugdexApp.Mount(target: Instance, context): ()
	if root then
		return
	end

	windowRef = Window.Create({
		Title = "Bugdex.exe",
		Size = UDim2.fromOffset(720, 500),
		Position = UDim2.fromScale(0.1, 0.12),
		Parent = target,
		OnClose = function()
			context.Controllers.Window.Close("Bugdex")
		end,
	})

	root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = windowRef.Content

	summaryLabel = Instance.new("TextLabel")
	summaryLabel.Size = UDim2.new(1, -16, 0, 30)
	summaryLabel.Position = UDim2.fromOffset(8, 8)
	summaryLabel.BackgroundTransparency = 1
	summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	summaryLabel.TextColor3 = Color3.new(1, 1, 1)
	summaryLabel.TextSize = 18
	summaryLabel.Text = "Discovered 0 / 0    Total Caught 0"
	summaryLabel.Parent = root

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, -16, 1, -50)
	listFrame.Position = UDim2.fromOffset(8, 42)
	listFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 8
	listFrame.Parent = root

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = listFrame

	if stateChangedConn then
		stateChangedConn:Disconnect()
		stateChangedConn = nil
	end
	if context.Events and context.Events.StateChanged then
		stateChangedConn = context.Events.StateChanged.Event:Connect(function()
			refresh(context)
		end)
	end

	refresh(context)
end

function BugdexApp.Unmount(): ()
	if stateChangedConn then
		stateChangedConn:Disconnect()
		stateChangedConn = nil
	end
	if windowRef then
		windowRef.Destroy()
	end
	windowRef = nil
	root = nil
	summaryLabel = nil
	listFrame = nil
end

return BugdexApp
