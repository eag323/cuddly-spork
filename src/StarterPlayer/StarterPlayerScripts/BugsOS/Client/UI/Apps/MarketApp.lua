--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("NumberFormatter"))
local MarketplaceConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MarketplaceConfig"))

local MarketApp = {}
local windowRef, priceValueLabel, deltaLabel, chartFrame
local autoSellBody, autoSellButton, autoSellStatus, targetLabel, sliderBar, sliderKnob
local GREEN_CANDLE_ASSET = "rbxassetid://132096679740132"
local RED_CANDLE_ASSET = "rbxassetid://133082519022540"

local function clearChart(frame: Frame)
	for _, c in ipairs(frame:GetChildren()) do
		if c:IsA("Frame") or c:IsA("ImageLabel") then
			c:Destroy()
		end
	end
end

local function renderChart(history)
	if not chartFrame then return end
	clearChart(chartFrame)
	if type(history) ~= "table" or #history < 2 then return end
	local startIndex = math.max(2, #history - 19)
	local prices = {}
	for i = startIndex, #history do table.insert(prices, history[i]) end
	for g = 1, 4 do local line=Instance.new("Frame"); line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,g/5,0); line.BackgroundColor3=Color3.fromRGB(32,56,90); line.BorderSizePixel=0; line.Parent=chartFrame end
	local minP,maxP = 0.5,3.0
	local range = maxP-minP
	local cWidth = math.max(10, math.floor((chartFrame.AbsoluteSize.X - 12) / #prices))
	for idx, closePrice in ipairs(prices) do
		local openPrice = history[startIndex + idx - 2]
		local highPrice = math.max(openPrice, closePrice)
		local lowPrice = math.min(openPrice, closePrice)
		local up = closePrice >= openPrice
		local color = up and Color3.fromRGB(65, 220, 120) or Color3.fromRGB(235, 90, 90)
		local candleAsset = up and GREEN_CANDLE_ASSET or RED_CANDLE_ASSET
		local x = 6 + (idx - 1) * cWidth + math.floor(cWidth / 2)
		local function yForPrice(p) return 4 + (1 - ((p - minP) / range)) * (chartFrame.AbsoluteSize.Y - 8) end
		local yHigh,yLow = yForPrice(highPrice), yForPrice(lowPrice)
		local wick=Instance.new("Frame"); wick.Size=UDim2.fromOffset(1, math.max(2, yLow-yHigh)); wick.Position=UDim2.fromOffset(x, yHigh); wick.BackgroundColor3=color; wick.BorderSizePixel=0; wick.Parent=chartFrame
		local yOpen,yClose = yForPrice(openPrice), yForPrice(closePrice)
		local yTop,yBottom = math.min(yOpen,yClose), math.max(yOpen,yClose)
		local bodyWidth = math.max(8, cWidth - 3)
		local bodyHeight = math.max(4, yBottom - yTop)
		local body=Instance.new("ImageLabel"); body.Size=UDim2.fromOffset(bodyWidth, bodyHeight); body.Position=UDim2.fromOffset(x - math.floor(bodyWidth / 2), yTop); body.BackgroundTransparency=1; body.Image=candleAsset; body.ScaleType=Enum.ScaleType.Stretch; body.Parent=chartFrame
		local border=Instance.new("Frame"); border.Size=UDim2.fromOffset(bodyWidth, bodyHeight); border.Position=body.Position; border.BackgroundTransparency=1; border.BorderSizePixel=1; border.BorderColor3=color; border.Parent=chartFrame
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
		autoSellStatus.Text = "Auto-Sell automatically sells your Food when the market reaches your selected price."
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
	windowRef = Window.Create({Title="Market.exe", Icon="🐟", AppId="Market", Size=UDim2.fromOffset(720,500), Position=UDim2.fromOffset(460,80), Parent=target, OnClose=function() context.Controllers.Window.Close("Market") end, OnMinimize=function() context.Controllers.Window.Minimize("Market") end, OnFocus=function() context.Controllers.Window.Focus("Market") end})
	local root = windowRef.Content; root.BackgroundColor3 = Color3.fromRGB(10, 22, 40)
	local container = Instance.new("Frame"); container.Size=UDim2.fromScale(1,1); container.BackgroundTransparency=1; container.Parent=root
	local padding = Instance.new("UIPadding"); padding.PaddingTop=UDim.new(0,8); padding.PaddingBottom=UDim.new(0,8); padding.PaddingLeft=UDim.new(0,8); padding.PaddingRight=UDim.new(0,8); padding.Parent=container
	local stack = Instance.new("UIListLayout"); stack.FillDirection=Enum.FillDirection.Vertical; stack.Padding=UDim.new(0,10); stack.Parent=container
	local top = Instance.new("Frame"); top.Size=UDim2.new(1,0,0.68,0); top.BackgroundColor3=Color3.fromRGB(18,34,58); top.BorderColor3=Color3.fromRGB(65,140,200); top.Parent=container
	local bottom = Instance.new("Frame"); bottom.Size=UDim2.new(1,0,0.32,0); bottom.BackgroundColor3=Color3.fromRGB(18,34,58); bottom.BorderColor3=Color3.fromRGB(65,140,200); bottom.Parent=container
	local intro=Instance.new("TextLabel"); intro.Size=UDim2.new(1,-12,0,20); intro.Position=UDim2.fromOffset(6,6); intro.BackgroundTransparency=1; intro.TextXAlignment=Enum.TextXAlignment.Left; intro.TextColor3=Color3.fromRGB(215,230,255); intro.Text="Sell your Food for Coins. Prices change every 30 seconds. Sell high!"; intro.Font=Enum.Font.GothamBold; intro.TextSize=15; intro.Parent=top
	local cpl=Instance.new("TextLabel"); cpl.Size=UDim2.new(1,-12,0,22); cpl.Position=UDim2.fromOffset(6,30); cpl.BackgroundTransparency=1; cpl.Text="Current Price Per Food"; cpl.TextXAlignment=Enum.TextXAlignment.Left; cpl.TextColor3=Color3.fromRGB(255,255,255); cpl.Font=Enum.Font.GothamBold; cpl.TextSize=17; cpl.Parent=top
	priceValueLabel=Instance.new("TextLabel"); priceValueLabel.Size=UDim2.new(0.48,-12,0,44); priceValueLabel.Position=UDim2.fromOffset(6,52); priceValueLabel.BackgroundTransparency=1; priceValueLabel.TextXAlignment=Enum.TextXAlignment.Left; priceValueLabel.Font=Enum.Font.GothamBold; priceValueLabel.TextSize=38; priceValueLabel.TextColor3=Color3.fromRGB(255,215,90); priceValueLabel.Parent=top
	deltaLabel=Instance.new("TextLabel"); deltaLabel.Size=UDim2.new(0.52,-12,0,44); deltaLabel.Position=UDim2.new(0.48,0,0,52); deltaLabel.BackgroundTransparency=1; deltaLabel.TextXAlignment=Enum.TextXAlignment.Left; deltaLabel.Font=Enum.Font.GothamBold; deltaLabel.TextSize=30; deltaLabel.TextColor3=Color3.fromRGB(170,170,170); deltaLabel.Parent=top
	chartFrame=Instance.new("Frame"); chartFrame.Size=UDim2.new(1,-12,0,190); chartFrame.Position=UDim2.fromOffset(6,100); chartFrame.BackgroundColor3=Color3.fromRGB(8,16,30); chartFrame.BorderColor3=Color3.fromRGB(56,90,130); chartFrame.Parent=top
	local row=Instance.new("Frame"); row.Size=UDim2.new(1,-12,0,40); row.Position=UDim2.fromOffset(6,300); row.BackgroundTransparency=1; row.Parent=top
	local function makeButton(t,x,c)
		local b=Instance.new("TextButton"); b.Size=UDim2.new(0.32,0,1,0); b.Position=UDim2.new(x,0,0,0); b.Text=t; b.BackgroundColor3=c; b.TextColor3=Color3.new(1,1,1); b.BorderSizePixel=0; b.Font=Enum.Font.GothamBold; b.TextSize=18; b.Parent=row; return b end
	local sell10Remote=context.Remotes.MarketSellFood; makeButton("Sell 10%",0,Color3.fromRGB(15,25,140)).Activated:Connect(function() sell10Remote:FireServer({SellPercent=10}) end)
	local sell50Remote=context.Remotes.MarketSellFood; makeButton("Sell 50%",0.34,Color3.fromRGB(20,130,70)).Activated:Connect(function() sell50Remote:FireServer({SellPercent=50}) end)
	local sellAllRemote=context.Remotes.MarketSellFood; makeButton("Sell All",0.68,Color3.fromRGB(230,70,90)).Activated:Connect(function() sellAllRemote:FireServer({SellPercent=100}) end)
	autoSellBody=bottom
	local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,-12,0,22); t.Position=UDim2.fromOffset(6,8); t.BackgroundTransparency=1; t.Text="Auto-Sell"; t.TextColor3=Color3.fromRGB(120,170,255); t.TextXAlignment=Enum.TextXAlignment.Left; t.Font=Enum.Font.GothamBold; t.TextSize=18; t.Parent=bottom
	autoSellStatus=Instance.new("TextLabel"); autoSellStatus.Size=UDim2.new(1,-12,0,38); autoSellStatus.Position=UDim2.fromOffset(6,34); autoSellStatus.BackgroundTransparency=1; autoSellStatus.TextWrapped=true; autoSellStatus.TextXAlignment=Enum.TextXAlignment.Left; autoSellStatus.TextYAlignment=Enum.TextYAlignment.Top; autoSellStatus.TextColor3=Color3.fromRGB(230,230,230); autoSellStatus.Font=Enum.Font.GothamBold; autoSellStatus.TextSize=14; autoSellStatus.Parent=bottom
	autoSellButton=Instance.new("TextButton"); autoSellButton.Size=UDim2.fromOffset(160,34); autoSellButton.Position=UDim2.fromOffset(6,74); autoSellButton.BackgroundColor3=Color3.fromRGB(70,70,80); autoSellButton.TextColor3=Color3.new(1,1,1); autoSellButton.Font=Enum.Font.GothamBold; autoSellButton.TextSize=17; autoSellButton.Parent=bottom
	targetLabel=Instance.new("TextLabel"); targetLabel.Size=UDim2.new(0.45,0,0,24); targetLabel.Position=UDim2.fromOffset(176,80); targetLabel.BackgroundTransparency=1; targetLabel.TextColor3=Color3.new(1,1,1); targetLabel.TextXAlignment=Enum.TextXAlignment.Left; targetLabel.Font=Enum.Font.GothamBold; targetLabel.TextSize=16; targetLabel.Parent=bottom
	sliderBar=Instance.new("TextButton"); sliderBar.Size=UDim2.new(1,-18,0,18); sliderBar.Position=UDim2.fromOffset(6,118); sliderBar.BackgroundColor3=Color3.fromRGB(24,42,72); sliderBar.BorderColor3=Color3.fromRGB(90,130,180); sliderBar.Text=""; sliderBar.AutoButtonColor=false; sliderBar.Parent=bottom
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
