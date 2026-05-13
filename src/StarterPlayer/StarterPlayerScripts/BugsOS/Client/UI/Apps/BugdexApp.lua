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
local stateChangedConn


local rarityColors = {
	Common = Color3.fromRGB(185, 185, 185),
	Uncommon = Color3.fromRGB(105, 214, 134),
	Rare = Color3.fromRGB(88, 170, 255),
	Epic = Color3.fromRGB(187, 102, 255),
	Legendary = Color3.fromRGB(255, 176, 66),
	Mythic = Color3.fromRGB(255, 106, 174),
}

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

	local fallbackOrder = {
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Epic = 4,
		Legendary = 5,
		Mythic = 6,
	}
	return fallbackOrder[rarity] or math.huge
end

local function getBugdexCatalog()
	if type(BugConfig.GetAllBugs) == "function" then
		return BugConfig.GetAllBugs()
	end

	if type(BugConfig.Bugs) == "table" then
		local list = {}
		for _, bug in pairs(BugConfig.Bugs) do
			table.insert(list, bug)
		end
		table.sort(list, function(a, b)
			local rarityA = getRarityOrderIndex(tostring(a.rarity))
			local rarityB = getRarityOrderIndex(tostring(b.rarity))
			if rarityA ~= rarityB then
				return rarityA < rarityB
			end
			local speciesA = tostring(a.species or "")
			local speciesB = tostring(b.species or "")
			if speciesA ~= speciesB then
				return speciesA < speciesB
			end
			return tostring(a.displayName or a.id) < tostring(b.displayName or b.id)
		end)
		return list
	end

	warn("[BugdexApp] BugConfig catalog missing. Falling back to empty display list.")
	return {}
end

local function isBugDiscovered(playerData, bugId: string, caughtCount: number): boolean
	if caughtCount > 0 then
		return true
	end

	local bugdexData = playerData.Bugdex
	if type(bugdexData) == "table" then
		local discovered = bugdexData.Discovered
		if type(discovered) == "table" and discovered[bugId] == true then
			return true
		end
		if bugdexData[bugId] == true then
			return true
		end
	end

	local bugsData = playerData.Bugs
	if type(bugsData) == "table" then
		local discovered = bugsData.Discovered
		if type(discovered) == "table" and discovered[bugId] == true then
			return true
		end
	end

	local discoveredBugs = playerData.DiscoveredBugs
	if type(discoveredBugs) == "table" and discoveredBugs[bugId] == true then
		return true
	end

	return false
end

local function makeProgressBar(parent: Instance, percent: number, color: Color3)
	local barTrack = Instance.new("Frame")
	barTrack.Size = UDim2.new(1, 0, 0, 8)
	barTrack.BackgroundColor3 = Color3.fromRGB(24, 38, 54)
	barTrack.BorderSizePixel = 0
	barTrack.Parent = parent

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
	barFill.BackgroundColor3 = color
	barFill.BorderSizePixel = 0
	barFill.Parent = barTrack
end

local function getNextCollectionMilestone(discovered: number)
	local bestRequired = math.huge
	local bestDefinition = nil

	for _, definition in ipairs(AchievementConfig.Definitions) do
		if definition.section == "Collection" and definition.stat == "UniqueBugsDiscovered" then
			if definition.required > discovered and definition.required < bestRequired then
				bestRequired = definition.required
				bestDefinition = definition
			end
		end
	end

	return bestDefinition
end

local function refresh(context)
	if not root or not summaryLabel or not listFrame or not milestoneLabel then
		return
	end

	for _, child in ipairs(listFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local playerData = context.State.PlayerData or {}
	local bugdexData = playerData.Bugdex or {}
	local totalsBySpecies = bugdexData.TotalCaughtBySpecies or {}
	local bugs = getBugdexCatalog()
	local totalSpecies = #bugs
	local discovered = 0
	local totalCaught = 0
	local groups = {}
	for _, bug in ipairs(bugs) do
		local rarity = tostring(bug.rarity or "Common")
		if groups[rarity] == nil then
			groups[rarity] = { rarity = rarity, total = 0, discovered = 0, entries = {} }
		end
		local group = groups[rarity]
		local bugId = tostring(bug.id or "")
		local count = tonumber(totalsBySpecies[bugId]) or 0
		local discoveredEntry = isBugDiscovered(playerData, bugId, count)
		group.total += 1
		if discoveredEntry then
			group.discovered += 1
			discovered += 1
		end
		totalCaught += count
		table.insert(group.entries, { bug = bug, count = count, discovered = discoveredEntry })
	end

	local rarityOrder = {}
	for rarity, _ in pairs(groups) do
		table.insert(rarityOrder, rarity)
	end
	table.sort(rarityOrder, function(a, b)
		local orderA = getRarityOrderIndex(a)
		local orderB = getRarityOrderIndex(b)
		if orderA ~= orderB then
			return orderA < orderB
		end
		return a < b
	end)

	local completion = if totalSpecies > 0 then math.floor((discovered / totalSpecies) * 1000 + 0.5) / 10 else 0
	summaryLabel.Text = string.format(
		"Discovered %s / %s bugs    Total bugs caught %s    Completion %s%%",
		NumberUtil.FormatNumber(discovered),
		NumberUtil.FormatNumber(totalSpecies),
		NumberUtil.FormatNumber(totalCaught),
		tostring(completion)
	)

	local nextMilestone = getNextCollectionMilestone(discovered)
	if nextMilestone then
		milestoneLabel.Text = string.format("Next: %d discovered -> %s", nextMilestone.required, nextMilestone.name)
	else
		milestoneLabel.Text = "Next: Collection milestones complete"
	end

	for _, rarity in ipairs(rarityOrder) do
		local group = groups[rarity]
		if group and group.total > 0 then
			local section = Instance.new("Frame")
			section.Size = UDim2.new(1, -4, 0, 0)
			section.AutomaticSize = Enum.AutomaticSize.Y
			section.BackgroundColor3 = Color3.fromRGB(23, 37, 54)
			section.BorderSizePixel = 0
			section.Parent = listFrame

			local sectionPadding = Instance.new("UIPadding")
			sectionPadding.PaddingTop = UDim.new(0, 8)
			sectionPadding.PaddingBottom = UDim.new(0, 8)
			sectionPadding.PaddingLeft = UDim.new(0, 8)
			sectionPadding.PaddingRight = UDim.new(0, 8)
			sectionPadding.Parent = section

			local sectionLayout = Instance.new("UIListLayout")
			sectionLayout.Padding = UDim.new(0, 6)
			sectionLayout.Parent = section

			local header = Instance.new("TextLabel")
			header.Size = UDim2.new(1, 0, 0, 24)
			header.BackgroundTransparency = 1
			header.TextXAlignment = Enum.TextXAlignment.Left
			header.TextColor3 = getRarityColor(rarity)
			header.Font = Enum.Font.GothamBold
			header.TextSize = 16
			header.Text = string.format("%s  %d/%d", rarity, group.discovered, group.total)
			header.Parent = section

			local sectionPercent = if group.total > 0 then group.discovered / group.total else 0
			makeProgressBar(section, sectionPercent, getRarityColor(rarity))

			table.sort(group.entries, function(a, b)
				local speciesA = tostring(a.bug.species or "")
				local speciesB = tostring(b.bug.species or "")
				if speciesA ~= speciesB then return speciesA < speciesB end
				return tostring(a.bug.displayName or a.bug.id) < tostring(b.bug.displayName or b.bug.id)
			end)

			for _, entry in ipairs(group.entries) do
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 44)
				row.BackgroundColor3 = Color3.fromRGB(28, 45, 66)
				row.BorderSizePixel = 0
				row.Parent = section

				local discoveredEntry = entry.discovered == true
				if not discoveredEntry then
					row.BackgroundTransparency = 0.35
				end

				local iconLabel = Instance.new("ImageLabel")
				iconLabel.Size = UDim2.fromOffset(28, 28)
				iconLabel.Position = UDim2.fromOffset(8, 8)
				iconLabel.BackgroundTransparency = 1
				iconLabel.ScaleType = Enum.ScaleType.Fit
				local icon = entry.bug.icon or "rbxassetid://0"
				iconLabel.Image = icon
				if discoveredEntry then
					iconLabel.ImageColor3 = Color3.new(1, 1, 1)
					iconLabel.ImageTransparency = 0
				else
					iconLabel.ImageColor3 = Color3.fromRGB(0, 0, 0)
					iconLabel.ImageTransparency = 0.2
				end
				iconLabel.Parent = row

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(0.42, -8, 1, 0)
				nameLabel.Position = UDim2.fromOffset(32, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.TextColor3 = if discoveredEntry then Color3.new(1, 1, 1) else Color3.fromRGB(140, 140, 140)
				nameLabel.TextSize = 15
				nameLabel.Text = if discoveredEntry then tostring(entry.bug.displayName) else "???"
				nameLabel.Parent = row

				local rarityLabel = Instance.new("TextLabel")
				rarityLabel.Size = UDim2.new(0.2, -6, 1, 0)
				rarityLabel.Position = UDim2.new(0.48, 0, 0, 0)
				rarityLabel.BackgroundTransparency = 1
				rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
				rarityLabel.TextColor3 = getRarityColor(rarity)
				rarityLabel.TextSize = 14
				rarityLabel.Text = rarity
				rarityLabel.Parent = row

				local caughtLabel = Instance.new("TextLabel")
				caughtLabel.Size = UDim2.new(0.2, -6, 1, 0)
				caughtLabel.Position = UDim2.new(0.68, 0, 0, 0)
				caughtLabel.BackgroundTransparency = 1
				caughtLabel.TextXAlignment = Enum.TextXAlignment.Left
				caughtLabel.TextColor3 = if discoveredEntry then Color3.fromRGB(206, 206, 206) else Color3.fromRGB(120, 120, 120)
				caughtLabel.TextSize = 14
				caughtLabel.Text = if discoveredEntry then tostring(entry.bug.species or "Unknown") else "Undiscovered"
				caughtLabel.Parent = row

				local checkLabel = Instance.new("TextLabel")
				checkLabel.Size = UDim2.new(0.12, 0, 1, 0)
				checkLabel.Position = UDim2.new(0.88, 0, 0, 0)
				checkLabel.BackgroundTransparency = 1
				checkLabel.TextColor3 = if discoveredEntry then Color3.fromRGB(121, 255, 163) else Color3.fromRGB(120, 120, 120)
				checkLabel.TextSize = 18
				checkLabel.Text = if discoveredEntry then "✓" else ""
				checkLabel.Parent = row
			end
		end
	end

	local layout = listFrame:FindFirstChildOfClass("UIListLayout")
	if layout then
		listFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 10)
	end
end

function BugdexApp.Mount(target: Instance, context): ()
	if root then
		return
	end

	windowRef = Window.Create({
		Title = "Bugdex.exe",
		Size = UDim2.fromOffset(780, 540),
		Position = UDim2.fromScale(0.1, 0.1),
		Parent = target,
		OnClose = function()
			context.Controllers.Window.Close("Bugdex")
		end,
	})

	root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = windowRef.Content

	local rootPadding = Instance.new("UIPadding")
	rootPadding.PaddingTop = UDim.new(0, 8)
	rootPadding.PaddingBottom = UDim.new(0, 8)
	rootPadding.PaddingLeft = UDim.new(0, 8)
	rootPadding.PaddingRight = UDim.new(0, 8)
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

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, 0, 1, -62)
	listFrame.Position = UDim2.fromOffset(0, 58)
	listFrame.BackgroundColor3 = Color3.fromRGB(16, 28, 42)
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 8
	listFrame.CanvasSize = UDim2.fromOffset(0, 0)
	listFrame.Parent = root

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 8)
	listPadding.PaddingBottom = UDim.new(0, 8)
	listPadding.PaddingLeft = UDim.new(0, 8)
	listPadding.PaddingRight = UDim.new(0, 8)
	listPadding.Parent = listFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = listFrame

	if stateChangedConn then
		stateChangedConn:Disconnect()
		stateChangedConn = nil
	end
	if context.Events and context.Events.StateChanged then
		stateChangedConn = context.Events.StateChanged.Event:Connect(function()
			refresh(context)
		end)
	end

	refresh(context)
end

function BugdexApp.Unmount(): ()
	if stateChangedConn then
		stateChangedConn:Disconnect()
		stateChangedConn = nil
	end
	if windowRef then
		windowRef.Destroy()
	end
	windowRef = nil
	root = nil
	summaryLabel = nil
	milestoneLabel = nil
	listFrame = nil
end

return BugdexApp
