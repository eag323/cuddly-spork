--!strict
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local GeneratorConfig = require(Shared:WaitForChild("Config"):WaitForChild("GeneratorConfig"))

local FoodHarvestersApp = {}
local root: Frame?
local windowRef
local currentClass = "snack"
local selectedSlotForBuy: number? = nil
local condimentSlotView: number? = nil
local contextRef

local function getData(ctx) return (ctx.State.PlayerData or {}).Generators or { SlotsUnlocked = 3, Equipped = {} } end
local function slotOutput(slot)
	if not slot then return 0 end
	local h = GeneratorConfig.GetHarvester(slot.GeneratorId); if not h then return 0 end
	local base = h.baseFoodPerSec or 0; local c = 0
	for _, id in ipairs(slot.Condiments or {}) do local cd = GeneratorConfig.GetCondiment(id); if cd then c += (cd.foodPerSec or 0) end end
	local m = 1 + ((h.buffType == "CondimentOutput") and (h.buffValue or 0) or 0)
	return base + (c * m)
end
local function clear(frame) for _,c in ipairs(frame:GetChildren()) do if not c:IsA("UIListLayout") and not c:IsA("UIGridLayout") then c:Destroy() end end end

function FoodHarvestersApp.Refresh(context)
	if not root then return end
	contextRef = context
	clear(root)
	local data = getData(context); local slots = data.SlotsUnlocked or 3; local equipped = data.Equipped or {}
	local total = 0; for i=1,slots do total += slotOutput(equipped[i]) end
	local header = Instance.new("TextLabel"); header.Size=UDim2.new(1,0,0,54); header.BackgroundTransparency=1; header.TextXAlignment=Enum.TextXAlignment.Left; header.RichText=true; header.Font=Enum.Font.GothamBold; header.TextSize=18; header.TextColor3=Color3.new(1,1,1); header.Text=string.format("YOUR HARVESTERS    <font color='#66F5FF'>%d/%d Slots</font>\n<font color='#58FF8B'>TOTAL: %s food/sec</font>",0,slots,NumberUtil.FormatNumber(total)); header.Parent=root
	if condimentSlotView then
		local slot = equipped[condimentSlotView]; if not slot then condimentSlotView=nil; FoodHarvestersApp.Refresh(context); return end
		local h = GeneratorConfig.GetHarvester(slot.GeneratorId); if not h then return end
		local back=Instance.new("TextButton"); back.Size=UDim2.new(1,0,0,34); back.Text="← Harvesters"; back.Parent=root; back.Activated:Connect(function() condimentSlotView=nil; FoodHarvestersApp.Refresh(context) end)
		local info=Instance.new("TextLabel"); info.Size=UDim2.new(1,0,0,32); info.BackgroundTransparency=1; info.Text=string.format("%s • +%s/s • %d/%d condiments",h.displayName,NumberUtil.FormatNumber(h.baseFoodPerSec or 0), #(slot.Condiments or {}), h.condimentSlots or 0); info.TextColor3=Color3.new(1,1,1); info.Parent=root
		for _,cond in ipairs(GeneratorConfig.GetCondimentsSorted()) do local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,32); row.Text=string.format("%s  +%s/s  x%d  Cost %s",cond.displayName,NumberUtil.FormatNumber(cond.foodPerSec or 0),0,NumberUtil.FormatNumber(cond.cost or 0)); row.Parent=root; row.Activated:Connect(function() context.Controllers.Generator.BuyEquipCondiment(condimentSlotView, cond.id) end) end
		return
	end
	local grid=Instance.new("Frame"); grid.Size=UDim2.new(1,0,0,240); grid.BackgroundTransparency=1; grid.Parent=root
	local gl=Instance.new("UIGridLayout"); gl.CellSize=UDim2.fromOffset(195,112); gl.CellPadding=UDim2.fromOffset(10,10); gl.FillDirectionMaxCells=4; gl.Parent=grid
	for i=1,slots do
		local card=Instance.new("TextButton"); card.BackgroundColor3=Color3.fromRGB(21,33,57); card.Text=""; card.Parent=grid
		local slot=equipped[i]
		if slot then
			local h=GeneratorConfig.GetHarvester(slot.GeneratorId)
			card.Text = string.format("%s\n<font color='#58FF8B'>+%s/s</font>\n%d/%d condiments", (h and h.displayName) or "Unknown", NumberUtil.FormatNumber(slotOutput(slot)), #(slot.Condiments or {}), (h and h.condimentSlots) or 0)
			card.RichText=true
			card.Activated:Connect(function() condimentSlotView=i; FoodHarvestersApp.Refresh(context) end)
			local up=Instance.new("TextButton"); up.Size=UDim2.new(1,-12,0,20); up.Position=UDim2.new(0,6,1,-24); up.Text="Upgrade"; up.Parent=card; up.Activated:Connect(function() context.Controllers.Generator.AutoUpgradeCondiments(i) end)
			local rm=Instance.new("TextButton"); rm.Size=UDim2.fromOffset(18,18); rm.Position=UDim2.new(1,-20,0,2); rm.Text="🗑"; rm.Parent=card; rm.Activated:Connect(function() context.Controllers.Generator.Remove(i) end)
		else
			card.Text = "+ Add Harvester"; card.TextColor3=Color3.fromRGB(102,245,255)
			card.Activated:Connect(function() selectedSlotForBuy=i end)
		end
	end
	local shop=Instance.new("TextLabel"); shop.Size=UDim2.new(1,0,0,30); shop.BackgroundTransparency=1; shop.Text="HARVESTER SHOP"; shop.TextXAlignment=Enum.TextXAlignment.Left; shop.TextColor3=Color3.new(1,1,1); shop.Parent=root
	for _, classInfo in ipairs(GeneratorConfig.Classes) do local b=Instance.new("TextButton"); b.Size=UDim2.new(0,95,0,26); b.Text=classInfo.displayName; b.Parent=root; b.Activated:Connect(function() currentClass=classInfo.id; FoodHarvestersApp.Refresh(context) end) end
	for _, harvester in ipairs(GeneratorConfig.GetStandardHarvestersForClass(currentClass)) do local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,32); row.Text=string.format("%s  +%s/s  %d condiments  Cost %s",harvester.displayName,NumberUtil.FormatNumber(harvester.baseFoodPerSec or 0),harvester.condimentSlots or 0,NumberUtil.FormatNumber(harvester.cost or 0)); row.Parent=root; row.Activated:Connect(function() local target=selectedSlotForBuy; if not target then for i=1,slots do if not equipped[i] then target=i break end end end; if target then context.Controllers.Generator.BuyEquip(target, harvester.id) end end) end
end

function FoodHarvestersApp.Mount(target, context)
	if root then return end
	windowRef = Window.Create({Title="Food Harvesters.exe", Size=UDim2.fromOffset(850,620), Position=UDim2.fromScale(0.1,0.08), Parent=target, OnClose=function() context.Controllers.Window.Close("FoodHarvesters") end})
	local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.fromScale(1,1); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.BackgroundColor3=Color3.fromRGB(9,18,38); scroll.Parent=windowRef.Content
	root=Instance.new("Frame"); root.Size=UDim2.new(1,-8,0,1); root.BackgroundTransparency=1; root.AutomaticSize=Enum.AutomaticSize.Y; root.Parent=scroll
	local list=Instance.new("UIListLayout"); list.Padding=UDim.new(0,8); list.Parent=root
	FoodHarvestersApp.Refresh(context)
end
function FoodHarvestersApp.ShowPassiveIncomeFeedback() end
function FoodHarvestersApp.Unmount() if windowRef then windowRef.Destroy() end root=nil windowRef=nil end
return FoodHarvestersApp
