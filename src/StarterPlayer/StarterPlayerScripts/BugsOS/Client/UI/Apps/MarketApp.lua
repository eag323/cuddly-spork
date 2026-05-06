--!strict

local MarketApp = {}

local root: Frame?
local priceLabel: TextLabel?

local function makeButton(parent: Instance, text: string, xScale: number): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromScale(0.22, 0.16)
	b.Position = UDim2.fromScale(xScale, 0.78)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Parent = parent
	return b
end

function MarketApp.Refresh(context): ()
	if not root then return end
	priceLabel.Text = string.format("Current Price: %.2f coins/food", context.State.Market.Price or 1)
end

function MarketApp.Mount(target: Instance, context): ()
	if root then return end
	root = Instance.new("Frame")
	root.Name = "MarketWindow"
	root.Position = UDim2.fromScale(0.12, 0.2)
	root.Size = UDim2.fromScale(0.35, 0.45)
	root.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	root.Parent = target

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(30, 30)
	close.Position = UDim2.new(1, -35, 0, 5)
	close.Text = "X"
	close.Parent = root
	close.Activated:Connect(function()
		context.Controllers.Window.Close("Market")
	end)

	priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -20, 0, 30)
	priceLabel.Position = UDim2.fromOffset(10, 40)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextColor3 = Color3.new(1, 1, 1)
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Parent = root

	local historyPlaceholder = Instance.new("TextLabel")
	historyPlaceholder.Size = UDim2.new(1, -20, 0, 160)
	historyPlaceholder.Position = UDim2.fromOffset(10, 80)
	historyPlaceholder.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	historyPlaceholder.TextColor3 = Color3.new(1, 1, 1)
	historyPlaceholder.Text = "Price History (placeholder)"
	historyPlaceholder.Parent = root

	local b10 = makeButton(root, "Sell 10%", 0.04)
	b10.Activated:Connect(function() context.Remotes.MarketSellFood:FireServer({ SellPercent = 10 }) end)
	local b50 = makeButton(root, "Sell 50%", 0.29)
	b50.Activated:Connect(function() context.Remotes.MarketSellFood:FireServer({ SellPercent = 50 }) end)
	local ball = makeButton(root, "Sell All", 0.54)
	ball.Activated:Connect(function() context.Remotes.MarketSellFood:FireServer({ SellPercent = 100 }) end)

	MarketApp.Refresh(context)
end

function MarketApp.Unmount(): ()
	if root then root:Destroy() end
	root = nil
	priceLabel = nil
end

return MarketApp
