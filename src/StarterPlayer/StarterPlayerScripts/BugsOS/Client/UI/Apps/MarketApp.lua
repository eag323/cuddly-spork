--!strict
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local MarketApp = {}
local windowRef, priceLabel
local function makeButton(parent, text, x): TextButton local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(160,36); b.Position=UDim2.new(0,x,1,-44); b.Text=text; b.BackgroundColor3=Color3.fromRGB(55,55,55); b.TextColor3=Color3.new(1,1,1); b.Parent=parent; return b end
function MarketApp.Refresh(context) if windowRef and priceLabel then priceLabel.Text=string.format("Current Price: %.2f coins/food", context.State.Market.Price or 1) end end
function MarketApp.Mount(target, context)
	if windowRef then return end
	windowRef = Window.Create({Title="Market.exe", Icon="🐟", AppId="Market", Size=UDim2.fromOffset(560,380), Position=UDim2.fromOffset(520,120), Parent=target, OnClose=function() context.Controllers.Window.Close("Market") end, OnFocus=function() context.Controllers.Window.Focus("Market") end})
	local root = windowRef.Content
	priceLabel = Instance.new("TextLabel"); priceLabel.Size=UDim2.new(1,-10,0,30); priceLabel.BackgroundTransparency=1; priceLabel.TextXAlignment=Enum.TextXAlignment.Left; priceLabel.TextColor3=Color3.new(1,1,1); priceLabel.Parent=root
	local history=Instance.new("TextLabel"); history.Size=UDim2.new(1,-10,1,-96); history.Position=UDim2.fromOffset(0,36); history.BackgroundColor3=Color3.fromRGB(45,45,45); history.TextColor3=Color3.new(1,1,1); history.Text="Price History (placeholder)"; history.Parent=root
	local b10=makeButton(root,"Sell 10%",10); b10.Activated:Connect(function() context.Remotes.MarketSellFood:FireServer({SellPercent=10}) end)
	local b50=makeButton(root,"Sell 50%",190); b50.Activated:Connect(function() context.Remotes.MarketSellFood:FireServer({SellPercent=50}) end)
	local all=makeButton(root,"Sell All",370); all.Activated:Connect(function() context.Remotes.MarketSellFood:FireServer({SellPercent=100}) end)
	MarketApp.Refresh(context)
end
function MarketApp.SetZIndex(z) if windowRef and windowRef.SetZIndex then windowRef.SetZIndex(z) end end
function MarketApp.Unmount() if windowRef then windowRef.Destroy() end; windowRef=nil; priceLabel=nil end
return MarketApp
