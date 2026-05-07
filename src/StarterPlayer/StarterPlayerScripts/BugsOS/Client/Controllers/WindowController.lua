--!strict
local MarketApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("MarketApp"))
local UpgradesApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("UpgradesApp"))
local FoodHarvestersApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("FoodHarvestersApp"))
local PrestigeApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("PrestigeApp"))
local BugFarmApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("BugFarmApp"))
local BugdexApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("BugdexApp"))
local WindowController, context, openApps = {}, nil, {}
local APP_DEFS={{id='Market',title='Market.exe',app=MarketApp},{id='Upgrades',title='Upgrades.exe',app=UpgradesApp},{id='FoodHarvesters',title='Food Harvesters.exe',app=FoodHarvestersApp},{id='BugFarm',title='Bug Farm.exe',app=BugFarmApp},{id='Bugdex',title='Bugdex.exe',app=BugdexApp},{id='Prestige',title='Prestige.exe',app=PrestigeApp}}
function WindowController.Init(c) context=c end
function WindowController.Open(id) if openApps[id] then return end for _,d in APP_DEFS do if d.id==id then d.app.Mount(context.UI.AppsLayer,context); openApps[id]=true; return end end end
function WindowController.Close(id) for _,d in APP_DEFS do if d.id==id then d.app.Unmount(); openApps[id]=nil; return end end end
function WindowController.Start()
 local holder=Instance.new('ScrollingFrame'); holder.Name='TaskbarButtons'; holder.Size=UDim2.new(1,-16,1,-10); holder.Position=UDim2.fromOffset(8,5); holder.BackgroundTransparency=1; holder.BorderSizePixel=0; holder.ScrollBarThickness=6; holder.ScrollingDirection=Enum.ScrollingDirection.X; holder.Parent=context.UI.Taskbar
 local layout=Instance.new('UIListLayout'); layout.FillDirection=Enum.FillDirection.Horizontal; layout.Padding=UDim.new(0,8); layout.Parent=holder
 local pad=Instance.new('UIPadding'); pad.PaddingLeft=UDim.new(0,2); pad.Parent=holder
 layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() holder.CanvasSize=UDim2.fromOffset(layout.AbsoluteContentSize.X+12,0) end)
 for _,d in APP_DEFS do local b=Instance.new('TextButton'); b.Name=d.id..'Button'; b.Size=UDim2.fromOffset(180,40); b.BackgroundColor3=Color3.fromRGB(52,52,52); b.TextColor3=Color3.new(1,1,1); b.TextSize=14; b.Text=d.title; b.Parent=holder; b.Activated:Connect(function() if openApps[d.id] then WindowController.Close(d.id) else WindowController.Open(d.id) end end) end
end
return WindowController
