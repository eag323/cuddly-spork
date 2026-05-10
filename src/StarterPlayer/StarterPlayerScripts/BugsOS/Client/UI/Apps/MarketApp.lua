--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local MarketplaceConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MarketplaceConfig"))
local UIAssets = require(script.Parent.Parent:WaitForChild("UIAssets"))

local MarketApp = {}
local windowRef, priceValueLabel, deltaLabel, chartFrame
local autoSellBody, autoSellButton, autoSellStatus, targetLabel, targetStepperRow, targetMinusButton, targetPlusButton, targetValueLabel
local tickerLabel
local alertAboveStepper, alertBelowStepper, alertStatusLabel
local tickerConn
local tickerOffset = 0
local DEFAULT_TICKER_SYMBOLS = {"ANTX", "HIVECO", "NECTR", "BUGMART", "WEBNET", "LARVA-LABS", "BEETL", "MOTHCO", "CRICKETCOM", "TERMITECH", "WASPWAY", "FLEABAY", "SILKNET", "POLLENEX", "GRUBHUBS", "STINGR", "ROACHCO", "FIREFLY", "QUEENX", "ANTBIT"}
local DEFAULT_TICKER_NEWS = {
	"BugMart reports record crumb demand.",
	"BeetleBay trading volume spikes overnight.",
	"Queen Futures steady after colony expansion.",
	"Larva Labs announces new hatchery upgrade.",
	"SpiderWeb Networks misses web traffic estimates.",
	"Ant workers increase food transport capacity.",
	"Nectar markets rise after backyard bloom.",
	"TermiteTech shares fall after wood shortage.",
	"Firefly Energy glows after sunset demand surge.",
	"WaspWay warns of volatile flight conditions.",
	"MothCo rallies on lamp season optimism.",
	"PollenEx reports strong spring guidance.",
	"FleaBay listings jump after rare bug demand.",
	"RoachCo remains resilient despite kitchen cleanup fears.",
	"HiveCo expands into picnic territory.",
}
local tickerRng = Random.new()
local tickerSnapshot = ""
local tickerRefreshAt = 0
local TICKER_REFRESH_MIN_SECONDS = 120
local TICKER_REFRESH_MAX_SECONDS = 180

local GREEN_CANDLE_ASSET = "rbxassetid://132096679740132"
local RED_CANDLE_ASSET = "rbxassetid://133082519022540"

local function clearChart(frame: Frame)
	for _, child in ipairs(frame:GetChildren()) do
		if child.Name == "ChartGridLine" or child.Name == "ChartCandle" then
			child:Destroy()
		end
	end
end

local function renderChart(history, marketCap)
	if not chartFrame then return end
	clearChart(chartFrame)
	if type(history) ~= "table" or #history < 2 then return end

	local minP, maxP = 0.5, math.max(3.0, tonumber(marketCap) or 3.0)
	local chartHeight = math.max(180, chartFrame.AbsoluteSize.Y)
	local chartWidth = math.max(520, chartFrame.AbsoluteSize.X)
	local topPadding = 10
	local bottomPadding = 10
	local leftPadding = 14
	local rightPadding = 14
	local usableHeight = math.max(60, chartHeight - topPadding - bottomPadding)
	local usableWidth = math.max(180, chartWidth - leftPadding - rightPadding)

	for i = 1, 4 do
		local line = Instance.new("Frame")
		line.Name = "ChartGridLine"
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, i / 5, 0)
		line.BackgroundColor3 = Color3.fromRGB(30, 54, 84)
		line.BackgroundTransparency = 0.35
		line.BorderSizePixel = 0
		line.ZIndex = 1
		line.Parent = chartFrame
	end

	local startIndex = math.max(2, #history - 19)
	local candleCount = #history - startIndex + 1
	if candleCount <= 0 then return end

	local candleWidth = 32
	local candleHeight = 64
	local preferredGap = 26
	local minGap = 20
	local maxGap = 30
	local gap = preferredGap
	if candleCount > 1 then
		local maxFitGap = (usableWidth - (candleCount * candleWidth)) / (candleCount - 1)
		gap = math.clamp(maxFitGap, minGap, maxGap)
	end
	local totalCandlesWidth = (candleCount * candleWidth) + ((candleCount - 1) * gap)
	local startX = leftPadding + math.max(0, (usableWidth - totalCandlesWidth) * 0.5)

	local function yForPrice(price: number): number
		local alpha = (math.clamp(price, minP, maxP) - minP) / (maxP - minP)
		return topPadding + (1 - alpha) * usableHeight
	end

	for index = 0, candleCount - 1 do
		local historyIndex = startIndex + index
		local openPrice = history[historyIndex - 1]
		local closePrice = history[historyIndex]
		if type(openPrice) == "number" and type(closePrice) == "number" then
			local up = closePrice >= openPrice
			local candleX = startX + (index * (candleWidth + gap)) + (candleWidth * 0.5)
			local yMid = (yForPrice(openPrice) + yForPrice(closePrice)) * 0.5
			local bodyY = math.clamp(yMid - (candleHeight * 0.5), topPadding, topPadding + usableHeight - candleHeight)

			local candle = Instance.new("ImageLabel")
			candle.Name = "ChartCandle"
			candle.AnchorPoint = Vector2.new(0.5, 0)
			candle.Position = UDim2.fromOffset(candleX, bodyY)
			candle.Size = UDim2.fromOffset(candleWidth, candleHeight)
			candle.BackgroundTransparency = 1
			candle.Image = up and GREEN_CANDLE_ASSET or RED_CANDLE_ASSET
			candle.ScaleType = Enum.ScaleType.Stretch
			candle.ZIndex = 3
			candle.Parent = chartFrame

		end
	end
end


local function buildDefaultTickerText(): string
	local entries = table.create(#DEFAULT_TICKER_SYMBOLS + #DEFAULT_TICKER_NEWS)
	for _, symbol in ipairs(DEFAULT_TICKER_SYMBOLS) do
		local up = tickerRng:NextNumber() >= 0.5
		local delta = tickerRng:NextNumber(0.2, 6.9)
		table.insert(entries, string.format("%s %s %.1f%%", symbol, up and "▲" or "▼", delta))
	end
	for _, headline in ipairs(DEFAULT_TICKER_NEWS) do
		table.insert(entries, headline)
	end
	return table.concat(entries, " | ")
end

local function getTickerText(marketState): string
	local now = os.clock()
	if tickerSnapshot == "" or now >= tickerRefreshAt then
		tickerSnapshot = buildDefaultTickerText()
		tickerRefreshAt = now + tickerRng:NextInteger(TICKER_REFRESH_MIN_SECONDS, TICKER_REFRESH_MAX_SECONDS)
	end
	local text = tickerSnapshot
	local activeEvent = marketState.ActiveEvent
	local headline = ""
	if type(activeEvent) == "table" then
		headline = tostring(activeEvent.TickerHeadline or activeEvent.Description or "")
	end
	if headline ~= "" then
		text = string.format("%s | BREAKING: %s", text, headline)
	end
	return text
end

local function updateAutoSellUi(context)
	local playerData = context.State.PlayerData or {}
	local purchases = playerData.Purchases or {}
	local settings = playerData.Settings or {}
	local owns = purchases.AutoSellOwned == true
	if autoSellBody then autoSellBody.BackgroundTransparency = owns and 0 or 0.35 end
	if not autoSellButton or not autoSellStatus or not targetLabel then return end
	if not owns then
		autoSellButton.Text = "Unlock Auto-Sell"
		autoSellButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		autoSellStatus.Text = "Auto-Sell automatically sells your food when the market reaches your selected price."
		targetLabel.Text = "Requires Auto-Sell gamepass"
		if targetStepperRow then targetStepperRow.Visible = false end
		return
	end
	if targetStepperRow then targetStepperRow.Visible = true end
	local enabled = settings.AutoSellEnabled == true
	local target = math.clamp(tonumber(settings.AutoSellTarget) or 1.5, 0.5, 3.0)
	target = math.round(target * 100) / 100
	autoSellButton.Text = enabled and "ON" or "OFF"
	autoSellButton.BackgroundColor3 = enabled and Color3.fromRGB(34, 150, 72) or Color3.fromRGB(176, 46, 46)
	autoSellStatus.Text = enabled and "Auto-Sell enabled" or "Auto-Sell disabled"
	targetLabel.Text = "Target Price:"
	if targetValueLabel then
		targetValueLabel.Text = string.format("$%.2f", target)
	end
	if targetMinusButton then targetMinusButton.Active = target > 0.5 end
	if targetPlusButton then targetPlusButton.Active = target < 3.0 end
end

function MarketApp.Refresh(context)
	if not windowRef or not priceValueLabel then return end
	local marketState = context.State.Market or {}
	local price = marketState.Price or 1
	priceValueLabel.Text = string.format("$%.2f", price)
	local history = marketState.History or {}
	if #history >= 2 then
		local delta = price - history[#history - 1]
		if delta > 0 then deltaLabel.Text = string.format("▲ +$%.2f", delta); deltaLabel.TextColor3=Color3.fromRGB(65,220,120)
		elseif delta < 0 then deltaLabel.Text = string.format("▼ -$%.2f", math.abs(delta)); deltaLabel.TextColor3=Color3.fromRGB(235,90,90)
		else deltaLabel.Text = "$0.00"; deltaLabel.TextColor3=Color3.fromRGB(170,170,170) end
	else deltaLabel.Text = "n/a"; deltaLabel.TextColor3=Color3.fromRGB(170,170,170) end
	renderChart(history, marketState.MarketCap)
	updateAutoSellUi(context)
	if tickerLabel then
		tickerLabel.Text = getTickerText(marketState)
	end
	if alertStatusLabel then
		local alerts = marketState.Alerts or { Above = 2.5, Below = 0.75 }
		alertStatusLabel.Text = string.format("Above: $%.2f    Below: $%.2f", alerts.Above or 2.5, alerts.Below or 0.75)
	end
end

function MarketApp.Mount(target, context)
	if windowRef then return end
	windowRef = Window.Create({Title="Market.exe", IconImage=UIAssets.AppIconImages.Market, AppId="Market", Size=UDim2.fromOffset(760,700), Position=UDim2.fromOffset(460,80), Parent=target, OnClose=function() context.Controllers.Window.Close("Market") end, OnMinimize=function() context.Controllers.Window.Minimize("Market") end, OnFocus=function() context.Controllers.Window.Focus("Market") end})
	local contentFrame = windowRef.Content
	contentFrame.BackgroundColor3 = Color3.fromRGB(10, 22, 40)
	contentFrame.ClipsDescendants = true

	local contentRoot = Instance.new("ScrollingFrame")
	contentRoot.Name = "ContentRoot"
	contentRoot.Size = UDim2.fromScale(1, 1)
	contentRoot.BackgroundTransparency = 1
	contentRoot.BorderSizePixel = 0
	contentRoot.ScrollBarThickness = 12
	contentRoot.ScrollBarImageColor3 = Color3.fromRGB(88, 150, 220)
	contentRoot.CanvasSize = UDim2.fromOffset(0, 0)
	contentRoot.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentRoot.ScrollingDirection = Enum.ScrollingDirection.Y
	contentRoot.Parent = contentFrame

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop = UDim.new(0, 10)
	contentPadding.PaddingBottom = UDim.new(0, 10)
	contentPadding.PaddingLeft = UDim.new(0, 10)
	contentPadding.PaddingRight = UDim.new(0, 10)
	contentPadding.Parent = contentRoot

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 12)
	contentLayout.Parent = contentRoot

	local tickerFrame = Instance.new("Frame")
	tickerFrame.Name = "NewsTicker"
	tickerFrame.LayoutOrder = 0
	tickerFrame.Size = UDim2.new(1, 0, 0, 28)
	tickerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	tickerFrame.BorderColor3 = Color3.fromRGB(35, 75, 35)
	tickerFrame.ClipsDescendants = true
	tickerFrame.Parent = contentRoot

	tickerLabel = Instance.new("TextLabel")
	tickerLabel.Size = UDim2.new(4, 0, 1, 0)
	tickerLabel.Position = UDim2.fromOffset(0, 0)
	tickerLabel.BackgroundTransparency = 1
	tickerLabel.TextXAlignment = Enum.TextXAlignment.Left
	tickerLabel.TextColor3 = Color3.fromRGB(74, 255, 97)
	tickerLabel.Font = Enum.Font.RobotoMono
	tickerLabel.TextSize = 15
	tickerLabel.Text = buildDefaultTickerText()
	tickerLabel.Parent = tickerFrame

	local intro = Instance.new("TextLabel")
	intro.Name = "IntroLabel"
	intro.LayoutOrder = 1
	intro.Size = UDim2.new(1, 0, 0, 44)
	intro.BackgroundTransparency = 1
	intro.Text = "Sell your food for coins. Prices change every 30 seconds. Sell high!"
	intro.TextXAlignment = Enum.TextXAlignment.Left
	intro.TextYAlignment = Enum.TextYAlignment.Top
	intro.TextWrapped = true
	intro.TextColor3 = Color3.fromRGB(215,230,255)
	intro.Font = Enum.Font.GothamBold
	intro.TextSize = 15
	intro.Parent = contentRoot

	local foodMarketSection = Instance.new("Frame")
	foodMarketSection.Name = "FoodMarketSection"
	foodMarketSection.LayoutOrder = 2
	foodMarketSection.Size = UDim2.new(1, 0, 0, 430)
	foodMarketSection.BackgroundColor3 = Color3.fromRGB(18,34,58)
	foodMarketSection.BorderColor3 = Color3.fromRGB(65,140,200)
	foodMarketSection.Parent = contentRoot

	local foodPadding = Instance.new("UIPadding")
	foodPadding.PaddingTop = UDim.new(0, 10)
	foodPadding.PaddingBottom = UDim.new(0, 10)
	foodPadding.PaddingLeft = UDim.new(0, 10)
	foodPadding.PaddingRight = UDim.new(0, 10)
	foodPadding.Parent = foodMarketSection

	local foodLayout = Instance.new("UIListLayout")
	foodLayout.FillDirection = Enum.FillDirection.Vertical
	foodLayout.SortOrder = Enum.SortOrder.LayoutOrder
	foodLayout.Padding = UDim.new(0, 9)
	foodLayout.Parent = foodMarketSection

	local currentPriceLabel = Instance.new("TextLabel")
	currentPriceLabel.Name = "CurrentPricePerFoodLabel"
	currentPriceLabel.LayoutOrder = 1
	currentPriceLabel.Size = UDim2.new(1,0,0,22)
	currentPriceLabel.BackgroundTransparency = 1
	currentPriceLabel.Text = "Current Price Per Food"
	currentPriceLabel.TextXAlignment = Enum.TextXAlignment.Left
	currentPriceLabel.TextColor3 = Color3.fromRGB(255,255,255)
	currentPriceLabel.Font = Enum.Font.GothamBold
	currentPriceLabel.TextSize = 17
	currentPriceLabel.Parent = foodMarketSection

	local priceRow = Instance.new("Frame")
	priceRow.Name = "PriceRow"
	priceRow.LayoutOrder = 2
	priceRow.Size = UDim2.new(1,0,0,54)
	priceRow.BackgroundTransparency = 1
	priceRow.Parent = foodMarketSection

	priceValueLabel = Instance.new("TextLabel")
	priceValueLabel.Size = UDim2.new(0.55,0,1,0)
	priceValueLabel.BackgroundTransparency = 1
	priceValueLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceValueLabel.Font = Enum.Font.GothamBold
	priceValueLabel.TextSize = 40
	priceValueLabel.TextColor3 = Color3.fromRGB(255,215,90)
	priceValueLabel.Parent = priceRow

	deltaLabel = Instance.new("TextLabel")
	deltaLabel.Size = UDim2.new(0.45,0,1,0)
	deltaLabel.Position = UDim2.new(0.55,0,0,0)
	deltaLabel.BackgroundTransparency = 1
	deltaLabel.TextXAlignment = Enum.TextXAlignment.Left
	deltaLabel.Font = Enum.Font.GothamBold
	deltaLabel.TextSize = 32
	deltaLabel.TextColor3 = Color3.fromRGB(170,170,170)
	deltaLabel.Parent = priceRow

	chartFrame = Instance.new("Frame")
	chartFrame.Name = "CandlestickChart"
	chartFrame.LayoutOrder = 3
	chartFrame.Size = UDim2.new(1,0,0,232)
	chartFrame.BackgroundColor3 = Color3.fromRGB(8,16,30)
	chartFrame.BorderColor3 = Color3.fromRGB(56,90,130)
	chartFrame.Parent = foodMarketSection

	local sellButtonsRow = Instance.new("Frame")
	sellButtonsRow.Name = "SellButtonsRow"
	sellButtonsRow.LayoutOrder = 4
	sellButtonsRow.Size = UDim2.new(1,0,0,40)
	sellButtonsRow.BackgroundTransparency = 1
	sellButtonsRow.Parent = foodMarketSection

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0,8)
	rowLayout.Parent = sellButtonsRow

	local function makeButton(t,c)
		local b=Instance.new("TextButton"); b.Size=UDim2.new(1/3,-6,1,0); b.Text=t; b.BackgroundColor3=c; b.TextColor3=Color3.new(1,1,1); b.BorderSizePixel=0; b.Font=Enum.Font.GothamBold; b.TextSize=18; b.Parent=sellButtonsRow; return b
	end
	local sellRemote=context.Remotes.MarketSellFood
	makeButton("Sell 10%",Color3.fromRGB(15,25,140)).Activated:Connect(function() sellRemote:FireServer({SellPercent=10}) end)
	makeButton("Sell 50%",Color3.fromRGB(20,130,70)).Activated:Connect(function() sellRemote:FireServer({SellPercent=50}) end)
	makeButton("Sell All",Color3.fromRGB(230,70,90)).Activated:Connect(function() sellRemote:FireServer({SellPercent=100}) end)

	local autoSellSection = Instance.new("Frame")
	autoSellSection.Name = "AutoSellSection"
	autoSellSection.LayoutOrder = 3
	autoSellSection.Size = UDim2.new(1,0,0,170)
	autoSellSection.BackgroundColor3 = Color3.fromRGB(18,34,58)
	autoSellSection.BorderColor3 = Color3.fromRGB(65,140,200)
	autoSellSection.Parent = contentRoot
	autoSellBody = autoSellSection

	local autoSellPadding = Instance.new("UIPadding")
	autoSellPadding.PaddingTop = UDim.new(0,10)
	autoSellPadding.PaddingBottom = UDim.new(0,10)
	autoSellPadding.PaddingLeft = UDim.new(0,10)
	autoSellPadding.PaddingRight = UDim.new(0,10)
	autoSellPadding.Parent = autoSellSection

	local autoSellLayout = Instance.new("UIListLayout")
	autoSellLayout.FillDirection = Enum.FillDirection.Vertical
	autoSellLayout.SortOrder = Enum.SortOrder.LayoutOrder
	autoSellLayout.Padding = UDim.new(0,8)
	autoSellLayout.Parent = autoSellSection

	local autoSellTitle = Instance.new("TextLabel")
	autoSellTitle.LayoutOrder = 1
	autoSellTitle.Size = UDim2.new(1,0,0,22)
	autoSellTitle.BackgroundTransparency = 1
	autoSellTitle.Text = "Auto-Sell"
	autoSellTitle.TextColor3 = Color3.fromRGB(120,170,255)
	autoSellTitle.TextXAlignment = Enum.TextXAlignment.Left
	autoSellTitle.Font = Enum.Font.GothamBold
	autoSellTitle.TextSize = 18
	autoSellTitle.Parent = autoSellSection

	autoSellStatus = Instance.new("TextLabel")
	autoSellStatus.LayoutOrder = 2
	autoSellStatus.Size = UDim2.new(1,0,0,38)
	autoSellStatus.BackgroundTransparency = 1
	autoSellStatus.TextWrapped = true
	autoSellStatus.TextXAlignment = Enum.TextXAlignment.Left
	autoSellStatus.TextYAlignment = Enum.TextYAlignment.Top
	autoSellStatus.TextColor3 = Color3.fromRGB(230,230,230)
	autoSellStatus.Font = Enum.Font.GothamBold
	autoSellStatus.TextSize = 14
	autoSellStatus.Parent = autoSellSection

	local controlRow = Instance.new("Frame")
	controlRow.LayoutOrder = 3
	controlRow.Size = UDim2.new(1,0,0,34)
	controlRow.BackgroundTransparency = 1
	controlRow.Parent = autoSellSection
	autoSellButton=Instance.new("TextButton"); autoSellButton.Size=UDim2.fromOffset(180,34); autoSellButton.BackgroundColor3=Color3.fromRGB(70,70,80); autoSellButton.TextColor3=Color3.new(1,1,1); autoSellButton.Font=Enum.Font.GothamBold; autoSellButton.TextSize=17; autoSellButton.Parent=controlRow
	targetLabel=Instance.new("TextLabel"); targetLabel.Size=UDim2.new(1,-190,1,0); targetLabel.Position=UDim2.fromOffset(190,0); targetLabel.BackgroundTransparency=1; targetLabel.TextColor3=Color3.new(1,1,1); targetLabel.TextXAlignment=Enum.TextXAlignment.Left; targetLabel.Font=Enum.Font.GothamBold; targetLabel.TextSize=16; targetLabel.Parent=controlRow

	targetStepperRow = Instance.new("Frame")
	targetStepperRow.LayoutOrder = 4
	targetStepperRow.Size = UDim2.new(1, 0, 0, 34)
	targetStepperRow.BackgroundTransparency = 1
	targetStepperRow.Parent = autoSellSection
	local stepperLayout = Instance.new("UIListLayout")
	stepperLayout.FillDirection = Enum.FillDirection.Horizontal
	stepperLayout.Padding = UDim.new(0, 8)
	stepperLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	stepperLayout.Parent = targetStepperRow
	targetMinusButton = Instance.new("TextButton")
	targetMinusButton.Size = UDim2.fromOffset(34, 34)
	targetMinusButton.Text = "-"
	targetMinusButton.Font = Enum.Font.GothamBold
	targetMinusButton.TextSize = 20
	targetMinusButton.TextColor3 = Color3.new(1, 1, 1)
	targetMinusButton.BackgroundColor3 = Color3.fromRGB(44, 74, 120)
	targetMinusButton.Parent = targetStepperRow
	targetValueLabel = Instance.new("TextLabel")
	targetValueLabel.Size = UDim2.fromOffset(110, 34)
	targetValueLabel.Text = "$1.50"
	targetValueLabel.Font = Enum.Font.GothamBold
	targetValueLabel.TextSize = 16
	targetValueLabel.TextColor3 = Color3.fromRGB(190, 245, 255)
	targetValueLabel.BackgroundColor3 = Color3.fromRGB(8, 16, 30)
	targetValueLabel.BorderColor3 = Color3.fromRGB(65, 140, 200)
	targetValueLabel.Parent = targetStepperRow
	targetPlusButton = Instance.new("TextButton")
	targetPlusButton.Size = UDim2.fromOffset(34, 34)
	targetPlusButton.Text = "+"
	targetPlusButton.Font = Enum.Font.GothamBold
	targetPlusButton.TextSize = 20
	targetPlusButton.TextColor3 = Color3.new(1, 1, 1)
	targetPlusButton.BackgroundColor3 = Color3.fromRGB(44, 74, 120)
	targetPlusButton.Parent = targetStepperRow

	local function stepTarget(delta: number)
		local settings = (((context.State.PlayerData or {}).Settings) or {})
		local current = tonumber(settings.AutoSellTarget) or 1.5
		local nextTarget = math.clamp(math.round((current + delta) * 100) / 100, 0.5, 3.0)
		context.Remotes.MarketSetAutoSellTarget:FireServer({Target = nextTarget})
		settings.AutoSellTarget = nextTarget
		updateAutoSellUi(context)
	end
	targetMinusButton.Activated:Connect(function() stepTarget(-0.05) end)
	targetPlusButton.Activated:Connect(function() stepTarget(0.05) end)
	autoSellButton.Activated:Connect(function()
		local owns = (((context.State.PlayerData or {}).Purchases or {}).AutoSellOwned == true)
		if owns then
			local enabled = (((context.State.PlayerData or {}).Settings or {}).AutoSellEnabled == true)
			context.Remotes.MarketSetAutoSellEnabled:FireServer({Enabled = not enabled})
			return
		end
		local passId = MarketplaceConfig.AutoSellGamepassId or 0
		if passId > 0 then MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, passId) end
	end)

	local priceAlertsSection = Instance.new("Frame")
	priceAlertsSection.Name = "PriceAlertsSection"
	priceAlertsSection.LayoutOrder = 4
	priceAlertsSection.Size = UDim2.new(1, 0, 0, 120)
	priceAlertsSection.BackgroundColor3 = Color3.fromRGB(18,34,58)
	priceAlertsSection.BorderColor3 = Color3.fromRGB(65,140,200)
	priceAlertsSection.Parent = contentRoot

	local alertsTitle = Instance.new("TextLabel")
	alertsTitle.Size = UDim2.new(1, -20, 0, 22)
	alertsTitle.Position = UDim2.fromOffset(10, 8)
	alertsTitle.BackgroundTransparency = 1
	alertsTitle.Text = "Price Alerts"
	alertsTitle.Font = Enum.Font.GothamBold
	alertsTitle.TextSize = 18
	alertsTitle.TextColor3 = Color3.fromRGB(120,170,255)
	alertsTitle.TextXAlignment = Enum.TextXAlignment.Left
	alertsTitle.Parent = priceAlertsSection

	local function makeStepper(yPos: number, prefix: string, defaultValue: number, onChanged)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -20, 0, 30)
		row.Position = UDim2.fromOffset(10, yPos)
		row.BackgroundTransparency = 1
		row.Parent = priceAlertsSection
		local minus = Instance.new("TextButton")
		minus.Size = UDim2.fromOffset(28, 28); minus.Text = "-"; minus.Parent = row
		local plus = Instance.new("TextButton")
		plus.Size = UDim2.fromOffset(28, 28); plus.Position = UDim2.new(1, -28, 0, 0); plus.Text = "+"; plus.Parent = row
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -70, 1, 0); label.Position = UDim2.fromOffset(35, 0); label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(235,235,235); label.Font = Enum.Font.Gotham; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
		local value = defaultValue
		local function syncLabel() label.Text = string.format("%s $%.2f", prefix, value) end
		local function updateValue(delta)
			value = math.clamp(math.round((value + delta) * 100) / 100, 0.5, 5.0)
			syncLabel()
			onChanged(value)
		end
		minus.Activated:Connect(function() updateValue(-0.05) end)
		plus.Activated:Connect(function() updateValue(0.05) end)
		syncLabel()
		return row
	end
	makeStepper(34, "Alert me above:", 2.5, function(v) context.State.Market.Alerts.Above = v end)
	makeStepper(66, "Alert me below:", 0.75, function(v) context.State.Market.Alerts.Below = v end)
	alertStatusLabel = Instance.new("TextLabel")
	alertStatusLabel.Size = UDim2.new(1, -20, 0, 16); alertStatusLabel.Position = UDim2.fromOffset(10, 98); alertStatusLabel.BackgroundTransparency = 1
	alertStatusLabel.TextXAlignment = Enum.TextXAlignment.Left; alertStatusLabel.Font = Enum.Font.Code; alertStatusLabel.TextSize = 13; alertStatusLabel.TextColor3 = Color3.fromRGB(156, 235, 162)
	alertStatusLabel.Parent = priceAlertsSection

	if tickerConn then tickerConn:Disconnect() end
	tickerConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
		if not tickerLabel or not tickerLabel.Parent then return end
		tickerOffset -= dt * 70
		if tickerOffset < -tickerLabel.TextBounds.X then
			tickerOffset = tickerFrame.AbsoluteSize.X
		end
		tickerLabel.Position = UDim2.fromOffset(tickerOffset, 0)
	end)
	MarketApp.Refresh(context)
end
function MarketApp.SetZIndex(z) if windowRef and windowRef.SetZIndex then windowRef.SetZIndex(z) end end
function MarketApp.Unmount() if tickerConn then tickerConn:Disconnect(); tickerConn = nil end; if windowRef then windowRef.Destroy() end; windowRef=nil end

return MarketApp
