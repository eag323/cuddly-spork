--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local ClickToolConfig = require(Shared:WaitForChild("Config"):WaitForChild("ClickToolConfig"))
local GeneratorConfig = require(Shared:WaitForChild("Config"):WaitForChild("GeneratorConfig"))
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local UITheme = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UITheme"))
local UIAssets = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIAssets"))

local CurrencyHUDController = {}
local context
local labels = {}
local generatorById = {}
local clickToolBonusById = {}
local isRunning = false

local function getBugBuffs(d)
	local buffs = { AllFood = 0, FoodPerSec = 0, ClickPower = 0 }
	local bugs = ((d or {}).Bugs or {})
	local inv = bugs.Inventory or {}
	local eq = bugs.Equipped or {}
	for _, uid in pairs(eq) do
		local bug = inv[uid]
		if type(bug) == "table" then
			local p = bug.Primary
			if type(p) == "table" and type(p.Value) == "number" then
				if buffs[p.Stat or p.Attribute] ~= nil then
					buffs[p.Stat or p.Attribute] += p.Value
				end
			end
			local ss = bug.Secondaries
			if type(ss) == "table" then
				for _, s in pairs(ss) do
					if type(s) == "table" and type(s.Value) == "number" and buffs[s.Stat or s.Attribute] ~= nil then
						buffs[s.Stat or s.Attribute] += s.Value
					end
				end
			end
		end
	end
	return buffs
end

local function sanitizeLevel(v)
	if type(v) ~= "number" or v < 1 then
		return 1
	end
	return math.floor(v)
end

local function prestigeMult(d)
	local p = (((d or {}).Progression or {}).Prestige or 0)
	return 1 + (0.1 * p)
end

local function calcFPS(d)
	local eq = ((((d or {}).Generators or {}).Equipped))
	if type(eq) ~= "table" then
		return 0
	end
	local t = 0
	local m = prestigeMult(d)
	for _, s in eq do
		if type(s) == "table" and type(s.GeneratorId) == "string" then
			local g = generatorById[s.GeneratorId]
			if g then
				local l = sanitizeLevel(s.Level)
				t += (g.baseFoodPerSec or 1) * (l ^ 1.55)
			end
		end
	end
	local b = getBugBuffs(d)
	return t * m * (1 + b.AllFood) * (1 + b.FoodPerSec)
end

local function calcFPC(d)
	local t = 1
	local tools = (d or {}).ClickTools
	if type(tools) ~= "table" then
		return t
	end
	for id, l in tools do
		if type(l) == "number" and l > 0 and clickToolBonusById[id] then
			t += clickToolBonusById[id] * l
		end
	end
	local b = getBugBuffs(d)
	return t * prestigeMult(d) * (1 + b.AllFood) * (1 + b.ClickPower)
end

local function formatLocalTimeText()
	local ok, localText = pcall(function()
		return DateTime.now():FormatLocalTime("h:mm A", "en-us")
	end)
	if ok and type(localText) == "string" and localText ~= "" then
		return localText
	end
	return os.date("!%I:%M %p")
end

local function refreshTime()
	if labels.Time then
		labels.Time.Text = formatLocalTimeText()
	end
end

local function refresh()
	local data = context.State.PlayerData
	local currencies = if type(data) == "table" and type(data.Currencies) == "table" then data.Currencies else {}
	labels.Food.Text = NumberUtil.FormatNumber(currencies.Food or 0)
	labels.Coins.Text = NumberUtil.FormatNumber(currencies.Coins or 0)
	labels.Nectar.Text = NumberUtil.FormatNumber(currencies.Nectar or 0)
	refreshTime()
end

function CurrencyHUDController.Init(c)
	context = c
	for _, e in ClickToolConfig.Tools do
		clickToolBonusById[e.id] = e.foodPerClickPerLevel
	end
	for _, e in GeneratorConfig.Generators do
		if e.classId == "snack" then
			generatorById[e.id] = e
		end
	end
end

function CurrencyHUDController.Start()
	local frame = Instance.new("ImageLabel")
	frame.Name = "CurrencyTray"
	frame.AnchorPoint = Vector2.new(1, 0.5)
	frame.Position = UDim2.new(1, -8, 0.5, 0)
	frame.Size = UDim2.fromOffset(360, 30)
	frame.BackgroundTransparency = 1
	frame.Image = UIAssets.TaskbarTabPressedImage
	frame.ScaleType = Enum.ScaleType.Slice
	frame.SliceCenter = UIAssets.SliceCenter
	frame.Parent = context.UI.Taskbar

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, 2)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = frame

	local items = {
		{ id = "Food", icon = "🥪" },
		{ id = "Coins", icon = "$" },
		{ id = "Nectar", icon = "💧" },
	}

	for _, spec in ipairs(items) do
		local item = Instance.new("Frame")
		item.Size = UDim2.fromOffset(72, 24)
		item.BackgroundTransparency = 1
		item.Parent = frame

		if spec.id == "Coins" then
			local coinImage = UIAssets.CurrencyIconImages and UIAssets.CurrencyIconImages.Coins
			local hasCoinImage = type(coinImage) == "string" and coinImage ~= "" and coinImage ~= "rbxassetid://0"
			if hasCoinImage then
				local iconImage = Instance.new("ImageLabel")
				iconImage.Size = UDim2.fromOffset(13, 13)
				iconImage.Position = UDim2.fromOffset(1, 6)
				iconImage.BackgroundTransparency = 1
				iconImage.Image = coinImage
				iconImage.Parent = item
			else
				local fallback = Instance.new("TextLabel")
				fallback.Size = UDim2.fromOffset(16, 24)
				fallback.Position = UDim2.fromOffset(0, 0)
				fallback.BackgroundTransparency = 1
				fallback.Font = UITheme.Font
				fallback.TextSize = 12
				fallback.TextColor3 = Color3.new(0, 0, 0)
				fallback.Text = "$"
				fallback.Parent = item
			end
		else
			local iconText = Instance.new("TextLabel")
			iconText.Size = UDim2.fromOffset(16, 24)
			iconText.Position = UDim2.fromOffset(0, 0)
			iconText.BackgroundTransparency = 1
			iconText.Font = UITheme.Font
			iconText.TextSize = 12
			iconText.TextColor3 = Color3.new(0, 0, 0)
			iconText.Text = spec.icon
			iconText.Parent = item
		end

		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -16, 1, 0)
		l.Position = UDim2.fromOffset(16, 0)
		l.BackgroundTransparency = 1
		l.TextColor3 = Color3.new(0, 0, 0)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Font = UITheme.Font
		l.TextSize = 11
		l.Text = "0"
		l.Parent = item
		labels[spec.id] = l
	end

	local divider = Instance.new("Frame")
	divider.Size = UDim2.fromOffset(6, 20)
	divider.BackgroundTransparency = 1
	divider.Parent = frame

	local dividerDark = Instance.new("Frame")
	dividerDark.Size = UDim2.fromOffset(1, 16)
	dividerDark.Position = UDim2.fromOffset(2, 2)
	dividerDark.BackgroundColor3 = UITheme.Colors.TaskbarBorderDark
	dividerDark.BorderSizePixel = 0
	dividerDark.Parent = divider

	local dividerLight = Instance.new("Frame")
	dividerLight.Size = UDim2.fromOffset(1, 16)
	dividerLight.Position = UDim2.fromOffset(3, 2)
	dividerLight.BackgroundColor3 = UITheme.Colors.TaskbarBorderLight
	dividerLight.BorderSizePixel = 0
	dividerLight.Parent = divider

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.fromOffset(56, 24)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.new(0, 0, 0)
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeLabel.Font = UITheme.Font
	timeLabel.TextSize = 11
	timeLabel.Text = "--:--"
	timeLabel.Parent = frame
	labels.Time = timeLabel

	local soundPlaceholder = Instance.new("Frame")
	soundPlaceholder.Name = "SoundPlaceholder"
	soundPlaceholder.Size = UDim2.fromOffset(14, 14)
	soundPlaceholder.BackgroundTransparency = 1
	soundPlaceholder.Visible = false
	soundPlaceholder.Parent = frame

	local networkPlaceholder = Instance.new("Frame")
	networkPlaceholder.Name = "NetworkPlaceholder"
	networkPlaceholder.Size = UDim2.fromOffset(14, 14)
	networkPlaceholder.BackgroundTransparency = 1
	networkPlaceholder.Visible = false
	networkPlaceholder.Parent = frame

	refresh()

	if not isRunning then
		isRunning = true
		task.spawn(function()
			while isRunning do
				task.wait(45)
				refreshTime()
			end
		end)
	end
end

function CurrencyHUDController.Refresh()
	refresh()
end

return CurrencyHUDController
