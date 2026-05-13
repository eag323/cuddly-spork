--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local AchievementConfig = require(Shared:WaitForChild("Config"):WaitForChild("AchievementConfig"))
local BugConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugConfig"))
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))

local BugdexApp = {}

local windowRef
local root
local progressCard
local discoveredLabel
local totalCaughtLabel
local completionLabel
local milestoneLabel
local rewardBarFill
local rewardBarLabel
local listFrame
local filtersFrame
local searchBox
local sortButton
local headerPanel
local detailOverlay
local detailPanel
local stateChangedConn
local selectedRarityFilter = "All"
local sortModes = { "Rarity", "Name", "Species", "Discovered First", "Undiscovered First" }
local sortIndex = 1
local searchQuery = ""
local collapsedByRarity = {}

local HEADER_TOP_PADDING = 8
local HEADER_GAP = 8
local HEADER_LIST_GAP = 12
local PROGRESS_CARD_HEIGHT = 96
local SEARCH_ROW_HEIGHT = 32
local TABS_ROW_HEIGHT = 40
local TAB_BUTTON_HEIGHT = 32
local closeButtonRef

local function clearTextStrokes(container: Instance)
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			descendant.TextStrokeTransparency = 1
		end
	end
end

local warnedInvalidBugs = {}
local makeRarityBadge
local openDetailPanel
local getRarityColor

local function warnInvalidBugEntry(bug)
	local key = "missing"
	if type(bug) == "table" then
		key = tostring(bug.id or bug.displayName or bug.species or "missing")
	end
	if warnedInvalidBugs[key] then return end
	warnedInvalidBugs[key] = true
	warn(string.format("[BugdexApp] Invalid bug entry encountered while rendering row (%s)", key))
end

local function createBugRow(parent: Instance, entry, rowZIndex: number, layoutOrder: number?)
	local bug = if type(entry) == "table" then entry.bug else nil
	if type(bug) ~= "table" then
		warnInvalidBugEntry(bug)
		bug = {}
	end
	local discoveredEntry = type(entry) == "table" and entry.discovered == true
	local rarity = tostring(bug.rarity or "Unknown")
	local iconImage = tostring(bug.icon or "")
	local displayName = tostring(bug.displayName or bug.id or "Unknown Bug")
	local species = tostring(bug.species or "Unknown")
	local role = tostring(bug.role or "Unknown Role")

	if bug.id == nil or bug.rarity == nil then
		warnInvalidBugEntry(bug)
	end

	local row = Instance.new("TextButton")
	row.Name = "BugRow"
	row.Size = UDim2.new(1, 0, 0, 68)
	row.BackgroundColor3 = discoveredEntry and Color3.fromRGB(32, 52, 74) or Color3.fromRGB(20, 28, 40)
	row.BorderColor3 = Color3.fromRGB(58, 78, 102)
	row.BorderSizePixel = 1
	row.AutoButtonColor = false
	row.Text = ""
	row.ZIndex = rowZIndex
	row.LayoutOrder = layoutOrder or 1
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local rowPadding = Instance.new("UIPadding")
	rowPadding.PaddingLeft = UDim.new(0, 10)
	rowPadding.PaddingRight = UDim.new(0, 10)
	rowPadding.Parent = row

	local rowContent = Instance.new("Frame")
	rowContent.Name = "RowContent"
	rowContent.BackgroundTransparency = 1
	rowContent.Size = UDim2.fromScale(1, 1)
	rowContent.ZIndex = rowZIndex + 1
	rowContent.Parent = row

	local iconHolder = Instance.new("Frame")
	iconHolder.Name = "IconHolder"
	iconHolder.Size = UDim2.fromOffset(48, 48)
	iconHolder.AnchorPoint = Vector2.new(0, 0.5)
	iconHolder.Position = UDim2.new(0, 0, 0.5, 0)
	local rarityColor = getRarityColor(rarity)
	iconHolder.BackgroundColor3 = discoveredEntry and Color3.fromRGB(9, 18, 30) or rarityColor:Lerp(Color3.fromRGB(8, 14, 22), 0.9)
	iconHolder.BorderSizePixel = 0
	iconHolder.ZIndex = rowZIndex + 1
	iconHolder.Parent = rowContent
	Instance.new("UICorner", iconHolder).CornerRadius = UDim.new(0, 8)

	local icon = Instance.new("ImageLabel")
	icon.Name = "BugIcon"
	icon.Size = UDim2.fromOffset(40, 40)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = iconImage
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = rowZIndex + 2
	if discoveredEntry then
		icon.ImageColor3 = Color3.new(1, 1, 1)
		icon.ImageTransparency = 0
	else
		icon.ImageColor3 = Color3.new(0, 0, 0)
		icon.ImageTransparency = 0.22
		local iconStroke = Instance.new("UIStroke")
		iconStroke.Color = rarityColor
		iconStroke.Transparency = 0.55
		iconStroke.Thickness = 1
		iconStroke.Parent = iconHolder
	end
	icon.Parent = iconHolder

	local textBlock = Instance.new("Frame")
	textBlock.Name = "TextBlock"
	textBlock.BackgroundTransparency = 1
	textBlock.Position = UDim2.fromOffset(64, 0)
	textBlock.Size = UDim2.new(1, -290, 1, 0)
	textBlock.ZIndex = rowZIndex + 1
	textBlock.Parent = rowContent

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.Position = UDim2.new(0, 0, 0.5, -21)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 17
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
	nameLabel.TextTransparency = 0
	nameLabel.Text = discoveredEntry and displayName or "???"
	nameLabel.ZIndex = rowZIndex + 2
	nameLabel.Parent = textBlock

	local subTextLabel = Instance.new("TextLabel")
	subTextLabel.Name = "SubTextLabel"
	subTextLabel.Size = UDim2.new(1, 0, 0, 18)
	subTextLabel.Position = UDim2.new(0, 0, 0.5, 3)
	subTextLabel.BackgroundTransparency = 1
	subTextLabel.Font = Enum.Font.Gotham
	subTextLabel.TextSize = 13
	subTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	subTextLabel.TextColor3 = Color3.fromRGB(155, 175, 198)
	subTextLabel.TextTransparency = 0
	subTextLabel.Text = discoveredEntry and string.format("Species: %s • %s", species, role) or "Undiscovered"
	subTextLabel.ZIndex = rowZIndex + 2
	subTextLabel.Parent = textBlock

	local rarityAnchor = Instance.new("Frame")
	rarityAnchor.Name = "RarityBadge"
	rarityAnchor.BackgroundTransparency = 1
	rarityAnchor.AnchorPoint = Vector2.new(0.5, 0.5)
	rarityAnchor.Position = UDim2.new(0.67, 0, 0.5, 0)
	rarityAnchor.Size = UDim2.fromOffset(140, 28)
	rarityAnchor.ZIndex = rowZIndex + 2
	rarityAnchor.Parent = rowContent
	if makeRarityBadge then
		makeRarityBadge(rarityAnchor, rarity)
	end

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.AnchorPoint = Vector2.new(1, 0.5)
	statusLabel.Position = UDim2.new(1, -10, 0.5, 0)
	statusLabel.Size = UDim2.fromOffset(120, 24)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 13
	statusLabel.TextXAlignment = Enum.TextXAlignment.Right
	statusLabel.Text = discoveredEntry and "✅ Discovered" or "Locked"
	statusLabel.TextColor3 = discoveredEntry and Color3.fromRGB(130, 255, 180) or Color3.fromRGB(154, 169, 186)
	statusLabel.TextTransparency = 0
	statusLabel.ZIndex = rowZIndex + 2
	statusLabel.Parent = rowContent

	local function isBugNew(_bugId: any): boolean
		return false
	end
	if discoveredEntry and isBugNew(bug.id) then
		local newBadge = Instance.new("TextLabel")
		newBadge.Size = UDim2.fromOffset(40, 18)
		newBadge.Position = UDim2.new(1, -52, 0.5, -24)
		newBadge.BackgroundColor3 = Color3.fromRGB(80, 225, 245)
		newBadge.BorderSizePixel = 0
		newBadge.Font = Enum.Font.GothamBold
		newBadge.TextSize = 11
		newBadge.TextColor3 = Color3.fromRGB(8, 20, 34)
		newBadge.Text = "NEW"
		newBadge.ZIndex = rowZIndex + 2
		newBadge.Parent = rowContent
		Instance.new("UICorner", newBadge).CornerRadius = UDim.new(0, 9)
	end

	local base = row.BackgroundColor3
	local baseBorder = row.BorderColor3
	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = base:Lerp(Color3.fromRGB(74, 99, 128), 0.25)
		row.BorderColor3 = baseBorder:Lerp(Color3.fromRGB(130, 165, 205), 0.35)
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = base
		row.BorderColor3 = baseBorder
	end)
	row.Activated:Connect(function()
		if openDetailPanel then
			openDetailPanel(entry)
		end
	end)
end

local rarityColors = {
	Common = Color3.fromRGB(185, 185, 185),
	Uncommon = Color3.fromRGB(105, 214, 134),
	Rare = Color3.fromRGB(88, 170, 255),
	Epic = Color3.fromRGB(187, 102, 255),
	Legendary = Color3.fromRGB(255, 176, 66),
	Mythic = Color3.fromRGB(255, 106, 174),
}

local rarityTabs = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

local selectedRarityTextColors = {
	All = Color3.fromRGB(8, 18, 30),
	Common = Color3.fromRGB(8, 18, 30),
	Uncommon = Color3.fromRGB(5, 25, 15),
	Rare = Color3.fromRGB(5, 15, 35),
	Epic = Color3.fromRGB(255, 245, 255),
	Legendary = Color3.fromRGB(35, 20, 5),
	Mythic = Color3.fromRGB(255, 255, 255),
}

local selectedRarityBackgroundColors = {
	All = Color3.fromRGB(125, 205, 255),
	Common = Color3.fromRGB(210, 215, 225),
	Uncommon = Color3.fromRGB(65, 210, 115),
	Rare = Color3.fromRGB(80, 155, 255),
	Epic = Color3.fromRGB(160, 95, 240),
	Legendary = Color3.fromRGB(255, 190, 75),
	Mythic = Color3.fromRGB(255, 90, 160),
}

getRarityColor = function(rarity: string): Color3
	return rarityColors[rarity] or Color3.fromRGB(210, 210, 210)
end

local function getRarityOrderIndex(rarity: string): number
	local configuredOrder = BugConfig.RarityOrder
	if type(configuredOrder) == "table" then
		local fromConfig = tonumber(configuredOrder[rarity])
		if fromConfig then
			return fromConfig
		end
	end
	local fallbackOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
	return fallbackOrder[rarity] or math.huge
end

local function getBugdexCatalog()
	if type(BugConfig.GetAllBugs) == "function" then return BugConfig.GetAllBugs() end
	if type(BugConfig.Bugs) == "table" then
		local list = {}
		for _, bug in pairs(BugConfig.Bugs) do table.insert(list, bug) end
		table.sort(list, function(a, b)
			local rarityA = getRarityOrderIndex(tostring(a.rarity))
			local rarityB = getRarityOrderIndex(tostring(b.rarity))
			if rarityA ~= rarityB then return rarityA < rarityB end
			local speciesA = tostring(a.species or "")
			local speciesB = tostring(b.species or "")
			if speciesA ~= speciesB then return speciesA < speciesB end
			return tostring(a.displayName or a.id) < tostring(b.displayName or b.id)
		end)
		return list
	end
	warn("[BugdexApp] BugConfig catalog missing. Falling back to empty display list.")
	return {}
end

local function slugifyKey(value: any): string
	local text = string.lower(tostring(value or ""))
	text = string.gsub(text, "%s+", "_")
	text = string.gsub(text, "[^%w_]", "")
	return text
end

local function getPossibleDiscoveryKeys(bug): { string }
	local keys = {}
	local seen = {}
	local function add(value: any)
		if value == nil then return end
		local key = tostring(value)
		if key == "" or seen[key] then return end
		seen[key] = true
		table.insert(keys, key)
	end
	add(bug.id)
	add(bug.displayName)
	add(slugifyKey(bug.displayName))
	add(bug.species)
	add(slugifyKey(bug.species))
	add(bug.legacyId)
	add(bug.speciesId)
	return keys
end

local function getCaughtCountForBug(bug, totalsBySpecies): number
	local keys = getPossibleDiscoveryKeys(bug)
	local total = 0
	local counted = {}
	for _, key in ipairs(keys) do
		if not counted[key] then
			local count = tonumber(totalsBySpecies[key])
			if count and count > 0 then
				total += count
			end
			counted[key] = true
		end
	end
	return total
end

local function isBugDiscovered(playerData, bug, caughtCount: number): boolean
	if caughtCount > 0 then return true end
	local keys = getPossibleDiscoveryKeys(bug)
	local bugdexData = playerData.Bugdex
	if type(bugdexData) == "table" then
		local discovered = bugdexData.Discovered
		if type(discovered) == "table" then
			for _, key in ipairs(keys) do
				if discovered[key] == true then return true end
			end
		end
		for _, key in ipairs(keys) do
			if bugdexData[key] == true then return true end
		end
	end
	local bugsData = playerData.Bugs
	if type(bugsData) == "table" then
		local discovered = bugsData.Discovered
		if type(discovered) == "table" then
			for _, key in ipairs(keys) do
				if discovered[key] == true then return true end
			end
		end
	end
	local discoveredBugs = playerData.DiscoveredBugs
	if type(discoveredBugs) == "table" then
		for _, key in ipairs(keys) do
			if discoveredBugs[key] == true then return true end
		end
	end
	return false
end

local function makeProgressBar(parent: Instance, percent: number, color: Color3)
	local barTrack = Instance.new("Frame")
	barTrack.Size = UDim2.new(1, 0, 0, 9)
	barTrack.BackgroundColor3 = Color3.fromRGB(18, 31, 46)
	barTrack.BorderSizePixel = 0
	barTrack.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = barTrack
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
	barFill.BackgroundColor3 = color
	barFill.BorderSizePixel = 0
	barFill.Parent = barTrack
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = barFill
	return barTrack
end


local function getMilestoneTargets(totalSpecies: number): { number }
	local targets = {}
	for _, definition in ipairs(AchievementConfig.Definitions) do
		if definition.section == "Collection" and definition.stat == "UniqueBugsDiscovered" then
			local required = tonumber(definition.required)
			if required and required > 0 and required <= totalSpecies then
				table.insert(targets, required)
			end
		end
	end
	if #targets == 0 then
		for _, fallback in ipairs({ 10, 25, 50, 100, 150, totalSpecies }) do
			if fallback <= totalSpecies then
				table.insert(targets, fallback)
			end
		end
	end
	table.sort(targets)
	local unique, seen = {}, {}
	for _, value in ipairs(targets) do if not seen[value] then seen[value] = true table.insert(unique, value) end end
	return unique
end

makeRarityBadge = function(parent: Instance, rarity: string)
	local badge = Instance.new("Frame")
	badge.AutomaticSize = Enum.AutomaticSize.X
	badge.Size = UDim2.fromOffset(0, 28)
	badge.BackgroundColor3 = getRarityColor(rarity):Lerp(Color3.fromRGB(20, 26, 38), 0.72)
	badge.BorderColor3 = getRarityColor(rarity)
	badge.BorderSizePixel = 1
	badge.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = badge
	local label = Instance.new("TextLabel")
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromScale(0, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = rarity
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextStrokeTransparency = 1
	label.Parent = badge
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = badge
end

local function createSectionTitle(parent: Instance, text: string, accent: Color3)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 24)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0, 4, 1, 0)
	line.BackgroundColor3 = accent
	line.BorderSizePixel = 0
	line.Parent = holder
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.fromOffset(10, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(150, 170, 195)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = holder
end

local statEmoji = { HP = "♥", ATK = "♦", DEF = "■", SPD = "▶", CR = "★", CD = "✸", RES = "⬢", ACC = "◎" }

local function createStatBox(parent: Instance, labelText: string, valueText: string)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0.125, -6, 0, 42)
	card.BackgroundColor3 = Color3.fromRGB(4, 12, 24)
	card.BorderSizePixel = 0
	card.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(52, 74, 98)
	stroke.Thickness = 1
	stroke.Parent = card
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 1)
	layout.Parent = card
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -6, 0, 12)
	label.BackgroundTransparency = 1
	label.Text = string.format("%s %s", statEmoji[labelText] or "•", labelText)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.TextColor3 = Color3.fromRGB(150, 170, 195)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = card
	local value = Instance.new("TextLabel")
	value.Size = UDim2.new(1, -6, 0, 16)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamBold
	value.TextSize = 14
	value.TextColor3 = Color3.fromRGB(245, 248, 255)
	value.TextXAlignment = Enum.TextXAlignment.Center
	value.TextTruncate = Enum.TextTruncate.AtEnd
	value.Text = valueText
	value.Parent = card
end

local function closeDetailPanel()
	if detailOverlay then detailOverlay.Visible = false end
end

openDetailPanel = function(entry)
	if not detailOverlay or not detailPanel then return end
	detailOverlay.Visible = true
	for _, child in ipairs(detailPanel:GetChildren()) do
		if child ~= closeButtonRef and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
	end
	local discoveredEntry = entry.discovered == true
	local bug = entry.bug
	local rarity = tostring(bug.rarity or "Common")
	local accent = getRarityColor(rarity)
	local stroke = detailPanel:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = accent end
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 112)
	header.BackgroundColor3 = Color3.fromRGB(18, 39, 63)
	header.BorderSizePixel = 0
	header.Parent = detailPanel
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)
	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingTop, headerPadding.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
	headerPadding.PaddingLeft, headerPadding.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	headerPadding.Parent = header
	local iconPanel = Instance.new("Frame")
	iconPanel.Size = UDim2.fromOffset(96, 96)
	iconPanel.BackgroundColor3 = Color3.fromRGB(4, 12, 24)
	iconPanel.BorderSizePixel = 0
	iconPanel.Parent = header
	Instance.new("UICorner", iconPanel).CornerRadius = UDim.new(0, 10)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = accent
	iconStroke.Transparency = discoveredEntry and 0.15 or 0.45
	iconStroke.Thickness = 1
	iconStroke.Parent = iconPanel
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(82, 82)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = bug.icon or bug.sprite or "rbxassetid://0"
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ImageColor3 = discoveredEntry and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
	icon.ImageTransparency = discoveredEntry and 0 or 0.2
	icon.Parent = iconPanel
	local info = Instance.new("Frame")
	info.Size = UDim2.new(1, -104, 1, 0)
	info.Position = UDim2.fromOffset(104, 0)
	info.BackgroundTransparency = 1
	info.Parent = header
	local infoLayout = Instance.new("UIListLayout")
	infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	infoLayout.Padding = UDim.new(0, 4)
	infoLayout.Parent = info
	makeRarityBadge(info, rarity)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 34)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 24
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = discoveredEntry and tostring(bug.displayName) or "???"
	nameLabel.Parent = info
	if not discoveredEntry then
		local undiscoveredText = Instance.new("TextLabel")
		undiscoveredText.Size = UDim2.new(1, 0, 0, 32)
			undiscoveredText.BackgroundTransparency = 1
		undiscoveredText.TextWrapped = true
		undiscoveredText.TextXAlignment = Enum.TextXAlignment.Left
		undiscoveredText.TextYAlignment = Enum.TextYAlignment.Top
		undiscoveredText.Font = Enum.Font.Gotham
		undiscoveredText.TextSize = 13
		undiscoveredText.TextColor3 = Color3.fromRGB(150, 170, 195)
		undiscoveredText.Text = "Undiscovered Bug\nCatch this bug to reveal its details."
		undiscoveredText.Parent = info
	end
	createSectionTitle(detailPanel, "COMBAT STATS", accent)
	local statRow = Instance.new("Frame")
	statRow.Size = UDim2.new(1, 0, 0, 42)
	statRow.BackgroundTransparency = 1
	statRow.Parent = detailPanel
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 4)
	rowLayout.Parent = statRow
	local stats = bug.stats or {}
	local statOrder = {{"HP","HP"},{"ATK","ATK"},{"DEF","DEF"},{"SPD","SPD"},{"CR","CritRate"},{"CD","CritDamage"},{"RES","RES"},{"ACC","ACC"}}
	for _, mapping in ipairs(statOrder) do
		local value = "???"
		if discoveredEntry then
			local raw = tonumber(stats[mapping[2]]) or 0
			value = (mapping[1] == "CR" or mapping[1] == "CD") and string.format("%d%%", raw) or tostring(raw)
		end
		createStatBox(statRow, mapping[1], value)
	end
	local statSpacing = Instance.new("Frame")
	statSpacing.Size = UDim2.new(1, 0, 0, 10)
	statSpacing.BackgroundTransparency = 1
	statSpacing.Parent = detailPanel
	if discoveredEntry and bug.ability then
		createSectionTitle(detailPanel, "ABILITY", accent)
		local ability = bug.ability
		local panel = Instance.new("Frame")
		panel.AutomaticSize = Enum.AutomaticSize.Y
		panel.Size = UDim2.new(1, 0, 0, 0)
		panel.BackgroundColor3 = Color3.fromRGB(18, 39, 63)
		panel.BorderSizePixel = 0
		panel.Parent = detailPanel
		Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
		local panelPadding = Instance.new("UIPadding")
		panelPadding.PaddingTop = UDim.new(0, 10)
		panelPadding.PaddingBottom = UDim.new(0, 10)
		panelPadding.PaddingLeft = UDim.new(0, 10)
		panelPadding.PaddingRight = UDim.new(0, 10)
		panelPadding.Parent = panel
		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, 0, 0, 24)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextSize = 18
		name.TextColor3 = Color3.fromRGB(245, 248, 255)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Text = tostring(ability.name or "Unknown Ability")
		name.Parent = panel
		local badgeLine = Instance.new("TextLabel")
		badgeLine.Size = UDim2.new(1, 0, 0, 20)
		badgeLine.Position = UDim2.fromOffset(0, 25)
		badgeLine.BackgroundTransparency = 1
		badgeLine.Font = Enum.Font.GothamBold
		badgeLine.TextSize = 13
		badgeLine.TextXAlignment = Enum.TextXAlignment.Left
		badgeLine.TextColor3 = Color3.fromRGB(90, 235, 245)
		local abilityType = tostring(ability.abilityType or ability.type or "Unknown")
		local cooldown = tonumber(ability.cooldownTurns or ability.cooldown)
		badgeLine.Text = cooldown and string.format("[ %s ] [ Cooldown: %d ]", abilityType, cooldown) or string.format("[ %s ]", abilityType)
		badgeLine.Parent = panel
		local desc = Instance.new("TextLabel")
		desc.AutomaticSize = Enum.AutomaticSize.Y
		desc.Size = UDim2.new(1, 0, 0, 0)
		desc.Position = UDim2.fromOffset(0, 48)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 13
		desc.TextWrapped = true
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextColor3 = Color3.fromRGB(150, 170, 195)
		desc.Text = tostring(ability.description or "")
		desc.Parent = panel
	end
	clearTextStrokes(detailPanel)
end

local function refresh(context)
	if not root or not listFrame or not milestoneLabel or not filtersFrame then return end
	for _, child in ipairs(listFrame:GetChildren()) do if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end end
	for _, child in ipairs(filtersFrame:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
	local playerData = context.State.PlayerData or {}
	local bugdexData = playerData.Bugdex or {}
	local totalsBySpecies = bugdexData.TotalCaughtBySpecies or {}
	local bugs = getBugdexCatalog()
	local totalSpecies, discovered, totalCaught = #bugs, 0, 0
	local groups = {}
	for _, bug in ipairs(bugs) do
		local rarity = tostring(bug.rarity or "Common")
		groups[rarity] = groups[rarity] or { rarity = rarity, total = 0, discovered = 0, entries = {} }
		local group = groups[rarity]
		local count = getCaughtCountForBug(bug, totalsBySpecies)
		local discoveredEntry = isBugDiscovered(playerData, bug, count)
		group.total += 1
		if discoveredEntry then group.discovered += 1 discovered += 1 end
		totalCaught += count
		table.insert(group.entries, { bug = bug, count = count, discovered = discoveredEntry })
	end
	local completion = if totalSpecies > 0 then math.floor((discovered / totalSpecies) * 1000 + 0.5) / 10 else 0
	discoveredLabel.Text = string.format("%s / %s", NumberUtil.FormatNumber(discovered), NumberUtil.FormatNumber(totalSpecies))
	totalCaughtLabel.Text = NumberUtil.FormatNumber(totalCaught)
	completionLabel.Text = string.format("%s%%", tostring(completion))
	local milestoneTargets = getMilestoneTargets(totalSpecies)
	local nextTarget = nil
	for _, target in ipairs(milestoneTargets) do
		if discovered < target then
			nextTarget = target
			break
		end
	end
	if nextTarget then
		milestoneLabel.Text = "Next Reward"
		rewardBarLabel.Text = string.format("%d / %d", discovered, nextTarget)
		rewardBarFill.Size = UDim2.new(math.clamp(discovered / nextTarget, 0, 1), 0, 1, 0)
	else
		milestoneLabel.Text = "All rewards claimed"
		rewardBarLabel.Text = "Bugdex complete"
		rewardBarFill.Size = UDim2.new(1, 0, 1, 0)
	end
	for _, tab in ipairs(rarityTabs) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(94, TAB_BUTTON_HEIGHT)
		button.Text = tab
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.TextScaled = false
		button.TextWrapped = false
		button.TextTruncate = Enum.TextTruncate.AtEnd
		button.TextStrokeTransparency = 1
		button.TextXAlignment = Enum.TextXAlignment.Center
		button.TextYAlignment = Enum.TextYAlignment.Center
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		local active = selectedRarityFilter == tab
		local tint = tab ~= "All" and getRarityColor(tab) or Color3.fromRGB(80, 150, 220)
		local selectedBackground = selectedRarityBackgroundColors[tab] or tint:Lerp(Color3.new(1, 1, 1), 0.55)
		local base = active and selectedBackground or tint:Lerp(Color3.fromRGB(18, 26, 38), 0.78)
		button.BackgroundColor3 = base
		button.TextColor3 = active and (selectedRarityTextColors[tab] or Color3.fromRGB(10, 18, 30)) or Color3.fromRGB(235, 245, 255)
		local stroke = Instance.new("UIStroke")
		stroke.Color = tint
		stroke.Thickness = active and 1.8 or 1
		stroke.Transparency = active and 0.05 or 0.2
		stroke.Parent = button
		button.Parent = filtersFrame
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
		if active then
			local underline = Instance.new("Frame")
			underline.Size = UDim2.new(1, -12, 0, 2)
			underline.Position = UDim2.new(0, 6, 1, -4)
			underline.BackgroundColor3 = tint
			underline.BorderSizePixel = 0
			underline.Parent = button
		end
		button.MouseEnter:Connect(function()
			if selectedRarityFilter ~= tab then
				button.BackgroundColor3 = tint:Lerp(Color3.fromRGB(34, 49, 68), 0.62)
			end
		end)
		button.MouseLeave:Connect(function() button.BackgroundColor3 = base end)
		button.Activated:Connect(function() selectedRarityFilter = tab refresh(context) end)
	end
	local query = string.lower(searchQuery)
	local rarityOrder = {"Common","Uncommon","Rare","Epic","Legendary","Mythic"}
	local anyVisibleRows = false
	for _, rarity in ipairs(rarityOrder) do
		if selectedRarityFilter == "All" or selectedRarityFilter == rarity then
			local group = groups[rarity]
			if group and group.total > 0 then
				table.sort(group.entries, function(a,b)
					if sortModes[sortIndex] == "Discovered First" and a.discovered ~= b.discovered then return a.discovered end
					if sortModes[sortIndex] == "Undiscovered First" and a.discovered ~= b.discovered then return not a.discovered end
					if sortModes[sortIndex] == "Name" then return tostring(a.bug.displayName or a.bug.id) < tostring(b.bug.displayName or b.bug.id) end
					if sortModes[sortIndex] == "Species" then return tostring(a.bug.species or "") < tostring(b.bug.species or "") end
					local ra, rb = getRarityOrderIndex(tostring(a.bug.rarity)), getRarityOrderIndex(tostring(b.bug.rarity)); if ra ~= rb then return ra < rb end
					return tostring(a.bug.displayName or a.bug.id) < tostring(b.bug.displayName or b.bug.id)
				end)
				local section = Instance.new("Frame")
				section.Size = UDim2.new(1, -4, 0, 0)
				section.AutomaticSize = Enum.AutomaticSize.Y
				section.BackgroundColor3 = Color3.fromRGB(23, 37, 54)
				section.BorderSizePixel = 0
				section.Parent = listFrame
				Instance.new("UICorner", section).CornerRadius = UDim.new(0, 8)
				local p = Instance.new("UIPadding", section); p.PaddingTop=UDim.new(0,10); p.PaddingBottom=UDim.new(0,10); p.PaddingLeft=UDim.new(0,8); p.PaddingRight=UDim.new(0,8)
				local l = Instance.new("UIListLayout", section); l.Padding=UDim.new(0,8)
				local headerBtn = Instance.new("TextButton")
				headerBtn.Size = UDim2.new(1,0,0,24); headerBtn.Text=""; headerBtn.BackgroundTransparency=1; headerBtn.Parent=section; headerBtn.LayoutOrder = 10
				local left = Instance.new("TextLabel", headerBtn); left.Size=UDim2.new(0.7,0,1,0); left.BackgroundTransparency=1; left.TextXAlignment=Enum.TextXAlignment.Left; left.Font=Enum.Font.GothamBold; left.TextSize=16; left.TextColor3=getRarityColor(rarity)
				left.Text = string.format("%s %s BUGS", collapsedByRarity[rarity] and "▶" or "▼", string.upper(rarity))
				local right = Instance.new("TextLabel", headerBtn); right.Size=UDim2.new(0.3,0,1,0); right.Position=UDim2.new(0.7,0,0,0); right.BackgroundTransparency=1; right.TextXAlignment=Enum.TextXAlignment.Right; right.Font=Enum.Font.GothamBold; right.TextSize=16; right.TextColor3=Color3.fromRGB(227,235,243); right.Text=string.format("%d / %d",group.discovered,group.total)
				headerBtn.Activated:Connect(function() collapsedByRarity[rarity] = not collapsedByRarity[rarity] refresh(context) end)
				local progressHolder = Instance.new("Frame")
				progressHolder.Name = "ProgressHolder"
				progressHolder.Size = UDim2.new(1, 0, 0, 26)
				progressHolder.BackgroundTransparency = 1
				progressHolder.LayoutOrder = 20
				progressHolder.Parent = section
				local bar = makeProgressBar(progressHolder, if group.total>0 then group.discovered/group.total else 0, getRarityColor(rarity))
				local progressLabel = Instance.new("TextLabel")
				progressLabel.Size = UDim2.new(1, 0, 0, 14)
				progressLabel.Position = UDim2.fromOffset(0, 12)
				progressLabel.BackgroundTransparency = 1
				progressLabel.Font = Enum.Font.Gotham
				progressLabel.TextSize = 11
				progressLabel.TextColor3 = Color3.fromRGB(150, 170, 195)
				progressLabel.TextXAlignment = Enum.TextXAlignment.Right
				progressLabel.Text = string.format("%d / %d discovered", group.discovered, group.total)
				progressLabel.Parent = progressHolder
				bar.Position = UDim2.fromOffset(0, 0)
				if not collapsedByRarity[rarity] then
					local rowsContainer = Instance.new("Frame")
					rowsContainer.Name = "RowsContainer"
					rowsContainer.Size = UDim2.new(1, 0, 0, 0)
					rowsContainer.AutomaticSize = Enum.AutomaticSize.Y
					rowsContainer.BackgroundTransparency = 1
					rowsContainer.LayoutOrder = 30
					rowsContainer.Parent = section
					local rowsLayout = Instance.new("UIListLayout")
					rowsLayout.Padding = UDim.new(0, 8)
					rowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
					rowsLayout.Parent = rowsContainer
					local visibleRows = 0
					for _, entry in ipairs(group.entries) do
						local bug = if type(entry) == "table" then entry.bug else nil
						local displayName = if type(bug) == "table" then tostring(bug.displayName or bug.id or "") else ""
						local species = if type(bug) == "table" then tostring(bug.species or "") else ""
						local rarityText = if type(bug) == "table" then tostring(bug.rarity or "") else ""
						local role = if type(bug) == "table" then tostring(bug.role or "") else ""
						local blob = string.lower(string.format("%s %s %s %s %s", displayName, species, rarityText, role, entry.discovered and "discovered" or "undiscovered"))
						if (query == "" or string.find(blob, query, 1, true)) then
							visibleRows += 1
							anyVisibleRows = true
							createBugRow(rowsContainer, entry, 1, visibleRows)
						end
					end
				end
			end
		end
	end
	if not anyVisibleRows then
		local emptyPanel = Instance.new("Frame")
		emptyPanel.Size = UDim2.new(1, -4, 0, 96)
		emptyPanel.BackgroundColor3 = Color3.fromRGB(20, 30, 43)
		emptyPanel.BorderSizePixel = 0
		emptyPanel.Parent = listFrame
		Instance.new("UICorner", emptyPanel).CornerRadius = UDim.new(0, 8)
		local emptyText = Instance.new("TextLabel")
		emptyText.Size = UDim2.fromScale(1, 1)
		emptyText.BackgroundTransparency = 1
		emptyText.Font = Enum.Font.Gotham
		emptyText.TextSize = 16
		emptyText.TextColor3 = Color3.fromRGB(145, 165, 188)
		emptyText.Text = "No bugs found.\nTry another search or filter."
		emptyText.Parent = emptyPanel
	end
	local layout = listFrame:FindFirstChildOfClass("UIListLayout")
	if layout then listFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12) end
	clearTextStrokes(root)
end

function BugdexApp.Mount(target: Instance, context): ()
	if windowRef and windowRef.Content and windowRef.Content.Parent then return end
	windowRef = nil
	root = nil
	windowRef = Window.Create({ Title = "Bugdex.exe", Size = UDim2.fromOffset(780, 540), Position = UDim2.fromScale(0.1, 0.1), Parent = target, OnClose = function() context.Controllers.Window.Close("Bugdex") end })
	root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = windowRef.Content
	local rootPadding = Instance.new("UIPadding")
	rootPadding.PaddingTop = UDim.new(0, 8) rootPadding.PaddingBottom = UDim.new(0, 8)
	rootPadding.PaddingLeft = UDim.new(0, 8) rootPadding.PaddingRight = UDim.new(0, 8)
	rootPadding.Parent = root

	local progressY = HEADER_TOP_PADDING
	local searchY = progressY + PROGRESS_CARD_HEIGHT + HEADER_GAP
	local tabsY = searchY + SEARCH_ROW_HEIGHT + HEADER_GAP
	local listY = tabsY + TABS_ROW_HEIGHT + HEADER_LIST_GAP

	headerPanel = Instance.new("Frame")
	headerPanel.Size = UDim2.new(1, 0, 0, listY)
	headerPanel.BackgroundTransparency = 1
	headerPanel.Parent = root
	progressCard = Instance.new("Frame")
	progressCard.Size = UDim2.new(1, 0, 0, PROGRESS_CARD_HEIGHT)
	progressCard.Position = UDim2.fromOffset(0, progressY)
	progressCard.BackgroundColor3 = Color3.fromRGB(10, 24, 42)
	progressCard.Parent = headerPanel
	Instance.new("UICorner", progressCard).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke", progressCard); st.Color = Color3.fromRGB(70, 130, 190); st.Thickness = 1
	local title = Instance.new("TextLabel", progressCard); title.Size=UDim2.new(1,-12,0,18); title.Position=UDim2.fromOffset(8,6); title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBold; title.TextSize=13; title.TextXAlignment=Enum.TextXAlignment.Left; title.TextColor3=Color3.fromRGB(170,210,255); title.Text="BUGDEX PROGRESS"
	local d = Instance.new("TextLabel", progressCard); d.Size=UDim2.new(0,160,0,18); d.Position=UDim2.fromOffset(8,26); d.BackgroundTransparency=1; d.TextXAlignment=Enum.TextXAlignment.Left; d.Font=Enum.Font.GothamBold; d.TextSize=14; d.TextColor3=Color3.fromRGB(220,230,245); d.Text="Unique Discovered:"
	discoveredLabel = Instance.new("TextLabel", progressCard); discoveredLabel.Size=UDim2.new(0,110,0,18); discoveredLabel.Position=UDim2.fromOffset(172,26); discoveredLabel.BackgroundTransparency=1; discoveredLabel.Font=Enum.Font.GothamBold; discoveredLabel.TextXAlignment=Enum.TextXAlignment.Left; discoveredLabel.TextSize=14; discoveredLabel.TextColor3=Color3.fromRGB(90,235,245)
	local c = d:Clone(); c.Parent=progressCard; c.Position=UDim2.fromOffset(8,46); c.Text="Total Caught:"; totalCaughtLabel = discoveredLabel:Clone(); totalCaughtLabel.Parent=progressCard; totalCaughtLabel.Position=UDim2.fromOffset(172,46)
	local e = d:Clone(); e.Parent=progressCard; e.Position=UDim2.fromOffset(8,66); e.Text="Completion:"; completionLabel = discoveredLabel:Clone(); completionLabel.Parent=progressCard; completionLabel.Position=UDim2.fromOffset(172,66); completionLabel.TextColor3=Color3.fromRGB(130,255,180)
	milestoneLabel = Instance.new("TextLabel", progressCard); milestoneLabel.Size=UDim2.new(0.4,0,0,18); milestoneLabel.Position=UDim2.new(0.56,0,0,26); milestoneLabel.BackgroundTransparency=1; milestoneLabel.Font=Enum.Font.GothamBold; milestoneLabel.TextSize=14; milestoneLabel.TextXAlignment=Enum.TextXAlignment.Left; milestoneLabel.TextColor3=Color3.fromRGB(255,220,110); milestoneLabel.Text="Budding Collector"
	local rewardTrack = Instance.new("Frame", progressCard); rewardTrack.Size=UDim2.new(0.4,0,0,10); rewardTrack.Position=UDim2.new(0.56,0,0,52); rewardTrack.BackgroundColor3=Color3.fromRGB(21,33,49); rewardTrack.BorderSizePixel=0; Instance.new("UICorner", rewardTrack).CornerRadius=UDim.new(0,4)
	rewardBarFill = Instance.new("Frame", rewardTrack); rewardBarFill.Size=UDim2.new(0,0,1,0); rewardBarFill.BackgroundColor3=Color3.fromRGB(255,220,110); rewardBarFill.BorderSizePixel=0; Instance.new("UICorner", rewardBarFill).CornerRadius=UDim.new(0,4)
	rewardBarLabel = Instance.new("TextLabel", progressCard); rewardBarLabel.Size=UDim2.new(0.4,0,0,16); rewardBarLabel.Position=UDim2.new(0.56,0,0,64); rewardBarLabel.BackgroundTransparency=1; rewardBarLabel.Font=Enum.Font.GothamBold; rewardBarLabel.TextSize=12; rewardBarLabel.TextColor3=Color3.fromRGB(220,230,245); rewardBarLabel.TextXAlignment=Enum.TextXAlignment.Center
	searchBox = Instance.new("TextBox", headerPanel); searchBox.Size=UDim2.new(0.55,0,0,SEARCH_ROW_HEIGHT); searchBox.Position=UDim2.fromOffset(0,searchY); searchBox.PlaceholderText="Search bugs..."; searchBox.Text=""; searchBox.TextStrokeTransparency=1; searchBox.ClearTextOnFocus=false; searchBox.BackgroundColor3=Color3.fromRGB(19,33,50); searchBox.TextColor3=Color3.fromRGB(230,238,248); searchBox.BorderSizePixel=0; searchBox.Font=Enum.Font.Gotham; searchBox.TextSize=14; searchBox.TextXAlignment=Enum.TextXAlignment.Left
	local searchStroke = Instance.new("UIStroke", searchBox); searchStroke.Color = Color3.fromRGB(72, 95, 124); searchStroke.Thickness = 1
	Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 7)
	local searchPadding = Instance.new("UIPadding", searchBox)
	searchPadding.PaddingLeft = UDim.new(0, 28)
	local searchIcon = Instance.new("TextLabel", searchBox)
	searchIcon.Size = UDim2.fromOffset(16, 16)
	searchIcon.Position = UDim2.new(0, 8, 0.5, 0)
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.BackgroundTransparency = 1
	searchIcon.Font = Enum.Font.GothamBold
	searchIcon.TextSize = 12
	searchIcon.TextColor3 = Color3.fromRGB(140, 170, 200)
	searchIcon.Text = "🔎"
	searchIcon.ZIndex = searchBox.ZIndex + 1

	sortButton = Instance.new("TextButton", headerPanel); sortButton.Size=UDim2.new(0.43,0,0,SEARCH_ROW_HEIGHT); sortButton.Position=UDim2.new(0.57,0,0,searchY); sortButton.Text="Sort: Rarity"; sortButton.BackgroundColor3=Color3.fromRGB(29,44,61); sortButton.TextColor3=Color3.fromRGB(235,245,255); sortButton.Font=Enum.Font.GothamBold; sortButton.TextSize=14; sortButton.TextScaled=false; sortButton.TextWrapped=false; sortButton.TextTruncate=Enum.TextTruncate.AtEnd; sortButton.TextStrokeTransparency=1; sortButton.TextXAlignment=Enum.TextXAlignment.Center; sortButton.TextYAlignment=Enum.TextYAlignment.Center; sortButton.BorderSizePixel=0
	local sortStroke = Instance.new("UIStroke", sortButton); sortStroke.Color = Color3.fromRGB(84, 116, 148); sortStroke.Thickness = 1
	Instance.new("UICorner", sortButton).CornerRadius = UDim.new(0, 7)
	filtersFrame = Instance.new("Frame")
	filtersFrame.Size = UDim2.new(1, 0, 0, TABS_ROW_HEIGHT)
	filtersFrame.Position = UDim2.fromOffset(0, tabsY)
	filtersFrame.BackgroundTransparency = 1
	filtersFrame.Parent = headerPanel
	local filtersLayout = Instance.new("UIListLayout")
	filtersLayout.FillDirection = Enum.FillDirection.Horizontal
	filtersLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	filtersLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	filtersLayout.Padding = UDim.new(0, 8)
	filtersLayout.Parent = filtersFrame
	listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, 0, 1, -listY)
	listFrame.Position = UDim2.fromOffset(0, listY)
	listFrame.BackgroundColor3 = Color3.fromRGB(16, 28, 42)
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 8
	listFrame.CanvasSize = UDim2.fromOffset(0, 0)
	listFrame.Parent = root
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 8) listPadding.PaddingBottom = UDim.new(0, 8)
	listPadding.PaddingLeft = UDim.new(0, 8) listPadding.PaddingRight = UDim.new(0, 8)
	listPadding.Parent = listFrame
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = listFrame

	detailOverlay = Instance.new("TextButton")
	detailOverlay.Size = UDim2.fromScale(1, 1)
	detailOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	detailOverlay.BackgroundTransparency = 0.35
	detailOverlay.Text = ""
	detailOverlay.Visible = false
	detailOverlay.ZIndex = 5
	detailOverlay.Parent = root
	detailOverlay.Activated:Connect(closeDetailPanel)
	detailPanel = Instance.new("Frame")
	detailPanel.AutomaticSize = Enum.AutomaticSize.Y
	detailPanel.Size = UDim2.fromOffset(560, 0)
	detailPanel.Position = UDim2.fromScale(0.5, 0.5)
	detailPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	detailPanel.BackgroundColor3 = Color3.fromRGB(8, 20, 36)
	detailPanel.BorderSizePixel = 0
	detailPanel.ZIndex = 6
	detailPanel.Parent = detailOverlay
	local detailPanelCorner = Instance.new("UICorner")
	detailPanelCorner.CornerRadius = UDim.new(0, 10)
	detailPanelCorner.Parent = detailPanel
	local panelPadding = Instance.new("UIPadding")
	panelPadding.PaddingTop = UDim.new(0, 16) panelPadding.PaddingBottom = UDim.new(0, 16)
	panelPadding.PaddingLeft = UDim.new(0, 16) panelPadding.PaddingRight = UDim.new(0, 16)
	panelPadding.Parent = detailPanel
	local panelLayout = Instance.new("UIListLayout")
	panelLayout.Padding = UDim.new(0, 12)
	panelLayout.Parent = detailPanel
	local detailStroke = Instance.new("UIStroke")
	detailStroke.Color = Color3.fromRGB(88, 170, 255)
	detailStroke.Thickness = 1.5
	detailStroke.Parent = detailPanel
	local closeButton = Instance.new("TextButton")
	closeButtonRef = closeButton
	closeButton.Size = UDim2.fromOffset(28, 28)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -12, 0, 12)
	closeButton.BackgroundColor3 = Color3.fromRGB(18, 39, 63)
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 17
	closeButton.Text = "X"
	closeButton.TextStrokeTransparency = 1
	closeButton.ZIndex = 7
	closeButton.Parent = detailPanel
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton
	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(90, 235, 245)
	closeStroke.Thickness = 1
	closeStroke.Parent = closeButton
	closeButton.MouseEnter:Connect(function() closeButton.BackgroundColor3 = Color3.fromRGB(33, 60, 89) end)
	closeButton.MouseLeave:Connect(function() closeButton.BackgroundColor3 = Color3.fromRGB(18, 39, 63) end)
	closeButton.Activated:Connect(closeDetailPanel)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function() searchQuery = searchBox.Text refresh(context) end)
	sortButton.Activated:Connect(function() sortIndex = (sortIndex % #sortModes) + 1 sortButton.Text = "Sort: " .. sortModes[sortIndex] refresh(context) end)

	if stateChangedConn then stateChangedConn:Disconnect() stateChangedConn = nil end
	if context.Events and context.Events.StateChanged then
		stateChangedConn = context.Events.StateChanged.Event:Connect(function() refresh(context) end)
	end
	refresh(context)
end

function BugdexApp.IsMounted(): boolean
	return windowRef ~= nil and windowRef.Content ~= nil and windowRef.Content.Parent ~= nil
end

function BugdexApp.Unmount(): ()
	if stateChangedConn then stateChangedConn:Disconnect() stateChangedConn = nil end
	if windowRef then windowRef.Destroy() end
	windowRef, root, progressCard, discoveredLabel, totalCaughtLabel, completionLabel, milestoneLabel, rewardBarFill, rewardBarLabel, listFrame, filtersFrame, searchBox, sortButton, headerPanel, detailOverlay, detailPanel = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
end

function BugdexApp.GetRootInstance()
	return root
end

return BugdexApp
