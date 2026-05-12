--!strict
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local GeneratorConfig = require(Shared:WaitForChild("Config"):WaitForChild("GeneratorConfig"))

local FoodHarvestersApp = {}

local root: Frame?
local windowRef
local contentFrame: Frame?
local notificationLabel: TextLabel?
local contextRef

local state = {
	mode = "main" :: "main" | "detail",
	selectedClass = "snack",
	selectedSlot = nil :: number?,
}

local COLORS = {
	background = Color3.fromRGB(8, 18, 39),
	panel = Color3.fromRGB(19, 36, 64),
	panelAlt = Color3.fromRGB(23, 44, 74),
	stroke = Color3.fromRGB(66, 97, 138),
	text = Color3.fromRGB(240, 246, 255),
	muted = Color3.fromRGB(160, 184, 212),
	positive = Color3.fromRGB(76, 255, 150),
	buff = Color3.fromRGB(255, 208, 92),
	cyan = Color3.fromRGB(102, 245, 255),
	button = Color3.fromRGB(32, 225, 160),
}

local function getData(ctx)
	return (ctx.State.PlayerData or {}).Generators or { SlotsUnlocked = 3, Equipped = {} }
end

local function clear(frame: Instance)
	for _, child in ipairs(frame:GetChildren()) do
		child:Destroy()
	end
end

local function slotOutput(slot)
	if not slot then return 0 end
	local h = GeneratorConfig.GetHarvester(slot.GeneratorId)
	if not h then return 0 end
	local condimentOutput = 0
	for _, id in ipairs(slot.Condiments or {}) do
		local cd = GeneratorConfig.GetCondiment(id)
		if cd then condimentOutput += (cd.foodPerSec or 0) end
	end
	local multiplier = 1 + ((h.buff == "CondimentOutput") and (h.buffValue or 0) or 0)
	return (h.baseFoodPerSec or 0) + condimentOutput * multiplier
end

local function setNotification(text: string)
	if notificationLabel then
		notificationLabel.Text = text
		task.delay(2, function()
			if notificationLabel and notificationLabel.Text == text then
				notificationLabel.Text = ""
			end
		end)
	end
end

local function mk(parent: Instance, className: string, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

local function buildHarvesterRow(parent: Instance, harvester, onBuy: () -> ())
	local row = mk(parent, "Frame", { Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = COLORS.panelAlt, BorderSizePixel = 0 })
	mk(row, "UICorner", { CornerRadius = UDim.new(0, 6) })
	mk(row, "UIStroke", { Color = COLORS.stroke, Thickness = 1 })
	local icon = mk(row, "ImageLabel", { Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(12, 15), BackgroundTransparency = 1, Image = harvester.icon or "" })
	icon.ScaleType = Enum.ScaleType.Fit
	mk(row, "TextLabel", { Size = UDim2.new(1, -220, 0, 25), Position = UDim2.fromOffset(64, 10), BackgroundTransparency = 1, Text = harvester.displayName, TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left })
	local detail = string.format("+%s/s • %d slots", NumberUtil.FormatNumber(harvester.baseFoodPerSec or 0), harvester.condimentSlots or 0)
	if harvester.buffText and harvester.buffText ~= "None" then detail = detail .. (" • " .. harvester.buffText) end
	mk(row, "TextLabel", { Size = UDim2.new(1, -220, 0, 20), Position = UDim2.fromOffset(64, 38), BackgroundTransparency = 1, Text = detail, TextColor3 = COLORS.muted, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
	mk(row, "TextButton", { Size = UDim2.fromOffset(140, 40), Position = UDim2.new(1, -152, 0.5, -20), BackgroundColor3 = Color3.fromRGB(209, 214, 220), Text = string.format("%s coins", NumberUtil.FormatNumber(harvester.cost or 0)), TextColor3 = Color3.fromRGB(25, 30, 39), Font = Enum.Font.GothamBold, TextSize = 16 }).Activated:Connect(onBuy)
end

local function refresh(context)
	if not contentFrame then return end
	contextRef = context
	clear(contentFrame)
	local data = getData(context)
	local slots = data.SlotsUnlocked or 3
	local equipped = data.Equipped or {}

	if state.mode == "detail" then
		local slot = state.selectedSlot and equipped[state.selectedSlot] or nil
		if not slot then state.mode = "main" return refresh(context) end
		local harvester = GeneratorConfig.GetHarvester(slot.GeneratorId)
		if not harvester then state.mode = "main" return refresh(context) end

		mk(contentFrame, "TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = COLORS.panel, BorderSizePixel = 0, Text = string.format("← Harvesters    %s • +%s/s • %d/%d equip", harvester.displayName, NumberUtil.FormatNumber(harvester.baseFoodPerSec or 0), #(slot.Condiments or {}), harvester.condimentSlots or 0), TextColor3 = COLORS.buff, Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left }).Activated:Connect(function() state.mode = "main" refresh(contextRef) end)

		local visual = mk(contentFrame, "Frame", { Size = UDim2.new(1, 0, 0, 290), BackgroundColor3 = Color3.fromRGB(31, 95, 150), BorderSizePixel = 0 })
		mk(visual, "UICorner", { CornerRadius = UDim.new(0, 6) })
		local center = mk(visual, "ImageLabel", { Size = UDim2.fromOffset(120, 120), Position = UDim2.new(0.5, -60, 0.5, -60), BackgroundColor3 = Color3.fromRGB(77, 129, 175), BackgroundTransparency = 0.4, BorderSizePixel = 0, Image = harvester.icon or "" })
		center.ScaleType = Enum.ScaleType.Fit
		local positions = { UDim2.new(0.35, -20, 0.38, -20), UDim2.new(0.62, -20, 0.38, -20), UDim2.new(0.35, -20, 0.65, -20), UDim2.new(0.62, -20, 0.65, -20), UDim2.new(0.48, -20, 0.25, -20), UDim2.new(0.48, -20, 0.78, -20) }
		for i = 1, (harvester.condimentSlots or 0) do
			local condId = slot.Condiments and slot.Condiments[i]
			mk(visual, "ImageLabel", { Size = UDim2.fromOffset(40, 40), Position = positions[i] or UDim2.new(0.1 + ((i - 1) * 0.12), 0, 0.7, 0), BackgroundColor3 = Color3.fromRGB(158, 198, 227), BorderSizePixel = 0, Image = condId and (GeneratorConfig.GetCondiment(condId) and GeneratorConfig.GetCondiment(condId).icon or "") or "", ScaleType = Enum.ScaleType.Fit })
			if not condId then mk(visual, "TextLabel", { Size = UDim2.fromOffset(40, 40), Position = positions[i] or UDim2.new(0.1 + ((i - 1) * 0.12), 0, 0.7, 0), BackgroundTransparency = 1, Text = "+", TextColor3 = Color3.fromRGB(133, 146, 163), Font = Enum.Font.GothamBold, TextSize = 22 }) end
		end

		mk(contentFrame, "TextLabel", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = string.format("CONDIMENT (%d/%d slots)", #(slot.Condiments or {}), harvester.condimentSlots or 0), TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left })
		for _, condiment in ipairs(GeneratorConfig.GetCondimentsSorted()) do
			local count = 0
			for _, id in ipairs(slot.Condiments or {}) do if id == condiment.id then count += 1 end end
			buildHarvesterRow(contentFrame, { displayName = condiment.displayName, baseFoodPerSec = condiment.foodPerSec, condimentSlots = count, buffText = "x" .. tostring(count), cost = condiment.cost, icon = condiment.icon }, function()
				if #(slot.Condiments or {}) >= (harvester.condimentSlots or 0) then setNotification("No empty condiment slots") return end
				context.Controllers.Generator.BuyEquipCondiment(state.selectedSlot, condiment.id)
			end)
		end
		return
	end

	local scroll = mk(contentFrame, "ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8 })
	local list = mk(scroll, "UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	mk(scroll, "UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10) })

	local total = 0
	local used = 0
	for i = 1, slots do
		total += slotOutput(equipped[i])
		if equipped[i] then used += 1 end
	end
	mk(scroll, "TextLabel", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = COLORS.text, Text = string.format("YOUR HARVESTERS    <font color='#66F5FF'>%d/%d Slots</font>\n<font color='#58FF8B'>TOTAL: %s food/sec</font>", used, slots, NumberUtil.FormatNumber(total)) })

	local gridWrap = mk(scroll, "Frame", { Size = UDim2.new(1, 0, 0, 250), BackgroundTransparency = 1 })
	local grid = mk(gridWrap, "UIGridLayout", { CellPadding = UDim2.fromOffset(10, 10), CellSize = UDim2.new(0.25, -8, 0, 170), SortOrder = Enum.SortOrder.LayoutOrder })
	if windowRef and windowRef.Content.AbsoluteSize.X < 780 then grid.CellSize = UDim2.new(1 / 3, -8, 0, 170) end

	for i = 1, slots do
		local slot = equipped[i]
		local card = mk(gridWrap, "Frame", { BackgroundColor3 = COLORS.panel, BorderSizePixel = 0 })
		mk(card, "UICorner", { CornerRadius = UDim.new(0, 6) }); mk(card, "UIStroke", { Color = COLORS.stroke })
		if slot then
			local h = GeneratorConfig.GetHarvester(slot.GeneratorId)
			if h then
				mk(card, "ImageLabel", { Size = UDim2.fromOffset(52, 52), Position = UDim2.new(0.5, -26, 0, 8), BackgroundTransparency = 1, Image = h.icon or "", ScaleType = Enum.ScaleType.Fit })
				mk(card, "TextLabel", { Size = UDim2.new(1, -12, 0, 20), Position = UDim2.fromOffset(6, 64), BackgroundTransparency = 1, Text = h.displayName, TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 16 })
				mk(card, "TextLabel", { Size = UDim2.new(1, -12, 0, 18), Position = UDim2.fromOffset(6, 84), BackgroundTransparency = 1, Text = "+" .. NumberUtil.FormatNumber(slotOutput(slot)) .. "/s", TextColor3 = COLORS.positive, Font = Enum.Font.GothamBold, TextSize = 15 })
				mk(card, "TextLabel", { Size = UDim2.new(1, -12, 0, 16), Position = UDim2.fromOffset(6, 102), BackgroundTransparency = 1, Text = string.format("%d/%d condiment slots", #(slot.Condiments or {}), h.condimentSlots or 0), TextColor3 = COLORS.muted, Font = Enum.Font.Gotham, TextSize = 13 })
				mk(card, "TextLabel", { Size = UDim2.new(1, -12, 0, 16), Position = UDim2.fromOffset(6, 118), BackgroundTransparency = 1, Text = h.buffText or "", TextColor3 = COLORS.buff, Font = Enum.Font.GothamBold, TextSize = 12 })
				mk(card, "TextButton", { Size = UDim2.new(1, -12, 0, 24), Position = UDim2.new(0, 6, 1, -30), BackgroundColor3 = COLORS.button, BorderSizePixel = 0, Text = "Upgrade", TextColor3 = Color3.fromRGB(12, 35, 26), Font = Enum.Font.GothamBold, TextSize = 14 }).Activated:Connect(function() context.Controllers.Generator.AutoUpgradeCondiments(i) end)
				mk(card, "TextButton", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -22, 0, 4), BackgroundTransparency = 1, Text = "🗑", TextSize = 14 }).Activated:Connect(function() context.Controllers.Generator.Remove(i) end)
				mk(card, "TextButton", { Size = UDim2.new(1, 0, 1, -34), Position = UDim2.new(), BackgroundTransparency = 1, Text = "" }).Activated:Connect(function() state.mode = "detail" state.selectedSlot = i refresh(contextRef) end)
			end
		else
			mk(card, "TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(16, 29, 51), Text = "+ Add Harvester", TextColor3 = COLORS.cyan, Font = Enum.Font.GothamBold, TextSize = 20 }).Activated:Connect(function() setNotification("Select a harvester below") end)
		end
	end

	mk(scroll, "TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "HARVESTER SHOP", TextColor3 = COLORS.buff, Font = Enum.Font.GothamBold, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left })
	local tabRow = mk(scroll, "Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })
	local tabLayout = mk(tabRow, "UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) })
	for _, c in ipairs(GeneratorConfig.Classes) do
		local selected = c.id == state.selectedClass
		mk(tabRow, "TextButton", { Size = UDim2.fromOffset(102, 36), BackgroundColor3 = selected and COLORS.cyan or COLORS.panel, BorderSizePixel = 0, Text = c.displayName, TextColor3 = selected and Color3.fromRGB(8, 22, 44) or COLORS.text, Font = Enum.Font.GothamBold, TextSize = 15 }).Activated:Connect(function() state.selectedClass = c.id refresh(contextRef) end)
	end

	mk(scroll, "TextLabel", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "STANDARD HARVESTERS", TextColor3 = COLORS.cyan, Font = Enum.Font.GothamBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left })
	for _, h in ipairs(GeneratorConfig.GetStandardHarvestersForClass(state.selectedClass)) do
		buildHarvesterRow(scroll, h, function()
			local targetSlot = nil
			for i = 1, slots do if not equipped[i] then targetSlot = i break end end
			if not targetSlot then setNotification("No empty harvester slots") return end
			context.Controllers.Generator.BuyEquip(targetSlot, h.id)
		end)
	end

	local skins = GeneratorConfig.GetSkinHarvestersForClass(state.selectedClass)
	if #skins > 0 then
		mk(scroll, "TextLabel", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "SKIN HARVESTERS", TextColor3 = COLORS.buff, Font = Enum.Font.GothamBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left })
		for _, h in ipairs(skins) do
			buildHarvesterRow(scroll, h, function()
				local targetSlot = nil
				for i = 1, slots do if not equipped[i] then targetSlot = i break end end
				if not targetSlot then setNotification("No empty harvester slots") return end
				context.Controllers.Generator.BuyEquip(targetSlot, h.id)
			end)
		end
	end

	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() gridWrap.Size = UDim2.new(1, 0, 0, math.max(180, grid.AbsoluteContentSize.Y)) end)
	gridWrap.Size = UDim2.new(1, 0, 0, math.max(180, grid.AbsoluteContentSize.Y))
end

function FoodHarvestersApp.Refresh(context)
	refresh(context)
end

function FoodHarvestersApp.Mount(target, context)
	if root then return end
	windowRef = Window.Create({ Title = "Food Harvesters.exe", Size = UDim2.fromOffset(860, 640), Position = UDim2.fromScale(0.1, 0.08), Parent = target, OnClose = function() context.Controllers.Window.Close("FoodHarvesters") end })
	root = mk(windowRef.Content, "Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = COLORS.background, BorderSizePixel = 0 })
	mk(root, "UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 8) })
	contentFrame = mk(root, "Frame", { Size = UDim2.new(1, 0, 1, -28), BackgroundTransparency = 1 })
	notificationLabel = mk(root, "TextLabel", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -22), BackgroundTransparency = 1, Text = "", TextColor3 = COLORS.buff, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
	refresh(context)
end

function FoodHarvestersApp.ShowPassiveIncomeFeedback() end

function FoodHarvestersApp.Unmount()
	if windowRef then windowRef.Destroy() end
	root = nil
	contentFrame = nil
	notificationLabel = nil
	windowRef = nil
	contextRef = nil
	state.mode = "main"
	state.selectedSlot = nil
end

return FoodHarvestersApp
