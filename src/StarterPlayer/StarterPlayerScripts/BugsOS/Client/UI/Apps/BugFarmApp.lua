--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local BugConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugConfig"))
local BugBonusConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugBonusConfig"))
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
local farmerStatFilter = "All"
local farmerSortMode = "Rarity"
local renameTargetUid = nil
local rarityFilter = "All"
local sortModes = {"Rarity","Name","Species","Newest","Locked First","Farmer Equipped","Combat Equipped","Power"}
local rarityTabs = {"All","Common","Uncommon","Rare","Epic","Legendary","Mythic"}
local FARMER_HABITAT_BACKGROUND_IMAGE = ""
local FARMER_STAT_FILTERS = {
	{Id="All", Label="All"},
	{Id="AllFood", Label="All Earnings"},
	{Id="FoodPerSec", Label="Food/sec"},
	{Id="ClickPower", Label="Click Power"},
	{Id="SellBonus", Label="Sell Bonus"},
	{Id="BugLuck", Label="Bug Luck"},
	{Id="NectarChance", Label="Nectar Chance"},
	{Id="BugSpawnRate", Label="Bug Spawn Rate"},
	{Id="MinigameTime", Label="Minigame Time"},
	{Id="ExpeditionSpeed", Label="Expedition Speed"},
	{Id="EquipmentDropRate", Label="Equipment Drop Rate"},
	{Id="BugEssenceGain", Label="Bug Essence Gain"},
}
local detailOverlay
local bugdexInlineHost
local render
local getLegacyBonusStats

local COLORS = {
	bg = Color3.fromRGB(6, 16, 30),
	card = Color3.fromRGB(18, 39, 63),
	cardDark = Color3.fromRGB(12, 27, 45),
	accent = Color3.fromRGB(90, 235, 245),
	gold = Color3.fromRGB(255, 185, 55),
	text = Color3.fromRGB(242, 248, 255),
	muted = Color3.fromRGB(148, 170, 196),
	good = Color3.fromRGB(132, 245, 170),
	warn = Color3.fromRGB(244, 186, 92),
	danger = Color3.fromRGB(236, 122, 96),
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



local FALLBACK_ASCENSION_COSTS = {
	Common = {5, 10, 20, 40, 80},
	Uncommon = {10, 20, 40, 80, 160},
	Rare = {25, 50, 100, 200, 400},
	Epic = {75, 150, 300, 600, 1200},
	Legendary = {250, 500, 1000, 2000, 4000},
	Mythic = {1000, 2000, 4000, 8000, 16000},
}

local function getOwnedBugUid(ownedBug, fallbackUid)
	if type(ownedBug) ~= "table" then return fallbackUid end
	return ownedBug.Uid or ownedBug.Id or ownedBug.InstanceId or fallbackUid
end

local function getOwnedBugBugId(ownedBug)
	if type(ownedBug) ~= "table" then return nil end
	return ownedBug.BugId or ownedBug.SpeciesId or ownedBug.Species
end

local function getBugConfig(ownedBug)
	local bugId = getOwnedBugBugId(ownedBug)
	if type(bugId) ~= "string" then return nil end
	return BugConfig.GetBug(bugId) or BugConfig.Bugs[bugId]
end



local function getDisplayName(bug, cfg)
	return tostring((bug and bug.Nickname) or (cfg and cfg.displayName) or (bug and bug.BugId) or "Unknown Bug")
end

local function getBugIcon(bug, cfg)
	return tostring((cfg and (cfg.icon or cfg.sprite)) or "")
end

local function getBonusStats(bug)
	if type(bug) ~= "table" then return {} end
	if type(bug.BonusStats) == "table" then return bug.BonusStats end
	return getLegacyBonusStats(bug)
end

local function getFarmerBonuses(bug)
	local out = {}
	for _, bonus in ipairs(getBonusStats(bug)) do
		if BugBonusConfig.GetCategory(tostring(bonus.Id)) == "Farmer" then table.insert(out, bonus) end
	end
	return out
end

local function formatPercent(value) return string.format("+%d%%", math.floor((tonumber(value) or 0) * 100 + 0.5)) end
local function formatBonus(bonus)
	if type(BugBonusConfig.FormatBonus) == "function" then return BugBonusConfig.FormatBonus(bonus) end
	local d = BugBonusConfig.GetDefinition(tostring(bonus.Id or ""))
	return string.format("%s %s", formatPercent(tonumber(bonus.Value) or 0), tostring((d and d.DisplayName) or bonus.Id or "Bonus"))
end
local function getBonusValueForStat(bug, statId)
	for _, bonus in ipairs(getFarmerBonuses(bug)) do if tostring(bonus.Id)==tostring(statId) then return tonumber(bonus.Value) or 0 end end
	return 0
end
local function hasBonusStat(bug, statId) return getBonusValueForStat(bug, statId) > 0 end
local function getBestFarmerBonusValue(bug)
	local best = 0
	for _, bonus in ipairs(getFarmerBonuses(bug)) do best = math.max(best, tonumber(bonus.Value) or 0) end
	return best
end
local function getActiveFarmerTotals(farmerSlots, inventory)
	local totals = {}
	for _, uid in ipairs(farmerSlots or {}) do
		local bug = inventory and inventory[uid]
		if bug then
			for _, b in ipairs(getFarmerBonuses(bug)) do
				local id = tostring(b.Id)
				totals[id] = (totals[id] or 0) + (tonumber(b.Value) or 0)
			end
		end
	end
	return totals
end
local function getStatMaxForSlots(statId, slotCount)
	local def = BugBonusConfig.GetDefinition(statId)
	return (def and tonumber(def.Max) or 0) * math.max(0, tonumber(slotCount) or 0)
end

getLegacyBonusStats = function(bug)
	local out = {}
	if type(bug) ~= "table" then return out end
	if type(bug.BonusStats) == "table" and #bug.BonusStats > 0 then return bug.BonusStats end
	if type(bug.Primary) == "table" then table.insert(out, { Id = bug.Primary.Stat or bug.Primary.Attribute, Value = bug.Primary.Value }) end
	if type(bug.Secondaries) == "table" then for _, b in ipairs(bug.Secondaries) do if type(b) == "table" then table.insert(out, { Id = b.Stat or b.Attribute, Value = b.Value }) end end end
	return out
end

local function formatBonusLine(bonus)
	if type(bonus) ~= "table" then return "No bonus" end
	local line = BugBonusConfig.FormatBonus(bonus)
	local q = tostring(bonus.RollQuality or "")
	if q == "Good" or q == "Great" or q == "Perfect" then line = line .. " [" .. q .. "]" end
	return line
end

local function isBugLocked(ownedBug)
	return type(ownedBug) == "table" and (ownedBug.Locked == true or ownedBug.IsLocked == true)
end

local function getBugAscension(ownedBug)
	if type(ownedBug) ~= "table" then return 0 end
	return math.max(0, math.min(5, tonumber(ownedBug.Ascension) or 0))
end

local function clear(container)
	for _, child in ipairs(container:GetChildren()) do
		child:Destroy()
	end
end

local function getBugsState(context)
	return ((context.State.PlayerData or {}).Bugs or {})
end

local function getFarmerSlotCount(context, bugs)
	local playerData = (context.State or {}).PlayerData or {}
	local prestige = tonumber(bugs.Prestige)
	if prestige == nil then
		prestige = tonumber(playerData.Prestige) or tonumber((playerData.Progression or {}).Prestige) or 0
	end
	local extra = tonumber(bugs.ExtraFarmerSlotsPurchased) or 0
	return 5 + math.max(0, prestige) + math.max(0, extra)
end


local function isAssignedFarmer(uid, farmerSlots)
	return table.find(farmerSlots, uid) ~= nil
end

local function isAssignedCombat(uid, combatSlots)
	return table.find(combatSlots, uid) ~= nil
end

local function getAssignmentStatus(uid, farmerSlots, combatSlots)
	if isAssignedFarmer(uid, farmerSlots) then return "Farmer" end
	if isAssignedCombat(uid, combatSlots) then return "Combat" end
	return "Unassigned"
end

local function getAssignmentHeaderLabel(uid, farmerSlots, combatSlots)
	local farmerSlot = table.find(farmerSlots, uid)
	if farmerSlot then return ("Farmer Slot %d"):format(farmerSlot) end
	local combatSlot = table.find(combatSlots, uid)
	if combatSlot then return ("Combat Team Slot %d"):format(combatSlot) end
	return "Unassigned"
end

local function getBugPower(bugConfig)
	local stats = (bugConfig and bugConfig.stats) or {}
	return math.floor((tonumber(stats.HP) or 0)
		+ (tonumber(stats.ATK) or 0) * 4
		+ (tonumber(stats.DEF) or 0) * 3
		+ (tonumber(stats.SPD) or 0) * 2
		+ (tonumber(stats.CritRate) or 0) * 8
		+ (tonumber(stats.CritDamage) or 0)
		+ (tonumber(stats.RES) or 0) * 2
		+ (tonumber(stats.ACC) or 0) * 2)
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

local function setBadgeTextColor(badge: Frame, color: Color3)
	local label = badge:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.TextColor3 = color
	end
end

local function makeBadge(parent, text, tint)
	local badge = Instance.new("Frame")
	badge.Size = UDim2.fromOffset(100, 22)
	badge.BackgroundColor3 = tint or getRarityColor(text)
	badge.BorderSizePixel = 0
	badge.Parent = parent
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color = badge.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.25)
	stroke.Transparency = 0.35
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = badge
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = tostring(text)
	label.TextSize = 12
	styleLabel(label, true)
	label.TextColor3 = Color3.fromRGB(8, 18, 30)
	label.Parent = badge
	return badge
end

local function getAssignmentBadgeStyle(assignText)
	if assignText == "Farmer" then
		return Color3.fromRGB(68, 190, 164), Color3.fromRGB(8, 24, 20)
	elseif assignText == "Combat" then
		return Color3.fromRGB(245, 162, 76), Color3.fromRGB(30, 16, 8)
	end
	return Color3.fromRGB(98, 118, 146), Color3.fromRGB(230, 240, 252)
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
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local base = color
	button.MouseEnter:Connect(function() button.BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.08) end)
	button.MouseLeave:Connect(function() button.BackgroundColor3 = base end)
	return button
end

local function formatNum(n)
	return tostring(math.floor(tonumber(n) or 0)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function makeSectionTitle(parent, text, y)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -20, 0, 18)
	t.Position = UDim2.fromOffset(10, y)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = text
	t.TextSize = 13
	styleLabel(t, true)
	t.TextColor3 = COLORS.accent
	t.Parent = parent
	return t
end


local function applyNoTextStrokeRecursive(rootNode: Instance)
	if rootNode:IsA("TextLabel") or rootNode:IsA("TextButton") or rootNode:IsA("TextBox") then
		rootNode.TextStrokeTransparency = 1
	end
	for _, child in ipairs(rootNode:GetChildren()) do
		applyNoTextStrokeRecursive(child)
	end
end

local function setButtonEnabled(button: TextButton, enabled: boolean, enabledColor: Color3)
	button.AutoButtonColor = false
	button.Active = enabled
	if enabled then
		button.BackgroundColor3 = enabledColor
		button.TextColor3 = COLORS.text
	else
		button.BackgroundColor3 = COLORS.cardDark
		button.TextColor3 = COLORS.muted
	end
end

local function makeDetailPopup(context, uid, bug)
	if detailOverlay then detailOverlay:Destroy() detailOverlay = nil end
	detailOverlay = Instance.new("TextButton")
	detailOverlay.Text = ""
	detailOverlay.AutoButtonColor = false
	detailOverlay.TextStrokeTransparency = 1
	detailOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	detailOverlay.BackgroundTransparency = 0.35
	detailOverlay.Size = UDim2.fromScale(1, 1)
	detailOverlay.Parent = root

	local cfg = getBugConfig(bug) or {}
	local rarity = tostring(cfg.rarity or bug.Rarity or "Common")
	local farmerSlots = getBugsState(context).FarmerSlots or {}
	local combatSlots = getBugsState(context).CombatSlots or {}
	local assignedFarmer = isAssignedFarmer(uid, farmerSlots)
	local assignedCombat = isAssignedCombat(uid, combatSlots)
	local assignText = getAssignmentStatus(uid, farmerSlots, combatSlots)
	local assignHeaderText = getAssignmentHeaderLabel(uid, farmerSlots, combatSlots)
	local assignColor, assignTextColor = getAssignmentBadgeStyle(assignText)

	local panel = makeCard(detailOverlay, UDim2.fromOffset(760, 540))
	panel.Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(380, 270)
	panel.BackgroundColor3 = Color3.fromRGB(10, 24, 42)
	local stroke = panel:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = getRarityColor(rarity) stroke.Thickness = 2 stroke.Transparency = 0.15 end
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, -32, 0, 125)
	header.Position = UDim2.fromOffset(16, 14)
	header.BackgroundTransparency = 1
	header.Parent = panel

	local popupScroll = Instance.new("ScrollingFrame")
	popupScroll.Size = UDim2.new(1, -32, 1, -158)
	popupScroll.Position = UDim2.fromOffset(16, 141)
	popupScroll.BackgroundTransparency = 1
	popupScroll.BorderSizePixel = 0
	popupScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	popupScroll.CanvasSize = UDim2.fromOffset(0, 0)
	popupScroll.ScrollBarThickness = 6
	popupScroll.ScrollBarImageColor3 = Color3.fromRGB(62, 82, 106)
	popupScroll.Parent = panel
	local bodyContent = Instance.new("Frame")
	bodyContent.Name = "BodyContentFrame"
	bodyContent.Position = UDim2.fromOffset(0, 0)
	bodyContent.Size = UDim2.new(1, -24, 0, 0)
	bodyContent.BackgroundTransparency = 1
	bodyContent.AutomaticSize = Enum.AutomaticSize.Y
	bodyContent.Parent = popupScroll
	local bodyPad = Instance.new("UIPadding")
	bodyPad.PaddingLeft = UDim.new(0, 2)
	bodyPad.PaddingRight = UDim.new(0, 14)
	bodyPad.PaddingBottom = UDim.new(0, 20)
	bodyPad.Parent = bodyContent
	local list = Instance.new("UIListLayout", bodyContent)
	list.Padding = UDim.new(0, 12)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Left
	list.SortOrder = Enum.SortOrder.LayoutOrder

	local closeBtn = makeButton(panel, "X", COLORS.cardDark, UDim2.fromOffset(28, 28))
	closeBtn.LayoutOrder = 0
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -14, 0, 14)
	closeBtn.ZIndex = 3
	closeBtn.TextStrokeTransparency = 1
	closeBtn.Activated:Connect(function() if detailOverlay then detailOverlay:Destroy() detailOverlay = nil end end)

	
	local iconPanel = makeCard(header, UDim2.fromOffset(110, 110)); iconPanel.Position = UDim2.fromOffset(0, 8); iconPanel.BackgroundColor3 = COLORS.cardDark
	local icon = Instance.new("ImageLabel"); icon.BackgroundTransparency = 1; icon.Size = UDim2.fromOffset(96, 96); icon.Position = UDim2.fromOffset(7, 7); icon.Image = tostring(cfg.icon or ""); icon.Parent = iconPanel
	local right = Instance.new("Frame"); right.BackgroundTransparency = 1; right.Size = UDim2.new(1, -132, 1, 0); right.Position = UDim2.fromOffset(132, 0); right.Parent = header
	local name = Instance.new("TextLabel"); name.BackgroundTransparency=1; name.Size=UDim2.new(1,-120,0,34); name.Position=UDim2.fromOffset(0,10); name.TextXAlignment=Enum.TextXAlignment.Left; name.Text=tostring(cfg.displayName or getOwnedBugBugId(bug) or "Unknown Bug"); name.TextSize=27; styleLabel(name,true); name.Parent=right
	local rarityBadge = makeBadge(right, rarity, getRarityColor(rarity)); rarityBadge.Position = UDim2.fromOffset(0, 52); rarityBadge.Size = UDim2.fromOffset(120, 24)
	local assignBadge = makeBadge(right, assignHeaderText, assignColor); assignBadge.Position = UDim2.fromOffset(128, 52); assignBadge.Size = UDim2.fromOffset(188, 24); setBadgeTextColor(assignBadge, assignTextColor)
	local species = Instance.new("TextLabel"); species.BackgroundTransparency=1; species.Size=UDim2.new(1,-10,0,20); species.Position=UDim2.fromOffset(0,84); species.TextXAlignment=Enum.TextXAlignment.Left; species.Text=tostring(cfg.role or "Unknown").." • "..tostring(cfg.species or "Unknown"); species.TextSize=13; styleLabel(species,false); species.TextColor3=COLORS.muted; species.Parent=right
	local caughtAt = bug.CaughtAt or bug.CapturedAt
	local instanceId = tostring(uid or "")
	if caughtAt or instanceId ~= "" then
		local meta = Instance.new("TextLabel")
		meta.BackgroundTransparency = 1
		meta.Size = UDim2.new(1, -10, 0, 16)
		meta.Position = UDim2.fromOffset(0, 103)
		meta.TextXAlignment = Enum.TextXAlignment.Left
		meta.TextSize = 11
		styleLabel(meta, false)
		meta.TextColor3 = Color3.fromRGB(133, 156, 182)
		local idSuffix = string.upper(string.sub(instanceId, math.max(1, #instanceId - 3)))
		local caughtText = nil
		local timestamp = tonumber(caughtAt)
		if timestamp and timestamp > 0 then
			if timestamp > 100000000000 then
				timestamp = math.floor(timestamp / 1000)
			end
			local dt = os.date("*t", timestamp)
			if dt then
				caughtText = string.format("Caught: %02d/%02d/%04d", dt.month, dt.day, dt.year)
			end
		end
		meta.Text = caughtText and (caughtText .. "  •  ID: #" .. idSuffix) or ("ID: #" .. idSuffix)
		meta.Parent = right
	end

	local statsSection = makeCard(bodyContent, UDim2.new(1, 0, 0, 98)); statsSection.BackgroundColor3 = COLORS.cardDark
	local statsPad = Instance.new("UIPadding", statsSection)
	statsPad.PaddingLeft = UDim.new(0, 10)
	statsPad.PaddingRight = UDim.new(0, 10)
	statsPad.PaddingTop = UDim.new(0, 8)
	statsPad.PaddingBottom = UDim.new(0, 10)
	local statsList = Instance.new("UIListLayout", statsSection)
	statsList.FillDirection = Enum.FillDirection.Vertical
	statsList.Padding = UDim.new(0, 6)
	statsList.SortOrder = Enum.SortOrder.LayoutOrder
	local statsTitle = Instance.new("TextLabel")
	statsTitle.BackgroundTransparency = 1
	statsTitle.Size = UDim2.new(1, 0, 0, 18)
	statsTitle.Text = "COMBAT STATS"
	statsTitle.TextXAlignment = Enum.TextXAlignment.Left
	statsTitle.TextSize = 13
	styleLabel(statsTitle, true)
	statsTitle.TextColor3 = COLORS.accent
	statsTitle.Parent = statsSection
	local chipWrap = Instance.new("Frame")
	chipWrap.BackgroundTransparency = 1
	chipWrap.Size = UDim2.new(1, 0, 0, 58)
	chipWrap.Parent = statsSection
	local grid = Instance.new("UIGridLayout", chipWrap); grid.CellPadding = UDim2.fromOffset(6, 6); grid.CellSize = UDim2.new(0.25, -5, 0, 26)
	local stats = cfg.stats or {}
	local icons = {HP="❤️",ATK="⚔️",DEF="🛡️",SPD="💨",CR="🎯",CD="💥",RES="🔒",ACC="👁️"}
	for _, entry in ipairs({{"HP","HP"},{"ATK","ATK"},{"DEF","DEF"},{"SPD","SPD"},{"CR","CritRate"},{"CD","CritDamage"},{"RES","RES"},{"ACC","ACC"}}) do
		local chip = makeCard(chipWrap, UDim2.new(0, 80, 0, 26)); chip.BackgroundColor3 = COLORS.card
		local t = Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.fromScale(1,1); t.Text=("%s %s %s"):format(icons[entry[1]], entry[1], tostring(stats[entry[2]] or 0)); t.TextSize=12; t.TextXAlignment=Enum.TextXAlignment.Center; t.TextYAlignment=Enum.TextYAlignment.Center; styleLabel(t,true); t.Parent=chip
	end

	local infoRow = Instance.new("Frame"); infoRow.Size = UDim2.new(1,0,0,128); infoRow.BackgroundTransparency = 1; infoRow.Parent = bodyContent
	local infoLayout = Instance.new("UIListLayout", infoRow); infoLayout.FillDirection = Enum.FillDirection.Horizontal; infoLayout.Padding = UDim.new(0, 10); infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	local buffsCard = makeCard(infoRow, UDim2.new(0.5, -5, 1, 0)); buffsCard.BackgroundColor3=COLORS.cardDark
	local buffsPad = Instance.new("UIPadding", buffsCard); buffsPad.PaddingLeft=UDim.new(0,10); buffsPad.PaddingRight=UDim.new(0,10); buffsPad.PaddingTop=UDim.new(0,8); buffsPad.PaddingBottom=UDim.new(0,8)
	local buffsList = Instance.new("UIListLayout", buffsCard); buffsList.FillDirection=Enum.FillDirection.Vertical; buffsList.Padding=UDim.new(0,6); buffsList.SortOrder=Enum.SortOrder.LayoutOrder
	local buffsTitle = Instance.new("TextLabel"); buffsTitle.BackgroundTransparency=1; buffsTitle.Size=UDim2.new(1,0,0,18); buffsTitle.TextXAlignment=Enum.TextXAlignment.Left; buffsTitle.Text="FARMING BUFFS"; buffsTitle.TextSize=13; styleLabel(buffsTitle,true); buffsTitle.TextColor3=COLORS.accent; buffsTitle.Parent=buffsCard
	local buffsText = Instance.new("TextLabel"); buffsText.BackgroundTransparency=1; buffsText.Size=UDim2.new(1,0,1,-24); buffsText.TextXAlignment=Enum.TextXAlignment.Left; buffsText.TextYAlignment=Enum.TextYAlignment.Top; buffsText.TextWrapped=true; buffsText.TextSize=12; styleLabel(buffsText,false); buffsText.TextColor3=COLORS.good; local allBonuses = getLegacyBonusStats(bug)
	local farmLines = {}
	local combatLines = {}
	for _, bonus in ipairs(allBonuses) do
		if BugBonusConfig.GetCategory(tostring(bonus.Id)) == "Combat" then table.insert(combatLines, formatBonusLine(bonus)) else table.insert(farmLines, formatBonusLine(bonus)) end
	end
	buffsText.Text=(#farmLines>0) and table.concat(farmLines, "\n") or "No bonus stats";  buffsText.Parent=buffsCard
	local abilityCard = makeCard(infoRow, UDim2.new(0.5, -5, 1, 0)); abilityCard.BackgroundColor3 = COLORS.cardDark
	local abilityPad = Instance.new("UIPadding", abilityCard); abilityPad.PaddingLeft=UDim.new(0,10); abilityPad.PaddingRight=UDim.new(0,10); abilityPad.PaddingTop=UDim.new(0,8); abilityPad.PaddingBottom=UDim.new(0,8)
	local abilityList = Instance.new("UIListLayout", abilityCard); abilityList.FillDirection=Enum.FillDirection.Vertical; abilityList.Padding=UDim.new(0,6); abilityList.SortOrder=Enum.SortOrder.LayoutOrder
	local abilityTitle = Instance.new("TextLabel"); abilityTitle.BackgroundTransparency=1; abilityTitle.Size=UDim2.new(1,0,0,18); abilityTitle.TextXAlignment=Enum.TextXAlignment.Left; abilityTitle.Text="COMBAT BONUSES"; abilityTitle.TextSize=13; styleLabel(abilityTitle,true); abilityTitle.TextColor3=COLORS.accent; abilityTitle.Parent=abilityCard
	local ability = cfg.ability
	local abName = Instance.new("TextLabel"); abName.BackgroundTransparency=1; abName.Size=UDim2.new(1,0,1,-24); abName.TextXAlignment=Enum.TextXAlignment.Left; abName.TextYAlignment=Enum.TextYAlignment.Top; abName.TextWrapped=true; abName.Text=(#combatLines>0) and table.concat(combatLines, "\n") or "No bonus stats"; abName.TextSize=12; styleLabel(abName,false); abName.Parent=abilityCard

	local equipSection = makeCard(bodyContent, UDim2.new(1,0,0,140)); equipSection.BackgroundColor3=COLORS.cardDark
	local eqPad = Instance.new("UIPadding", equipSection); eqPad.PaddingLeft=UDim.new(0,10); eqPad.PaddingRight=UDim.new(0,10); eqPad.PaddingTop=UDim.new(0,8); eqPad.PaddingBottom=UDim.new(0,10)
	local eqList = Instance.new("UIListLayout", equipSection); eqList.FillDirection=Enum.FillDirection.Vertical; eqList.Padding=UDim.new(0,6); eqList.SortOrder=Enum.SortOrder.LayoutOrder
	local eqTitle = Instance.new("TextLabel"); eqTitle.BackgroundTransparency=1; eqTitle.Size=UDim2.new(1,0,0,18); eqTitle.TextXAlignment=Enum.TextXAlignment.Left; eqTitle.Text="EQUIPMENT"; eqTitle.TextSize=13; styleLabel(eqTitle,true); eqTitle.TextColor3=COLORS.accent; eqTitle.Parent=equipSection
	local eqInfo = Instance.new("TextLabel"); eqInfo.BackgroundTransparency=1; eqInfo.Size=UDim2.new(1,0,0,16); eqInfo.TextXAlignment=Enum.TextXAlignment.Left; eqInfo.Text="Equipment Coming Soon"; eqInfo.TextSize=11; styleLabel(eqInfo,false); eqInfo.TextColor3=COLORS.muted; eqInfo.Parent=equipSection
	local eqWrap = Instance.new("Frame"); eqWrap.BackgroundTransparency=1; eqWrap.Size=UDim2.new(1,0,0,68); eqWrap.Parent=equipSection
	local eqLayout = Instance.new("UIGridLayout", eqWrap); eqLayout.FillDirection=Enum.FillDirection.Horizontal; eqLayout.CellPadding=UDim2.fromOffset(8,0); eqLayout.CellSize=UDim2.new(0.2,-7,0,62)
	for _, slotName in ipairs({"Weapon","Helmet","Chestplate","Boots","Charm"}) do
		local slot = makeCard(eqWrap, UDim2.new(0, 0, 0, 62)); slot.BackgroundColor3=COLORS.card
		local slotPad = Instance.new("UIPadding", slot); slotPad.PaddingLeft=UDim.new(0,4); slotPad.PaddingRight=UDim.new(0,4); slotPad.PaddingTop=UDim.new(0,7); slotPad.PaddingBottom=UDim.new(0,7)
		local slotList = Instance.new("UIListLayout", slot); slotList.FillDirection=Enum.FillDirection.Vertical; slotList.HorizontalAlignment=Enum.HorizontalAlignment.Center; slotList.Padding=UDim.new(0,4)
		local s = Instance.new("TextLabel"); s.BackgroundTransparency=1; s.Size=UDim2.new(1,0,0,16); s.Text=slotName; s.TextSize=11; styleLabel(s,true); s.Parent=slot
		local c = Instance.new("TextLabel"); c.BackgroundTransparency=1; c.Size=UDim2.new(1,0,0,14); c.Text="Coming Soon"; c.TextSize=10; styleLabel(c,false); c.TextColor3=COLORS.muted; c.Parent=slot
	end

	local rank = getBugAscension(bug)
	local costTable = ((cfg.ascension or {}).essenceRequiredByRank) or FALLBACK_ASCENSION_COSTS[rarity] or FALLBACK_ASCENSION_COSTS.Common
	local cost = tonumber(costTable[rank + 1]) or tonumber(costTable[rank + 2]) or 0
	local essence = tonumber((((context.State.PlayerData or {}).Currencies or {}).BugEssence)) or 0
	local ascSec = makeCard(bodyContent, UDim2.new(1,0,0,74)); ascSec.BackgroundColor3=COLORS.cardDark
	local ascPad = Instance.new("UIPadding", ascSec); ascPad.PaddingLeft=UDim.new(0,10); ascPad.PaddingRight=UDim.new(0,10); ascPad.PaddingTop=UDim.new(0,8); ascPad.PaddingBottom=UDim.new(0,8)
	local ascTitle = Instance.new("TextLabel"); ascTitle.BackgroundTransparency=1; ascTitle.Size=UDim2.new(1,-170,0,16); ascTitle.Position=UDim2.fromOffset(0,0); ascTitle.Text="ASCENSION"; ascTitle.TextXAlignment=Enum.TextXAlignment.Left; ascTitle.TextSize=13; styleLabel(ascTitle,true); ascTitle.TextColor3=COLORS.accent; ascTitle.Parent=ascSec
	local ascInfo = Instance.new("TextLabel"); ascInfo.BackgroundTransparency=1; ascInfo.Size=UDim2.new(1,-170,0,32); ascInfo.Position=UDim2.fromOffset(0,24); ascInfo.TextXAlignment=Enum.TextXAlignment.Left; ascInfo.TextYAlignment=Enum.TextYAlignment.Top; ascInfo.TextWrapped=true; ascInfo.Text=("Rank %d / 5 • Cost: %d • Essence: %d"):format(rank,cost,essence); ascInfo.TextSize=12; styleLabel(ascInfo,false); ascInfo.Parent=ascSec
	local ascBtn = makeButton(ascSec, rank >= 5 and "Max Ascension" or "Ascend", COLORS.accent, UDim2.fromOffset(146, 32)); ascBtn.Position=UDim2.new(1,-146,0.5,-16); ascBtn.TextColor3=Color3.fromRGB(8,20,34)
	if rank >= 5 or essence < cost then setButtonEnabled(ascBtn, false, COLORS.accent) if essence < cost and rank < 5 then ascBtn.Text = "Not Enough Essence" end else ascBtn.Activated:Connect(function() context.Controllers.BugFarm.Ascend(uid) if detailOverlay then detailOverlay:Destroy(); detailOverlay=nil end end) end

	applyNoTextStrokeRecursive(panel)

	detailOverlay.Activated:Connect(function() if detailOverlay then detailOverlay:Destroy() detailOverlay = nil end end)
	panel.InputBegan:Connect(function() end)
end


local function isValidFarmerFilter(filterId)
	if filterId == "All" then return true end
	for _, sf in ipairs(FARMER_STAT_FILTERS) do
		if sf.Id == filterId then return true end
	end
	return false
end

local function makeIconButton(parent, emoji, fallback, color)
	local b = makeButton(parent, emoji, color or Color3.fromRGB(33, 57, 86), UDim2.fromOffset(36, 34))
	b.TextSize = 16
	if b.Text == "" then b.Text = fallback end
	return b
end


local function getSlotUid(slot)
	if type(slot) == "string" then return slot end
	if type(slot) ~= "table" then return nil end
	return slot.Uid or slot.uid or slot.BugUid or slot.bugUid or slot.Id or slot.id
end

local function getOwnedBugUidNormalized(ownedBug, fallbackUid)
	if type(ownedBug) ~= "table" then return fallbackUid end
	return ownedBug.Uid or ownedBug.uid or ownedBug.Id or ownedBug.id or ownedBug.InstanceId or fallbackUid
end

local function findOwnedBugByUid(inventory, uid)
	if uid == nil or inventory == nil then return nil end
	local target = tostring(uid)
	if type(inventory) == "table" then
		local direct = inventory[uid] or inventory[target]
		if type(direct) == "table" then return direct end
		for key, bug in pairs(inventory) do
			if type(bug) == "table" then
				local bugUid = getOwnedBugUidNormalized(bug, key)
				if bugUid ~= nil and tostring(bugUid) == target then return bug end
			end
		end
	end
	return nil
end

local function getEquippedFarmerBugs(farmerSlots, inventory)
	local equipped = {}
	for slotIndex, slot in ipairs(farmerSlots or {}) do
		local uid = getSlotUid(slot)
		if uid ~= nil then
			local bug = findOwnedBugByUid(inventory, uid)
			if bug then
				table.insert(equipped, {
					SlotIndex = slotIndex,
					Uid = uid,
					Bug = bug,
					Config = getBugConfig(bug) or {},
				})
			end
		end
	end
	return equipped
end

local function renderFarmersTab(context, scroll, bugs, inventory, owned, farmerSlots, combatSlots)
	if not isValidFarmerFilter(farmerStatFilter) then farmerStatFilter = "All" end
	local slotCount = getFarmerSlotCount(context, bugs)
	local equipped = getEquippedFarmerBugs(farmerSlots, inventory)

	local habitat = makeCard(scroll, UDim2.new(1,-20,0,176)); habitat.LayoutOrder = 1; habitat.BackgroundColor3 = Color3.fromRGB(18,50,38); habitat.ClipsDescendants=true
	local stroke = Instance.new("UIStroke", habitat); stroke.Color = Color3.fromRGB(76, 190, 178); stroke.Transparency = 0.15; stroke.Thickness = 1.4
	local topBand = Instance.new("Frame"); topBand.Size=UDim2.new(1,0,0.36,0); topBand.BackgroundColor3=Color3.fromRGB(17,57,41); topBand.BorderSizePixel=0; topBand.Parent=habitat
	local grassBand = Instance.new("Frame"); grassBand.Size=UDim2.new(1,0,0.44,0); grassBand.Position=UDim2.new(0,0,0.36,0); grassBand.BackgroundColor3=Color3.fromRGB(28,82,54); grassBand.BorderSizePixel=0; grassBand.Parent=habitat
	local soil = Instance.new("Frame"); soil.Size=UDim2.new(1,0,0.2,0); soil.Position=UDim2.new(0,0,0.8,0); soil.BackgroundColor3=Color3.fromRGB(43,35,25); soil.BorderSizePixel=0; soil.Parent=habitat
	local vignette = Instance.new("Frame"); vignette.Size=UDim2.new(1,-8,1,-8); vignette.Position=UDim2.fromOffset(4,4); vignette.BackgroundTransparency=1; vignette.Parent=habitat
	local inner = Instance.new("UIStroke", vignette); inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; inner.Color = Color3.fromRGB(6,20,16); inner.Transparency = 0.55; inner.Thickness = 2

	local bgImage = FARMER_HABITAT_BACKGROUND_IMAGE
	if type(bgImage)=="string" and bgImage ~= "" then local img=Instance.new("ImageLabel"); img.Size=UDim2.fromScale(1,1); img.BackgroundTransparency=1; img.Image=bgImage; img.ScaleType=Enum.ScaleType.Crop; img.Parent=habitat end

	for idx, entry in ipairs(equipped) do
		local aura = Instance.new("Frame"); aura.Size=UDim2.fromOffset(64,64); aura.BackgroundColor3=getRarityColor(tostring(entry.Config.rarity or entry.Bug.Rarity or "Common")); aura.BackgroundTransparency=0.78; aura.BorderSizePixel=0; aura.Parent=habitat; Instance.new("UICorner", aura).CornerRadius=UDim.new(1,0)
		local icon = Instance.new("ImageLabel"); icon.Name = "HabitatBug"; icon.Size=UDim2.fromOffset(56,56); icon.BackgroundTransparency=1; icon.Image=getBugIcon(entry.Bug,entry.Config); icon.Parent=habitat
		local baseX = 12 + ((idx * 86) % 220)
		local baseY = 24 + ((idx * 52) % 88)
		aura.Position = UDim2.fromOffset(baseX - 4, baseY - 4)
		icon.Position = UDim2.fromOffset(baseX, baseY)
		task.spawn(function()
			local TweenService = game:GetService("TweenService")
			while icon.Parent == habitat do
				local w, h = habitat.AbsoluteSize.X, habitat.AbsoluteSize.Y
				local minX, maxX = 8, math.max(8, w - icon.AbsoluteSize.X - 8)
				local minY, maxY = 10, math.max(10, h - icon.AbsoluteSize.Y - 10)
				local tx = math.random(minX, maxX)
				local ty = math.random(minY, maxY)
				local tweenInfo = TweenInfo.new(5 + math.random() * 3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				local ti = TweenService:Create(icon, tweenInfo, {Position = UDim2.fromOffset(tx, ty)})
				local ta = TweenService:Create(aura, tweenInfo, {Position = UDim2.fromOffset(tx - 4, ty - 4)})
				ti:Play(); ta:Play(); ti.Completed:Wait(); if icon.Parent ~= habitat then break end
			end
		end)
	end
	if #equipped == 0 then local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text="Equip bugs to see them here."; t.TextSize=18; styleLabel(t,true); t.TextColor3=COLORS.muted; t.Parent=habitat end

	local pills = Instance.new("ScrollingFrame"); pills.Size=UDim2.new(1,-20,0,36); pills.LayoutOrder=2; pills.BackgroundTransparency=1; pills.ScrollBarThickness=2; pills.ScrollingDirection=Enum.ScrollingDirection.X; pills.CanvasSize=UDim2.fromOffset(0,0); pills.Parent=scroll
	local ppad=Instance.new("UIPadding", pills); ppad.PaddingLeft=UDim.new(0,8); ppad.PaddingRight=UDim.new(0,8)
	local pl = Instance.new("UIListLayout", pills); pl.FillDirection=Enum.FillDirection.Horizontal; pl.Padding=UDim.new(0,6)
	pl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() pills.CanvasSize = UDim2.fromOffset(pl.AbsoluteContentSize.X + 20, 0) end)
	local totals = getActiveFarmerTotals(farmerSlots, inventory); local countP=0
	for _,sf in ipairs(FARMER_STAT_FILTERS) do if sf.Id ~= "All" then local total=totals[sf.Id] or 0; if total > 0 then countP+=1; local maxV=getStatMaxForSlots(sf.Id, slotCount); local b=makeBadge(pills, string.format("%s / %s %s", formatPercent(total), formatPercent(maxV), sf.Label), Color3.fromRGB(54,104,133)); b.Size=UDim2.fromOffset(212,28); local bs=b:FindFirstChildOfClass("UIStroke"); if bs then bs.Color=Color3.fromRGB(115,190,222) end end end end
	if countP==0 then local b=makeBadge(pills,"No active farmer buffs",Color3.fromRGB(74,93,116)); b.Size=UDim2.fromOffset(210,28); setBadgeTextColor(b, COLORS.text) end

	local inst=Instance.new("TextLabel"); inst.Size=UDim2.new(1,-20,0,30); inst.LayoutOrder=3; inst.BackgroundTransparency=1; inst.TextXAlignment=Enum.TextXAlignment.Left; inst.TextWrapped=true; inst.Text="Equip bugs here for passive buffs. Catch bugs on your home screen to fill your collection."; inst.TextSize=13; styleLabel(inst,false); inst.TextColor3=Color3.fromRGB(138,162,190); inst.Parent=scroll
	local eqh=Instance.new("TextLabel"); eqh.Size=UDim2.new(1,-20,0,24); eqh.LayoutOrder=4; eqh.BackgroundTransparency=1; eqh.TextXAlignment=Enum.TextXAlignment.Left; eqh.Text=string.format("Equipped (%d/%d)", #equipped, slotCount); eqh.TextSize=18; styleLabel(eqh,true); eqh.TextColor3=COLORS.accent; eqh.Parent=scroll
	local equippedList = Instance.new("Frame"); equippedList.Size=UDim2.new(1,-20,0,0); equippedList.AutomaticSize=Enum.AutomaticSize.Y; equippedList.BackgroundTransparency=1; equippedList.LayoutOrder=5; equippedList.Parent=scroll
	Instance.new("UIListLayout", equippedList).Padding=UDim.new(0,8)
	if #equipped==0 then local e=makeCard(equippedList, UDim2.new(1,0,0,56)); local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text="No farmer bugs equipped."; styleLabel(t,false); t.TextColor3=COLORS.muted; t.Parent=e end
	for _,e in ipairs(equipped) do local row=makeCard(equippedList, UDim2.new(1,0,0,68)); row.BackgroundColor3=Color3.fromRGB(15,34,56); local i=Instance.new("ImageLabel"); i.Size=UDim2.fromOffset(46,46); i.Position=UDim2.fromOffset(14,11); i.BackgroundTransparency=1; i.Image=getBugIcon(e.Bug,e.Config); i.Parent=row; local n=Instance.new("TextLabel"); n.Size=UDim2.new(1,-190,0,22); n.Position=UDim2.fromOffset(76,9); n.BackgroundTransparency=1; n.TextXAlignment=Enum.TextXAlignment.Left; n.Text=getDisplayName(e.Bug,e.Config); n.TextSize=17; styleLabel(n,true); n.TextColor3=getRarityColor(tostring(e.Config.rarity or e.Bug.Rarity or "Common")); n.Parent=row; local st=Instance.new("TextLabel"); st.Size=UDim2.new(1,-190,0,20); st.Position=UDim2.fromOffset(76,34); st.BackgroundTransparency=1; st.TextXAlignment=Enum.TextXAlignment.Left; local btxt={}; for _,b in ipairs(getFarmerBonuses(e.Bug)) do table.insert(btxt, formatBonus(b)) end; st.Text=(#btxt>0) and table.concat(btxt," | ") or "No farmer bonus"; styleLabel(st,false); st.TextColor3=(#btxt>0) and COLORS.good or COLORS.muted; st.Parent=row; local rm=makeButton(row,"Remove",Color3.fromRGB(160,58,58),UDim2.fromOffset(92,34)); rm.Position=UDim2.new(1,-104,0.5,-17); rm.Activated:Connect(function() context.Controllers.BugFarm.UnequipFarmer(e.SlotIndex) end) end

	local fs=Instance.new("ScrollingFrame"); fs.Size=UDim2.new(1,-20,0,42); fs.LayoutOrder=6; fs.BackgroundTransparency=1; fs.ScrollBarThickness=2; fs.ScrollingDirection=Enum.ScrollingDirection.X; fs.CanvasSize=UDim2.fromOffset(0,0); fs.Parent=scroll
	local fpad=Instance.new("UIPadding",fs); fpad.PaddingLeft=UDim.new(0,10); fpad.PaddingRight=UDim.new(0,10)
	local fsl=Instance.new("UIListLayout",fs); fsl.FillDirection=Enum.FillDirection.Horizontal; fsl.Padding=UDim.new(0,8)
	fsl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() fs.CanvasSize = UDim2.fromOffset(fsl.AbsoluteContentSize.X + 24, 0) end)
	for _,sf in ipairs(FARMER_STAT_FILTERS) do local active=farmerStatFilter==sf.Id; local b=makeButton(fs,sf.Label,active and Color3.fromRGB(76,196,220) or Color3.fromRGB(33,57,86),UDim2.fromOffset(math.max(96,#sf.Label*8+26),32)); if active then b.TextColor3=Color3.fromRGB(9,23,35) end; b.TextStrokeTransparency=1; b.Activated:Connect(function() farmerStatFilter=sf.Id if render then render(context) end end) end

	local hdr=makeCard(scroll, UDim2.new(1,-20,0,52)); hdr.LayoutOrder=7; hdr.BackgroundColor3=Color3.fromRGB(14,31,52)
	local h=Instance.new("TextLabel"); h.Size=UDim2.new(0.52,0,1,0); h.BackgroundTransparency=1; h.TextXAlignment=Enum.TextXAlignment.Left; h.Text=string.format("Your Bugs (%d/%d)", #owned, tonumber(BugConfig.MaxOwnedBugs) or 1000); h.TextSize=18; styleLabel(h,true); h.TextColor3=Color3.fromRGB(226,241,255); h.Parent=hdr
	for i,m in ipairs({"Rarity","Buff","Type"}) do local active=farmerSortMode==m; local c=active and Color3.fromRGB(76,196,220) or Color3.fromRGB(33,57,86); local b=makeButton(hdr,m,c,UDim2.fromOffset(70,30)); b.Position=UDim2.new(1,-(232-(i-1)*78),0.5,-15); if active then b.TextColor3=Color3.fromRGB(9,23,35) end; b.Activated:Connect(function() farmerSortMode=m if render then render(context) end end) end

	local rows={} for _,e in ipairs(owned) do if farmerStatFilter=="All" or hasBonusStat(e.Bug, farmerStatFilter) then table.insert(rows,e) end end
	table.sort(rows,function(a,b) local acfg,bcfg=getBugConfig(a.Bug) or {}, getBugConfig(b.Bug) or {}; if farmerSortMode=="Type" then local ar=tostring(acfg.role or acfg.species or ""); local br=tostring(bcfg.role or bcfg.species or ""); if ar~=br then return ar<br end elseif farmerSortMode=="Buff" then local av=(farmerStatFilter=="All") and getBestFarmerBonusValue(a.Bug) or getBonusValueForStat(a.Bug,farmerStatFilter); local bv=(farmerStatFilter=="All") and getBestFarmerBonusValue(b.Bug) or getBonusValueForStat(b.Bug,farmerStatFilter); if av~=bv then return av>bv end else local ar=BugConfig.RarityOrder[tostring(acfg.rarity or a.Bug.Rarity or "Common")] or 1; local br=BugConfig.RarityOrder[tostring(bcfg.rarity or b.Bug.Rarity or "Common")] or 1; if ar~=br then return ar>br end end return getDisplayName(a.Bug,acfg)<getDisplayName(b.Bug,bcfg) end)
	local availableList = Instance.new("Frame"); availableList.Size=UDim2.new(1,-20,0,0); availableList.AutomaticSize=Enum.AutomaticSize.Y; availableList.BackgroundTransparency=1; availableList.LayoutOrder=8; availableList.Parent=scroll
	Instance.new("UIListLayout", availableList).Padding=UDim.new(0,8)
	for _,e in ipairs(rows) do local uid,bug,cfg=e.Uid,e.Bug,getBugConfig(e.Bug) or {}; local row=makeCard(availableList, UDim2.new(1,0,0,76)); row.BackgroundColor3=Color3.fromRGB(15,34,56); local i=Instance.new("ImageLabel"); i.Size=UDim2.fromOffset(48,48); i.Position=UDim2.fromOffset(12,14); i.BackgroundTransparency=1; i.Image=getBugIcon(bug,cfg); i.Parent=row; local n=Instance.new("TextLabel"); n.Size=UDim2.new(1,-320,0,22); n.Position=UDim2.fromOffset(72,7); n.BackgroundTransparency=1; n.TextXAlignment=Enum.TextXAlignment.Left; n.Text=getDisplayName(bug,cfg); n.TextSize=17; styleLabel(n,true); n.TextColor3=getRarityColor(tostring(cfg.rarity or bug.Rarity or "Common")); n.Parent=row; local sub=Instance.new("TextLabel"); sub.Size=UDim2.new(1,-320,0,18); sub.Position=UDim2.fromOffset(72,29); sub.BackgroundTransparency=1; sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Text=string.format("%s • %s", tostring(cfg.role or "Unknown"), tostring(cfg.species or bug.BugId or "Unknown")); styleLabel(sub,false); sub.TextColor3=COLORS.muted; sub.Parent=row; local btxt={}; for _,b in ipairs(getFarmerBonuses(bug)) do table.insert(btxt, formatBonus(b)) end; local bon=Instance.new("TextLabel"); bon.Size=UDim2.new(1,-320,0,18); bon.Position=UDim2.fromOffset(72,50); bon.BackgroundTransparency=1; bon.TextXAlignment=Enum.TextXAlignment.Left; bon.Text=(#btxt>0) and table.concat(btxt," | ") or "No farmer bonus"; styleLabel(bon,false); bon.TextColor3=(#btxt>0) and COLORS.good or COLORS.muted; bon.Parent=row; local lk=makeIconButton(row, isBugLocked(bug) and "🔓" or "🔒", "Lock", Color3.fromRGB(39,66,92)); lk.Size=UDim2.fromOffset(34,34); lk.Position=UDim2.new(1,-214,0.5,-17); local rn=makeIconButton(row,"✏️","Edit",Color3.fromRGB(39,76,104)); rn.Size=UDim2.fromOffset(34,34); rn.Position=UDim2.new(1,-174,0.5,-17); lk.Activated:Connect(function() context.Controllers.BugFarm.ToggleLock(uid) end); rn.Activated:Connect(function() renameTargetUid=uid if render then render(context) end end); if isAssignedFarmer(uid, farmerSlots) then local b=makeBadge(row,"Equipped",Color3.fromRGB(70,196,156)); b.Position=UDim2.new(1,-96,0.5,-11) elseif isAssignedCombat(uid, combatSlots) then local b=makeBadge(row,"Combat Team",Color3.fromRGB(118,132,152)); b.Position=UDim2.new(1,-128,0.5,-11) else local eq=makeButton(row,"Equip",Color3.fromRGB(35,194,157),UDim2.fromOffset(88,32)); eq.Position=UDim2.new(1,-96,0.5,-16); eq.Activated:Connect(function() context.Controllers.BugFarm.EquipFarmer(uid,nil) end) end end

	if renameTargetUid and inventory[renameTargetUid] then local modal=Instance.new("TextButton"); modal.Size=UDim2.fromScale(1,1); modal.Text=""; modal.BackgroundColor3=Color3.new(0,0,0); modal.BackgroundTransparency=0.35; modal.Parent=contentHost; local card=makeCard(modal, UDim2.fromOffset(360,180)); card.Position=UDim2.new(0.5,-180,0.5,-90); card.BackgroundColor3=Color3.fromRGB(11,27,46); local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-20,0,28); title.Position=UDim2.fromOffset(10,10); title.BackgroundTransparency=1; title.Text="Rename Bug"; styleLabel(title,true); title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=card; local tb=Instance.new("TextBox"); tb.Size=UDim2.new(1,-20,0,36); tb.Position=UDim2.fromOffset(10,48); tb.BackgroundColor3=COLORS.cardDark; tb.ClearTextOnFocus=false; tb.Text=tostring(inventory[renameTargetUid].Nickname or (getBugConfig(inventory[renameTargetUid]) or {}).displayName or ""); tb.TextSize=14; tb.TextXAlignment=Enum.TextXAlignment.Left; tb.TextEditable=true; tb.MaxVisibleGraphemes=24; styleLabel(tb,false); tb.Parent=card; Instance.new("UICorner",tb).CornerRadius=UDim.new(0,8); local sv=makeButton(card,"Save",COLORS.good,UDim2.fromOffset(90,30)); sv.Position=UDim2.fromOffset(10,132); sv.Activated:Connect(function() context.Controllers.BugFarm.RenameBug(renameTargetUid, string.sub(tb.Text,1,24)); renameTargetUid=nil; if render then render(context) end end); local cl=makeButton(card,"Clear",Color3.fromRGB(91,110,138),UDim2.fromOffset(90,30)); cl.Position=UDim2.fromOffset(110,132); cl.Activated:Connect(function() context.Controllers.BugFarm.RenameBug(renameTargetUid,""); renameTargetUid=nil; if render then render(context) end end); local cn=makeButton(card,"Cancel",COLORS.danger,UDim2.fromOffset(90,30)); cn.Position=UDim2.fromOffset(210,132); cn.Activated:Connect(function() renameTargetUid=nil; if render then render(context) end end) end
end


render = function(context)
	if not root then return end
	clear(contentHost)
	local bugs = getBugsState(context)
	local inventory = bugs.Inventory or {}
	local owned = getOwnedList(inventory)
	local farmerSlots = bugs.FarmerSlots or {}
	local combatSlots = bugs.CombatSlots or {}
	for name, button in pairs(tabButtons) do
		local isActive = name == selectedTab
		button.BackgroundColor3 = isActive and Color3.fromRGB(33, 76, 124) or Color3.fromRGB(20, 35, 56)
		button.TextColor3 = isActive and COLORS.text or Color3.fromRGB(184, 203, 226)
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = isActive and COLORS.accent or Color3.fromRGB(74, 94, 118)
			stroke.Transparency = isActive and 0.08 or 0.45
			stroke.Thickness = isActive and 1.8 or 1
		end
		local underline = button:FindFirstChild("ActiveUnderline")
		if underline then underline.Visible = isActive end
	end

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 8
	scroll.BackgroundTransparency = 1
	scroll.Parent = contentHost
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	Instance.new("UIPadding", scroll).PaddingLeft = UDim.new(0, 10)

	if selectedTab == "Farmers" then
		renderFarmersTab(context, scroll, bugs, inventory, owned, farmerSlots, combatSlots)
		applyNoTextStrokeRecursive(scroll)
		return
	end

	local summary = makeCard(scroll, UDim2.new(1, -20, 0, 98))
	summary.BackgroundColor3 = Color3.fromRGB(10, 24, 42)
	local summaryStroke = summary:FindFirstChildOfClass("UIStroke")
	if summaryStroke then summaryStroke.Color = Color3.fromRGB(86, 214, 228) summaryStroke.Transparency = 0.4 end
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
	summaryText.Visible = false
	local lockedCount = 0
	for _, b in pairs(inventory) do if b.Locked then lockedCount += 1 end end
	local highest = "None"
	local highestOrder = 0
	local totalPower = 0
	for _, ob in pairs(inventory) do
		local cfg = getBugConfig(ob) or {}
		local r = tostring(cfg.rarity or ob.Rarity or "Common")
		local o = BugConfig.RarityOrder[r] or 1
		if o > highestOrder then highestOrder = o highest = r end
		totalPower += getBugPower(cfg)
	end
	if selectedTab == "Farmers" then
		summaryText.Text = string.format("Equipped: %d / %d\nExtra Slots: %d / 10", #farmerSlots, 5 + tonumber(bugs.ExtraFarmerSlotsPurchased or 0), tonumber(bugs.ExtraFarmerSlotsPurchased or 0))
	end
	if selectedTab == "Combat Team" then
		summaryText.Text = string.format("Equipped: %d / 5\nTeam Power: %d", #combatSlots, 0)
	elseif selectedTab == "Recycling" then
		summaryText.Text = string.format("Bug Essence: %s\nSelected: %d bugs\nRecycle Value: +%d Essence", tostring(bugs.Essence or 0), selectedCount, selectedValue)
	end
	if selectedTab == "My Bugs" then
		local subtitle = Instance.new("TextLabel")
		subtitle.BackgroundTransparency = 1
		subtitle.Size = UDim2.new(0.58, -8, 0, 36)
		subtitle.Position = UDim2.fromOffset(10, 34)
		subtitle.Text = "Manage your owned bugs, assignments, equipment, and ascension."
		subtitle.TextSize = 12
		subtitle.TextWrapped = true
		subtitle.TextXAlignment = Enum.TextXAlignment.Left
		subtitle.TextYAlignment = Enum.TextYAlignment.Top
		styleLabel(subtitle, false)
		subtitle.TextColor3 = COLORS.muted
		subtitle.Parent = summary
		local stats = {
			{"Owned Bugs", tostring(#owned), COLORS.accent},
			{"Total Power", formatNum(totalPower), COLORS.good},
		}
		for i, st in ipairs(stats) do
			local tile = makeCard(summary, UDim2.fromOffset(168, 56))
			tile.BackgroundColor3 = COLORS.cardDark
			tile.Position = UDim2.new(1, -354 + (i - 1) * 176, 0, 20)
			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.new(1, -10, 0, 16)
			lbl.Position = UDim2.fromOffset(6, 8)
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Text = st[1]
			lbl.TextSize = 11
			styleLabel(lbl, false)
			lbl.TextColor3 = COLORS.muted
			lbl.Parent = tile
			local val = Instance.new("TextLabel")
			val.BackgroundTransparency = 1
			val.Size = UDim2.new(1, -10, 0, 24)
			val.Position = UDim2.fromOffset(6, 22)
			val.TextXAlignment = Enum.TextXAlignment.Left
			val.Text = tostring(st[2])
			val.TextSize = 18
			styleLabel(val, true)
			val.TextColor3 = st[3]
			val.Parent = tile
		end
		else
		summaryText.Size = UDim2.new(1, -14, 1, -36)
		summaryText.Position = UDim2.fromOffset(10, 32)
		summaryText.TextXAlignment = Enum.TextXAlignment.Left
		summaryText.TextYAlignment = Enum.TextYAlignment.Top
		summaryText.TextSize = 14
		styleLabel(summaryText, false)
		summaryText.TextColor3 = COLORS.muted
		summaryText.Visible = true
		summaryText.Parent = summary
	end

	local controls = makeCard(scroll, UDim2.new(1, -20, 0, 50))
	local search = Instance.new("TextBox")
	search.PlaceholderText = "Search bugs..."
	search.Text = searchQuery
	search.Size = UDim2.new(0.68, -10, 0, 34)
	search.Position = UDim2.fromOffset(8, 8)
	search.BackgroundColor3 = COLORS.cardDark
	search.TextSize = 13
	search.ClearTextOnFocus = false
	styleLabel(search, false)
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.TextStrokeTransparency = 1
	search.Parent = controls
	Instance.new("UICorner", search).CornerRadius = UDim.new(0, 8)
	search:GetPropertyChangedSignal("Text"):Connect(function() searchQuery = search.Text render(context) end)
	local sort = makeButton(controls, "Sort: " .. sortMode, Color3.fromRGB(31, 73, 116), UDim2.new(0.30, -2, 0, 34))
	sort.Position = UDim2.new(0.70, 0, 0, 8)
	sort.Activated:Connect(function()
		local idx = table.find(sortModes, sortMode) or 1
		sortMode = sortModes[(idx % #sortModes) + 1]
		render(context)
	end)

	if selectedTab == "Combat Team" then
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

	if selectedTab == "My Bugs" then
		local filterBar = makeCard(scroll, UDim2.new(1, -20, 0, 48))
		local wrap = Instance.new("Frame"); wrap.BackgroundTransparency=1; wrap.Size=UDim2.new(1,-8,1,-8); wrap.Position=UDim2.fromOffset(4,4); wrap.Parent=filterBar
		local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center; tabLayout.Padding = UDim.new(0, 7); tabLayout.Parent=wrap
		for _, r in ipairs(rarityTabs) do
			local color = getRarityColor(r)
			local tinted = r == "All" and Color3.fromRGB(70, 94, 124) or color:Lerp(Color3.fromRGB(10, 22, 40), 0.62)
			local b = makeButton(wrap, r, r == rarityFilter and color or tinted, UDim2.fromOffset(92, 32))
			b.TextColor3 = r == rarityFilter and Color3.fromRGB(245, 252, 255) or Color3.fromRGB(208, 221, 240)
			local s = b:FindFirstChildOfClass("UIStroke"); if s then s.Color = color s.Transparency = r == rarityFilter and 0.12 or 0.52 s.Thickness = r == rarityFilter and 1.5 or 1 end
			if r == rarityFilter then local u = Instance.new("Frame"); u.Size=UDim2.new(1,-18,0,2); u.Position=UDim2.new(0,9,1,-4); u.BackgroundColor3=color; u.BorderSizePixel=0; u.Parent=b end
			b.Activated:Connect(function() rarityFilter = r render(context) end)
		end
		local gridWrap = makeCard(scroll, UDim2.new(1, -20, 0, 260))
		gridWrap.BackgroundColor3 = Color3.fromRGB(10, 23, 41)
		local gridPad = Instance.new("UIPadding", gridWrap)
		gridPad.PaddingLeft = UDim.new(0, 12)
		gridPad.PaddingRight = UDim.new(0, 12)
		gridPad.PaddingTop = UDim.new(0, 12)
		gridPad.PaddingBottom = UDim.new(0, 12)
		local gridContent = Instance.new("Frame")
		gridContent.BackgroundTransparency = 1
		gridContent.Size = UDim2.new(1, -24, 0, 216)
		gridContent.Position = UDim2.fromOffset(12, 12)
		gridContent.Parent = gridWrap
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(170, 216)
		grid.CellPadding = UDim2.fromOffset(12, 12)
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
		grid.VerticalAlignment = Enum.VerticalAlignment.Top
		grid.Parent = gridContent

		local display = {}
		for _, entry in ipairs(owned) do table.insert(display, entry) end
		table.sort(display, function(a, b)
			local aCfg, bCfg = getBugConfig(a.Bug), getBugConfig(b.Bug)
			local aUid, bUid = tostring(a.Uid), tostring(b.Uid)
			if sortMode == "Name" then return tostring((aCfg and aCfg.displayName) or getOwnedBugBugId(a.Bug) or "") < tostring((bCfg and bCfg.displayName) or getOwnedBugBugId(b.Bug) or "") end
			if sortMode == "Species" then return tostring((aCfg and aCfg.species) or "") < tostring((bCfg and bCfg.species) or "") end
			if sortMode == "Locked First" then return (isBugLocked(a.Bug) and 1 or 0) > (isBugLocked(b.Bug) and 1 or 0) end
			if sortMode == "Farmer Equipped" then return (isAssignedFarmer(aUid, farmerSlots) and 1 or 0) > (isAssignedFarmer(bUid, farmerSlots) and 1 or 0) end
			if sortMode == "Combat Equipped" then return (isAssignedCombat(aUid, combatSlots) and 1 or 0) > (isAssignedCombat(bUid, combatSlots) and 1 or 0) end
			if sortMode == "Power" then return getBugPower(aCfg) > getBugPower(bCfg) end
			local ar = BugConfig.RarityOrder[tostring((aCfg and aCfg.rarity) or a.Bug.Rarity or "Common")] or 1
			local br = BugConfig.RarityOrder[tostring((bCfg and bCfg.rarity) or b.Bug.Rarity or "Common")] or 1
			return ar > br
		end)

		local shown = 0
		for _, entry in ipairs(display) do
			local uid, bug = entry.Uid, entry.Bug
			local cfg = getBugConfig(bug) or {}
			local rarity = tostring(cfg.rarity or bug.Rarity or "Common")
			local assign = getAssignmentStatus(uid, farmerSlots, combatSlots)
			local hay = string.lower(table.concat({tostring(cfg.displayName or "Unknown Bug"), tostring(cfg.species or ""), tostring(cfg.role or ""), rarity, assign}, " "))
			if (rarityFilter == "All" or rarity == rarityFilter) and (searchQuery == "" or string.find(hay, string.lower(searchQuery), 1, true)) then
				shown += 1
				local card = makeCard(gridContent, UDim2.fromOffset(170, 216))
				card.BackgroundColor3 = COLORS.card
				card.ClipsDescendants = false
				local cardPad = Instance.new("UIPadding", card)
				cardPad.PaddingLeft = UDim.new(0, 8)
				cardPad.PaddingRight = UDim.new(0, 8)
				cardPad.PaddingTop = UDim.new(0, 8)
				cardPad.PaddingBottom = UDim.new(0, 8)
				local stroke = card:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Color = getRarityColor(rarity) stroke.Thickness = (BugConfig.RarityOrder[rarity] or 1) >= 4 and 2 or 1.5 end
				local icon = Instance.new("ImageLabel"); icon.BackgroundTransparency = 1; icon.Size = UDim2.fromOffset(82, 82); icon.Position = UDim2.new(0.5, -41, 0, 38); icon.Image = tostring(cfg.icon or ""); icon.Parent = card
				local name = Instance.new("TextLabel"); name.BackgroundTransparency = 1; name.Size = UDim2.new(1, -16, 0, 34); name.Position = UDim2.fromOffset(8, 126); name.Text = tostring(cfg.displayName or "Unknown Bug"); name.TextWrapped = true; name.TextSize = 14; styleLabel(name, true); name.Parent = card
				local sub = Instance.new("TextLabel"); sub.BackgroundTransparency = 1; sub.Size = UDim2.new(1, -16, 0, 16); sub.Position = UDim2.fromOffset(8, 150); sub.Text = tostring(cfg.role or cfg.species or "Unknown"); sub.TextSize = 12; sub.TextColor3 = COLORS.muted; styleLabel(sub, false); sub.Parent = card
				local badgeColor, badgeText = getAssignmentBadgeStyle(assign)
				local asn = makeBadge(card, assign, badgeColor); asn.Size = UDim2.fromOffset(104, 20); asn.Position = UDim2.new(0.5, -52, 0, 170); setBadgeTextColor(asn, badgeText)
				local rarityBadge = makeBadge(card, rarity, getRarityColor(rarity)); rarityBadge.Size = UDim2.fromOffset(78, 18); rarityBadge.Position = UDim2.fromOffset(8, 8)
				local previewBonus = getLegacyBonusStats(bug)[1]
				local p = Instance.new("TextLabel"); p.BackgroundTransparency = 1; p.Size = UDim2.new(1, -16, 0, 14); p.Position = UDim2.fromOffset(8, 194); p.Text = previewBonus and formatBonusLine(previewBonus) or "No bonus"; p.TextSize = 12; styleLabel(p, true); p.TextColor3 = COLORS.good; p.Parent = card
				if isBugLocked(bug) then local l=makeBadge(card, "LOCKED", COLORS.warn); l.Size=UDim2.fromOffset(62,18); l.Position=UDim2.new(1,-70,0,8); setBadgeTextColor(l, Color3.fromRGB(32, 22, 8)) end
				local asc = getBugAscension(bug); if asc > 0 then local a=makeBadge(card, "A"..tostring(asc), Color3.fromRGB(106, 229, 186)); a.Size=UDim2.fromOffset(38,18); a.Position=UDim2.fromOffset(88,8); setBadgeTextColor(a, Color3.fromRGB(10, 26, 20)) end
				local hoverHint = Instance.new("TextLabel"); hoverHint.BackgroundTransparency = 0.28; hoverHint.BackgroundColor3 = Color3.fromRGB(8, 20, 34); hoverHint.Size = UDim2.fromOffset(90, 18); hoverHint.Position = UDim2.new(1, -96, 1, -24); hoverHint.Text = "View Details"; hoverHint.TextSize = 10; hoverHint.Visible = false; styleLabel(hoverHint, true); hoverHint.Parent = card; Instance.new("UICorner", hoverHint).CornerRadius = UDim.new(0, 6)
				card.MouseEnter:Connect(function() card.BackgroundColor3 = COLORS.card:Lerp(Color3.new(1,1,1), 0.1); if stroke then stroke.Transparency = 0; stroke.Color = getRarityColor(rarity):Lerp(Color3.new(1,1,1), 0.1) end hoverHint.Visible = true end)
				card.MouseLeave:Connect(function() card.BackgroundColor3 = COLORS.card; if stroke then stroke.Transparency = 0.15; stroke.Color = getRarityColor(rarity) end hoverHint.Visible = false end)
				card.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then makeDetailPopup(context, uid, bug) end end)
			end
		end
		local cardsPerRow = math.max(1, math.floor(math.max(gridContent.AbsoluteSize.X, 1) / (170 + 12)))
		local rows = math.max(1, math.ceil(shown / cardsPerRow))
		local gridHeight = rows * 216 + math.max(0, rows - 1) * 12
		gridContent.Size = UDim2.new(1, -24, 0, gridHeight)
		gridWrap.Size = UDim2.new(1, -20, 0, gridHeight + 24)
		if shown == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, -20, 0, 80); empty.Position = UDim2.fromOffset(10, 180); empty.BackgroundTransparency = 1; empty.TextSize = 18
			empty.Text = (#owned == 0) and "No bugs owned.\nCatch bugs to build your collection." or "No bugs found.\nTry another search or filter."
			styleLabel(empty, true); empty.TextColor3 = COLORS.muted; empty.Parent = gridWrap
		end
	else for _, entry in ipairs(owned) do
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
			elseif selectedTab == "Combat Team" then
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
	end end

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
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			d.TextStrokeTransparency = 1
		end
		if d:IsA("UIStroke") and (d.Parent:IsA("TextLabel") or d.Parent:IsA("TextButton") or d.Parent:IsA("TextBox")) then
			d.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end
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
		local tab = makeButton(tabs, name, Color3.fromRGB(20, 35, 56), UDim2.fromOffset(170, 30))
		tab.Position = UDim2.fromOffset((i - 1) * 178, 4)
		tab.TextColor3 = Color3.fromRGB(184, 203, 226)
		local underline = Instance.new("Frame")
		underline.Name = "ActiveUnderline"
		underline.Size = UDim2.new(1, -18, 0, 2)
		underline.Position = UDim2.new(0, 9, 1, -3)
		underline.BackgroundColor3 = COLORS.accent
		underline.BorderSizePixel = 0
		underline.Visible = false
		underline.Parent = tab
		tab.Activated:Connect(function() selectedTab = name render(context) end)
		tabButtons[name] = tab
	end

	contentHost = Instance.new("Frame")
	contentHost.Size = UDim2.new(1, -16, 1, -58)
	contentHost.Position = UDim2.fromOffset(8, 56)
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
