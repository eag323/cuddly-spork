--!strict

local FoodHarvestersApp = {}
local root: Frame?
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local NumberUtil = require(SharedFolder:WaitForChild("Util"):WaitForChild("NumberUtil"))
local GeneratorConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("GeneratorConfig"))

local generatorById = {}
for _, generator in ipairs(GeneratorConfig.Generators) do
	generatorById[generator.id] = generator
end

local function getFeedbackAnchor(context): (Instance?, UDim2)
	if root then
		return root, UDim2.new(1, -28, 0, 32)
	end

	if context.UI and context.UI.AppsLayer then
		return context.UI.AppsLayer, UDim2.fromScale(0.56, 0.12)
	end

	return nil, UDim2.fromScale(0.56, 0.12)
end


local function getPrestigeMultiplier(context): number
	local prestige = 0
	if context.State.PlayerData and context.State.PlayerData.Progression then
		prestige = context.State.PlayerData.Progression.Prestige or 0
	end

	return 1 + (prestige * 0.1)
end

function FoodHarvestersApp.ShowPassiveIncomeFeedback(context, foodPerSecond: number): ()
	local anchorParent, position = getFeedbackAnchor(context)
	if not anchorParent then
		return
	end

	local popup = Instance.new("TextLabel")
	popup.Name = "PassiveFoodIncomeFeedback"
	popup.AnchorPoint = Vector2.new(1, 0)
	popup.Size = UDim2.fromOffset(170, 26)
	popup.Position = position
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBold
	popup.TextSize = 18
	popup.TextColor3 = Color3.fromRGB(152, 255, 168)
	popup.TextStrokeTransparency = 0.35
	popup.TextXAlignment = Enum.TextXAlignment.Right
	popup.Text = string.format("+%s Food/sec", NumberUtil.FormatNumber(foodPerSecond))
	popup.ZIndex = 8
	popup.Parent = anchorParent

	local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(popup, tweenInfo, {
		Position = popup.Position - UDim2.fromOffset(0, 24),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	Debris:AddItem(popup, 0.55)
end

function FoodHarvestersApp.Refresh(context): ()
	if not root then return end
	local equipped = nil
	if context.State.PlayerData and context.State.PlayerData.Generators then
		equipped = context.State.PlayerData.Generators.Equipped
	end
	for i = 1, 3 do
		local label = root:FindFirstChild("SlotLabel" .. i) :: TextLabel
		local upgrade = root:FindFirstChild("SlotUpgrade" .. i) :: TextButton
		local entry = equipped and equipped[i]
		local generator = entry and generatorById[entry.GeneratorId] or nil
		local name = generator and generator.displayName or "Empty Slot"
		local level = entry and entry.Level or 0
		local baseFoodPerSec = generator and generator.baseFoodPerSec or 0
		local prestigeMultiplier = getPrestigeMultiplier(context)
		local estimatedFoodPerSec = baseFoodPerSec * (level ^ 1.55) * prestigeMultiplier
		label.Text = string.format(
			"Slot %d | %s | Level %d | Food/sec %s",
			i,
			name,
			level,
			NumberUtil.FormatNumber(estimatedFoodPerSec)
		)
		upgrade.Visible = entry ~= nil
	end
end

function FoodHarvestersApp.Mount(target: Instance, context): ()
	if root then return end
	root = Instance.new("Frame")
	root.Name = "FoodHarvestersWindow"
	root.Position = UDim2.fromScale(0.18, 0.1)
	root.Size = UDim2.fromScale(0.4, 0.56)
	root.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	root.Parent = target

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(30, 30)
	close.Position = UDim2.new(1, -35, 0, 5)
	close.Text = "X"
	close.Parent = root
	close.Activated:Connect(function() context.Controllers.Window.Close("FoodHarvesters") end)

	for i = 1, 3 do
		local label = Instance.new("TextLabel")
		label.Name = "SlotLabel" .. i
		label.Size = UDim2.new(0.65, 0, 0, 34)
		label.Position = UDim2.fromOffset(10, 40 + ((i - 1) * 70))
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = root

		local upgrade = Instance.new("TextButton")
		upgrade.Name = "SlotUpgrade" .. i
		upgrade.Size = UDim2.new(0.28, 0, 0, 30)
		upgrade.Position = UDim2.new(0.68, 0, 0, 42 + ((i - 1) * 70))
		upgrade.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		upgrade.TextColor3 = Color3.new(1, 1, 1)
		upgrade.Text = "Upgrade"
		upgrade.Parent = root
		upgrade.Activated:Connect(function()
			context.Controllers.Generator.Upgrade(i)
		end)

		local generatorButtons = {
			{ id = "plain_cracker", label = "Equip Plain Cracker" },
			{ id = "potato_chip", label = "Equip Potato Chip" },
			{ id = "cookie_crumb", label = "Equip Cookie Crumb" },
		}
		for buttonIndex, info in ipairs(generatorButtons) do
			local equip = Instance.new("TextButton")
			equip.Size = UDim2.new(0.28, 0, 0, 22)
			equip.Position = UDim2.new(0.68, 0, 0, 74 + ((i - 1) * 70) + ((buttonIndex - 1) * 24))
			equip.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			equip.TextColor3 = Color3.new(1, 1, 1)
			equip.Text = info.label
			equip.TextSize = 12
			equip.Parent = root
			equip.Activated:Connect(function()
				context.Controllers.Generator.Equip(i, info.id)
			end)
		end
	end

	FoodHarvestersApp.Refresh(context)
end

function FoodHarvestersApp.Unmount(): ()
	if root then root:Destroy() end
	root = nil
end

return FoodHarvestersApp
