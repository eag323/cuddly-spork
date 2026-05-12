--!strict
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local UIAssets = require(script.Parent.Parent:WaitForChild("UIAssets"))
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
local mainScrollRef: ScrollingFrame?
local lastRefreshSignature: string? = nil

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
	upgradeButton = Color3.fromRGB(34, 220, 150),
	upgradeButtonStroke = Color3.fromRGB(18, 140, 95),
	shopButton = Color3.fromRGB(209, 214, 220),
	shopButtonStroke = Color3.fromRGB(138, 146, 156),
	slotUpsell = Color3.fromRGB(255, 185, 55),
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
	local buyButton = mk(row, "TextButton", { Size = UDim2.fromOffset(152, 40), Position = UDim2.new(1, -164, 0.5, -20), BackgroundColor3 = COLORS.shopButton, Text = string.format("💰 %s coins", NumberUtil.FormatNumber(harvester.cost or 0)), TextColor3 = Color3.fromRGB(25, 30, 39), Font = Enum.Font.GothamBold, TextSize = 15, TextScaled = true })
	mk(buyButton, "UICorner", { CornerRadius = UDim.new(0, 6) })
	mk(buyButton, "UIStroke", { Color = COLORS.shopButtonStroke, Thickness = 1.5 })
	mk(buyButton, "UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 12 })
	buyButton.Activated:Connect(onBuy)
end

local function getPrestigeLevel(ctx)
	local playerData = ctx.State.PlayerData or {}
	local prestigeData = playerData.Prestige
	local level = tonumber((type(prestigeData) == "table" and prestigeData.Level) or playerData.PrestigeLevel) or 0
	return level
end

local function isClassUnlocked(ctx, classInfo)
	local required = tonumber(classInfo.unlockPrestige) or 0
	return getPrestigeLevel(ctx) >= required, required
end

local function buildHarvesterSignature(context)
	local data = getData(context)
	local equipped = data.Equipped or {}
	local slotParts = {}
	for i = 1, (data.SlotsUnlocked or 3) do
		local slot = equipped[i]
		if type(slot) == "table" then
			table.insert(slotParts, string.format("%d:%s:%d", i, tostring(slot.GeneratorId), #(slot.Condiments or {})))
		else
			table.insert(slotParts, string.format("%d:-:0", i))
		end
	end
	return table.concat({
		"mode=" .. tostring(state.mode),
		"class=" .. tostring(state.selectedClass),
		"slot=" .. tostring(state.selectedSlot),
		"slots=" .. tostring(data.SlotsUnlocked or 3),
		"equipped=" .. table.concat(slotParts, "|"),
		"prestige=" .. tostring(getPrestigeLevel(context)),
	}, ";")
end

local function refresh(context, resetScroll: boolean?)
	if not root or not contentFrame then return end
	contextRef = context
	local previousCanvasPosition = if mainScrollRef then mainScrollRef.CanvasPosition else Vector2.zero
	local previousMode = state.mode
	local previousClass = state.selectedClass
	clear(contentFrame)
	mainScrollRef = nil
	local data = getData(context)
	local slots = data.SlotsUnlocked or 3
	local equipped = data.Equipped or {}

	if state.mode == "detail" then
		local slot = state.selectedSlot and equipped[state.selectedSlot] or nil
		if not slot then state.mode = "main" return refresh(context) end
		local harvester = GeneratorConfig.GetHarvester(slot.GeneratorId)
		if not harvester then state.mode = "main" return refresh(context) end

		local detailScroll = mk(contentFrame, "ScrollingFrame", {
			Name = "DetailScroll",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 8,
			CanvasPosition = Vector2.zero,
		})
		mk(detailScroll, "UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10) })
		mk(detailScroll, "UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

		local detailHeader = mk(detailScroll, "Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 })
		local backButton = mk(detailHeader, "TextButton", { Size = UDim2.fromOffset(132, 36), Position = UDim2.fromOffset(0, 0), BackgroundColor3 = COLORS.panel, BorderSizePixel = 0, Text = "← Harvesters", TextColor3 = COLORS.buff, Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left })
		mk(backButton, "UICorner", { CornerRadius = UDim.new(0, 6) })
		mk(detailHeader, "TextLabel", { Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(140, 0), BackgroundTransparency = 1, Text = string.format("%s • +%s/s • %d/%d condiment slots", harvester.displayName, NumberUtil.FormatNumber(harvester.baseFoodPerSec or 0), #(slot.Condiments or {}), harvester.condimentSlots or 0), TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left })
		backButton.Activated:Connect(function() state.mode = "main" refresh(contextRef, true) end)

		local visual = mk(detailScroll, "Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 290), BackgroundColor3 = Color3.fromRGB(31, 95, 150), BorderSizePixel = 0 })
		mk(visual, "UICorner", { CornerRadius = UDim.new(0, 6) })
		local center = mk(visual, "ImageLabel", { Size = UDim2.fromOffset(120, 120), Position = UDim2.new(0.5, -60, 0.5, -60), BackgroundColor3 = Color3.fromRGB(77, 129, 175), BackgroundTransparency = 0.4, BorderSizePixel = 0, Image = harvester.icon or "" })
		center.ScaleType = Enum.ScaleType.Fit
		for i = 1, (harvester.condimentSlots or 0) do
			local condId = slot.Condiments and slot.Condiments[i]
			local columns = math.clamp(math.ceil(math.sqrt(harvester.condimentSlots or 1)), 2, 6)
			local row = math.floor((i - 1) / columns)
			local col = (i - 1) % columns
			local x = 0.1 + (col * (0.8 / math.max(columns - 1, 1)))
			local y = 0.68 + (row * 0.13)
			local slotBox = mk(visual, "ImageLabel", { Size = UDim2.fromOffset(34, 34), Position = UDim2.new(x, -17, y, -17), BackgroundColor3 = Color3.fromRGB(158, 198, 227), BorderSizePixel = 0, Image = condId and (GeneratorConfig.GetCondiment(condId) and GeneratorConfig.GetCondiment(condId).icon or "") or "", ScaleType = Enum.ScaleType.Fit })
			mk(slotBox, "UICorner", { CornerRadius = UDim.new(0, 4) })
			if not condId then mk(visual, "TextLabel", { Size = UDim2.fromOffset(34, 34), Position = UDim2.new(x, -17, y, -17), BackgroundTransparency = 1, Text = "+", TextColor3 = Color3.fromRGB(133, 146, 163), Font = Enum.Font.GothamBold, TextSize = 18 }) end
			if condId then
				mk(slotBox, "TextButton", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -12, 0, -2), BackgroundColor3 = Color3.fromRGB(220, 84, 84), BorderSizePixel = 0, Text = "❌", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 8, ZIndex = 5 }).Activated:Connect(function()
					context.Controllers.Generator.RemoveCondiment(state.selectedSlot, i)
				end)
			end
		end

		mk(detailScroll, "TextLabel", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = string.format("CONDIMENTS (%d/%d slots)", #(slot.Condiments or {}), harvester.condimentSlots or 0), TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left })
		local condimentList = mk(detailScroll, "Frame", { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
		mk(condimentList, "UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
		for _, condiment in ipairs(GeneratorConfig.GetCondimentsSorted()) do
			local count = 0
			for _, id in ipairs(slot.Condiments or {}) do if id == condiment.id then count += 1 end end
			buildHarvesterRow(condimentList, { displayName = condiment.displayName, baseFoodPerSec = condiment.foodPerSec, condimentSlots = count, buffText = "x" .. tostring(count), cost = condiment.cost, icon = condiment.icon }, function()
				if #(slot.Condiments or {}) >= (harvester.condimentSlots or 0) then setNotification("No empty condiment slots") return end
				context.Controllers.Generator.BuyEquipCondiment(state.selectedSlot, condiment.id)
			end)
		end
		return
	end

	local scroll = mk(contentFrame, "ScrollingFrame", { Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.fromRGB(5, 17, 33), BackgroundTransparency = 0, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 8, ClipsDescendants = true })
	mainScrollRef = scroll
	local list = mk(scroll, "UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	mk(scroll, "UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10) })

	local total = 0
	local used = 0
	for i = 1, slots do
		total += slotOutput(equipped[i])
		if equipped[i] then used += 1 end
	end
	local header = mk(scroll, "Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1 })
	mk(header, "TextLabel", { Size = UDim2.new(1, -140, 0, 26), Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Text = "YOUR HARVESTERS", TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left })
	mk(header, "TextLabel", { Size = UDim2.new(0, 140, 0, 26), Position = UDim2.new(1, -140, 0, 0), BackgroundTransparency = 1, Text = string.format("%d/%d Slots", used, slots), TextColor3 = COLORS.cyan, Font = Enum.Font.GothamBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Right })
	mk(header, "TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 32), BackgroundTransparency = 1, Text = string.format("TOTAL: %s food/sec", NumberUtil.FormatNumber(total)), TextColor3 = Color3.fromRGB(88, 255, 139), Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left })

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
				local upgradeButton = mk(card, "TextButton", { Size = UDim2.new(1, -12, 0, 24), Position = UDim2.new(0, 6, 1, -30), BackgroundColor3 = COLORS.upgradeButton, BorderSizePixel = 0, Text = "Upgrade", TextColor3 = Color3.fromRGB(12, 28, 45), Font = Enum.Font.GothamBold, TextSize = 14, ZIndex = 6 })
				mk(upgradeButton, "UICorner", { CornerRadius = UDim.new(0, 5) })
				mk(upgradeButton, "UIStroke", { Color = COLORS.upgradeButtonStroke, Thickness = 2 })
				upgradeButton.Activated:Connect(function() context.Controllers.Generator.AutoUpgradeCondiments(i) end)
				mk(card, "TextButton", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -22, 0, 4), BackgroundTransparency = 1, Text = "🗑", TextSize = 14, ZIndex = 7 }).Activated:Connect(function()
					context.Controllers.Generator.Remove(i)
				end)
				mk(card, "TextButton", { Size = UDim2.new(1, -34, 1, -38), Position = UDim2.fromOffset(6, 4), BackgroundTransparency = 1, Text = "", ZIndex = 2 }).Activated:Connect(function()
					state.mode = "detail"
					state.selectedSlot = i
					refresh(contextRef, true)
				end)
			end
		else
			mk(card, "TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(16, 29, 51), Text = "+ Add Harvester", TextColor3 = COLORS.cyan, Font = Enum.Font.GothamBold, TextSize = 20 }).Activated:Connect(function() setNotification("Select a harvester below") end)
		end
	end
	if used >= slots then
		local upsellCard = mk(gridWrap, "Frame", { BackgroundColor3 = Color3.fromRGB(16, 29, 51), BorderSizePixel = 0 })
		mk(upsellCard, "UICorner", { CornerRadius = UDim.new(0, 6) })
		mk(upsellCard, "UIStroke", { Color = COLORS.slotUpsell, Thickness = 2 })
		mk(upsellCard, "TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "GET MORE SLOTS", TextColor3 = COLORS.slotUpsell, Font = Enum.Font.GothamBold, TextSize = 20 }).Activated:Connect(function()
			context.Controllers.Generator.PromptExtraSlotPurchase()
		end)
	end

	mk(scroll, "TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "HARVESTER SHOP", TextColor3 = COLORS.buff, Font = Enum.Font.GothamBold, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left })
	local tabRow = mk(scroll, "Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })
	local tabLayout = mk(tabRow, "UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) })
	for _, c in ipairs(GeneratorConfig.Classes) do
		local selected = c.id == state.selectedClass
		local unlocked, requiredPrestige = isClassUnlocked(context, c)
		local tabText = if unlocked then c.displayName else string.format("%s\nP%d", c.displayName, requiredPrestige)
		local button = mk(tabRow, "TextButton", { Size = UDim2.fromOffset(102, 36), BackgroundColor3 = (selected and unlocked) and COLORS.cyan or COLORS.panel, BorderSizePixel = 0, Text = tabText, TextColor3 = (selected and unlocked) and Color3.fromRGB(8, 22, 44) or (unlocked and COLORS.text or COLORS.muted), Font = Enum.Font.GothamBold, TextSize = 13 })
		button.Active = unlocked
		button.AutoButtonColor = unlocked
		button.Activated:Connect(function()
			if not unlocked then
				setNotification(string.format("Reach Prestige %d to unlock %s harvesters.", requiredPrestige, c.displayName))
				return
			end
			state.selectedClass = c.id
			refresh(contextRef, true)
		end)
	end
	local selectedClassInfo = GeneratorConfig.GetClass(state.selectedClass)
	local selectedUnlocked = selectedClassInfo and isClassUnlocked(context, selectedClassInfo) or true
	if not selectedUnlocked then
		state.selectedClass = "snack"
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
	if previousMode == "main" and state.mode == "main" and state.selectedClass == previousClass and not resetScroll then
		task.defer(function()
			if mainScrollRef == scroll then
				scroll.CanvasPosition = previousCanvasPosition
			end
		end)
	end
end

function FoodHarvestersApp.Refresh(context)
	local signature = buildHarvesterSignature(context)
	if signature == lastRefreshSignature then
		return
	end
	lastRefreshSignature = signature
	refresh(context)
end

function FoodHarvestersApp.Mount(target, context)
	if root then return end
	windowRef = Window.Create({ Title = "Food Harvesters.exe", IconImage = UIAssets.AppIconImages.FoodHarvesters, Size = UDim2.fromOffset(860, 640), Position = UDim2.fromScale(0.1, 0.08), Parent = target, OnClose = function() context.Controllers.Window.Close("FoodHarvesters") end })
	root = mk(windowRef.Content, "Frame", { Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.fromRGB(5, 17, 33), BackgroundTransparency = 0, BorderSizePixel = 0, ClipsDescendants = true })
	mk(root, "UIPadding", { PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 8) })
	contentFrame = mk(root, "Frame", { Size = UDim2.new(1, 0, 1, -28), BackgroundColor3 = Color3.fromRGB(5, 17, 33), BackgroundTransparency = 0, BorderSizePixel = 0, ClipsDescendants = true })
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
	lastRefreshSignature = nil
end

return FoodHarvestersApp
