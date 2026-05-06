--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local ConfigFolder = SharedFolder:WaitForChild("Config")

local ClickToolConfig = require(ConfigFolder:WaitForChild("ClickToolConfig"))
local GeneratorConfig = require(ConfigFolder:WaitForChild("GeneratorConfig"))

local CurrencyHUDController = {}

local context: { [string]: any }
local foodLabel: TextLabel?
local coinLabel: TextLabel?
local foodPerSecondLabel: TextLabel?
local foodPerClickLabel: TextLabel?

local generatorById: { [string]: any } = {}
local clickToolBonusById: { [string]: number } = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

local function formatCompact(value: number): string
	local absoluteValue = math.abs(value)
	local suffixIndex = 1

	while absoluteValue >= 1000 and suffixIndex < #SUFFIXES do
		value /= 1000
		absoluteValue /= 1000
		suffixIndex += 1
	end

	if suffixIndex == 1 then
		return tostring(math.floor(value + 0.5))
	end

	if absoluteValue >= 100 then
		return string.format("%.0f%s", value, SUFFIXES[suffixIndex])
	elseif absoluteValue >= 10 then
		return string.format("%.1f%s", value, SUFFIXES[suffixIndex])
	else
		return string.format("%.2f%s", value, SUFFIXES[suffixIndex])
	end
end

local function sanitizeLevel(value: any): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return 1
	end

	if value < 1 then
		return 1
	end

	return math.floor(value)
end

local function getPrestigeMultiplier(playerData: { [string]: any }): number
	local progression = playerData.Progression
	if type(progression) ~= "table" then
		return 1
	end

	local prestige = progression.Prestige
	if type(prestige) ~= "number" or prestige < 0 then
		return 1
	end

	return 1 + (0.1 * prestige)
end

local function calculateFoodPerSecond(playerData: { [string]: any }): number
	local generators = playerData.Generators
	if type(generators) ~= "table" or type(generators.Equipped) ~= "table" then
		return 0
	end

	local prestigeMultiplier = getPrestigeMultiplier(playerData)
	local total = 0

	for _, slotData in generators.Equipped do
		if type(slotData) == "table" and type(slotData.GeneratorId) == "string" then
			local generatorDef = generatorById[slotData.GeneratorId]
			if generatorDef then
				local level = sanitizeLevel(slotData.Level)
				local baseFoodPerSec = generatorDef.baseFoodPerSec or 1
				total += baseFoodPerSec * (level ^ 1.55) * prestigeMultiplier
			end
		end
	end

	return total
end

local function calculateFoodPerClick(playerData: { [string]: any }): number
	local total = 1
	local clickTools = playerData.ClickTools
	if type(clickTools) ~= "table" then
		return total
	end

	for toolId, levelValue in clickTools do
		if type(toolId) == "string" and type(levelValue) == "number" and levelValue > 0 then
			local bonusPerLevel = clickToolBonusById[toolId]
			if type(bonusPerLevel) == "number" then
				total += bonusPerLevel * levelValue
			end
		end
	end

	return total
end

local function refresh(): ()
	local data = context.State.PlayerData
	if type(data) ~= "table" or type(data.Currencies) ~= "table" then
		return
	end

	if not foodLabel or not coinLabel or not foodPerSecondLabel or not foodPerClickLabel then
		return
	end

	local foodValue = data.Currencies.Food or 0
	local coinValue = data.Currencies.Coins or 0
	local foodPerSecond = calculateFoodPerSecond(data)
	local foodPerClick = calculateFoodPerClick(data)

	foodLabel.Text = string.format("Food: %s", formatCompact(foodValue))
	coinLabel.Text = string.format("Coins: %s", formatCompact(coinValue))
	foodPerSecondLabel.Text = string.format("Food/sec: %s", formatCompact(foodPerSecond))
	foodPerClickLabel.Text = string.format("Food/click: %s", formatCompact(foodPerClick))
end

local function buildLookups(): ()
	for _, entry in ClickToolConfig.Tools do
		if type(entry) == "table" and type(entry.id) == "string" and type(entry.foodPerClickPerLevel) == "number" then
			clickToolBonusById[entry.id] = entry.foodPerClickPerLevel
		end
	end

	for _, entry in GeneratorConfig.Generators do
		if type(entry) == "table" and type(entry.id) == "string" and entry.classId == "snack" then
			generatorById[entry.id] = entry
		end
	end
end

function CurrencyHUDController.Init(initContext): ()
	context = initContext
	buildLookups()
end

function CurrencyHUDController.Start(): ()
	local frame = Instance.new("Frame")
	frame.Name = "CurrencyHUD"
	frame.Position = UDim2.fromOffset(10, 10)
	frame.Size = UDim2.fromOffset(220, 130)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.Parent = context.UI.HUDLayer

	local function createLabel(yOffset: number, defaultText: string): TextLabel
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -10, 0, 28)
		label.Position = UDim2.fromOffset(5, yOffset)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.GothamSemibold
		label.TextSize = 14
		label.Text = defaultText
		label.Parent = frame
		return label
	end

	foodLabel = createLabel(4, "Food: 0")
	coinLabel = createLabel(34, "Coins: 0")
	foodPerSecondLabel = createLabel(64, "Food/sec: 0")
	foodPerClickLabel = createLabel(94, "Food/click: 0")

	refresh()
end

function CurrencyHUDController.Refresh(): ()
	refresh()
end

return CurrencyHUDController
