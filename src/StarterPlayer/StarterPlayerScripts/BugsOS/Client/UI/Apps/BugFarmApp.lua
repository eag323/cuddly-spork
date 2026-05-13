--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local BugConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugConfig"))
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local BugdexView = require(script.Parent:WaitForChild("Views"):WaitForChild("BugdexView"))

local BugFarmApp = {}

local windowRef
local root
local tabButtons: {[string]: TextButton} = {}
local contentHost
local stateConn
local selectedTab = "My Bugs"
local selectedRecycle: {[string]: boolean} = {}
local searchQuery = ""
local sortMode = "Rarity"
local detailOverlay
local bugdexInlineHost

local COLORS = {
	bg = Color3.fromRGB(6, 16, 30),
	card = Color3.fromRGB(18, 39, 63),
	cardDark = Color3.fromRGB(12, 27, 45),
	accent = Color3.fromRGB(90, 235, 245),
	gold = Color3.fromRGB(255, 185, 55),
	text = Color3.fromRGB(242, 248, 255),
	muted = Color3.fromRGB(148, 170, 196),
	good = Color3.fromRGB(132, 245, 170),
}

local rarityColors = {
	Common = Color3.fromRGB(190, 193, 203),
	Uncommon = Color3.fromRGB(108, 216, 136),
	Rare = Color3.fromRGB(92, 176, 255),
	Epic = Color3.fromRGB(188, 107, 255),
	Legendary = Color3.fromRGB(255, 183, 75),
	Mythic = Color3.fromRGB(255, 106, 174),
}

local function getBugCfg(id)
	return BugConfig.Bugs[id]
end

local function clear(container)
	for _, child in ipairs(container:GetChildren()) do
		child:Destroy()
	end
end

local function getBugsState(context)
	return ((context.State.PlayerData or {}).Bugs or {})
end

local function getOwnedList(inventory)
	local list = {}
	for uid, bug in pairs(inventory or {}) do
		table.insert(list, {Uid = uid, Bug = bug})
	end
	table.sort(list, function(a, b)
		return tostring(a.Uid) < tostring(b.Uid)
	end)
	return list
end

local function getRarityColor(rarity)
	return rarityColors[rarity] or Color3.fromRGB(210, 210, 215)
end

local function styleLabel(label, bold)
	label.BackgroundTransparency = 1
	label.TextColor3 = COLORS.text
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextStrokeTransparency = 1
end

local function makeCard(parent, size)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = COLORS.card
	frame.BorderSizePixel = 0
	frame.Size = size
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(61, 90, 120)
	stroke.Thickness = 1
	stroke.Transparency = 0.2
	stroke.Parent = frame
	return frame
end

local function makeBadge(parent, rarity)
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(100, 22)
	badge.BackgroundColor3 = getRarityColor(rarity)
	badge.BorderSizePixel = 0
	badge.Text = rarity
	styleLabel(badge, true)
	badge.TextSize = 12
	badge.TextColor3 = Color3.fromRGB(8, 18, 30)
	badge.Parent = parent
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
	return badge
end

local function makeButton(parent, text, color, size)
	local button = Instance.new("TextButton")
	button.Text = text
	button.Size = size
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.TextSize = 13
	styleLabel(button, true)
	button.Parent = parent
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color:Lerp(Color3.new(1, 1, 1), 0.2)
	stroke.Transparency = 0.55
	stroke.Parent = button
	local base = color
	button.MouseEnter:Connect(function() button.BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.08) end)
	button.MouseLeave:Connect(function() button.BackgroundColor3 = base end)
	return button
end

local function makeDetailPopup(context, uid, bug)
	if detailOverlay then detailOverlay:Destroy() detailOverlay = nil end
	local cfg = getBugCfg(bug.BugId) or {}
	detailOverlay = Instance.new("TextButton")
	detailOverlay.Text = ""
	detailOverlay.AutoButtonColor = false
	detailOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	detailOverlay.BackgroundTransparency = 0.3
	detailOverlay.Size = UDim2.fromScale(1, 1)
	detailOverlay.Parent = root
	local panel = makeCard(detailOverlay, UDim2.fromOffset(520, 300))
	panel.Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(260, 150)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 26)
	title.Position = UDim2.fromOffset(10, 10)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = tostring(cfg.displayName or bug.BugId)
	title.TextSize = 20
	styleLabel(title, true)
	title.Parent = panel
	local rarity = tostring(cfg.rarity or bug.Rarity or "Common")
	local badge = makeBadge(panel, rarity)
	badge.Position = UDim2.fromOffset(12, 44)
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -20, 1, -84)
	info.Position = UDim2.fromOffset(10, 72)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.TextWrapped = true
	info.TextSize = 14
	local stats = cfg.stats or {}
	local buffs = cfg.farmBuffs or {}
	info.Text = string.format("HP %s  ATK %s  DEF %s  SPD %s\nAbility: %s\nBuffs: Earnings +%s%%  Click +%s%%  Food/sec +%s%%",
		tostring(stats.hp or 0), tostring(stats.atk or 0), tostring(stats.def or 0), tostring(stats.spd or 0),
		tostring(cfg.ability or "None"), tostring(math.floor(((buffs.EarningsMultiplier or 1) - 1) * 100)),
		tostring(math.floor((buffs.ClickPowerBonus or 0) * 100)), tostring(math.floor((buffs.FoodPerSecondBonus or 0) * 100)))
	styleLabel(info, false)
	info.TextColor3 = COLORS.muted
	info.Parent = panel
	local lockButton = makeButton(panel, bug.Locked and "Unlock" or "Lock", bug.Locked and COLORS.gold or COLORS.cardDark, UDim2.fromOffset(110, 30))
	lockButton.Position = UDim2.new(1, -122, 1, -40)
	lockButton.Activated:Connect(function()
		context.Controllers.BugFarm.ToggleLock(uid)
		detailOverlay:Destroy()
		detailOverlay = nil
	end)
	detailOverlay.Activated:Connect(function() if detailOverlay then detailOverlay:Destroy() detailOverlay = nil end end)
end

local function render(context)
	if not root then return end
	clear(contentHost)
	local bugs = getBugsState(context)
	local inventory = bugs.Inventory or {}
	local owned = getOwnedList(inventory)
	local farmerSlots = bugs.FarmerSlots or {}
	local combatSlots = bugs.CombatSlots or {}
	for name, button in pairs(tabButtons) do
		button.BackgroundColor3 = (name == selectedTab) and COLORS.accent or COLORS.cardDark
		button.TextColor3 = (name == selectedTab) and Color3.fromRGB(7, 20, 33) or COLORS.text
	end

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 8
	scroll.BackgroundTransparency = 1
	scroll.Parent = contentHost
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scroll
	Instance.new("UIPadding", scroll).PaddingLeft = UDim.new(0, 10)

	local summary = makeCard(scroll, UDim2.new(1, -20, 0, 110))
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -14, 0, 24)
	title.Position = UDim2.fromOffset(10, 8)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = (selectedTab == "My Bugs" and "MY BUGS") or (selectedTab == "Farmers" and "FARMER BUGS") or (selectedTab == "Combat Team" and "COMBAT TEAM") or (selectedTab == "Recycling" and "BUG RECYCLING") or "BUGDEX"
	title.TextSize = 18
	styleLabel(title, true)
	title.Parent = summary

	local selectedCount = 0
	local selectedValue = 0
	for uid, picked in pairs(selectedRecycle) do
		if picked and inventory[uid] then selectedCount += 1 selectedValue += tonumber((inventory[uid].RecycleValue or 10)) or 10 end
	end
	local summaryText = Instance.new("TextLabel")
	summaryText.Size = UDim2.new(1, -14, 1, -36)
	summaryText.Position = UDim2.fromOffset(10, 32)
	summaryText.TextXAlignment = Enum.TextXAlignment.Left
	summaryText.TextYAlignment = Enum.TextYAlignment.Top
	summaryText.TextSize = 14
	styleLabel(summaryText, false)
	summaryText.TextColor3 = COLORS.muted
	summaryText.Text = string.format("Owned Bugs: %d\nLocked: %d\nBug Essence: %s", #owned, 0, tostring((context.State.PlayerData or {}).Currencies and (context.State.PlayerData or {}).Currencies.BugEssence or 0))
	local lockedCount = 0
	for _, b in pairs(inventory) do if b.Locked then lockedCount += 1 end end
	summaryText.Text = string.format("Owned Bugs: %d\nLocked: %d\nBug Essence: %s\nFarmer Assigned: %d\nCombat Assigned: %d", #owned, lockedCount, tostring((context.State.PlayerData or {}).Currencies and (context.State.PlayerData or {}).Currencies.BugEssence or 0), #farmerSlots, #combatSlots)
	if selectedTab == "Farmers" then
		summaryText.Text = string.format("Equipped: %d / %d\nExtra Slots: %d / 10", #farmerSlots, 5 + tonumber(bugs.ExtraFarmerSlotsPurchased or 0), tonumber(bugs.ExtraFarmerSlotsPurchased or 0))
	end
	if selectedTab == "Combat Team" then
		summaryText.Text = string.format("Equipped: %d / 5\nTeam Power: %d", #combatSlots, 0)
	elseif selectedTab == "Recycling" then
		summaryText.Text = string.format("Bug Essence: %s\nSelected: %d bugs\nRecycle Value: +%d Essence", tostring(bugs.Essence or 0), selectedCount, selectedValue)
	end
	summaryText.Parent = summary

	local controls = makeCard(scroll, UDim2.new(1, -20, 0, 46))
	local search = Instance.new("TextBox")
	search.PlaceholderText = "Search bugs"
	search.Text = searchQuery
	search.Size = UDim2.new(0.6, -10, 0, 30)
	search.Position = UDim2.fromOffset(8, 8)
	search.BackgroundColor3 = COLORS.cardDark
	search.TextSize = 13
	search.ClearTextOnFocus = false
	styleLabel(search, false)
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.Parent = controls
	Instance.new("UICorner", search).CornerRadius = UDim.new(0, 8)
	search.FocusLost:Connect(function() searchQuery = search.Text render(context) end)
	local sort = makeButton(controls, "Sort: " .. sortMode, COLORS.cardDark, UDim2.new(0.38, 0, 0, 30))
	sort.Position = UDim2.new(0.62, 0, 0, 8)
	sort.Activated:Connect(function() sortMode = (sortMode == "Rarity") and "Name" or "Rarity" render(context) end)

	if selectedTab == "Farmers" or selectedTab == "Combat Team" then
	for i = 1, (selectedTab == "Combat Team" and 5 or 5 + tonumber(bugs.ExtraFarmerSlotsPurchased or 0)) do
		local slot = makeCard(scroll, UDim2.new(1, -20, 0, 76))
		local uid = selectedTab == "Combat Team" and combatSlots[i] or farmerSlots[i]
		if uid and inventory[uid] then
			local bug = inventory[uid]
			local cfg = getBugCfg(bug.BugId) or {}
			local icon = Instance.new("ImageLabel")
			icon.Size = UDim2.fromOffset(48, 48)
			icon.Position = UDim2.fromOffset(10, 14)
			icon.BackgroundTransparency = 1
			icon.Image = tostring(cfg.icon or "")
			icon.Parent = slot
			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -240, 0, 26)
			name.Position = UDim2.fromOffset(66, 12)
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Text = tostring(cfg.displayName or bug.BugId)
			name.TextSize = 16
			styleLabel(name, true)
			name.Parent = slot
			local badge = makeBadge(slot, tostring(cfg.rarity or bug.Rarity or "Common"))
			badge.Position = UDim2.fromOffset(66, 42)
			local un = makeButton(slot, "Unequip", COLORS.cardDark, UDim2.fromOffset(92, 30))
			un.Position = UDim2.new(1, -102, 0.5, -15)
			un.Activated:Connect(function() if selectedTab == "Combat Team" then context.Controllers.BugFarm.UnequipCombat(i) else context.Controllers.BugFarm.UnequipFarmer(i) end end)
			slot.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then makeDetailPopup(context, uid, bug) end end)
		else
			local add = Instance.new("TextLabel")
			add.Size = UDim2.fromScale(1, 1)
			add.Text = selectedTab == "Combat Team" and "+ Add Combat Bug" or "+ Add Bug"
			add.TextSize = 18
			styleLabel(add, true)
			add.TextColor3 = COLORS.accent
			add.Parent = slot
		end
	end
end

	for _, entry in ipairs(owned) do
		local uid, bug = entry.Uid, entry.Bug
		local cfg = getBugCfg(bug.BugId) or {}
		local text = string.lower(tostring(cfg.displayName or bug.BugId))
		if searchQuery == "" or string.find(text, string.lower(searchQuery), 1, true) then
			local row = makeCard(scroll, UDim2.new(1, -20, 0, 72))
			local icon = Instance.new("ImageLabel")
			icon.Size = UDim2.fromOffset(44, 44)
			icon.Position = UDim2.fromOffset(10, 14)
			icon.BackgroundTransparency = 1
			icon.Image = tostring(cfg.icon or "")
			icon.Parent = row
			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -340, 0, 24)
			name.Position = UDim2.fromOffset(62, 10)
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.TextSize = 15
			name.Text = tostring(cfg.displayName or bug.BugId)
			styleLabel(name, true)
			name.Parent = row
			local sub = Instance.new("TextLabel")
			sub.Size = UDim2.new(1, -340, 0, 20)
			sub.Position = UDim2.fromOffset(62, 36)
			sub.TextXAlignment = Enum.TextXAlignment.Left
			sub.TextSize = 13
			sub.Text = string.format("Species: %s • %s", tostring(cfg.species or "Unknown"), tostring(cfg.role or "Unknown"))
			styleLabel(sub, false)
			sub.TextColor3 = COLORS.muted
			sub.Parent = row
			local badge = makeBadge(row, tostring(cfg.rarity or bug.Rarity or "Common"))
			badge.Position = UDim2.new(1, -270, 0.5, -11)
			local lock = makeButton(row, bug.Locked and "Unlock" or "Lock", bug.Locked and COLORS.gold or COLORS.cardDark, UDim2.fromOffset(72, 28))
			lock.Position = UDim2.new(1, -166, 0.5, -14)
			lock.Activated:Connect(function() context.Controllers.BugFarm.ToggleLock(uid) end)
			if selectedTab == "Recycling" then
				local selected = selectedRecycle[uid] == true
				local disabled = bug.Locked or table.find(farmerSlots, uid) or table.find(combatSlots, uid)
				local selectBtn = makeButton(row, selected and "Selected" or "Select", disabled and COLORS.cardDark or COLORS.accent, UDim2.fromOffset(88, 28))
				selectBtn.TextColor3 = disabled and COLORS.muted or Color3.fromRGB(8, 20, 34)
				selectBtn.Position = UDim2.new(1, -74, 0.5, -14)
				if not disabled then
					selectBtn.Activated:Connect(function() selectedRecycle[uid] = not selectedRecycle[uid] render(context) end)
				end
			elseif selectedTab == "Farmers" or selectedTab == "Combat Team" then
				local equip = makeButton(row, "Equip", COLORS.accent, UDim2.fromOffset(72, 28))
				equip.TextColor3 = Color3.fromRGB(8, 20, 34)
				equip.Position = UDim2.new(1, -74, 0.5, -14)
				equip.Activated:Connect(function()
					if selectedTab == "Combat Team" then context.Controllers.BugFarm.EquipCombat(uid, nil) else context.Controllers.BugFarm.EquipFarmer(uid, nil) end
				end)
			end
			if selectedTab == "My Bugs" then
				local manage = makeButton(row, "Manage", COLORS.accent, UDim2.fromOffset(84, 28))
				manage.TextColor3 = Color3.fromRGB(8, 20, 34)
				manage.Position = UDim2.new(1, -86, 0.5, -14)
				manage.Activated:Connect(function() makeDetailPopup(context, uid, bug) end)
			end
			row.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then makeDetailPopup(context, uid, bug) end end)
		end
	end

	if selectedTab == "Bugdex" then
		if bugdexInlineHost then
			BugdexView.Unmount()
			bugdexInlineHost:Destroy()
			bugdexInlineHost = nil
		end
		bugdexInlineHost = Instance.new("Frame")
		bugdexInlineHost.Name = "BugdexInlineHost"
		bugdexInlineHost.BackgroundTransparency = 1
		bugdexInlineHost.Size = UDim2.new(1, -20, 1, -20)
		bugdexInlineHost.Parent = contentHost
		BugdexView.Mount(bugdexInlineHost, context)
		return
	elseif bugdexInlineHost then
		BugdexView.Unmount()
		bugdexInlineHost:Destroy()
		bugdexInlineHost = nil
	end

	if selectedTab == "Recycling" then
		local bar = makeCard(scroll, UDim2.new(1, -20, 0, 50))
		local recycle = makeButton(bar, "Recycle Selected", selectedCount > 0 and Color3.fromRGB(220, 110, 80) or COLORS.cardDark, UDim2.fromOffset(170, 32))
		recycle.Position = UDim2.fromOffset(8, 9)
		if selectedCount > 0 then
			recycle.Activated:Connect(function()
				local uids = {}
				for uid, chosen in pairs(selectedRecycle) do if chosen then table.insert(uids, uid) end end
				context.Controllers.BugFarm.RecycleSelected(uids)
				selectedRecycle = {}
			end)
		end
		local clearBtn = makeButton(bar, "Clear Selection", COLORS.cardDark, UDim2.fromOffset(140, 32))
		clearBtn.Position = UDim2.fromOffset(186, 9)
		clearBtn.Activated:Connect(function() selectedRecycle = {} render(context) end)
	end
end

function BugFarmApp.Mount(target, context)
	if root then return end
	windowRef = Window.Create({
		Title = "Bugs.exe",
		Size = UDim2.fromOffset(940, 640),
		Position = UDim2.fromScale(0.08, 0.1),
		Parent = target,
		OnClose = function() context.Controllers.Window.Close("BugFarm") end,
	})
	root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = COLORS.bg
	root.BorderSizePixel = 0
	root.Parent = windowRef.Content

	local tabs = Instance.new("Frame")
	tabs.Size = UDim2.new(1, -16, 0, 42)
	tabs.Position = UDim2.fromOffset(8, 8)
	tabs.BackgroundTransparency = 1
	tabs.Parent = root
	for i, name in ipairs({"My Bugs", "Farmers", "Combat Team", "Recycling", "Bugdex"}) do
		local tab = makeButton(tabs, name, COLORS.cardDark, UDim2.fromOffset(170, 32))
		tab.Position = UDim2.fromOffset((i - 1) * 178, 4)
		tab.Activated:Connect(function() selectedTab = name render(context) end)
		tabButtons[name] = tab
	end

	contentHost = Instance.new("Frame")
	contentHost.Size = UDim2.new(1, -16, 1, -58)
	contentHost.Position = UDim2.fromOffset(8, 52)
	contentHost.BackgroundTransparency = 1
	contentHost.Parent = root

	if context.Events and context.Events.StateChanged then
		stateConn = context.Events.StateChanged.Event:Connect(function() render(context) end)
	end
	render(context)
end

function BugFarmApp.Unmount()
	if stateConn then stateConn:Disconnect() end
	if bugdexInlineHost then
		BugdexView.Unmount()
		bugdexInlineHost:Destroy()
		bugdexInlineHost = nil
	end
	if windowRef then windowRef.Destroy() end
	stateConn = nil
	windowRef = nil
	root = nil
	contentHost = nil
	tabButtons = {}
end

return BugFarmApp
