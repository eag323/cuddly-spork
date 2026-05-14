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
	bodyContent.Size = UDim2.new(1, -12, 0, 0)
	bodyContent.BackgroundTransparency = 1
	bodyContent.AutomaticSize = Enum.AutomaticSize.Y
	bodyContent.Parent = popupScroll
	local bodyPad = Instance.new("UIPadding")
	bodyPad.PaddingRight = UDim.new(0, 10)
	bodyPad.PaddingBottom = UDim.new(0, 12)
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

	local statsSection = makeCard(bodyContent, UDim2.new(1, -2, 0, 122)); statsSection.BackgroundColor3 = COLORS.cardDark
	makeSectionTitle(statsSection, "COMBAT STATS", 8)
	local chipWrap = Instance.new("Frame"); chipWrap.BackgroundTransparency=1; chipWrap.Size=UDim2.new(1,-20,0,76); chipWrap.Position=UDim2.fromOffset(10,36); chipWrap.Parent=statsSection
	local grid = Instance.new("UIGridLayout", chipWrap); grid.CellPadding = UDim2.fromOffset(8, 8); grid.CellSize = UDim2.new(0.25, -8, 0, 34)
	local stats = cfg.stats or {}
	local icons = {HP="❤️",ATK="⚔️",DEF="🛡️",SPD="💨",CR="🎯",CD="💥",RES="🔒",ACC="👁️"}
	for _, entry in ipairs({{"HP","HP"},{"ATK","ATK"},{"DEF","DEF"},{"SPD","SPD"},{"CR","CritRate"},{"CD","CritDamage"},{"RES","RES"},{"ACC","ACC"}}) do
		local chip = makeCard(chipWrap, UDim2.new(0, 80, 0, 34)); chip.BackgroundColor3 = COLORS.card
		local t = Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.fromScale(1,1); t.Text=("%s %s %s"):format(icons[entry[1]], entry[1], tostring(stats[entry[2]] or 0)); t.TextSize=12; t.TextXAlignment=Enum.TextXAlignment.Center; t.TextYAlignment=Enum.TextYAlignment.Center; styleLabel(t,true); t.Parent=chip
	end

	local infoRow = Instance.new("Frame"); infoRow.Size = UDim2.new(1,-2,0,130); infoRow.BackgroundTransparency = 1; infoRow.Parent = bodyContent
	local buffsCard = makeCard(infoRow, UDim2.new(0.5, -6, 1, 0)); buffsCard.BackgroundColor3=COLORS.cardDark
	makeSectionTitle(buffsCard, "FARMING BUFFS", 8)
	local buffsText = Instance.new("TextLabel"); buffsText.BackgroundTransparency=1; buffsText.Size=UDim2.new(1,-16,1,-38); buffsText.Position=UDim2.fromOffset(8,32); buffsText.TextXAlignment=Enum.TextXAlignment.Left; buffsText.TextYAlignment=Enum.TextYAlignment.Top; buffsText.TextWrapped=true; buffsText.TextSize=12; styleLabel(buffsText,false); buffsText.TextColor3=COLORS.good; buffsText.Text=(#(cfg.idleBonuses or {})>0) and table.concat(cfg.idleBonuses, "\n") or "No farming buffs";  buffsText.Parent=buffsCard
	local abilityCard = makeCard(infoRow, UDim2.new(0.5, -6, 1, 0)); abilityCard.Position = UDim2.new(0.5, 6, 0, 0); abilityCard.BackgroundColor3 = COLORS.cardDark
	makeSectionTitle(abilityCard, "ABILITY", 8)
	local ability = cfg.ability
	local abName = Instance.new("TextLabel"); abName.BackgroundTransparency=1; abName.Size=UDim2.new(1,-16,0,18); abName.Position=UDim2.fromOffset(8,32); abName.TextXAlignment=Enum.TextXAlignment.Left; abName.Text=(ability and tostring(ability.name or "Ability")) or "No ability"; abName.TextSize=13; styleLabel(abName,true); abName.Parent=abilityCard
	local abDesc = Instance.new("TextLabel"); abDesc.BackgroundTransparency=1; abDesc.Size=UDim2.new(1,-16,0,66); abDesc.Position=UDim2.fromOffset(8,50); abDesc.TextXAlignment=Enum.TextXAlignment.Left; abDesc.TextYAlignment=Enum.TextYAlignment.Top; abDesc.TextWrapped=true; abDesc.Text=((ability and string.format("%s • CD %ss\n%s", tostring(ability.type or "Passive"), tostring(ability.cooldown or "-"), tostring(ability.description or ""))) or ""); abDesc.TextSize=11; styleLabel(abDesc,false); abDesc.Parent=abilityCard

	local equipSection = makeCard(bodyContent, UDim2.new(1,-2,0,148)); equipSection.BackgroundColor3=COLORS.cardDark
	makeSectionTitle(equipSection, "EQUIPMENT", 8)
	local eqInfo = Instance.new("TextLabel"); eqInfo.BackgroundTransparency=1; eqInfo.Size=UDim2.new(1,-20,0,16); eqInfo.Position=UDim2.fromOffset(10,28); eqInfo.TextXAlignment=Enum.TextXAlignment.Left; eqInfo.Text="Equipment Coming Soon"; eqInfo.TextSize=11; styleLabel(eqInfo,false); eqInfo.TextColor3=COLORS.muted; eqInfo.Parent=equipSection
	local eqWrap = Instance.new("Frame"); eqWrap.BackgroundTransparency=1; eqWrap.Size=UDim2.new(1,-20,0,70); eqWrap.Position=UDim2.fromOffset(10,56); eqWrap.Parent=equipSection
	local eqLayout = Instance.new("UIListLayout", eqWrap); eqLayout.FillDirection=Enum.FillDirection.Horizontal; eqLayout.Padding=UDim.new(0,8)
	for _, slotName in ipairs({"Weapon","Helmet","Chestplate","Boots","Charm"}) do
		local slot = makeCard(eqWrap, UDim2.fromOffset(122, 64)); slot.BackgroundColor3=COLORS.card
		local s = Instance.new("TextLabel"); s.BackgroundTransparency=1; s.Size=UDim2.new(1,0,0,18); s.Position=UDim2.fromOffset(0,7); s.Text=slotName; s.TextSize=11; styleLabel(s,true); s.Parent=slot
		local c = Instance.new("TextLabel"); c.BackgroundTransparency=1; c.Size=UDim2.new(1,0,0,16); c.Position=UDim2.fromOffset(0,31); c.Text="Coming Soon"; c.TextSize=10; styleLabel(c,false); c.TextColor3=COLORS.muted; c.Parent=slot
	end

	local rank = getBugAscension(bug)
	local costTable = ((cfg.ascension or {}).essenceRequiredByRank) or FALLBACK_ASCENSION_COSTS[rarity] or FALLBACK_ASCENSION_COSTS.Common
	local cost = tonumber(costTable[rank + 1]) or tonumber(costTable[rank + 2]) or 0
	local essence = tonumber((((context.State.PlayerData or {}).Currencies or {}).BugEssence)) or 0
	local ascSec = makeCard(bodyContent, UDim2.new(1,-2,0,82)); ascSec.BackgroundColor3=COLORS.cardDark
	makeSectionTitle(ascSec, "ASCENSION", 8)
	local ascInfo = Instance.new("TextLabel"); ascInfo.BackgroundTransparency=1; ascInfo.Size=UDim2.new(0.62,0,0,40); ascInfo.Position=UDim2.fromOffset(10,30); ascInfo.TextXAlignment=Enum.TextXAlignment.Left; ascInfo.TextYAlignment=Enum.TextYAlignment.Top; ascInfo.Text=("Rank %d / 5   •   Cost: %d Essence   •   Current: %d"):format(rank,cost,essence); ascInfo.TextSize=12; styleLabel(ascInfo,false); ascInfo.Parent=ascSec
	local ascBtn = makeButton(ascSec, rank >= 5 and "Max Ascension" or "Ascend", COLORS.accent, UDim2.fromOffset(146, 32)); ascBtn.Position=UDim2.new(1,-156,0,34); ascBtn.TextColor3=Color3.fromRGB(8,20,34)
	if rank >= 5 or essence < cost then setButtonEnabled(ascBtn, false, COLORS.accent) if essence < cost and rank < 5 then ascBtn.Text = "Not Enough Essence" end else ascBtn.Activated:Connect(function() context.Controllers.BugFarm.Ascend(uid) if detailOverlay then detailOverlay:Destroy(); detailOverlay=nil end end) end

	applyNoTextStrokeRecursive(panel)

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
	layout.Parent = scroll
	Instance.new("UIPadding", scroll).PaddingLeft = UDim.new(0, 10)

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
		local gridWrap = makeCard(scroll, UDim2.new(1, -20, 0, 0))
		gridWrap.BackgroundColor3 = Color3.fromRGB(10, 23, 41)
		gridWrap.AutomaticSize = Enum.AutomaticSize.Y
		local gridContent = Instance.new("Frame")
		gridContent.BackgroundTransparency = 1
		gridContent.AutomaticSize = Enum.AutomaticSize.Y
		gridContent.Size = UDim2.new(1, -24, 0, 0)
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
				local stroke = card:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Color = getRarityColor(rarity) stroke.Thickness = (BugConfig.RarityOrder[rarity] or 1) >= 4 and 2 or 1.5 end
				local icon = Instance.new("ImageLabel"); icon.BackgroundTransparency = 1; icon.Size = UDim2.fromOffset(82, 82); icon.Position = UDim2.new(0.5, -41, 0, 24); icon.Image = tostring(cfg.icon or ""); icon.Parent = card
				local name = Instance.new("TextLabel"); name.BackgroundTransparency = 1; name.Size = UDim2.new(1, -12, 0, 34); name.Position = UDim2.fromOffset(6, 106); name.Text = tostring(cfg.displayName or "Unknown Bug"); name.TextWrapped = true; name.TextSize = 14; styleLabel(name, true); name.Parent = card
				local sub = Instance.new("TextLabel"); sub.BackgroundTransparency = 1; sub.Size = UDim2.new(1, -12, 0, 16); sub.Position = UDim2.fromOffset(6, 138); sub.Text = tostring(cfg.role or cfg.species or "Unknown"); sub.TextSize = 12; sub.TextColor3 = COLORS.muted; styleLabel(sub, false); sub.Parent = card
				local badgeColor, badgeText = getAssignmentBadgeStyle(assign)
				local asn = makeBadge(card, assign, badgeColor); asn.Size = UDim2.fromOffset(104, 20); asn.Position = UDim2.new(0.5, -52, 0, 160); setBadgeTextColor(asn, badgeText)
				local rarityBadge = makeBadge(card, rarity, getRarityColor(rarity)); rarityBadge.Size = UDim2.fromOffset(78, 18); rarityBadge.Position = UDim2.fromOffset(6, 6)
				local p = Instance.new("TextLabel"); p.BackgroundTransparency = 1; p.Size = UDim2.new(1, -10, 0, 14); p.Position = UDim2.fromOffset(5, 186); p.Text = "Power "..formatNum(getBugPower(cfg)); p.TextSize = 12; styleLabel(p, true); p.TextColor3 = COLORS.good; p.Parent = card
				if isBugLocked(bug) then local l=makeBadge(card, "LOCKED", COLORS.warn); l.Size=UDim2.fromOffset(62,18); l.Position=UDim2.new(1,-68,0,6); setBadgeTextColor(l, Color3.fromRGB(32, 22, 8)) end
				local asc = getBugAscension(bug); if asc > 0 then local a=makeBadge(card, "A"..tostring(asc), Color3.fromRGB(106, 229, 186)); a.Size=UDim2.fromOffset(38,18); a.Position=UDim2.fromOffset(88,6); setBadgeTextColor(a, Color3.fromRGB(10, 26, 20)) end
				local hoverHint = Instance.new("TextLabel"); hoverHint.BackgroundTransparency = 0.28; hoverHint.BackgroundColor3 = Color3.fromRGB(8, 20, 34); hoverHint.Size = UDim2.fromOffset(90, 18); hoverHint.Position = UDim2.new(1, -96, 1, -24); hoverHint.Text = "View Details"; hoverHint.TextSize = 10; hoverHint.Visible = false; styleLabel(hoverHint, true); hoverHint.Parent = card; Instance.new("UICorner", hoverHint).CornerRadius = UDim.new(0, 6)
				card.MouseEnter:Connect(function() card.BackgroundColor3 = COLORS.card:Lerp(Color3.new(1,1,1), 0.1); if stroke then stroke.Transparency = 0; stroke.Color = getRarityColor(rarity):Lerp(Color3.new(1,1,1), 0.1) end hoverHint.Visible = true end)
				card.MouseLeave:Connect(function() card.BackgroundColor3 = COLORS.card; if stroke then stroke.Transparency = 0.15; stroke.Color = getRarityColor(rarity) end hoverHint.Visible = false end)
				card.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then makeDetailPopup(context, uid, bug) end end)
			end
		end
		gridWrap.Size = UDim2.new(1, -20, 0, math.max(260, grid.AbsoluteContentSize.Y + 58))
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
