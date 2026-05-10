--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("NumberFormatter"))

local MarketApp = {}
local windowRef, priceLabel, deltaLabel, chartFrame, autoStatus

local function makeButton(parent, text, xScale): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.31, 0, 1, 0)
	b.Position = UDim2.new(xScale, 0, 0, 0)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(55,55,55)
	b.TextColor3 = Color3.new(1,1,1)
	b.BorderSizePixel = 0
	b.Parent = parent
	return b
end

local function renderChart(history)
	if not chartFrame then return end
	for _, c in ipairs(chartFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if type(history) ~= "table" or #history == 0 then return end
	local start = math.max(1, #history - 24)
	local minP, maxP = history[start], history[start]
	for i = start, #history do minP = math.min(minP, history[i]); maxP = math.max(maxP, history[i]) end
	local range = math.max(0.01, maxP - minP)
	local w = (chartFrame.AbsoluteSize.X - 8) / (#history - start + 1)
	for i = start, #history do
		local p = history[i]
		local prev = history[math.max(start, i - 1)]
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Size = UDim2.fromOffset(math.max(3, w - 2), math.max(8, ((p - minP) / range) * (chartFrame.AbsoluteSize.Y - 8)))
		bar.Position = UDim2.fromOffset(4 + (i - start) * w, chartFrame.AbsoluteSize.Y - 4)
		bar.BackgroundColor3 = (p - prev) >= 0 and Color3.fromRGB(55, 205, 95) or Color3.fromRGB(218, 76, 76)
		bar.BorderSizePixel = 0
		bar.Parent = chartFrame
	end
end

function MarketApp.Refresh(context)
	if windowRef and priceLabel then
		local marketState = context.State.Market or {}
		local price = marketState.Price or 1
		priceLabel.Text = string.format("Current Price Per Food: %s coins", NumberFormatter.FormatCompact(price))
		local history = marketState.History or {}
		if #history >= 2 then
			local delta = price - history[#history - 1]
			deltaLabel.Text = string.format("Delta: %+.2f", delta)
		else
			deltaLabel.Text = "Delta: n/a"
		end
		renderChart(history)
	end
end

function MarketApp.Mount(target, context)
	if windowRef then return end
	windowRef = Window.Create({Title="Market.exe", Icon="🐟", AppId="Market", Size=UDim2.fromOffset(640,460), Position=UDim2.fromOffset(500,100), Parent=target, OnClose=function() context.Controllers.Window.Close("Market") end, OnMinimize=function() context.Controllers.Window.Minimize("Market") end, OnFocus=function() context.Controllers.Window.Focus("Market") end})
	local root = windowRef.Content
	root.BackgroundColor3 = Color3.fromRGB(10, 22, 40)

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.Position = UDim2.fromOffset(0, 0)
	container.BackgroundTransparency = 1
	container.Parent = root

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = container

	local intro = Instance.new("TextLabel"); intro.Size=UDim2.new(1,0,0,22); intro.Position=UDim2.fromOffset(0,0); intro.BackgroundTransparency=1; intro.TextXAlignment=Enum.TextXAlignment.Left; intro.TextColor3=Color3.fromRGB(215,230,255); intro.Text="Sell your Food for Coins. Prices change over time. Sell high!"; intro.Parent=container
	local welcome = Instance.new("TextLabel"); welcome.Size=UDim2.new(1,0,0,22); welcome.Position=UDim2.fromOffset(0,24); welcome.BackgroundTransparency=1; welcome.TextXAlignment=Enum.TextXAlignment.Left; welcome.TextColor3=Color3.fromRGB(255,255,255); welcome.Text="Welcome to the Food Market"; welcome.Parent=container
	priceLabel = Instance.new("TextLabel"); priceLabel.Size=UDim2.new(1,0,0,22); priceLabel.Position=UDim2.fromOffset(0,48); priceLabel.BackgroundTransparency=1; priceLabel.TextXAlignment=Enum.TextXAlignment.Left; priceLabel.TextColor3=Color3.new(1,1,1); priceLabel.Parent=container
	deltaLabel = Instance.new("TextLabel"); deltaLabel.Size=UDim2.new(1,0,0,20); deltaLabel.Position=UDim2.fromOffset(0,70); deltaLabel.BackgroundTransparency=1; deltaLabel.TextXAlignment=Enum.TextXAlignment.Left; deltaLabel.TextColor3=Color3.fromRGB(170, 210, 255); deltaLabel.Parent=container

	chartFrame=Instance.new("Frame"); chartFrame.Size=UDim2.new(1,0,0.48,0); chartFrame.Position=UDim2.fromOffset(0,96); chartFrame.BackgroundColor3=Color3.fromRGB(16,32,54); chartFrame.BorderSizePixel=0; chartFrame.Parent=container

	local buttonsRow = Instance.new("Frame")
	buttonsRow.Size = UDim2.new(1, 0, 0, 36)
	buttonsRow.Position = UDim2.new(0, 0, 0.48, 106)
	buttonsRow.BackgroundTransparency = 1
	buttonsRow.Parent = container
	local b10=makeButton(buttonsRow,"Sell 10%",0)
	local sell10Remote = context.Remotes.MarketSellFood; b10.Activated:Connect(function() sell10Remote:FireServer({SellPercent=10}) end)
	local b50=makeButton(buttonsRow,"Sell 50%",0.345)
	local sell50Remote = context.Remotes.MarketSellFood; b50.Activated:Connect(function() sell50Remote:FireServer({SellPercent=50}) end)
	local all=makeButton(buttonsRow,"Sell All",0.69)
	local sellAllRemote = context.Remotes.MarketSellFood; all.Activated:Connect(function() sellAllRemote:FireServer({SellPercent=100}) end)

	local autoPanel = Instance.new("Frame"); autoPanel.AnchorPoint=Vector2.new(0,1); autoPanel.Size=UDim2.new(1,0,0,120); autoPanel.Position=UDim2.new(0,0,1,0); autoPanel.BackgroundColor3=Color3.fromRGB(16,32,54); autoPanel.BorderSizePixel=0; autoPanel.Parent=container
	local autoTitle = Instance.new("TextLabel"); autoTitle.Size=UDim2.new(1,-12,0,22); autoTitle.Position=UDim2.fromOffset(6,4); autoTitle.BackgroundTransparency=1; autoTitle.Text="Auto-Sell"; autoTitle.TextXAlignment=Enum.TextXAlignment.Left; autoTitle.TextColor3=Color3.new(1,1,1); autoTitle.Parent=autoPanel
	autoStatus = Instance.new("TextLabel"); autoStatus.Size=UDim2.new(1,-12,0,20); autoStatus.Position=UDim2.fromOffset(6,28); autoStatus.BackgroundTransparency=1; autoStatus.TextXAlignment=Enum.TextXAlignment.Left; autoStatus.TextColor3=Color3.fromRGB(190,210,255); autoStatus.Text="Status: Use existing Auto-Sell controls"; autoStatus.Parent=autoPanel
	local slider = Instance.new("TextLabel"); slider.Size=UDim2.new(1,-12,0,20); slider.Position=UDim2.fromOffset(6,52); slider.BackgroundTransparency=1; slider.TextXAlignment=Enum.TextXAlignment.Left; slider.TextColor3=Color3.fromRGB(190,210,255); slider.Text="Target Price Slider available in existing system"; slider.Parent=autoPanel
	MarketApp.Refresh(context)
end
function MarketApp.SetZIndex(z) if windowRef and windowRef.SetZIndex then windowRef.SetZIndex(z) end end
function MarketApp.Unmount() if windowRef then windowRef.Destroy() end; windowRef=nil; priceLabel=nil; deltaLabel=nil; chartFrame=nil; autoStatus=nil end
return MarketApp
