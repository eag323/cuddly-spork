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
local rarityFilter = "All"
local sortModes = {"Rarity","Name","Species","Newest","Locked First","Farmer Equipped","Combat Equipped","Power"}
local rarityTabs = {"All","Common","Uncommon","Rare","Epic","Legendary","Mythic"}
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

local function makeBadge(parent, text, tint)
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(100, 22)
	badge.BackgroundColor3 = tint or getRarityColor(text)
	badge.BorderSizePixel = 0
	badge.Text = tostring(text)
	styleLabel(badge, true)
	badge.TextSize = 12
	badge.TextColor3 = Color3.fromRGB(8, 18, 30)
	badge.Parent = parent
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color = badge.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.25)
	stroke.Transparency = 0.35
	stroke.Parent = badge
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
	local assignColor = assignText == "Farmer" and Color3.fromRGB(72, 202, 164) or (assignText == "Combat" and Color3.fromRGB(94, 162, 255) or Color3.fromRGB(104, 124, 152))

	local panel = makeCard(detailOverlay, UDim2.fromOffset(760, 560))
	panel.Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(380, 280)
	panel.BackgroundColor3 = Color3.fromRGB(10, 24, 42)
	local stroke = panel:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = getRarityColor(rarity) stroke.Thickness = 2 stroke.Transparency = 0.15 end
	local pad = Instance.new("UIPadding", panel)
	pad.PaddingLeft = UDim.new(0, 16); pad.PaddingRight = UDim.new(0, 16); pad.PaddingTop = UDim.new(0, 16); pad.PaddingBottom = UDim.new(0, 16)
	local list = Instance.new("UIListLayout", panel)
	list.Padding = UDim.new(0, 10)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Left
	list.SortOrder = Enum.SortOrder.LayoutOrder

	local closeBtn = makeButton(panel, "X", COLORS.cardDark, UDim2.fromOffset(28, 28))
	closeBtn.LayoutOrder = 0
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -16, 0, 16)
	closeBtn.ZIndex = 3
	closeBtn.TextStrokeTransparency = 1
	closeBtn.Activated:Connect(function() if detailOverlay then detailOverlay:Destroy() detailOverlay = nil end end)

	local header = Instance.new("Frame")
	header.LayoutOrder = 1
	header.Size = UDim2.new(1, 0, 0, 125)
	header.BackgroundTransparency = 1
	header.Parent = panel
	local iconPanel = makeCard(header, UDim2.fromOffset(110, 110)); iconPanel.Position = UDim2.fromOffset(0, 8); iconPanel.BackgroundColor3 = COLORS.cardDark
	local icon = Instance.new("ImageLabel"); icon.BackgroundTransparency = 1; icon.Size = UDim2.fromOffset(96, 96); icon.Position = UDim2.fromOffset(7, 7); icon.Image = tostring(cfg.icon or ""); icon.Parent = iconPanel
	local right = Instance.new("Frame"); right.BackgroundTransparency = 1; right.Size = UDim2.new(1, -132, 1, 0); right.Position = UDim2.fromOffset(132, 0); right.Parent = header
	local name = Instance.new("TextLabel"); name.BackgroundTransparency=1; name.Size=UDim2.new(1,-120,0,34); name.Position=UDim2.fromOffset(0,10); name.TextXAlignment=Enum.TextXAlignment.Left; name.Text=tostring(cfg.displayName or getOwnedBugBugId(bug) or "Unknown Bug"); name.TextSize=27; styleLabel(name,true); name.Parent=right
	local rarityBadge = makeBadge(right, rarity, getRarityColor(rarity)); rarityBadge.Position = UDim2.fromOffset(0, 52); rarityBadge.Size = UDim2.fromOffset(120, 24)
	local assignBadge = makeBadge(right, assignText, assignColor); assignBadge.Position = UDim2.fromOffset(128, 52); assignBadge.Size = UDim2.fromOffset(140, 24)
	local species = Instance.new("TextLabel"); species.BackgroundTransparency=1; species.Size=UDim2.new(1,-10,0,20); species.Position=UDim2.fromOffset(0,84); species.TextXAlignment=Enum.TextXAlignment.Left; species.Text=tostring(cfg.role or "Unknown").." • "..tostring(cfg.species or "Unknown"); species.TextSize=13; styleLabel(species,false); species.TextColor3=COLORS.muted; species.Parent=right

	local statsSection = makeCard(panel, UDim2.new(1, 0, 0, 104)); statsSection.LayoutOrder = 2; statsSection.BackgroundColor3 = COLORS.cardDark; statsSection.Parent = panel
	local sTitle = makeSectionTitle(statsSection, "COMBAT STATS", 10)
	local chipWrap = Instance.new("Frame"); chipWrap.BackgroundTransparency=1; chipWrap.Size=UDim2.new(1,-20,0,56); chipWrap.Position=UDim2.fromOffset(10,34); chipWrap.Parent=statsSection
	local grid = Instance.new("UIGridLayout", chipWrap); grid.CellPadding = UDim2.fromOffset(8,6); grid.CellSize = UDim2.new(0.125, -7, 0, 46)
	local stats = cfg.stats or {}
	for _, entry in ipairs({{"HP","HP"},{"ATK","ATK"},{"DEF","DEF"},{"SPD","SPD"},{"CR","CritRate"},{"CD","CritDamage"},{"RES","RES"},{"ACC","ACC"}}) do
		local chip = makeCard(chipWrap, UDim2.new(0, 80, 0, 46)); chip.BackgroundColor3 = COLORS.card
		local l = Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Size=UDim2.new(1,0,0,14); l.Position=UDim2.fromOffset(0,5); l.Text=entry[1]; l.TextSize=10; styleLabel(l,false); l.TextColor3=COLORS.muted; l.Parent=chip
		local v = Instance.new("TextLabel"); v.BackgroundTransparency=1; v.Size=UDim2.new(1,0,0,16); v.Position=UDim2.fromOffset(0,22); v.Text=tostring(stats[entry[2]] or 0); v.TextSize=13; styleLabel(v,true); v.Parent=chip
	end

	local infoRow = Instance.new("Frame"); infoRow.LayoutOrder = 3; infoRow.Size = UDim2.new(1,0,0,118); infoRow.BackgroundTransparency = 1; infoRow.Parent = panel
	local buffsCard = makeCard(infoRow, UDim2.new(0.5, -6, 1, 0)); buffsCard.BackgroundColor3=COLORS.cardDark
	makeSectionTitle(buffsCard, "FARMING BUFFS", 8)
	local buffsText = Instance.new("TextLabel"); buffsText.BackgroundTransparency=1; buffsText.Size=UDim2.new(1,-16,1,-38); buffsText.Position=UDim2.fromOffset(8,32); buffsText.TextXAlignment=Enum.TextXAlignment.Left; buffsText.TextYAlignment=Enum.TextYAlignment.Top; buffsText.TextWrapped=true; buffsText.TextSize=12; styleLabel(buffsText,false); buffsText.TextColor3=COLORS.good; buffsText.Text=(#(cfg.idleBonuses or {})>0) and table.concat(cfg.idleBonuses, "\n") or "No farming buffs"; if #(cfg.idleBonuses or {})==0 then buffsText.TextColor3=COLORS.muted end; buffsText.Parent=buffsCard
	local abilityCard = makeCard(infoRow, UDim2.new(0.5, -6, 1, 0)); abilityCard.Position = UDim2.new(0.5, 6, 0, 0); abilityCard.BackgroundColor3 = COLORS.cardDark
	makeSectionTitle(abilityCard, "ABILITY", 8)
	local ability = cfg.ability
	local abName = Instance.new("TextLabel"); abName.BackgroundTransparency=1; abName.Size=UDim2.new(1,-16,0,18); abName.Position=UDim2.fromOffset(8,32); abName.TextXAlignment=Enum.TextXAlignment.Left; abName.Text=(ability and tostring(ability.name or "Ability")) or "No ability"; abName.TextSize=13; styleLabel(abName,true); abName.Parent=abilityCard
	local abDesc = Instance.new("TextLabel"); abDesc.BackgroundTransparency=1; abDesc.Size=UDim2.new(1,-16,0,58); abDesc.Position=UDim2.fromOffset(8,52); abDesc.TextXAlignment=Enum.TextXAlignment.Left; abDesc.TextYAlignment=Enum.TextYAlignment.Top; abDesc.TextWrapped=true; abDesc.Text=(ability and tostring(ability.description or "")) or ""; abDesc.TextSize=11; styleLabel(abDesc,false); abDesc.TextColor3=COLORS.muted; abDesc.Parent=abilityCard

	local equipSection = makeCard(panel, UDim2.new(1,0,0,100)); equipSection.LayoutOrder=4; equipSection.BackgroundColor3=COLORS.cardDark; equipSection.Parent=panel
	makeSectionTitle(equipSection, "EQUIPMENT", 8)
	local eqWrap = Instance.new("Frame"); eqWrap.BackgroundTransparency=1; eqWrap.Size=UDim2.new(1,-20,0,62); eqWrap.Position=UDim2.fromOffset(10,30); eqWrap.Parent=equipSection
	local eqLayout = Instance.new("UIListLayout", eqWrap); eqLayout.FillDirection=Enum.FillDirection.Horizontal; eqLayout.Padding=UDim.new(0,8)
	for _, slotName in ipairs({"Weapon","Helmet","Chestplate","Boots","Charm"}) do
		local slot = makeCard(eqWrap, UDim2.fromOffset(124, 62)); slot.BackgroundColor3=COLORS.card
		local s = Instance.new("TextLabel"); s.BackgroundTransparency=1; s.Size=UDim2.new(1,0,0,18); s.Position=UDim2.fromOffset(0,7); s.Text=slotName; s.TextSize=11; styleLabel(s,true); s.Parent=slot
		local c = Instance.new("TextLabel"); c.BackgroundTransparency=1; c.Size=UDim2.new(1,0,0,16); c.Position=UDim2.fromOffset(0,31); c.Text="Coming Soon"; c.TextSize=10; styleLabel(c,false); c.TextColor3=COLORS.muted; c.Parent=slot
	end

	local rank = getBugAscension(bug)
	local costTable = ((cfg.ascension or {}).essenceRequiredByRank) or FALLBACK_ASCENSION_COSTS[rarity] or FALLBACK_ASCENSION_COSTS.Common
	local cost = tonumber(costTable[rank + 1]) or tonumber(costTable[rank + 2]) or 0
	local essence = tonumber((((context.State.PlayerData or {}).Currencies or {}).BugEssence)) or 0
	local ascSec = makeCard(panel, UDim2.new(1,0,0,70)); ascSec.LayoutOrder=5; ascSec.BackgroundColor3=COLORS.cardDark; ascSec.Parent=panel
	makeSectionTitle(ascSec, "ASCENSION", 8)
	local ascInfo = Instance.new("TextLabel"); ascInfo.BackgroundTransparency=1; ascInfo.Size=UDim2.new(0.72,0,0,22); ascInfo.Position=UDim2.fromOffset(10,34); ascInfo.TextXAlignment=Enum.TextXAlignment.Left; ascInfo.Text=("Rank: %d / 5   Cost: %d Bug Essence   Essence: %d"):format(rank,cost,essence); ascInfo.TextSize=12; styleLabel(ascInfo,false); ascInfo.Parent=ascSec
	local ascBtn = makeButton(ascSec, rank >= 5 and "Max Rank" or "Ascend", COLORS.accent, UDim2.fromOffset(132, 32)); ascBtn.Position=UDim2.new(1,-142,0,26); ascBtn.TextColor3=Color3.fromRGB(8,20,34)
	if rank >= 5 or essence < cost then setButtonEnabled(ascBtn, false, COLORS.accent) else ascBtn.Activated:Connect(function() context.Controllers.BugFarm.Ascend(uid) if detailOverlay then detailOverlay:Destroy(); detailOverlay=nil end end) end

	local actionRow = Instance.new("Frame"); actionRow.LayoutOrder=6; actionRow.Size=UDim2.new(1,0,0,38); actionRow.BackgroundTransparency=1; actionRow.Parent=panel
	local actionLayout = Instance.new("UIListLayout", actionRow); actionLayout.FillDirection = Enum.FillDirection.Horizontal; actionLayout.Padding = UDim.new(0, 8)
	local farmerBtn = makeButton(actionRow, assignedFarmer and "Assigned Farmer" or "Equip Farmer", Color3.fromRGB(68, 170, 150), UDim2.new(0.25, -6, 1, 0)); setButtonEnabled(farmerBtn, not assignedFarmer, Color3.fromRGB(68,170,150)); farmerBtn.Activated:Connect(function() context.Controllers.BugFarm.EquipFarmer(uid, nil) end)
	local combatBtn = makeButton(actionRow, assignedCombat and "On Combat Team" or "Add Combat", Color3.fromRGB(82, 136, 220), UDim2.new(0.25, -6, 1, 0)); setButtonEnabled(combatBtn, not assignedCombat, Color3.fromRGB(82,136,220)); combatBtn.Activated:Connect(function() context.Controllers.BugFarm.EquipCombat(uid, nil) end)
	local lockBtn = makeButton(actionRow, isBugLocked(bug) and "Unlock" or "Lock", isBugLocked(bug) and COLORS.gold or Color3.fromRGB(120, 124, 132), UDim2.new(0.25, -6, 1, 0)); lockBtn.Activated:Connect(function() context.Controllers.BugFarm.ToggleLock(uid); if detailOverlay then detailOverlay:Destroy(); detailOverlay=nil end end)
	local recycleBtn = makeButton(actionRow, "Recycle", Color3.fromRGB(210, 108, 74), UDim2.new(0.25, -6, 1, 0)); setButtonEnabled(recycleBtn, not (isBugLocked(bug) or assignedFarmer or assignedCombat), Color3.fromRGB(210,108,74)); recycleBtn.Activated:Connect(function() context.Controllers.BugFarm.RecycleSelected({uid}) end)

	detailOverlay.Activated:Connect(function() if detailOverlay then detailOverlay:Destroy() detailOverlay = nil end end)
	panel.InputBegan:Connect(function() end)
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

	local summary = makeCard(scroll, UDim2.new(1, -20, 0, 186))
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
		local stats = {
			{"Owned Bugs", tostring(#owned), COLORS.text},
			{"Locked", tostring(lockedCount), COLORS.gold},
			{"Bug Essence", formatNum((context.State.PlayerData or {}).Currencies and (context.State.PlayerData or {}).Currencies.BugEssence or 0), COLORS.accent},
			{"Farmers", tostring(#farmerSlots), COLORS.good},
			{"Combat", tostring(#combatSlots), Color3.fromRGB(134, 180, 255)},
			{"Highest Rarity", highest, getRarityColor(highest)},
			{"Total Power", formatNum(totalPower), COLORS.text},
		}
		for i, st in ipairs(stats) do
			local col = (i - 1) % 4
			local row = math.floor((i - 1) / 4)
			local tile = makeCard(summary, UDim2.new(0.24, -6, 0, 58))
			tile.BackgroundColor3 = COLORS.cardDark
			tile.Position = UDim2.new(0.02 + col * 0.245, 0, 0, 36 + row * 64)
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
			val.Position = UDim2.fromOffset(6, 26)
			val.TextXAlignment = Enum.TextXAlignment.Left
			val.Text = tostring(st[2])
			val.TextSize = 15
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

	if selectedTab == "My Bugs" then
		local filterBar = makeCard(scroll, UDim2.new(1, -20, 0, 44))
		local wrap = Instance.new("Frame"); wrap.BackgroundTransparency=1; wrap.Size=UDim2.new(1,-8,1,-8); wrap.Position=UDim2.fromOffset(4,4); wrap.Parent=filterBar
		local tabLayout = Instance.new("UIGridLayout"); tabLayout.CellSize = UDim2.fromOffset(94, 32); tabLayout.CellPadding = UDim2.fromOffset(6, 4); tabLayout.FillDirectionMaxCells=7; tabLayout.Parent=wrap
		for _, r in ipairs(rarityTabs) do
			local color = getRarityColor(r)
			local tinted = r == "All" and Color3.fromRGB(70, 94, 124) or color:Lerp(Color3.fromRGB(10, 22, 40), 0.62)
			local b = makeButton(wrap, r, r == rarityFilter and color or tinted, UDim2.fromOffset(95, 30))
			b.TextColor3 = r == rarityFilter and Color3.fromRGB(12, 20, 30) or Color3.fromRGB(232, 240, 251)
			local s = b:FindFirstChildOfClass("UIStroke"); if s then s.Color = color s.Transparency = r == rarityFilter and 0.1 or 0.55 end
			b.Activated:Connect(function() rarityFilter = r render(context) end)
		end
		local gridWrap = makeCard(scroll, UDim2.new(1, -20, 0, 500))
		gridWrap.BackgroundColor3 = Color3.fromRGB(10, 23, 41)
		local gridScroll = Instance.new("ScrollingFrame")
		gridScroll.Size = UDim2.new(1, -12, 1, -12)
		gridScroll.Position = UDim2.fromOffset(6, 6)
		gridScroll.BackgroundTransparency = 1
		gridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		gridScroll.CanvasSize = UDim2.fromOffset(0, 0)
		gridScroll.ScrollBarThickness = 7
		gridScroll.Parent = gridWrap
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(160, 225)
		grid.CellPadding = UDim2.fromOffset(12, 12)
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
		grid.VerticalAlignment = Enum.VerticalAlignment.Top
		grid.Parent = gridScroll

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
				local card = makeCard(gridScroll, UDim2.fromOffset(160, 225))
				card.BackgroundColor3 = COLORS.card
				local stroke = card:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Color = getRarityColor(rarity) stroke.Thickness = (BugConfig.RarityOrder[rarity] or 1) >= 4 and 2 or 1.5 end
				local icon = Instance.new("ImageLabel"); icon.BackgroundTransparency = 1; icon.Size = UDim2.fromOffset(82, 82); icon.Position = UDim2.new(0.5, -41, 0, 28); icon.Image = tostring(cfg.icon or ""); icon.Parent = card
				local name = Instance.new("TextLabel"); name.BackgroundTransparency = 1; name.Size = UDim2.new(1, -12, 0, 34); name.Position = UDim2.fromOffset(6, 114); name.Text = tostring(cfg.displayName or "Unknown Bug"); name.TextWrapped = true; name.TextSize = 14; styleLabel(name, true); name.Parent = card
				local sub = Instance.new("TextLabel"); sub.BackgroundTransparency = 1; sub.Size = UDim2.new(1, -12, 0, 16); sub.Position = UDim2.fromOffset(6, 148); sub.Text = tostring(cfg.role or cfg.species or "Unknown"); sub.TextSize = 12; sub.TextColor3 = COLORS.muted; styleLabel(sub, false); sub.Parent = card
				local asn = makeBadge(card, assign, assign == "Farmer" and Color3.fromRGB(72, 202, 164) or (assign == "Combat" and Color3.fromRGB(94, 162, 255) or Color3.fromRGB(92, 114, 148))); asn.Size = UDim2.fromOffset(100, 20); asn.Position = UDim2.new(0.5, -50, 0, 168)
				local rarityBadge = makeBadge(card, rarity, getRarityColor(rarity)); rarityBadge.Size = UDim2.fromOffset(78, 18); rarityBadge.Position = UDim2.fromOffset(6, 6)
				local p = Instance.new("TextLabel"); p.BackgroundTransparency = 1; p.Size = UDim2.new(1, -10, 0, 14); p.Position = UDim2.fromOffset(5, 190); p.Text = "Power: "..formatNum(getBugPower(cfg)); p.TextSize = 12; styleLabel(p, false); p.Parent = card
				if isBugLocked(bug) then local l=makeBadge(card, "Locked"); l.Size=UDim2.fromOffset(64,18); l.Position=UDim2.new(1,-70,0,6); l.BackgroundColor3 = COLORS.gold end
				local asc = getBugAscension(bug); if asc > 0 then local a=makeBadge(card, "A"..tostring(asc), Color3.fromRGB(106, 229, 186)); a.Size=UDim2.fromOffset(42,18); a.Position=UDim2.fromOffset(88,6) end
				card.MouseEnter:Connect(function() card.BackgroundColor3 = COLORS.card:Lerp(Color3.new(1,1,1), 0.06); if stroke then stroke.Transparency = 0 end end)
				card.MouseLeave:Connect(function() card.BackgroundColor3 = COLORS.card; if stroke then stroke.Transparency = 0.15 end end)
				card.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then makeDetailPopup(context, uid, bug) end end)
			end
		end
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
