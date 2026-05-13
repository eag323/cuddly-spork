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
local summaryLabel
local milestoneLabel
local listFrame
local filtersFrame
local detailOverlay
local detailPanel
local stateChangedConn
local selectedRarityFilter = "All"
local closeButtonRef

local rarityColors = {
	Common = Color3.fromRGB(185, 185, 185),
	Uncommon = Color3.fromRGB(105, 214, 134),
	Rare = Color3.fromRGB(88, 170, 255),
	Epic = Color3.fromRGB(187, 102, 255),
	Legendary = Color3.fromRGB(255, 176, 66),
	Mythic = Color3.fromRGB(255, 106, 174),
}

local rarityTabs = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

local function getRarityColor(rarity: string): Color3
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

local function isBugDiscovered(playerData, bugId: string, caughtCount: number): boolean
	if caughtCount > 0 then return true end
	local bugdexData = playerData.Bugdex
	if type(bugdexData) == "table" then
		local discovered = bugdexData.Discovered
		if type(discovered) == "table" and discovered[bugId] == true then return true end
		if bugdexData[bugId] == true then return true end
	end
	local bugsData = playerData.Bugs
	if type(bugsData) == "table" then
		local discovered = bugsData.Discovered
		if type(discovered) == "table" and discovered[bugId] == true then return true end
	end
	local discoveredBugs = playerData.DiscoveredBugs
	if type(discoveredBugs) == "table" and discoveredBugs[bugId] == true then return true end
	return false
end

local function makeProgressBar(parent: Instance, percent: number, color: Color3)
	local barTrack = Instance.new("Frame")
	barTrack.Size = UDim2.new(1, 0, 0, 10)
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
end

local function getNextCollectionMilestone(discovered: number)
	local bestRequired, bestDefinition = math.huge, nil
	for _, definition in ipairs(AchievementConfig.Definitions) do
		if definition.section == "Collection" and definition.stat == "UniqueBugsDiscovered" then
			if definition.required > discovered and definition.required < bestRequired then
				bestRequired, bestDefinition = definition.required, definition
			end
		end
	end
	return bestDefinition
end

local function makeRarityBadge(parent: Instance, rarity: string)
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

local function createStatBox(parent: Instance, labelText: string, valueText: string)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.fromRGB(4, 12, 24)
	card.BorderSizePixel = 0
	card.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(52, 74, 98)
	stroke.Thickness = 1
	stroke.Parent = card
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = card
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(150, 170, 195)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = card
	local value = Instance.new("TextLabel")
	value.Size = UDim2.new(1, 0, 0, 18)
	value.Position = UDim2.fromOffset(0, 14)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamBold
	value.TextSize = 16
	value.TextColor3 = Color3.fromRGB(245, 248, 255)
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Text = valueText
	value.Parent = card
end

local function getSpeciesFlavor(species: string, role: string): string
	local flavorBySpecies = {
		Ant = "A balanced colony worker that supports the whole team.",
		Beetle = "A heavy-shelled defender built to absorb pressure.",
		["Pill Bug"] = "A fortress-like bug that excels at surviving long fights.",
		Wasp = "A fragile but deadly attacker built for burst damage.",
	}
	return flavorBySpecies[species] or string.format("A %s specialist adapted for colony combat.", string.lower(role ~= "" and role or "field"))
end

local function closeDetailPanel()
	if detailOverlay then detailOverlay.Visible = false end
end

local function openDetailPanel(entry)
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
	header.Size = UDim2.new(1, 0, 0, 132)
	header.BackgroundColor3 = Color3.fromRGB(18, 39, 63)
	header.BorderSizePixel = 0
	header.Parent = detailPanel
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)
	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingTop, headerPadding.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
	headerPadding.PaddingLeft, headerPadding.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	headerPadding.Parent = header
	local iconPanel = Instance.new("Frame")
	iconPanel.Size = UDim2.fromOffset(112, 112)
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
	icon.Size = UDim2.fromOffset(88, 88)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = bug.icon or bug.sprite or "rbxassetid://0"
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ImageColor3 = discoveredEntry and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
	icon.ImageTransparency = discoveredEntry and 0 or 0.2
	icon.Parent = iconPanel
	local info = Instance.new("Frame")
	info.Size = UDim2.new(1, -124, 1, 0)
	info.Position = UDim2.fromOffset(124, 0)
	info.BackgroundTransparency = 1
	info.Parent = header
	local infoLayout = Instance.new("UIListLayout")
	infoLayout.Padding = UDim.new(0, 6)
	infoLayout.Parent = info
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 34)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 26
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = discoveredEntry and tostring(bug.displayName) or "???"
	nameLabel.Parent = info
	makeRarityBadge(info, rarity)
	local meta = Instance.new("TextLabel")
	meta.Size = UDim2.new(1, 0, 0, 40)
	meta.BackgroundTransparency = 1
	meta.TextWrapped = true
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.TextYAlignment = Enum.TextYAlignment.Top
	meta.Font = Enum.Font.Gotham
	meta.TextSize = 14
	meta.TextColor3 = Color3.fromRGB(150, 170, 195)
	meta.Text = discoveredEntry and string.format("Species: %s\nRole: %s", tostring(bug.species or "Unknown"), tostring(bug.role or "Unknown")) or "Undiscovered Bug\nCatch this bug to reveal its details."
	meta.Parent = info
	createSectionTitle(detailPanel, "COMBAT STATS", accent)
	local statGrid = Instance.new("Frame")
	statGrid.Size = UDim2.new(1, 0, 0, 122)
	statGrid.BackgroundTransparency = 1
	statGrid.Parent = detailPanel
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.24, 0, 0, 56)
	grid.CellPadding = UDim2.new(0.013, 0, 0, 8)
	grid.Parent = statGrid
	local stats = bug.stats or {}
	local statOrder = {{"HP","HP"},{"ATK","ATK"},{"DEF","DEF"},{"SPD","SPD"},{"CRATE","CritRate"},{"CDMG","CritDamage"},{"RES","RES"},{"ACC","ACC"}}
	for _, mapping in ipairs(statOrder) do
		local value = "???"
		if discoveredEntry then
			local raw = tonumber(stats[mapping[2]]) or 0
			value = (mapping[1] == "CRATE" or mapping[1] == "CDMG") and string.format("%d%%", raw) or tostring(raw)
		end
		createStatBox(statGrid, mapping[1], value)
	end
	if discoveredEntry and bug.ability then
		createSectionTitle(detailPanel, "ABILITY", accent)
		local ability = bug.ability
		local panel = Instance.new("Frame")
		panel.Size = UDim2.new(1, 0, 0, 118)
		panel.BackgroundColor3 = Color3.fromRGB(18, 39, 63)
		panel.BorderSizePixel = 0
		panel.Parent = detailPanel
		Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
		local panelPadding = Instance.new("UIPadding")
		panelPadding.PaddingTop = UDim.new(0, 8)
		panelPadding.PaddingBottom = UDim.new(0, 8)
		panelPadding.PaddingLeft = UDim.new(0, 10)
		panelPadding.PaddingRight = UDim.new(0, 10)
		panelPadding.Parent = panel
		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, 0, 0, 22)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextSize = 16
		name.TextColor3 = Color3.fromRGB(245, 248, 255)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Text = tostring(ability.name or "Unknown Ability")
		name.Parent = panel
		local badgeLine = Instance.new("TextLabel")
		badgeLine.Size = UDim2.new(1, 0, 0, 20)
		badgeLine.Position = UDim2.fromOffset(0, 22)
		badgeLine.BackgroundTransparency = 1
		badgeLine.Font = Enum.Font.GothamBold
		badgeLine.TextSize = 12
		badgeLine.TextXAlignment = Enum.TextXAlignment.Left
		badgeLine.TextColor3 = Color3.fromRGB(90, 235, 245)
		local abilityType = tostring(ability.abilityType or ability.type or "Unknown")
		local target = tostring(ability.target or "Unknown")
		local cooldown = tonumber(ability.cooldownTurns or ability.cooldown)
		badgeLine.Text = cooldown and string.format("[ %s ] [ Cooldown: %d ] [ Target: %s ]", abilityType, cooldown, target) or string.format("[ %s ] [ Target: %s ]", abilityType, target)
		badgeLine.Parent = panel
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, 0, 1, -44)
		desc.Position = UDim2.fromOffset(0, 44)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 13
		desc.TextWrapped = true
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextColor3 = Color3.fromRGB(150, 170, 195)
		desc.Text = tostring(ability.description or "")
		desc.Parent = panel
	elseif not discoveredEntry and (rarity == "Legendary" or rarity == "Mythic") then
		createSectionTitle(detailPanel, "ABILITY", accent)
		local locked = Instance.new("TextLabel")
		locked.Size = UDim2.new(1, 0, 0, 24)
		locked.BackgroundTransparency = 1
		locked.Font = Enum.Font.GothamBold
		locked.TextSize = 14
		locked.TextXAlignment = Enum.TextXAlignment.Left
		locked.TextColor3 = Color3.fromRGB(150, 170, 195)
		locked.Text = "Ability: ???"
		locked.Parent = detailPanel
	end
	local flavor = Instance.new("TextLabel")
	flavor.Size = UDim2.new(1, 0, 0, 48)
	flavor.BackgroundTransparency = 1
	flavor.TextWrapped = true
	flavor.TextXAlignment = Enum.TextXAlignment.Left
	flavor.TextYAlignment = Enum.TextYAlignment.Top
	flavor.Font = Enum.Font.Gotham
	flavor.TextSize = 14
	flavor.TextColor3 = Color3.fromRGB(150, 170, 195)
	flavor.Text = discoveredEntry and ("Status: Discovered\n" .. getSpeciesFlavor(tostring(bug.species or ""), tostring(bug.role or ""))) or "Status: Undiscovered\nCatch this bug to reveal its details."
	flavor.Parent = detailPanel
end

local function refresh(context)
	if not root or not summaryLabel or not listFrame or not milestoneLabel or not filtersFrame then return end
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
		local bugId = tostring(bug.id or "")
		local count = tonumber(totalsBySpecies[bugId]) or 0
		local discoveredEntry = isBugDiscovered(playerData, bugId, count)
		group.total += 1
		if discoveredEntry then group.discovered += 1 discovered += 1 end
		totalCaught += count
		table.insert(group.entries, { bug = bug, count = count, discovered = discoveredEntry })
	end
	local rarityOrder = {}
	for _, tab in ipairs(rarityTabs) do if tab ~= "All" then table.insert(rarityOrder, tab) end end
	local completion = if totalSpecies > 0 then math.floor((discovered / totalSpecies) * 1000 + 0.5) / 10 else 0
	summaryLabel.Text = string.format("Discovered %s / %s bugs    Total bugs caught %s    Completion %s%%", NumberUtil.FormatNumber(discovered), NumberUtil.FormatNumber(totalSpecies), NumberUtil.FormatNumber(totalCaught), tostring(completion))
	local nextMilestone = getNextCollectionMilestone(discovered)
	milestoneLabel.Text = nextMilestone and string.format("Next: %d discovered -> %s", nextMilestone.required, nextMilestone.name) or "Next: Collection milestones complete"

	for _, tab in ipairs(rarityTabs) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(94, 30)
		button.Text = tab
		button.Font = Enum.Font.GothamBold
		button.TextSize = 13
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		local active = selectedRarityFilter == tab
		local tint = tab ~= "All" and getRarityColor(tab) or Color3.fromRGB(80, 150, 220)
		button.BackgroundColor3 = active and tint:Lerp(Color3.new(1,1,1),0.65) or Color3.fromRGB(29, 44, 61)
		button.TextColor3 = active and Color3.fromRGB(14, 18, 26) or Color3.fromRGB(223, 230, 236)
		button.Parent = filtersFrame
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 7)
		buttonCorner.Parent = button
		button.Activated:Connect(function() selectedRarityFilter = tab refresh(context) end)
	end

	for _, rarity in ipairs(rarityOrder) do
		if selectedRarityFilter == "All" or selectedRarityFilter == rarity then
			local group = groups[rarity]
			if group and group.total > 0 then
				local section = Instance.new("Frame")
				section.Size = UDim2.new(1, -4, 0, 0)
				section.AutomaticSize = Enum.AutomaticSize.Y
				section.BackgroundColor3 = Color3.fromRGB(23, 37, 54)
				section.BorderSizePixel = 0
				section.Parent = listFrame
				local sectionCorner = Instance.new("UICorner")
				sectionCorner.CornerRadius = UDim.new(0, 8)
				sectionCorner.Parent = section
				local sectionPadding = Instance.new("UIPadding")
				sectionPadding.PaddingTop = UDim.new(0, 8) sectionPadding.PaddingBottom = UDim.new(0, 8)
				sectionPadding.PaddingLeft = UDim.new(0, 8) sectionPadding.PaddingRight = UDim.new(0, 8)
				sectionPadding.Parent = section
				local sectionLayout = Instance.new("UIListLayout")
				sectionLayout.Padding = UDim.new(0, 8)
				sectionLayout.Parent = section

				local headerRow = Instance.new("Frame")
				headerRow.Size = UDim2.new(1, 0, 0, 24)
				headerRow.BackgroundTransparency = 1
				headerRow.Parent = section
				local left = Instance.new("TextLabel")
				left.Size = UDim2.new(0.7, 0, 1, 0)
				left.BackgroundTransparency = 1
				left.TextXAlignment = Enum.TextXAlignment.Left
				left.Font = Enum.Font.GothamBold
				left.TextSize = 16
				left.TextColor3 = getRarityColor(rarity)
				left.Text = string.upper(rarity) .. " BUGS"
				left.Parent = headerRow
				local right = Instance.new("TextLabel")
				right.Size = UDim2.new(0.3, 0, 1, 0)
				right.Position = UDim2.new(0.7, 0, 0, 0)
				right.BackgroundTransparency = 1
				right.TextXAlignment = Enum.TextXAlignment.Right
				right.Font = Enum.Font.GothamBold
				right.TextSize = 16
				right.TextColor3 = Color3.fromRGB(227, 235, 243)
				right.Text = string.format("%d / %d", group.discovered, group.total)
				right.Parent = headerRow

				makeProgressBar(section, if group.total > 0 then group.discovered / group.total else 0, getRarityColor(rarity))
				table.sort(group.entries, function(a, b)
					local speciesA, speciesB = tostring(a.bug.species or ""), tostring(b.bug.species or "")
					if speciesA ~= speciesB then return speciesA < speciesB end
					return tostring(a.bug.displayName or a.bug.id) < tostring(b.bug.displayName or b.bug.id)
				end)
				for _, entry in ipairs(group.entries) do
					local row = Instance.new("TextButton")
					row.Size = UDim2.new(1, 0, 0, 62)
					row.BackgroundColor3 = entry.discovered and Color3.fromRGB(28, 45, 66) or Color3.fromRGB(25, 34, 49)
					row.BorderColor3 = Color3.fromRGB(58, 78, 102)
					row.BorderSizePixel = 1
					row.AutoButtonColor = false
					row.Text = ""
					row.Parent = section
					local rowCorner = Instance.new("UICorner")
					rowCorner.CornerRadius = UDim.new(0, 8)
					rowCorner.Parent = row
					row.MouseEnter:Connect(function() row.BackgroundColor3 = row.BackgroundColor3:Lerp(Color3.fromRGB(55, 73, 95), 0.15) end)
					row.MouseLeave:Connect(function() row.BackgroundColor3 = entry.discovered and Color3.fromRGB(28, 45, 66) or Color3.fromRGB(25, 34, 49) end)
					row.Activated:Connect(function() openDetailPanel(entry) end)

					local icon = Instance.new("ImageLabel")
					icon.Size = UDim2.fromOffset(42, 42)
					icon.Position = UDim2.fromOffset(10, 10)
					icon.BackgroundTransparency = 1
					icon.ScaleType = Enum.ScaleType.Fit
					icon.Image = entry.bug.icon or "rbxassetid://0"
					icon.ImageColor3 = entry.discovered and Color3.new(1,1,1) or Color3.fromRGB(0,0,0)
					icon.ImageTransparency = entry.discovered and 0 or 0.2
					icon.Parent = row

					local name = Instance.new("TextLabel")
					name.Size = UDim2.new(0.43, 0, 0, 24)
					name.Position = UDim2.fromOffset(60, 7)
					name.BackgroundTransparency = 1
					name.TextXAlignment = Enum.TextXAlignment.Left
					name.Font = Enum.Font.GothamBold
					name.TextSize = 16
					name.TextColor3 = entry.discovered and Color3.new(1,1,1) or Color3.fromRGB(162, 172, 182)
					name.Text = entry.discovered and tostring(entry.bug.displayName) or "???"
					name.Parent = row

					local sub = Instance.new("TextLabel")
					sub.Size = UDim2.new(0.43, 0, 0, 20)
					sub.Position = UDim2.fromOffset(60, 33)
					sub.BackgroundTransparency = 1
					sub.TextXAlignment = Enum.TextXAlignment.Left
					sub.TextSize = 13
					sub.TextColor3 = Color3.fromRGB(181, 192, 204)
					sub.Text = entry.discovered and ("Species: " .. tostring(entry.bug.species or "Unknown")) or "Undiscovered"
					sub.Parent = row

					local badgeHolder = Instance.new("Frame")
					badgeHolder.Size = UDim2.new(0, 102, 0, 26)
					badgeHolder.Position = UDim2.new(0.63, -10, 0.5, -13)
					badgeHolder.BackgroundTransparency = 1
					badgeHolder.Parent = row
					makeRarityBadge(badgeHolder, rarity)

					local status = Instance.new("TextLabel")
					status.Size = UDim2.new(0.16, 0, 1, 0)
					status.Position = UDim2.new(0.84, 0, 0, 0)
					status.BackgroundTransparency = 1
					status.Font = Enum.Font.GothamBold
					status.TextSize = 15
					status.TextXAlignment = Enum.TextXAlignment.Center
					status.TextColor3 = entry.discovered and Color3.fromRGB(121, 255, 163) or Color3.fromRGB(160, 165, 173)
					status.Text = entry.discovered and "✓" or "Locked"
					status.Parent = row
				end
			end
		end
	end
	local layout = listFrame:FindFirstChildOfClass("UIListLayout")
	if layout then listFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12) end
end

function BugdexApp.Mount(target: Instance, context): ()
	if root then return end
	windowRef = Window.Create({ Title = "Bugdex.exe", Size = UDim2.fromOffset(780, 540), Position = UDim2.fromScale(0.1, 0.1), Parent = target, OnClose = function() context.Controllers.Window.Close("Bugdex") end })
	root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = windowRef.Content
	local rootPadding = Instance.new("UIPadding")
	rootPadding.PaddingTop = UDim.new(0, 8) rootPadding.PaddingBottom = UDim.new(0, 8)
	rootPadding.PaddingLeft = UDim.new(0, 8) rootPadding.PaddingRight = UDim.new(0, 8)
	rootPadding.Parent = root

	summaryLabel = Instance.new("TextLabel")
	summaryLabel.Size = UDim2.new(1, 0, 0, 28)
	summaryLabel.BackgroundTransparency = 1
	summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	summaryLabel.TextColor3 = Color3.new(1, 1, 1)
	summaryLabel.Font = Enum.Font.GothamBold
	summaryLabel.TextSize = 17
	summaryLabel.Text = "Discovered 0 / 300 bugs    Total bugs caught 0    Completion 0%"
	summaryLabel.Parent = root

	milestoneLabel = Instance.new("TextLabel")
	milestoneLabel.Size = UDim2.new(1, 0, 0, 22)
	milestoneLabel.Position = UDim2.fromOffset(0, 30)
	milestoneLabel.BackgroundTransparency = 1
	milestoneLabel.TextXAlignment = Enum.TextXAlignment.Left
	milestoneLabel.TextColor3 = Color3.fromRGB(255, 220, 110)
	milestoneLabel.TextSize = 14
	milestoneLabel.Text = "Next: 10 discovered -> Budding Collector"
	milestoneLabel.Parent = root

	filtersFrame = Instance.new("Frame")
	filtersFrame.Size = UDim2.new(1, 0, 0, 34)
	filtersFrame.Position = UDim2.fromOffset(0, 54)
	filtersFrame.BackgroundTransparency = 1
	filtersFrame.Parent = root
	local filtersLayout = Instance.new("UIListLayout")
	filtersLayout.FillDirection = Enum.FillDirection.Horizontal
	filtersLayout.Padding = UDim.new(0, 8)
	filtersLayout.Parent = filtersFrame

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, 0, 1, -100)
	listFrame.Position = UDim2.fromOffset(0, 96)
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
	detailPanel.Size = UDim2.fromOffset(610, 500)
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
	panelPadding.PaddingTop = UDim.new(0, 12) panelPadding.PaddingBottom = UDim.new(0, 12)
	panelPadding.PaddingLeft = UDim.new(0, 12) panelPadding.PaddingRight = UDim.new(0, 12)
	panelPadding.Parent = detailPanel
	local panelLayout = Instance.new("UIListLayout")
	panelLayout.Padding = UDim.new(0, 10)
	panelLayout.Parent = detailPanel
	local detailStroke = Instance.new("UIStroke")
	detailStroke.Color = Color3.fromRGB(88, 170, 255)
	detailStroke.Thickness = 1.5
	detailStroke.Parent = detailPanel
	local closeButton = Instance.new("TextButton")
	closeButtonRef = closeButton
	closeButton.Size = UDim2.fromOffset(28, 28)
	closeButton.Position = UDim2.new(1, -34, 0, 8)
	closeButton.BackgroundColor3 = Color3.fromRGB(18, 39, 63)
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 17
	closeButton.Text = "×"
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

	if stateChangedConn then stateChangedConn:Disconnect() stateChangedConn = nil end
	if context.Events and context.Events.StateChanged then
		stateChangedConn = context.Events.StateChanged.Event:Connect(function() refresh(context) end)
	end
	refresh(context)
end

function BugdexApp.Unmount(): ()
	if stateChangedConn then stateChangedConn:Disconnect() stateChangedConn = nil end
	if windowRef then windowRef.Destroy() end
	windowRef, root, summaryLabel, milestoneLabel, listFrame, filtersFrame, detailOverlay, detailPanel = nil, nil, nil, nil, nil, nil, nil, nil
end

return BugdexApp
