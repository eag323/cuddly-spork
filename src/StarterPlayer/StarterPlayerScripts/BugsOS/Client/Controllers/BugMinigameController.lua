--!strict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local BugConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugConfig"))
local BugBonusConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugBonusConfig"))

local BugMinigameController = {}
local context
local bugRoot
local activeId
local hitsRemaining = 0
local bugButton: TextButton?
local headerLabel: TextLabel?
local activeRewardGui: Frame?

local function clear()
	if bugRoot then bugRoot:Destroy(); bugRoot=nil end
	bugButton=nil; headerLabel=nil; activeId=nil; hitsRemaining=0
end

local function clearRewardScreen()
	if activeRewardGui then activeRewardGui:Destroy(); activeRewardGui=nil end
end

local function updateHeader(displayName: string, rarity: string)
	if headerLabel then headerLabel.Text = string.format("%s [%s] Hits: %d", displayName, rarity, math.max(hitsRemaining, 0)) end
end

local function getRarityStyle(rarity: string)
	local styles = {
		Common = {Accent = Color3.fromRGB(170, 188, 210), Glow = 0.78, Bounce = 0.09, Sparkles = false, Intensity = 1.0},
		Uncommon = {Accent = Color3.fromRGB(102, 224, 133), Glow = 0.68, Bounce = 0.11, Sparkles = true, Intensity = 1.1},
		Rare = {Accent = Color3.fromRGB(94, 174, 255), Glow = 0.58, Bounce = 0.13, Sparkles = true, Intensity = 1.25},
		Epic = {Accent = Color3.fromRGB(196, 112, 255), Glow = 0.48, Bounce = 0.16, Sparkles = true, Intensity = 1.45},
		Legendary = {Accent = Color3.fromRGB(255, 188, 74), Glow = 0.38, Bounce = 0.2, Sparkles = true, Intensity = 1.7},
		Mythic = {Accent = Color3.fromRGB(255, 104, 162), Glow = 0.28, Bounce = 0.24, Sparkles = true, Intensity = 1.95},
	}
	return styles[rarity] or styles.Common
end

local function formatPercent(value)
	return string.format("+%d%%", math.floor((tonumber(value) or 0) * 100 + 0.5))
end

local function formatBonusStat(bonus)
	if BugBonusConfig and BugBonusConfig.FormatBonus then return BugBonusConfig.FormatBonus(bonus) end
	local displayName = tostring((bonus and bonus.DisplayName) or (bonus and bonus.Id) or "Bonus")
	return string.format("%s %s", formatPercent(bonus and bonus.Value), displayName)
end

local function getBugConfigFromPayload(payload)
	local bug = type(payload.Bug)=="table" and payload.Bug or {}
	local speciesId = bug.BugId or bug.SpeciesId or payload.SpeciesId
	if type(speciesId)=="string" then return BugConfig.GetBug(speciesId) or BugConfig.Bugs[speciesId] end
	local name = string.lower(tostring(payload.DisplayName or bug.Species or "")):gsub("%s+", "_")
	return BugConfig.Bugs[name]
end

local function createText(parent, text, size, font, color, pos, sx, sy)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 1
	label.Text = text
	label.TextSize = size
	label.Font = font
	label.TextColor3 = color
	label.Position = pos
	label.Size = UDim2.new(1, -20, sy or 0, sx or 24)
	label.Parent = parent
	return label
end

local function createBadge(parent, text, color, pos, width, height)
	local badge = Instance.new("TextLabel")
	badge.BackgroundColor3 = color
	badge.BackgroundTransparency = 0.12
	badge.TextStrokeTransparency = 1
	badge.Text = text
	badge.TextColor3 = Color3.fromRGB(8, 18, 32)
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 13
	badge.Position = pos
	badge.Size = UDim2.fromOffset(width, height)
	badge.Parent = parent
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
	return badge
end

local function showRewardScreen(payload)
	clearRewardScreen()
	local bug = type(payload.Bug)=="table" and payload.Bug or {}
	local cfg = getBugConfigFromPayload(payload) or {}
	local rarity = tostring(payload.Rarity or bug.Rarity or cfg.rarity or "Common")
	local style = getRarityStyle(rarity)
	local displayName = tostring(payload.DisplayName or bug.Species or cfg.displayName or "Bug")
	local role = tostring(cfg.role or bug.Role or "")
	local species = tostring(cfg.species or bug.Species or "")
	local iconImage = tostring(cfg.icon or "")
	local bonuses = payload.BonusStats or bug.BonusStats or {}
	if type(bonuses) ~= "table" then bonuses = {} end

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1,1)
	overlay.BackgroundColor3 = Color3.new(0,0,0)
	overlay.BackgroundTransparency = 1
	overlay.Parent = context.UI.WorldLayer
	activeRewardGui = overlay

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.fromOffset(550, 650)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(10, 24, 42)
	card.BorderSizePixel = 0
	card.Parent = overlay
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
	local cardStroke = Instance.new("UIStroke"); cardStroke.Color = style.Accent; cardStroke.Thickness = 2; cardStroke.Transparency = 0.08; cardStroke.Parent = card

	local title = createText(card, "BUG CAUGHT!", 30, Enum.Font.GothamBlack, Color3.fromRGB(240, 247, 255), UDim2.fromOffset(10, 14), 36, 0)
	title.TextXAlignment = Enum.TextXAlignment.Center

	local glow = Instance.new("Frame")
	glow.Size = UDim2.fromOffset(210, 210)
	glow.Position = UDim2.new(0.5, -105, 0, 60)
	glow.BackgroundColor3 = style.Accent
	glow.BackgroundTransparency = style.Glow
	glow.Parent = card
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset(180, 180)
	icon.Position = UDim2.new(0.5, -90, 0, 74)
	icon.Image = iconImage
	icon.Parent = card
	if iconImage == "" then
		local fallback = createText(icon, "BUG", 44, Enum.Font.GothamBlack, Color3.fromRGB(240, 247, 255), UDim2.fromOffset(0, 0), 180, 1)
		fallback.Size = UDim2.fromScale(1, 1)
		fallback.TextXAlignment = Enum.TextXAlignment.Center
		fallback.TextYAlignment = Enum.TextYAlignment.Center
	end

	local nameLabel = createText(card, displayName, 28, Enum.Font.GothamBold, Color3.fromRGB(243, 248, 255), UDim2.fromOffset(10, 266), 32, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	local rarityBadge = createBadge(card, rarity, style.Accent, UDim2.new(0.5, -60, 0, 304), 120, 26)
	local roleSpeciesText = (role ~= "" and species ~= "") and (role .. " • " .. species) or ""
	local roleSpecies = createText(card, roleSpeciesText, 15, Enum.Font.GothamSemibold, Color3.fromRGB(172, 194, 220), UDim2.fromOffset(10, 338), 22, 0)
	roleSpecies.TextXAlignment = Enum.TextXAlignment.Center
	roleSpecies.Visible = roleSpeciesText ~= ""

	local newDiscovery = nil
	if payload.WasNewDiscovery == true then
		newDiscovery = createBadge(card, "NEW DISCOVERY!  Added to Bugdex", Color3.fromRGB(95, 238, 211), UDim2.new(0.5, -145, 0, roleSpecies.Visible and 366 or 344), 290, 28)
	end

	local bonusHeaderY = newDiscovery and 404 or (roleSpecies.Visible and 392 or 372)
	local bonusHeader = createText(card, "BONUS STATS", 15, Enum.Font.GothamBold, Color3.fromRGB(91, 233, 244), UDim2.fromOffset(24, bonusHeaderY), 20, 0)
	bonusHeader.TextXAlignment = Enum.TextXAlignment.Left

	local bonusCards = {}
	local bonusStartY = bonusHeaderY + 24
	if #bonuses == 0 then
		local empty = createText(card, "No bonus stats", 14, Enum.Font.Gotham, Color3.fromRGB(153, 170, 194), UDim2.fromOffset(24, bonusStartY + 6), 20, 0)
		empty.TextXAlignment = Enum.TextXAlignment.Left
	else
		for i, b in ipairs(bonuses) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -46, 0, 32)
			row.Position = UDim2.fromOffset(23, bonusStartY + ((i-1) * 36))
			local category = tostring(b.Category or "Farmer")
			row.BackgroundColor3 = (category == "Combat") and Color3.fromRGB(52, 30, 30) or Color3.fromRGB(24, 44, 44)
			row.BackgroundTransparency = 0.1
			row.BorderSizePixel = 0
			row.Parent = card
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
			local rowStroke = Instance.new("UIStroke"); rowStroke.Color = (category == "Combat") and Color3.fromRGB(244, 121, 92) or Color3.fromRGB(92, 238, 205); rowStroke.Thickness = 1.5; rowStroke.Transparency = 0.22; rowStroke.Parent = row
			local txt = createText(row, formatBonusStat(b), 14, Enum.Font.GothamSemibold, Color3.fromRGB(232, 245, 252), UDim2.fromOffset(10, 0), 32, 1)
			txt.TextXAlignment = Enum.TextXAlignment.Left
			local q = tostring(b.RollQuality or "Normal")
			if q == "Good" or q == "Great" or q == "Perfect" then
				local qColor = (q == "Good" and Color3.fromRGB(100, 228, 240)) or (q == "Great" and Color3.fromRGB(161, 138, 255)) or Color3.fromRGB(255, 194, 112)
				createBadge(row, q, qColor, UDim2.new(1, -84, 0.5, -11), 72, 22)
			end
			row.Visible = false
			table.insert(bonusCards, row)
		end
	end

	local pointsY = math.clamp(bonusStartY + math.max(#bonuses, 1) * 36 + 18, 510, 548)
	local points = createText(card, string.format("Bug Points +%d", tonumber(payload.BugPointsAwarded) or 0), 20, Enum.Font.GothamBold, Color3.fromRGB(255, 189, 76), UDim2.fromOffset(24, pointsY), 28, 0)
	points.TextXAlignment = Enum.TextXAlignment.Left

	local viewButton = Instance.new("TextButton")
	viewButton.Size = UDim2.fromOffset(220, 42)
	viewButton.Position = UDim2.new(0.5, -236, 1, -58)
	viewButton.BackgroundColor3 = Color3.fromRGB(78, 126, 168)
	viewButton.TextColor3 = Color3.fromRGB(242, 248, 255)
	viewButton.TextStrokeTransparency = 1
	viewButton.Text = "View Bug"
	viewButton.TextSize = 15
	viewButton.Font = Enum.Font.GothamBold
	viewButton.Parent = card
	Instance.new("UICorner", viewButton).CornerRadius = UDim.new(0, 8)
	local vbStroke = Instance.new("UIStroke"); vbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; vbStroke.Color = Color3.fromRGB(154, 186, 218); vbStroke.Thickness = 1; vbStroke.Transparency = 0.2; vbStroke.Parent = viewButton

	local continueButton = Instance.new("TextButton")
	continueButton.Size = UDim2.fromOffset(220, 42)
	continueButton.Position = UDim2.new(0.5, 16, 1, -58)
	continueButton.BackgroundColor3 = style.Accent
	continueButton.TextColor3 = Color3.fromRGB(8, 18, 32)
	continueButton.TextStrokeTransparency = 1
	continueButton.Text = "Continue"
	continueButton.TextSize = 15
	continueButton.Font = Enum.Font.GothamBold
	continueButton.Parent = card
	Instance.new("UICorner", continueButton).CornerRadius = UDim.new(0, 8)
	local cbStroke = Instance.new("UIStroke"); cbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; cbStroke.Color = Color3.fromRGB(248, 250, 255); cbStroke.Thickness = 1; cbStroke.Transparency = 0.35; cbStroke.Parent = continueButton

	viewButton.Visible = false
	continueButton.Visible = false

	local function safeClose() clearRewardScreen() end
	continueButton.Activated:Connect(safeClose)
	viewButton.Activated:Connect(function()
		safeClose()
		local windowController = context and context.Controllers and context.Controllers.Window
		if windowController and windowController.Open then
			windowController.Open("Bugs")
		else
			if context.Controllers.Notification then context.Controllers.Notification.Show("Open Bugs.exe to view your bug.", "Info") end
		end
	end)

	-- Reveal animation sequence + rarity intensity.
	card.Size = UDim2.fromOffset(470, 552)
	overlay.BackgroundTransparency = 1
	TweenService:Create(overlay, TweenInfo.new(0.16), {BackgroundTransparency = 0.35}):Play()
	TweenService:Create(card, TweenInfo.new(0.2 + style.Bounce, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(550, 650)}):Play()
	for _, v in ipairs({title, icon, nameLabel, rarityBadge, roleSpecies, points}) do v.Visible = false end
	if newDiscovery then newDiscovery.Visible = false end

	task.delay(0.08, function() if activeRewardGui ~= overlay then return end title.Visible = true end)
	task.delay(0.2, function() if activeRewardGui ~= overlay then return end icon.Visible = true; TweenService:Create(glow, TweenInfo.new(0.2 * style.Intensity), {BackgroundTransparency = math.max(0.12, style.Glow - 0.1)}):Play() end)
	task.delay(0.36, function() if activeRewardGui ~= overlay then return end nameLabel.Visible = true; rarityBadge.Visible = true; roleSpecies.Visible = roleSpeciesText ~= "" end)
	task.delay(0.5, function() if activeRewardGui ~= overlay then return end if newDiscovery then newDiscovery.Visible = true; TweenService:Create(newDiscovery, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true), {BackgroundTransparency = 0.02}):Play() end end)

	for i, row in ipairs(bonusCards) do
		task.delay(0.62 + (i - 1) * 0.14, function()
			if activeRewardGui ~= overlay then return end
			row.Visible = true
			row.Size = UDim2.new(1, -46, 0, 24)
			TweenService:Create(row, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, -46, 0, 32)}):Play()
		end)
	end

	task.delay(0.96, function() if activeRewardGui ~= overlay then return end points.Visible = true end)
	task.delay(1.08, function() if activeRewardGui ~= overlay then return end viewButton.Visible = true; continueButton.Visible = true end)

	if style.Sparkles then
		for i = 1, 5 do
			local sparkle = Instance.new("Frame")
			sparkle.Size = UDim2.fromOffset(6, 6)
			sparkle.Position = UDim2.fromScale(0.5, 0.2)
			sparkle.BackgroundColor3 = style.Accent
			sparkle.BorderSizePixel = 0
			sparkle.BackgroundTransparency = 0.2
			sparkle.Parent = card
			Instance.new("UICorner", sparkle).CornerRadius = UDim.new(1, 0)
			local driftX = math.random(-180, 180)
			local driftY = math.random(30, 230)
			TweenService:Create(sparkle, TweenInfo.new(0.45 + i * 0.05), {Position = UDim2.new(0.5, driftX, 0, driftY), BackgroundTransparency = 1}):Play()
			task.delay(0.6 + i * 0.06, function() if sparkle then sparkle:Destroy() end end)
		end
	end

	task.spawn(function()
		while activeRewardGui == overlay and icon.Parent do
			TweenService:Create(icon, TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, -90, 0, 68)}):Play()
			task.wait(0.85)
			if activeRewardGui ~= overlay then break end
			TweenService:Create(icon, TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, -90, 0, 76)}):Play()
			task.wait(0.85)
		end
	end)

	-- TODO: Sound hooks can be added here using existing approved audio utility/assets only.
end

local function hitFeedback(button) local up=TweenService:Create(button,TweenInfo.new(0.08),{Size=UDim2.fromOffset(92,92)}); local down=TweenService:Create(button,TweenInfo.new(0.1),{Size=UDim2.fromOffset(84,84)}); up.Completed:Once(function() down:Play() end); up:Play() end
local function startMovement(button, behavior) task.spawn(function() task.wait(0.5); while button.Parent do local pos=UDim2.fromScale(math.random(20,80)/100,math.random(20,75)/100); local d=1.6; if behavior=="ZigZagger" then d=1.0 end if behavior=="Dasher" then d=0.65 task.wait(0.5) end TweenService:Create(button,TweenInfo.new(d,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Position=pos}):Play(); task.wait(d) end end) end
function BugMinigameController.Init(c) context=c end
function BugMinigameController.Start()
	context.Remotes.BugSpawned.OnClientEvent:Connect(function(payload)
		clear(); clearRewardScreen(); activeId=payload.ActiveBugId; hitsRemaining=payload.HitsRequired
		local holder=Instance.new("Frame"); holder.Size=UDim2.fromScale(1,1); holder.BackgroundTransparency=1; holder.Parent=context.UI.WorldLayer; bugRoot=holder
		local label=Instance.new("TextLabel"); label.Size=UDim2.fromOffset(360,24); label.Position=UDim2.fromOffset(12,12); label.BackgroundTransparency=1; label.TextStrokeTransparency=1; label.TextColor3=Color3.new(1,1,1); label.TextXAlignment=Enum.TextXAlignment.Left; label.Font=Enum.Font.GothamSemibold; label.TextSize=15; label.Parent=holder; headerLabel=label; updateHeader(payload.DisplayName,payload.Rarity)
		local bug=Instance.new("TextButton"); bug.Size=UDim2.fromOffset(84,84); bug.Position=UDim2.fromScale(0.5,0.5); bug.Text="🐞"; bug.TextStrokeTransparency=1; bug.TextScaled=true; bug.BackgroundColor3=Color3.fromRGB(80,40,40); bug.Parent=holder; Instance.new("UICorner",bug).CornerRadius=UDim.new(1,0); bugButton=bug
		bug.Activated:Connect(function() if not activeId then return end context.Remotes.BugAttemptCatch:FireServer({ActiveBugId=activeId}) end)
		startMovement(bug,payload.Behavior)
	end)
	context.Remotes.BugHitUpdate.OnClientEvent:Connect(function(payload) if type(payload)=="table" and payload.ActiveBugId==activeId then hitsRemaining=tonumber(payload.HitsRemaining) or hitsRemaining; if bugButton then hitFeedback(bugButton) end end end)
	context.Remotes.BugCaptured.OnClientEvent:Connect(function(payload) clear(); if type(payload)=="table" then showRewardScreen(payload) end end)
	context.Remotes.BugEscaped.OnClientEvent:Connect(function(payload) if type(payload)=="table" and context.Controllers.Notification then context.Controllers.Notification.Show(string.format("%s escaped", payload.DisplayName or "Bug"), "Warning") end clear() end)
end
return BugMinigameController
