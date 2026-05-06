--!strict

local CurrencyHUDController = {}

local context: { [string]: any }
local foodLabel: TextLabel?
local coinLabel: TextLabel?

local function refresh(): ()
	local data = context.State.PlayerData
	if not data or not data.Currencies then
		return
	end
	foodLabel.Text = string.format("Food: %s", tostring(data.Currencies.Food or 0))
	coinLabel.Text = string.format("Coins: %s", tostring(data.Currencies.Coins or 0))
end

function CurrencyHUDController.Init(initContext): ()
	context = initContext
end

function CurrencyHUDController.Start(): ()
	local frame = Instance.new("Frame")
	frame.Name = "CurrencyHUD"
	frame.Position = UDim2.fromOffset(10, 10)
	frame.Size = UDim2.fromOffset(220, 70)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.Parent = context.UI.HUDLayer

	foodLabel = Instance.new("TextLabel")
	foodLabel.Size = UDim2.new(1, -10, 0, 30)
	foodLabel.Position = UDim2.fromOffset(5, 4)
	foodLabel.BackgroundTransparency = 1
	foodLabel.TextColor3 = Color3.new(1, 1, 1)
	foodLabel.TextXAlignment = Enum.TextXAlignment.Left
	foodLabel.Text = "Food: 0"
	foodLabel.Parent = frame

	coinLabel = Instance.new("TextLabel")
	coinLabel.Size = UDim2.new(1, -10, 0, 30)
	coinLabel.Position = UDim2.fromOffset(5, 34)
	coinLabel.BackgroundTransparency = 1
	coinLabel.TextColor3 = Color3.new(1, 1, 1)
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Text = "Coins: 0"
	coinLabel.Parent = frame

	refresh()
end

function CurrencyHUDController.Refresh(): ()
	refresh()
end

return CurrencyHUDController
