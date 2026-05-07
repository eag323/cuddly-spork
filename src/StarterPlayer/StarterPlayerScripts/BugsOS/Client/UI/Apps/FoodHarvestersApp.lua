--!strict
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local FoodHarvestersApp = {}
local root: Frame?
local windowRef
local slotLabels: { [number]: TextLabel } = {}
local slotUpgradeButtons: { [number]: TextButton } = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SharedFolder = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local NumberUtil = require(SharedFolder:WaitForChild("Util"):WaitForChild("NumberUtil"))
local GeneratorConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("GeneratorConfig"))
local generatorById = {}; for _,g in ipairs(GeneratorConfig.Generators) do generatorById[g.id]=g end
local function getPrestigeMultiplier(context) local p=(((context.State.PlayerData or {}).Progression or {}).Prestige or 0); return 1+(p*0.1) end
function FoodHarvestersApp.ShowPassiveIncomeFeedback(context, foodPerSecond)
 local parent = root or context.UI.AppsLayer; if not parent then return end
 local popup=Instance.new("TextLabel"); popup.AnchorPoint=Vector2.new(1,0); popup.Size=UDim2.fromOffset(170,26); popup.Position=UDim2.new(1,-28,0,32); popup.BackgroundTransparency=1; popup.Font=Enum.Font.GothamBold; popup.TextSize=18; popup.TextColor3=Color3.fromRGB(152,255,168); popup.TextXAlignment=Enum.TextXAlignment.Right; popup.Text=string.format("+%s Food/sec",NumberUtil.FormatNumber(foodPerSecond)); popup.Parent=parent
 TweenService:Create(popup,TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=popup.Position-UDim2.fromOffset(0,24),TextTransparency=1}):Play(); Debris:AddItem(popup,0.55)
end
function FoodHarvestersApp.Refresh(context)
 if not root then return end
 local equipped = (((context.State.PlayerData or {}).Generators or {}).Equipped)
 for i=1,3 do
  local label = slotLabels[i]
  local upgrade = slotUpgradeButtons[i]
  local entry=equipped and equipped[i]; local gen=entry and generatorById[entry.GeneratorId] or nil; local lvl=entry and entry.Level or 0
  local est=(gen and gen.baseFoodPerSec or 0)*(lvl^1.55)*getPrestigeMultiplier(context)
  if label then
   label.Text=string.format("Slot %d\n%s\nLevel %d\nFood/sec %s",i,gen and gen.displayName or "Empty Slot",lvl,NumberUtil.FormatNumber(est))
  end
  if upgrade then
   if entry then upgrade.Text=string.format("Upgrade: %s Coins", NumberUtil.FormatNumber((gen.baseUpgradeCost or 0)*(lvl^2.05))); upgrade.Visible=true else upgrade.Visible=false end
  end
 end
end
function FoodHarvestersApp.Mount(target, context)
 if root then return end
 slotLabels = {}
 slotUpgradeButtons = {}
 windowRef=Window.Create({Title="Food Harvesters.exe", Size=UDim2.fromOffset(760,500), Position=UDim2.fromScale(0.12,0.1), Parent=target, OnClose=function() context.Controllers.Window.Close("FoodHarvesters") end})
 local content=windowRef.Content
 local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.fromScale(1,1); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.ScrollBarThickness=8; scroll.Parent=content
 local list=Instance.new("UIListLayout"); list.Padding=UDim.new(0,10); list.Parent=scroll
 root=Instance.new("Frame"); root.Size=UDim2.new(1,-6,0,1); root.AutomaticSize=Enum.AutomaticSize.Y; root.BackgroundTransparency=1; root.Parent=scroll
 local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,10); layout.Parent=root
 for i=1,3 do local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,118); row.BackgroundColor3=Color3.fromRGB(38,38,46); row.Parent=root
  local label=Instance.new("TextLabel"); label.Name="SlotLabel"..i; label.Size=UDim2.new(0.52,0,1,-10); label.Position=UDim2.fromOffset(8,5); label.BackgroundTransparency=1; label.TextColor3=Color3.new(1,1,1); label.TextXAlignment=Enum.TextXAlignment.Left; label.TextYAlignment=Enum.TextYAlignment.Top; label.TextWrapped=true; label.Parent=row
  slotLabels[i] = label
  local upgrade=Instance.new("TextButton"); upgrade.Name="SlotUpgrade"..i; upgrade.Size=UDim2.fromOffset(180,32); upgrade.Position=UDim2.new(1,-188,0,8); upgrade.BackgroundColor3=Color3.fromRGB(55,55,55); upgrade.TextColor3=Color3.new(1,1,1); upgrade.Parent=row; upgrade.Activated:Connect(function() context.Controllers.Generator.Upgrade(i) end)
  slotUpgradeButtons[i] = upgrade
  local buttons={{id='plain_cracker',label='Equip Plain Cracker'},{id='potato_chip',label='Equip Potato Chip'},{id='cookie_crumb',label='Equip Cookie Crumb'}}
  for bi,info in ipairs(buttons) do local e=Instance.new("TextButton"); e.Size=UDim2.fromOffset(180,24); e.Position=UDim2.new(1,-188,0,44+((bi-1)*25)); e.BackgroundColor3=Color3.fromRGB(45,45,45); e.TextColor3=Color3.new(1,1,1); e.Text=info.label; e.TextSize=12; e.Parent=row; e.Activated:Connect(function() context.Controllers.Generator.Equip(i,info.id) end) end
 end
 FoodHarvestersApp.Refresh(context)
end
function FoodHarvestersApp.Unmount() if windowRef then windowRef.Destroy() end; root=nil; windowRef=nil; slotLabels={}; slotUpgradeButtons={} end
return FoodHarvestersApp
