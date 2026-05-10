--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local MarketplaceConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MarketplaceConfig"))

local MarketApp = {}
local windowRef, priceValueLabel, deltaLabel, chartFrame
local autoSellBody, autoSellButton, autoSellStatus, targetLabel, sliderBar, sliderKnob
local GREEN_CANDLE_ASSET = "rbxassetid://132096679740132"
local RED_CANDLE_ASSET = "rbxassetid://133082519022540"

local function clearChart(frame: Frame)
	for _, child in ipairs(frame:GetChildren()) do
		if child.Name == "ChartGridLine" or child.Name == "ChartCandle" then
			child:Destroy()
		end
	end
end

local function renderChart(history)
	if not chartFrame then return end
	clearChart(chartFrame)
	if type(history) ~= "table" or #history < 2 then return end

	local minP, maxP = 0.5, 3.0
	local chartHeight = math.max(120, chartFrame.AbsoluteSize.Y)
	local chartWidth = math.max(360, chartFrame.AbsoluteSize.X)
	local topPadding = 8
	local bottomPadding = 8
	local leftPadding = 12
	local rightPadding = 12
	local usableHeight = math.max(40, chartHeight - topPadding - bottomPadding)
	local usableWidth = math.max(120, chartWidth - leftPadding - rightPadding)

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

	local spacing = usableWidth / candleCount
	local candleWidth = math.clamp(math.floor(spacing * 0.62), 18, 24)
	local minBodyHeight = 12
	local maxBodyHeight = math.floor(usableHeight * 0.92)

	local function yForPrice(price: number): number
		local alpha = (math.clamp(price, minP, maxP) - minP) / (maxP - minP)
		return topPadding + (1 - alpha) * usableHeight
	end

	for index = 0, candleCount - 1 do
		local historyIndex = startIndex + index
		local openPrice = history[historyIndex - 1]
		local closePrice = history[historyIndex]
		if type(openPrice) == "number" and type(closePrice) == "number" then
			local highPrice = math.max(openPrice, closePrice)
			local lowPrice = math.min(openPrice, closePrice)
			local up = closePrice >= openPrice
			local candleX = leftPadding + (index * spacing) + (spacing * 0.5)

			local yOpen = yForPrice(openPrice)
			local yClose = yForPrice(closePrice)
			local yHigh = yForPrice(highPrice)
			local yLow = yForPrice(lowPrice)
			local yMid = (yOpen + yClose) * 0.5
			local bodyHeight = math.clamp(math.abs(yClose - yOpen), minBodyHeight, maxBodyHeight)
			local bodyY = math.clamp(yMid - (bodyHeight * 0.5), topPadding, topPadding + usableHeight - bodyHeight)

			local candle = Instance.new("ImageLabel")
			candle.Name = "ChartCandle"
			candle.AnchorPoint = Vector2.new(0.5, 0)
			candle.Position = UDim2.fromOffset(candleX, bodyY)
			candle.Size = UDim2.fromOffset(candleWidth, bodyHeight)
			candle.BackgroundTransparency = 1
			candle.Image = up and GREEN_CANDLE_ASSET or RED_CANDLE_ASSET
			candle.ScaleType = Enum.ScaleType.Stretch
			candle.ZIndex = 3
			candle.Parent = chartFrame

			local wick = Instance.new("Frame")
			wick.Name = "ChartCandle"
			wick.AnchorPoint = Vector2.new(0.5, 0)
			wick.Position = UDim2.fromOffset(candleX, yHigh)
			wick.Size = UDim2.fromOffset(2, math.max(2, yLow - yHigh))
			wick.BackgroundColor3 = up and Color3.fromRGB(70, 220, 125) or Color3.fromRGB(230, 90, 95)
			wick.BorderSizePixel = 0
			wick.ZIndex = 2
			wick.Parent = chartFrame
		end
	end
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
		autoSellStatus.Text = "Auto-Sell automatically sells your food when the market reaches your selected price."
		targetLabel.Text = "Requires Auto-Sell gamepass"
		if sliderBar then sliderBar.Visible = false end
		if sliderKnob then sliderKnob.Visible = false end
		return
	end
	if sliderBar then sliderBar.Visible = true end
	if sliderKnob then sliderKnob.Visible = true end
	local enabled = settings.AutoSellEnabled == true
	local target = tonumber(settings.AutoSellTarget) or 1.5
	autoSellButton.Text = enabled and "ON" or "OFF"
	autoSellStatus.Text = enabled and "Auto-Sell enabled" or "Auto-Sell disabled"
	targetLabel.Text = string.format("Target: $%.2f", target)
	local alpha = math.clamp((target - 0.5) / 2.5, 0, 1)
	sliderKnob.Position = UDim2.new(alpha, -6, 0.5, -10)
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
	renderChart(history)
	updateAutoSellUi(context)
end

function MarketApp.Mount(target, context)
	if windowRef then return end
	windowRef = Window.Create({Title="Market.exe", Icon="🐟", AppId="Market", Size=UDim2.fromOffset(740,580), Position=UDim2.fromOffset(460,80), Parent=target, OnClose=function() context.Controllers.Window.Close("Market") end, OnMinimize=function() context.Controllers.Window.Minimize("Market") end, OnFocus=function() context.Controllers.Window.Focus("Market") end})
	local root = windowRef.Content; root.BackgroundColor3 = Color3.fromRGB(10, 22, 40)
	local container = Instance.new("Frame"); container.Size=UDim2.fromScale(1,1); container.BackgroundTransparency=1; container.Parent=root
	local padding = Instance.new("UIPadding"); padding.PaddingTop=UDim.new(0,10); padding.PaddingBottom=UDim.new(0,10); padding.PaddingLeft=UDim.new(0,10); padding.PaddingRight=UDim.new(0,10); padding.Parent=container
	local stack = Instance.new("UIListLayout"); stack.FillDirection=Enum.FillDirection.Vertical; stack.Padding=UDim.new(0,12); stack.Parent=container

	local top = Instance.new("Frame"); top.Name="FoodMarketSection"; top.Size=UDim2.new(1,0,0,380); top.BackgroundColor3=Color3.fromRGB(18,34,58); top.BorderColor3=Color3.fromRGB(65,140,200); top.Parent=container
	local topPad = Instance.new("UIPadding"); topPad.PaddingTop=UDim.new(0,10); topPad.PaddingBottom=UDim.new(0,10); topPad.PaddingLeft=UDim.new(0,10); topPad.PaddingRight=UDim.new(0,10); topPad.Parent=top
	local topLayout = Instance.new("UIListLayout"); topLayout.FillDirection=Enum.FillDirection.Vertical; topLayout.Padding=UDim.new(0,9); topLayout.Parent=top

	local intro=Instance.new("TextLabel"); intro.Size=UDim2.new(1,0,0,22); intro.BackgroundTransparency=1; intro.TextXAlignment=Enum.TextXAlignment.Left; intro.TextColor3=Color3.fromRGB(215,230,255); intro.Text="Sell your food for coins. Prices change every 30 seconds. Sell high!"; intro.Font=Enum.Font.GothamBold; intro.TextSize=15; intro.Parent=top
	local cpl=Instance.new("TextLabel"); cpl.Size=UDim2.new(1,0,0,22); cpl.BackgroundTransparency=1; cpl.Text="Current Price Per Food"; cpl.TextXAlignment=Enum.TextXAlignment.Left; cpl.TextColor3=Color3.fromRGB(255,255,255); cpl.Font=Enum.Font.GothamBold; cpl.TextSize=17; cpl.Parent=top

	local priceRow = Instance.new("Frame"); priceRow.Size=UDim2.new(1,0,0,54); priceRow.BackgroundTransparency=1; priceRow.Parent=top
	priceValueLabel=Instance.new("TextLabel"); priceValueLabel.Size=UDim2.new(0.55,0,1,0); priceValueLabel.BackgroundTransparency=1; priceValueLabel.TextXAlignment=Enum.TextXAlignment.Left; priceValueLabel.Font=Enum.Font.GothamBold; priceValueLabel.TextSize=40; priceValueLabel.TextColor3=Color3.fromRGB(255,215,90); priceValueLabel.Parent=priceRow
	deltaLabel=Instance.new("TextLabel"); deltaLabel.Size=UDim2.new(0.45,0,1,0); deltaLabel.Position=UDim2.new(0.55,0,0,0); deltaLabel.BackgroundTransparency=1; deltaLabel.TextXAlignment=Enum.TextXAlignment.Left; deltaLabel.Font=Enum.Font.GothamBold; deltaLabel.TextSize=32; deltaLabel.TextColor3=Color3.fromRGB(170,170,170); deltaLabel.Parent=priceRow

	chartFrame=Instance.new("Frame"); chartFrame.Size=UDim2.new(1,0,0,210); chartFrame.BackgroundColor3=Color3.fromRGB(8,16,30); chartFrame.BorderColor3=Color3.fromRGB(56,90,130); chartFrame.Parent=top
	local row=Instance.new("Frame"); row.Name="SellButtonsRow"; row.Size=UDim2.new(1,0,0,40); row.BackgroundTransparency=1; row.Parent=top
	local rowLayout = Instance.new("UIListLayout"); rowLayout.FillDirection=Enum.FillDirection.Horizontal; rowLayout.Padding=UDim.new(0,8); rowLayout.Parent=row

	local function makeButton(t,c)
		local b=Instance.new("TextButton"); b.Size=UDim2.new(1/3,-6,1,0); b.Text=t; b.BackgroundColor3=c; b.TextColor3=Color3.new(1,1,1); b.BorderSizePixel=0; b.Font=Enum.Font.GothamBold; b.TextSize=18; b.Parent=row; return b end
	local sellRemote=context.Remotes.MarketSellFood
	makeButton("Sell 10%",Color3.fromRGB(15,25,140)).Activated:Connect(function() sellRemote:FireServer({SellPercent=10}) end)
	makeButton("Sell 50%",Color3.fromRGB(20,130,70)).Activated:Connect(function() sellRemote:FireServer({SellPercent=50}) end)
	makeButton("Sell All",Color3.fromRGB(230,70,90)).Activated:Connect(function() sellRemote:FireServer({SellPercent=100}) end)

	local bottom = Instance.new("Frame"); bottom.Name="AutoSellSection"; bottom.Size=UDim2.new(1,0,0,150); bottom.BackgroundColor3=Color3.fromRGB(18,34,58); bottom.BorderColor3=Color3.fromRGB(65,140,200); bottom.Parent=container
	autoSellBody=bottom
	local bottomPad = Instance.new("UIPadding"); bottomPad.PaddingTop=UDim.new(0,10); bottomPad.PaddingBottom=UDim.new(0,10); bottomPad.PaddingLeft=UDim.new(0,10); bottomPad.PaddingRight=UDim.new(0,10); bottomPad.Parent=bottom
	local bottomLayout = Instance.new("UIListLayout"); bottomLayout.FillDirection=Enum.FillDirection.Vertical; bottomLayout.Padding=UDim.new(0,8); bottomLayout.Parent=bottom

	local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,0,0,22); t.BackgroundTransparency=1; t.Text="Auto-Sell"; t.TextColor3=Color3.fromRGB(120,170,255); t.TextXAlignment=Enum.TextXAlignment.Left; t.Font=Enum.Font.GothamBold; t.TextSize=18; t.Parent=bottom
	autoSellStatus=Instance.new("TextLabel"); autoSellStatus.Size=UDim2.new(1,0,0,38); autoSellStatus.BackgroundTransparency=1; autoSellStatus.TextWrapped=true; autoSellStatus.TextXAlignment=Enum.TextXAlignment.Left; autoSellStatus.TextYAlignment=Enum.TextYAlignment.Top; autoSellStatus.TextColor3=Color3.fromRGB(230,230,230); autoSellStatus.Font=Enum.Font.GothamBold; autoSellStatus.TextSize=14; autoSellStatus.Parent=bottom

	local controlRow=Instance.new("Frame"); controlRow.Size=UDim2.new(1,0,0,34); controlRow.BackgroundTransparency=1; controlRow.Parent=bottom
	autoSellButton=Instance.new("TextButton"); autoSellButton.Size=UDim2.fromOffset(180,34); autoSellButton.BackgroundColor3=Color3.fromRGB(70,70,80); autoSellButton.TextColor3=Color3.new(1,1,1); autoSellButton.Font=Enum.Font.GothamBold; autoSellButton.TextSize=17; autoSellButton.Parent=controlRow
	targetLabel=Instance.new("TextLabel"); targetLabel.Size=UDim2.new(1,-190,1,0); targetLabel.Position=UDim2.fromOffset(190,0); targetLabel.BackgroundTransparency=1; targetLabel.TextColor3=Color3.new(1,1,1); targetLabel.TextXAlignment=Enum.TextXAlignment.Left; targetLabel.Font=Enum.Font.GothamBold; targetLabel.TextSize=16; targetLabel.Parent=controlRow

	sliderBar=Instance.new("TextButton"); sliderBar.Size=UDim2.new(1,0,0,18); sliderBar.BackgroundColor3=Color3.fromRGB(24,42,72); sliderBar.BorderColor3=Color3.fromRGB(90,130,180); sliderBar.Text=""; sliderBar.AutoButtonColor=false; sliderBar.Parent=bottom
	sliderKnob=Instance.new("Frame"); sliderKnob.Size=UDim2.fromOffset(12,20); sliderKnob.AnchorPoint=Vector2.new(0,0.5); sliderKnob.BackgroundColor3=Color3.fromRGB(180,200,255); sliderKnob.BorderColor3=Color3.fromRGB(30,30,30); sliderKnob.Parent=sliderBar

	local function updateTargetFromX(x)
		local alpha = math.clamp((x - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
		local target = math.round((0.5 + alpha * 2.5) * 100) / 100
		context.Remotes.MarketSetAutoSellTarget:FireServer({Target=target})
	end
	sliderBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then updateTargetFromX(input.Position.X) end end)
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
	MarketApp.Refresh(context)
end
function MarketApp.SetZIndex(z) if windowRef and windowRef.SetZIndex then windowRef.SetZIndex(z) end end
function MarketApp.Unmount() if windowRef then windowRef.Destroy() end; windowRef=nil end

return MarketApp
