--!strict
local TweenService = game:GetService("TweenService")
local Window = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("Window"))

local EnemySpawnController = {}
local context
local activeEnemy
local enemyGui
local popup
local currentPopupEnemyId: string? = nil

local terminalWindow
local terminalLinesLayout
local terminalLinesFrame
local terminalSkipButton
local terminalCloseButton
local terminalStatusLabel
local terminalTopCenterLabel
local terminalTurnLabel
local terminalCenterPanel
local terminalPhaseLabel
local terminalActionLabel
local terminalDamageLabel
local terminalResultLabel
local terminalTeamPanel
local terminalEnemyPanel
local terminalUnitPanels = {}
local terminalUnitState = {}

local activeBattleResult
local playbackIndex = 0
local playbackSkipped = false
local terminalOpen = false
local playbackToken = 0
local awaitingResult = false
local playbackStartedAt = 0
local playbackFinished = false

local BOOT_LINE_DELAY = 0.4
local ACTION_LINE_DELAY = 0.85
local FINAL_RESULT_DELAY = 1.25
local MIN_TERMINAL_DISPLAY = 4
local MODAL_Z = 80
local REWARD_Z = 105

local function createOsWindow(title: string, size: UDim2, zIndex: number, onClose: (() -> ())?)
	local hud = context.UI.HUDLayer
	if not hud then return nil end
	local ref = Window.Create({
		Title = title,
		Icon = "⚔️",
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = hud,
		OnClose = onClose,
	})
	ref.Root.AnchorPoint = Vector2.new(0.5, 0.5)
	ref.Root.Position = UDim2.fromScale(0.5, 0.5)
	ref.SetZIndex(zIndex)
	local minimizeButton = ref.Root:FindFirstChild("MinimizeButton", true)
	if minimizeButton and minimizeButton:IsA("GuiButton") then
		minimizeButton.Visible = false
		minimizeButton.Active = false
	end
	ref.Content.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
	ref.Content.ClipsDescendants = false
	return ref
end

local function createInsetPanel(parent: Instance, pos: UDim2, size: UDim2, z: number, bg: Color3?): Frame
	local panel = Instance.new("Frame")
	panel.Position = pos
	panel.Size = size
	panel.BackgroundColor3 = bg or Color3.fromRGB(225, 225, 225)
	panel.BorderSizePixel = 2
	panel.BorderColor3 = Color3.fromRGB(96, 96, 96)
	panel.ZIndex = z
	panel.Parent = parent
	local inner = Instance.new("UIStroke")
	inner.Color = Color3.fromRGB(255, 255, 255)
	inner.Thickness = 1
	inner.Transparency = 0.2
	inner.Parent = panel
	return panel
end

local function createButton(parent: Instance, text: string, pos: UDim2, size: UDim2, z: number, accent: Color3?): TextButton
	local button = Instance.new("TextButton")
	button.Position = pos
	button.Size = size
	button.BackgroundColor3 = accent or Color3.fromRGB(192, 192, 192)
	button.BorderSizePixel = 2
	button.BorderColor3 = Color3.fromRGB(64, 64, 64)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(20, 20, 20)
	button.Font = Enum.Font.ArialBold
	button.TextSize = 14
	button.ZIndex = z
	button.Parent = parent
	return button
end

local function styleButton(button: TextButton, normal: Color3, hover: Color3, pressed: Color3, textColor: Color3?)
	button.BackgroundColor3 = normal
	button.TextColor3 = textColor or Color3.fromRGB(20, 20, 20)
	button.AutoButtonColor = false
	button.MouseEnter:Connect(function()
		if button.Active then button.BackgroundColor3 = hover end
	end)
	button.MouseLeave:Connect(function()
		if button.Active then button.BackgroundColor3 = normal end
	end)
	button.MouseButton1Down:Connect(function()
		if button.Active then button.BackgroundColor3 = pressed end
	end)
	button.MouseButton1Up:Connect(function()
		if button.Active then button.BackgroundColor3 = hover end
	end)
end

local function enemyTierLabel(tier: any): string
	local raw = tostring(tier or "CommonEnemy")
	local spaced = string.gsub(raw, "Enemy$", " Enemy")
	spaced = string.gsub(spaced, "(%l)(%u)", "%1 %2")
	return spaced
end

local function clearEnemy()
	if enemyGui then
		enemyGui:Destroy()
		enemyGui = nil
	end
end

local function closePopup()
	if popup then
		popup:Destroy()
		popup = nil
		currentPopupEnemyId = nil
	end
end

local function getCombatTeamCount(): number
	local playerData = context and context.State and context.State.PlayerData
	local combatSlots = playerData and playerData.Bugs and playerData.Bugs.CombatSlots
	if type(combatSlots) ~= "table" then return 0 end
	local count = 0
	for _, slot in pairs(combatSlots) do
		if slot ~= nil and slot ~= "" then count += 1 end
	end
	return count
end

local function friendlyFailure(reason: string): string
	if reason == "NoCombatTeam" then return "Equip bugs in Bugs.exe > Combat Team first." end
	if reason == "NoEnemy" then return "This enemy is no longer available." end
	if reason == "EnemyExpired" then return "This enemy escaped." end
	if reason == "InvalidPayload" then return "Attack failed. Try again." end
	return "Attack failed. Try again."
end

local function createTerminalLine(text: string, color: Color3?)
	if not terminalLinesFrame then return end
	local line = Instance.new("TextLabel")
	line.BackgroundTransparency = 1
	line.Size = UDim2.new(1, -8, 0, 22)
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.Text = text
	line.TextColor3 = color or Color3.fromRGB(80, 245, 180)
	line.Font = Enum.Font.Code
	line.TextSize = 15
	line.TextWrapped = false
	line.ZIndex = MODAL_Z + 20
	line.Parent = terminalLinesFrame
	task.defer(function()
		if terminalLinesFrame and terminalLinesLayout then
			local y = terminalLinesLayout.AbsoluteContentSize.Y
			terminalLinesFrame.CanvasSize = UDim2.fromOffset(0, y + 6)
			terminalLinesFrame.CanvasPosition = Vector2.new(0, math.max(0, y - terminalLinesFrame.AbsoluteSize.Y + 16))
		end
	end)
end

local function closeTerminal()
	terminalOpen = false
	if terminalWindow then terminalWindow.Destroy() end
	terminalWindow = nil
	terminalLinesLayout = nil
	terminalLinesFrame = nil
	terminalSkipButton = nil
	terminalCloseButton = nil
	terminalStatusLabel = nil
	terminalTopCenterLabel = nil
	terminalTurnLabel = nil
	terminalCenterPanel = nil
	terminalPhaseLabel = nil
	terminalActionLabel = nil
	terminalDamageLabel = nil
	terminalResultLabel = nil
	terminalTeamPanel = nil
	terminalEnemyPanel = nil
	terminalUnitPanels = {}
	terminalUnitState = {}
end

local function updateUnitPanel(name: string)
	local panel = terminalUnitPanels[name]
	local state = terminalUnitState[name]
	if not panel or not state then return end
	local hp = math.max(0, tonumber(state.CurrentHP) or 0)
	local maxHp = math.max(1, tonumber(state.MaxHP) or 1)
	panel.Status.Text = hp > 0 and string.format("HP %d/%d", hp, maxHp) or "DEFEATED"
	panel.Bar.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
	panel.Bar.BackgroundColor3 = hp > 0 and Color3.fromRGB(92, 220, 116) or Color3.fromRGB(156, 40, 40)
end

local function highlightUnit(name: string, color: Color3?)
	local panel = terminalUnitPanels[name]
	if not panel then return end
	local stroke = panel.Stroke
	stroke.Color = color or Color3.fromRGB(255, 230, 120)
	stroke.Thickness = 2
	TweenService:Create(stroke, TweenInfo.new(0.45), {Transparency = 0.1}):Play()
	task.delay(0.5, function()
		if stroke.Parent then
			TweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 0.7}):Play()
		end
	end)
end

local COMBAT_CARD_HEIGHT = 32
local COMBAT_CARD_GAP = 4

local function createCombatantCard(parent: Instance, unit, y: number)
	local name = tostring(unit.Name or unit.Id or "Unit")
	local card = Instance.new("Frame")
	card.Name = "CombatantCard"
	card.Size = UDim2.new(1, -12, 0, COMBAT_CARD_HEIGHT)
	card.Position = UDim2.fromOffset(6, y)
	card.BackgroundColor3 = Color3.fromRGB(18, 28, 32)
	card.BorderSizePixel = 1
	card.BorderColor3 = Color3.fromRGB(86, 118, 112)
	card.ZIndex = MODAL_Z + 18
	card.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(135, 255, 210)
	stroke.Transparency = 0.72
	stroke.Parent = card
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(24, 24)
	icon.Position = UDim2.fromOffset(5, 4)
	icon.BackgroundTransparency = 1
	icon.Image = tostring(unit.Icon or "")
	icon.ZIndex = MODAL_Z + 19
	icon.Parent = card
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -94, 0, 15)
	label.Position = UDim2.fromOffset(34, 3)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Font = Enum.Font.ArialBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(230, 250, 244)
	label.Text = name
	label.ZIndex = MODAL_Z + 19
	label.Parent = card
	local status = Instance.new("TextLabel")
	status.Size = UDim2.fromOffset(52, 15)
	status.Position = UDim2.new(1, -58, 0, 3)
	status.BackgroundTransparency = 1
	status.TextXAlignment = Enum.TextXAlignment.Right
	status.Font = Enum.Font.Code
	status.TextSize = 10
	status.TextColor3 = Color3.fromRGB(140, 255, 185)
	status.ZIndex = MODAL_Z + 19
	status.Parent = card
	local barBack = Instance.new("Frame")
	barBack.Size = UDim2.new(1, -40, 0, 6)
	barBack.Position = UDim2.fromOffset(34, 22)
	barBack.BackgroundColor3 = Color3.fromRGB(48, 56, 58)
	barBack.BorderSizePixel = 0
	barBack.ZIndex = MODAL_Z + 19
	barBack.Parent = card
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = Color3.fromRGB(92, 220, 116)
	bar.BorderSizePixel = 0
	bar.ZIndex = MODAL_Z + 20
	bar.Parent = barBack
	local maxHp = math.max(1, tonumber(unit.Stats and unit.Stats.HP) or tonumber(unit.CurrentHP) or 1)
	terminalUnitState[name] = {CurrentHP = maxHp, MaxHP = maxHp}
	terminalUnitPanels[name] = {Root = card, Status = status, Bar = bar, Stroke = stroke}
	updateUnitPanel(name)
end

local function populateCombatPanels(result)
	if not terminalTeamPanel or not terminalEnemyPanel then return end
	for _, child in ipairs(terminalTeamPanel:GetChildren()) do if child.Name == "CombatantCard" or child.Name == "WaitingTeamLabel" then child:Destroy() end end
	for _, child in ipairs(terminalEnemyPanel:GetChildren()) do if child.Name == "CombatantCard" then child:Destroy() end end
	terminalUnitPanels = {}
	terminalUnitState = {}
	local playerY = 34
	local enemyY = 34
	for _, unit in ipairs(result.FinalUnits or {}) do
		if unit.Team == "Player" then
			createCombatantCard(terminalTeamPanel, unit, playerY)
			playerY += COMBAT_CARD_HEIGHT + COMBAT_CARD_GAP
		elseif unit.Team == "Enemy" then
			createCombatantCard(terminalEnemyPanel, unit, enemyY)
			enemyY += COMBAT_CARD_HEIGHT + COMBAT_CARD_GAP
		end
	end
end

local function updateTopStatus(leftText: string?, centerText: string?, rightText: string?)
	if terminalStatusLabel and leftText then terminalStatusLabel.Text = leftText end
	if terminalTopCenterLabel and centerText then terminalTopCenterLabel.Text = centerText end
	if terminalTurnLabel and rightText then terminalTurnLabel.Text = rightText end
end

local function flashCenterPanel(color: Color3)
	if not terminalCenterPanel then return end
	local original = terminalCenterPanel.BackgroundColor3
	terminalCenterPanel.BackgroundColor3 = color
	TweenService:Create(terminalCenterPanel, TweenInfo.new(0.45), {BackgroundColor3 = original}):Play()
end

local function updateCenterStatus(phase: string, action: string?, damageText: string?, resultText: string?)
	if terminalPhaseLabel then terminalPhaseLabel.Text = phase end
	if terminalActionLabel then terminalActionLabel.Text = action or "Awaiting combat telemetry..." end
	if terminalDamageLabel then terminalDamageLabel.Text = damageText or "-- DMG" end
	if terminalResultLabel then terminalResultLabel.Text = resultText or "" end
end

local function applyEventState(logLine: string, event)
	local lowerLine = string.lower(logLine)
	local actor = event and event.ActorName
	local target = event and event.TargetName
	local damage = event and event.Damage
	local isCrit = event and event.IsCrit

	if not actor or not target or not damage then
		actor, target, damage = string.match(logLine, "^CRIT%! (.-) hits (.-) for (%d+) damage%.")
		isCrit = isCrit or actor ~= nil
		if not actor then actor, target, damage = string.match(logLine, "^(.-) hits (.-) for (%d+) damage%.") end
	end

	if actor and target and damage then
		local damageNumber = tonumber(damage) or 0
		local phase = isCrit and "Critical Hit" or "Attacking"
		local damageText = isCrit and string.format("CRIT %d DMG", damageNumber) or string.format("%d DMG", damageNumber)
		updateTopStatus("Simulating battle...", phase, nil)
		updateCenterStatus(phase, string.format("%s attacks %s", actor, target), damageText, nil)
		highlightUnit(tostring(actor), Color3.fromRGB(95, 255, 205))
		highlightUnit(tostring(target), Color3.fromRGB(255, 128, 70))
		local state = terminalUnitState[tostring(target)]
		if state then
			if event and event.TargetRemainingHP ~= nil then
				state.CurrentHP = math.max(0, tonumber(event.TargetRemainingHP) or 0)
				state.MaxHP = math.max(1, tonumber(event.TargetMaxHP) or tonumber(state.MaxHP) or 1)
			else
				state.CurrentHP = math.max(0, (tonumber(state.CurrentHP) or 0) - damageNumber)
			end
			updateUnitPanel(tostring(target))
		end
		return
	end

	local defeatedName = (event and event.Defeated and event.TargetName) or string.match(logLine, "^(.-) is defeated%.")
	if defeatedName or string.find(lowerLine, "defeated", 1, true) then
		defeatedName = defeatedName or "Unit"
		updateTopStatus("Simulating battle...", "Unit Defeated", nil)
		updateCenterStatus("Unit Defeated", "Defense grid collapsed", nil, tostring(defeatedName) .. " defeated")
		local state = terminalUnitState[tostring(defeatedName)]
		if state then state.CurrentHP = 0; updateUnitPanel(tostring(defeatedName)) end
		highlightUnit(tostring(defeatedName), Color3.fromRGB(255, 86, 86))
	end
end

local function createResultStat(parent: Instance, labelText: string, valueText: string, x: number)
	local card = createInsetPanel(parent, UDim2.fromOffset(x, 0), UDim2.fromOffset(148, 54), REWARD_Z + 14, Color3.fromRGB(224, 224, 224))
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 18)
	label.Position = UDim2.fromOffset(5, 5)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.ArialBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(42, 42, 42)
	label.Text = labelText
	label.ZIndex = REWARD_Z + 18
	label.Parent = card
	local value = Instance.new("TextLabel")
	value.Size = UDim2.new(1, -10, 0, 24)
	value.Position = UDim2.fromOffset(5, 24)
	value.BackgroundTransparency = 1
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Font = Enum.Font.ArialBold
	value.TextSize = 18
	value.TextColor3 = Color3.fromRGB(10, 10, 10)
	value.Text = valueText
	value.ZIndex = REWARD_Z + 18
	value.Parent = card
end

local function showFinalPopup(result)
	print("[EnemySpawnController] Final result popup", tostring(result and result.Winner))
	local windowRef = createOsWindow("Battle Results", UDim2.fromOffset(560, 500), REWARD_Z, nil)
	if not windowRef then return end
	local frame = windowRef.Content
	local winner = tostring(result.Winner or "Draw")
	local isVictory = winner == "Player"
	local isDefeat = winner == "Enemy"
	local resultText = isVictory and "VICTORY" or (isDefeat and "DEFEAT" or "DRAW")
	local accent = isVictory and Color3.fromRGB(100, 255, 160) or (isDefeat and Color3.fromRGB(255, 96, 96) or Color3.fromRGB(255, 196, 92))
	local rewards = (isVictory and result.Rewards) or {BugEssence = 0}
	local essence = tonumber(rewards and rewards.BugEssence) or 0

	local banner = createInsetPanel(frame, UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 64), REWARD_Z + 12, isVictory and Color3.fromRGB(5, 54, 32) or (isDefeat and Color3.fromRGB(58, 22, 22) or Color3.fromRGB(62, 42, 12)))
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 1, 0)
	title.Position = UDim2.fromOffset(12, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.ArialBold
	title.TextSize = 36
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Text = resultText
	title.TextColor3 = accent
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextStrokeTransparency = 0.25
	title.ZIndex = REWARD_Z + 18
	title.Parent = banner

	local enemyPanel = createInsetPanel(frame, UDim2.fromOffset(16, 88), UDim2.new(1, -32, 0, 86), REWARD_Z + 12, Color3.fromRGB(22, 34, 48))
	local enemyIcon = Instance.new("ImageLabel")
	enemyIcon.Size = UDim2.fromOffset(62, 62)
	enemyIcon.Position = UDim2.fromOffset(12, 12)
	enemyIcon.BackgroundTransparency = 1
	enemyIcon.Image = tostring(result.EnemyIcon or "")
	enemyIcon.ZIndex = REWARD_Z + 16
	enemyIcon.Parent = enemyPanel
	local enemyName = Instance.new("TextLabel")
	enemyName.Size = UDim2.new(1, -92, 0, 28)
	enemyName.Position = UDim2.fromOffset(88, 14)
	enemyName.BackgroundTransparency = 1
	enemyName.TextXAlignment = Enum.TextXAlignment.Left
	enemyName.TextTruncate = Enum.TextTruncate.AtEnd
	enemyName.Font = Enum.Font.ArialBold
	enemyName.TextSize = 21
	enemyName.TextColor3 = Color3.fromRGB(244, 248, 255)
	enemyName.Text = tostring(result.EnemyName or "Enemy")
	enemyName.ZIndex = REWARD_Z + 16
	enemyName.Parent = enemyPanel
	local detailRow = Instance.new("TextLabel")
	detailRow.Size = UDim2.new(1, -92, 0, 24)
	detailRow.Position = UDim2.fromOffset(88, 46)
	detailRow.BackgroundTransparency = 1
	detailRow.TextXAlignment = Enum.TextXAlignment.Left
	detailRow.Font = Enum.Font.Code
	detailRow.TextSize = 14
	detailRow.TextColor3 = Color3.fromRGB(130, 240, 200)
	detailRow.Text = isVictory and "Enemy defeated. Rewards granted." or "The enemy escaped after the battle."
	detailRow.ZIndex = REWARD_Z + 16
	detailRow.Parent = enemyPanel

	local statsRow = Instance.new("Frame")
	statsRow.Size = UDim2.new(1, -32, 0, 54)
	statsRow.Position = UDim2.fromOffset(16, 186)
	statsRow.BackgroundTransparency = 1
	statsRow.ZIndex = REWARD_Z + 12
	statsRow.Parent = frame
	createResultStat(statsRow, "Turns", tostring(result.Turns or "?"), 0)
	createResultStat(statsRow, "Player Remaining", tostring(result.PlayerRemaining or "?"), 188)
	createResultStat(statsRow, "Enemy Remaining", tostring(result.EnemyRemaining or "?"), 376)

	local rewardsPanel = createInsetPanel(frame, UDim2.fromOffset(16, 252), UDim2.new(1, -32, 0, 94), REWARD_Z + 12, isVictory and Color3.fromRGB(15, 58, 42) or Color3.fromRGB(48, 42, 42))
	local rewardHeader = Instance.new("TextLabel")
	rewardHeader.Size = UDim2.new(1, -24, 0, 24)
	rewardHeader.Position = UDim2.fromOffset(12, 9)
	rewardHeader.BackgroundTransparency = 1
	rewardHeader.TextXAlignment = Enum.TextXAlignment.Left
	rewardHeader.Font = Enum.Font.ArialBold
	rewardHeader.TextSize = 16
	rewardHeader.TextColor3 = Color3.fromRGB(236, 252, 244)
	rewardHeader.Text = "Rewards Earned"
	rewardHeader.ZIndex = REWARD_Z + 16
	rewardHeader.Parent = rewardsPanel
	local essenceLabel = Instance.new("TextLabel")
	essenceLabel.Size = UDim2.new(1, -24, 0, 44)
	essenceLabel.Position = UDim2.fromOffset(12, 36)
	essenceLabel.BackgroundTransparency = 1
	essenceLabel.Font = Enum.Font.ArialBold
	essenceLabel.TextSize = 32
	essenceLabel.TextXAlignment = Enum.TextXAlignment.Left
	essenceLabel.TextColor3 = isVictory and Color3.fromRGB(120, 255, 178) or Color3.fromRGB(255, 150, 150)
	essenceLabel.Text = "Bug Essence +0"
	essenceLabel.ZIndex = REWARD_Z + 16
	essenceLabel.Parent = rewardsPanel

	local equipmentPanel = createInsetPanel(frame, UDim2.fromOffset(16, 358), UDim2.new(1, -32, 0, 54), REWARD_Z + 12, Color3.fromRGB(214, 214, 214))
	local equipmentText = Instance.new("TextLabel")
	equipmentText.Size = UDim2.new(1, -24, 1, 0)
	equipmentText.Position = UDim2.fromOffset(12, 0)
	equipmentText.BackgroundTransparency = 1
	equipmentText.TextXAlignment = Enum.TextXAlignment.Left
	equipmentText.Font = Enum.Font.Arial
	equipmentText.TextSize = 15
	equipmentText.TextColor3 = Color3.fromRGB(55, 55, 55)
	equipmentText.Text = "Equipment Drops: None"
	equipmentText.ZIndex = REWARD_Z + 16
	equipmentText.Parent = equipmentPanel

	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, -40, 0, 24)
	message.Position = UDim2.fromOffset(20, 420)
	message.BackgroundTransparency = 1
	message.Font = Enum.Font.Arial
	message.TextSize = 15
	message.TextColor3 = Color3.fromRGB(38, 38, 38)
	message.Text = isVictory and "Bug Essence collected." or "No rewards were granted."
	message.ZIndex = REWARD_Z + 15
	message.Parent = frame
	local closeBtn = createButton(frame, isVictory and "Claim Essence" or "Close", UDim2.new(0.5, -98, 1, -44), UDim2.fromOffset(196, 34), REWARD_Z + 15, isVictory and Color3.fromRGB(40, 190, 92) or Color3.fromRGB(204, 204, 204))
	styleButton(closeBtn, closeBtn.BackgroundColor3, isVictory and Color3.fromRGB(54, 220, 110) or Color3.fromRGB(224, 224, 224), isVictory and Color3.fromRGB(28, 150, 70) or Color3.fromRGB(170, 170, 170), isVictory and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20))
	closeBtn.MouseButton1Click:Connect(function() windowRef.Destroy() end)
	if isVictory then
		TweenService:Create(rewardsPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(16, 248)}):Play()
		task.spawn(function()
			for i = 0, essence do
				if not essenceLabel.Parent then return end
				essenceLabel.Text = "Bug Essence +" .. tostring(i)
				task.wait(math.max(0.015, math.min(0.04, 0.5 / math.max(essence, 1))))
			end
		end)
		for i = 1, 14 do
			task.delay(i * 0.045, function()
				if not frame.Parent then return end
				local sparkle = Instance.new("Frame")
				sparkle.Size = UDim2.fromOffset(math.random(4, 9), math.random(4, 9))
				sparkle.Position = UDim2.new(0.5, math.random(-210, 210), 0, math.random(252, 340))
				sparkle.BorderSizePixel = 0
				sparkle.BackgroundColor3 = Color3.fromRGB(138, 255, 186)
				sparkle.ZIndex = REWARD_Z + 22
				sparkle.Parent = frame
				Instance.new("UICorner", sparkle).CornerRadius = UDim.new(1, 0)
				local startPos = sparkle.Position
				TweenService:Create(sparkle, TweenInfo.new(0.55), {BackgroundTransparency = 1, Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + math.random(-28, 28), startPos.Y.Scale, startPos.Y.Offset + math.random(-36, 8))}):Play()
				task.delay(0.6, function() if sparkle then sparkle:Destroy() end end)
			end)
		end
	else
		essenceLabel.Text = "Bug Essence +0"
	end
end

local function finishPlayback(result)
	if playbackFinished then return end
	playbackFinished = true
	local winner = tostring(result and result.Winner or "Draw")
	if winner == "Player" then
		flashCenterPanel(Color3.fromRGB(20, 92, 44))
	elseif winner == "Enemy" then
		flashCenterPanel(Color3.fromRGB(92, 22, 22))
	else
		flashCenterPanel(Color3.fromRGB(92, 72, 22))
	end
	task.wait(0.25)
	if terminalCloseButton then
		terminalCloseButton.Visible = true
		terminalCloseButton.Active = true
		terminalCloseButton.AutoButtonColor = true
	end
	closeTerminal()
	print("[EnemySpawnController] Playback complete", tostring(result and result.EnemyId))
	showFinalPopup(result)
end

local function startTerminalPlayback(result)
	if not terminalOpen or not terminalLinesFrame then return end
	print("[EnemySpawnController] Battle playback started", tostring(result.EnemyId), tostring(result.Winner))
	activeBattleResult = result
	playbackIndex = 0
	playbackSkipped = false
	playbackFinished = false
	playbackToken += 1
	local myToken = playbackToken
	playbackStartedAt = os.clock()
	populateCombatPanels(result)
	if terminalSkipButton then
		terminalSkipButton.Active = true
		terminalSkipButton.AutoButtonColor = true
		terminalSkipButton.Text = "Skip"
	end
	print("[EnemySpawnController] Playback line delay started", tostring(result.EnemyId))
	local logs = result.Log or {}
	local events = result.Events or {}
	flashCenterPanel(Color3.fromRGB(18, 58, 68))
	task.spawn(function()
		local bootLines = {
			"> COMBAT LINK ESTABLISHED",
			"> BUG.OS COMBAT SIM v1.0",
			"> Target: " .. tostring(result.EnemyName or "Enemy"),
			"> Combat Team deployed.",
			"> Running turn simulation...",
			"> --- COMBAT LOG ---",
		}
		updateTopStatus("Awaiting server result...", tostring(result.EnemyName or "Enemy"), "Action 0 / " .. tostring(#logs))
		updateCenterStatus("Initializing", "Combat link established", nil, nil)
		for _, bootLine in ipairs(bootLines) do
			if not terminalOpen or myToken ~= playbackToken then return end
			createTerminalLine(bootLine, Color3.fromRGB(104, 232, 255))
			if not playbackSkipped then task.wait(BOOT_LINE_DELAY) end
		end
		while terminalOpen and myToken == playbackToken and playbackIndex < #logs do
			if playbackSkipped then
				for i = playbackIndex + 1, #logs do
					local logLine = tostring(logs[i])
					applyEventState(logLine, events[i])
					local lowerLine = string.lower(logLine)
					local lineColor = Color3.fromRGB(80, 245, 140)
					local prefix = ""
					if string.find(lowerLine, "crit", 1, true) then lineColor = Color3.fromRGB(255, 242, 130); prefix = "!! "
					elseif string.find(lowerLine, "defeat", 1, true) or string.find(lowerLine, "defeated", 1, true) then lineColor = Color3.fromRGB(255, 132, 90) end
					createTerminalLine(string.format("[%02d] %s%s", i, prefix, logLine), lineColor)
				end
				playbackIndex = #logs
				break
			end
			playbackIndex += 1
			local event = events[playbackIndex]
			local turn = event and event.Turn or math.max(1, math.ceil(playbackIndex / 2))
			updateTopStatus("Simulating battle...", "Turn " .. tostring(turn), string.format("Action %d / %d", playbackIndex, #logs))
			local logLine = tostring(logs[playbackIndex])
			local lowerLine = string.lower(logLine)
			local lineColor = Color3.fromRGB(80, 245, 140)
			if string.find(lowerLine, "crit", 1, true) then lineColor = Color3.fromRGB(255, 242, 130)
			elseif string.find(lowerLine, "defeat", 1, true) or string.find(lowerLine, "defeated", 1, true) then lineColor = Color3.fromRGB(255, 132, 90) end
			local prefix = ""
			if string.find(lowerLine, "crit", 1, true) then prefix = "!! " end
			applyEventState(logLine, event)
			createTerminalLine(string.format("[%02d] %s%s", playbackIndex, prefix, logLine), lineColor)
			task.wait(ACTION_LINE_DELAY)
		end
		if not terminalOpen or myToken ~= playbackToken then return end
		createTerminalLine("> ---", Color3.fromRGB(104, 232, 255))
		local winner = string.lower(tostring(result.Winner or "Unknown"))
		local resultColor = Color3.fromRGB(255, 176, 120)
		if winner == "player" then resultColor = Color3.fromRGB(128, 255, 164) elseif winner == "enemy" then resultColor = Color3.fromRGB(255, 120, 120) end
		local resultWord = winner == "player" and "VICTORY" or (winner == "enemy" and "DEFEAT" or "DRAW")
		updateTopStatus("Battle complete", "Battle Complete", string.format("Action %d / %d", #logs, #logs))
		updateCenterStatus("Battle Complete", "Simulation resolved", nil, resultWord)
		createTerminalLine("> RESULT: " .. resultWord, resultColor)
		if not playbackSkipped then
			local elapsed = os.clock() - playbackStartedAt
			if elapsed < MIN_TERMINAL_DISPLAY then task.wait(MIN_TERMINAL_DISPLAY - elapsed) end
			task.wait(FINAL_RESULT_DELAY)
		end
		finishPlayback(result)
	end)
end

local function openTerminalWaiting(enemy)
	closeTerminal()
	local windowRef = createOsWindow("Combat Simulator", UDim2.fromOffset(720, 500), MODAL_Z, function() closeTerminal() end)
	if not windowRef then return end
	terminalOpen = true
	terminalWindow = windowRef
	local content = windowRef.Content
	local simPanel = createInsetPanel(content, UDim2.fromOffset(10, 10), UDim2.new(1, -20, 1, -20), MODAL_Z + 12, Color3.fromRGB(5, 10, 12))
	local infoBar = createInsetPanel(simPanel, UDim2.fromOffset(10, 10), UDim2.new(1, -20, 0, 42), MODAL_Z + 14, Color3.fromRGB(16, 36, 42))
	terminalStatusLabel = Instance.new("TextLabel")
	terminalStatusLabel.Size = UDim2.new(0, 220, 1, 0)
	terminalStatusLabel.Position = UDim2.fromOffset(10, 0)
	terminalStatusLabel.BackgroundTransparency = 1
	terminalStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	terminalStatusLabel.Font = Enum.Font.Code
	terminalStatusLabel.TextSize = 15
	terminalStatusLabel.TextColor3 = Color3.fromRGB(118, 255, 205)
	terminalStatusLabel.Text = "Awaiting server result..."
	terminalStatusLabel.ZIndex = MODAL_Z + 18
	terminalStatusLabel.Parent = infoBar
	terminalTopCenterLabel = Instance.new("TextLabel")
	terminalTopCenterLabel.Size = UDim2.new(1, -420, 1, 0)
	terminalTopCenterLabel.Position = UDim2.fromOffset(230, 0)
	terminalTopCenterLabel.BackgroundTransparency = 1
	terminalTopCenterLabel.TextXAlignment = Enum.TextXAlignment.Center
	terminalTopCenterLabel.Font = Enum.Font.Code
	terminalTopCenterLabel.TextSize = 15
	terminalTopCenterLabel.TextColor3 = Color3.fromRGB(255, 218, 112)
	terminalTopCenterLabel.Text = tostring(enemy.DisplayName or "Enemy")
	terminalTopCenterLabel.TextTruncate = Enum.TextTruncate.AtEnd
	terminalTopCenterLabel.ZIndex = MODAL_Z + 18
	terminalTopCenterLabel.Parent = infoBar
	terminalTurnLabel = Instance.new("TextLabel")
	terminalTurnLabel.Size = UDim2.fromOffset(160, 28)
	terminalTurnLabel.Position = UDim2.new(1, -170, 0.5, -14)
	terminalTurnLabel.BackgroundTransparency = 1
	terminalTurnLabel.Font = Enum.Font.Code
	terminalTurnLabel.TextSize = 15
	terminalTurnLabel.TextColor3 = Color3.fromRGB(155, 225, 255)
	terminalTurnLabel.Text = "Turn --"
	terminalTurnLabel.ZIndex = MODAL_Z + 18
	terminalTurnLabel.Parent = infoBar
	terminalTeamPanel = createInsetPanel(simPanel, UDim2.fromOffset(10, 62), UDim2.fromOffset(230, 220), MODAL_Z + 14, Color3.fromRGB(10, 20, 24))
	terminalEnemyPanel = createInsetPanel(simPanel, UDim2.new(1, -240, 0, 62), UDim2.fromOffset(230, 220), MODAL_Z + 14, Color3.fromRGB(24, 12, 14))
	for _, spec in ipairs({{terminalTeamPanel, "YOUR TEAM"}, {terminalEnemyPanel, "ENEMY"}}) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -12, 0, 26)
		label.Position = UDim2.fromOffset(6, 4)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.ArialBold
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Color3.fromRGB(228, 238, 232)
		label.Text = spec[2]
		label.ZIndex = MODAL_Z + 18
		label.Parent = spec[1]
	end
	createCombatantCard(terminalEnemyPanel, {Name = enemy.DisplayName, Icon = enemy.Icon, Stats = enemy.Stats}, 34)
	local waiting = Instance.new("TextLabel")
	waiting.Name = "WaitingTeamLabel"
	waiting.Size = UDim2.new(1, -12, 0, 70)
	waiting.Position = UDim2.fromOffset(6, 34)
	waiting.BackgroundColor3 = Color3.fromRGB(18, 28, 32)
	waiting.BorderSizePixel = 1
	waiting.BorderColor3 = Color3.fromRGB(86, 118, 112)
	waiting.Font = Enum.Font.Code
	waiting.TextSize = 13
	waiting.TextColor3 = Color3.fromRGB(130, 240, 200)
	waiting.TextWrapped = true
	waiting.Text = "Loading equipped combat bugs..."
	waiting.ZIndex = MODAL_Z + 18
	waiting.Parent = terminalTeamPanel
	terminalCenterPanel = createInsetPanel(simPanel, UDim2.fromOffset(250, 62), UDim2.new(1, -500, 0, 220), MODAL_Z + 14, Color3.fromRGB(12, 17, 24))
	local vsLabel = Instance.new("TextLabel")
	vsLabel.Size = UDim2.new(1, -20, 0, 40)
	vsLabel.Position = UDim2.fromOffset(10, 10)
	vsLabel.BackgroundTransparency = 1
	vsLabel.Font = Enum.Font.ArialBold
	vsLabel.TextSize = 31
	vsLabel.TextColor3 = Color3.fromRGB(255, 210, 92)
	vsLabel.Text = "VS"
	vsLabel.ZIndex = MODAL_Z + 18
	vsLabel.Parent = terminalCenterPanel
	terminalPhaseLabel = Instance.new("TextLabel")
	terminalPhaseLabel.Size = UDim2.new(1, -20, 0, 24)
	terminalPhaseLabel.Position = UDim2.fromOffset(10, 52)
	terminalPhaseLabel.BackgroundTransparency = 1
	terminalPhaseLabel.Font = Enum.Font.ArialBold
	terminalPhaseLabel.TextSize = 18
	terminalPhaseLabel.TextColor3 = Color3.fromRGB(104, 232, 255)
	terminalPhaseLabel.Text = "Initializing"
	terminalPhaseLabel.ZIndex = MODAL_Z + 18
	terminalPhaseLabel.Parent = terminalCenterPanel
	terminalActionLabel = Instance.new("TextLabel")
	terminalActionLabel.Size = UDim2.new(1, -20, 0, 54)
	terminalActionLabel.Position = UDim2.fromOffset(10, 84)
	terminalActionLabel.BackgroundTransparency = 1
	terminalActionLabel.Font = Enum.Font.Code
	terminalActionLabel.TextSize = 13
	terminalActionLabel.TextWrapped = true
	terminalActionLabel.TextColor3 = Color3.fromRGB(128, 245, 218)
	terminalActionLabel.Text = "Awaiting combat telemetry..."
	terminalActionLabel.ZIndex = MODAL_Z + 18
	terminalActionLabel.Parent = terminalCenterPanel
	terminalDamageLabel = Instance.new("TextLabel")
	terminalDamageLabel.Size = UDim2.new(1, -20, 0, 30)
	terminalDamageLabel.Position = UDim2.fromOffset(10, 142)
	terminalDamageLabel.BackgroundTransparency = 1
	terminalDamageLabel.Font = Enum.Font.ArialBold
	terminalDamageLabel.TextSize = 20
	terminalDamageLabel.TextColor3 = Color3.fromRGB(255, 238, 128)
	terminalDamageLabel.Text = "-- DMG"
	terminalDamageLabel.ZIndex = MODAL_Z + 18
	terminalDamageLabel.Parent = terminalCenterPanel
	terminalResultLabel = Instance.new("TextLabel")
	terminalResultLabel.Size = UDim2.new(1, -20, 0, 28)
	terminalResultLabel.Position = UDim2.fromOffset(10, 178)
	terminalResultLabel.BackgroundTransparency = 1
	terminalResultLabel.Font = Enum.Font.Code
	terminalResultLabel.TextSize = 13
	terminalResultLabel.TextColor3 = Color3.fromRGB(255, 146, 94)
	terminalResultLabel.Text = ""
	terminalResultLabel.ZIndex = MODAL_Z + 18
	terminalResultLabel.Parent = terminalCenterPanel
	local feedLabel = Instance.new("TextLabel")
	feedLabel.Size = UDim2.new(1, -20, 0, 20)
	feedLabel.Position = UDim2.fromOffset(10, 286)
	feedLabel.BackgroundTransparency = 1
	feedLabel.Font = Enum.Font.Code
	feedLabel.TextSize = 13
	feedLabel.TextXAlignment = Enum.TextXAlignment.Left
	feedLabel.TextColor3 = Color3.fromRGB(104, 232, 255)
	feedLabel.Text = "TERMINAL FEED"
	feedLabel.ZIndex = MODAL_Z + 18
	feedLabel.Parent = simPanel
	terminalLinesFrame = Instance.new("ScrollingFrame")
	terminalLinesFrame.Size = UDim2.new(1, -20, 1, -356)
	terminalLinesFrame.Position = UDim2.fromOffset(10, 312)
	terminalLinesFrame.BackgroundColor3 = Color3.fromRGB(1, 5, 4)
	terminalLinesFrame.BorderSizePixel = 1
	terminalLinesFrame.BorderColor3 = Color3.fromRGB(40, 115, 80)
	terminalLinesFrame.ScrollBarThickness = 6
	terminalLinesFrame.ZIndex = MODAL_Z + 16
	terminalLinesFrame.Parent = simPanel
	terminalLinesLayout = Instance.new("UIListLayout")
	terminalLinesLayout.Padding = UDim.new(0, 4)
	terminalLinesLayout.Parent = terminalLinesFrame
	terminalSkipButton = createButton(simPanel, "Waiting...", UDim2.fromOffset(10, 1), UDim2.fromOffset(110, 30), MODAL_Z + 18, Color3.fromRGB(156, 188, 168))
	terminalSkipButton.Position = UDim2.new(0, 10, 1, -38)
	terminalSkipButton.Active = false
	terminalSkipButton.AutoButtonColor = false
	terminalCloseButton = createButton(simPanel, "Close", UDim2.new(1, -120, 1, -38), UDim2.fromOffset(110, 30), MODAL_Z + 18, nil)
	terminalCloseButton.Visible = false
	terminalCloseButton.Active = false
	terminalCloseButton.AutoButtonColor = false
	terminalCloseButton.MouseButton1Click:Connect(function() closeTerminal() end)
	terminalSkipButton.MouseButton1Click:Connect(function()
		if not activeBattleResult then return end
		print("[EnemySpawnController] Battle playback skipped", tostring(activeBattleResult.EnemyId))
		playbackSkipped = true
	end)
	createTerminalLine("> Awaiting server result...", Color3.fromRGB(104, 232, 255))
end

local function createInfoRow(parent: Instance, labelText: string, valueText: string, x: number, y: number)
	local row = createInsetPanel(parent, UDim2.fromOffset(x, y), UDim2.fromOffset(134, 44), MODAL_Z + 15, Color3.fromRGB(232, 232, 232))
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 16)
	label.Position = UDim2.fromOffset(5, 4)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.ArialBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(40, 40, 40)
	label.Text = labelText
	label.ZIndex = MODAL_Z + 18
	label.Parent = row
	local value = Instance.new("TextLabel")
	value.Size = UDim2.new(1, -10, 0, 18)
	value.Position = UDim2.fromOffset(5, 21)
	value.BackgroundTransparency = 1
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextTruncate = Enum.TextTruncate.AtEnd
	value.Font = Enum.Font.Arial
	value.TextSize = 13
	value.TextColor3 = Color3.fromRGB(15, 15, 15)
	value.Text = valueText
	value.ZIndex = MODAL_Z + 18
	value.Parent = row
end

local function makePopup(enemy)
	closePopup()
	local windowRef = createOsWindow("Enemy Encounter", UDim2.fromOffset(470, 380), MODAL_Z, function() closePopup() end)
	if not windowRef then return end
	popup = windowRef.Root
	currentPopupEnemyId = enemy.EnemyId
	local content = windowRef.Content
	local topPanel = createInsetPanel(content, UDim2.fromOffset(12, 12), UDim2.new(1, -24, 0, 94), MODAL_Z + 12, Color3.fromRGB(230, 230, 230))
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(68, 68)
	icon.Position = UDim2.fromOffset(12, 12)
	icon.BackgroundTransparency = 1
	icon.Image = enemy.Icon or ""
	icon.ZIndex = MODAL_Z + 18
	icon.Parent = topPanel
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -96, 0, 30)
	name.Position = UDim2.fromOffset(92, 14)
	name.BackgroundTransparency = 1
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Font = Enum.Font.ArialBold
	name.TextSize = 21
	name.TextColor3 = Color3.fromRGB(20, 20, 20)
	name.Text = tostring(enemy.DisplayName)
	name.ZIndex = MODAL_Z + 18
	name.Parent = topPanel
	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -96, 0, 24)
	sub.Position = UDim2.fromOffset(92, 48)
	sub.BackgroundTransparency = 1
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Font = Enum.Font.ArialBold
	sub.TextSize = 15
	sub.TextColor3 = Color3.fromRGB(128, 38, 30)
	sub.Text = enemyTierLabel(enemy.Tier)
	sub.ZIndex = MODAL_Z + 18
	sub.Parent = topPanel
	createInfoRow(content, "Power", tostring(tonumber(enemy.Power) or 0), 12, 118)
	createInfoRow(content, "Species", tostring(enemy.Species), 158, 118)
	local rewardPanel = createInsetPanel(content, UDim2.fromOffset(12, 174), UDim2.new(1, -24, 0, 76), MODAL_Z + 12, Color3.fromRGB(22, 38, 32))
	local rewardTitle = Instance.new("TextLabel")
	rewardTitle.Size = UDim2.new(1, -18, 0, 22)
	rewardTitle.Position = UDim2.fromOffset(9, 8)
	rewardTitle.BackgroundTransparency = 1
	rewardTitle.TextXAlignment = Enum.TextXAlignment.Left
	rewardTitle.Font = Enum.Font.ArialBold
	rewardTitle.TextSize = 14
	rewardTitle.TextColor3 = Color3.fromRGB(232, 252, 238)
	rewardTitle.Text = "Possible Rewards"
	rewardTitle.ZIndex = MODAL_Z + 18
	rewardTitle.Parent = rewardPanel
	local rewardText = Instance.new("TextLabel")
	rewardText.Size = UDim2.new(1, -18, 0, 32)
	rewardText.Position = UDim2.fromOffset(9, 32)
	rewardText.BackgroundTransparency = 1
	rewardText.TextXAlignment = Enum.TextXAlignment.Left
	rewardText.Font = Enum.Font.ArialBold
	rewardText.TextSize = 22
	rewardText.TextColor3 = Color3.fromRGB(120, 255, 175)
	rewardText.Text = string.format("Bug Essence +%d", tonumber(enemy.RewardsPreview and enemy.RewardsPreview.BugEssence) or 0)
	rewardText.ZIndex = MODAL_Z + 18
	rewardText.Parent = rewardPanel
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -24, 0, 26)
	status.Position = UDim2.fromOffset(12, 258)
	status.BackgroundTransparency = 1
	status.Text = ""
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextColor3 = Color3.fromRGB(44, 44, 44)
	status.Font = Enum.Font.Arial
	status.TextSize = 14
	status.ZIndex = MODAL_Z + 18
	status.Parent = content
	local attack = createButton(content, "Attack", UDim2.fromOffset(12, 296), UDim2.fromOffset(170, 36), MODAL_Z + 18, Color3.fromRGB(196, 52, 30))
	styleButton(attack, Color3.fromRGB(196, 52, 30), Color3.fromRGB(226, 72, 38), Color3.fromRGB(150, 36, 24), Color3.fromRGB(255, 255, 255))
	local close = createButton(content, "Close", UDim2.new(1, -116, 0, 296), UDim2.fromOffset(104, 36), MODAL_Z + 18, Color3.fromRGB(210, 210, 210))
	styleButton(close, Color3.fromRGB(210, 210, 210), Color3.fromRGB(232, 232, 232), Color3.fromRGB(170, 170, 170), Color3.fromRGB(20, 20, 20))
	local hasTeam = getCombatTeamCount() > 0
	if hasTeam then
		attack.Active = true; attack.Text = "Attack"; status.Text = "Ready to simulate battle."
	else
		attack.Active = false; attack.Text = "No Combat Team"; attack.BackgroundColor3 = Color3.fromRGB(122, 82, 78); status.Text = "Equip bugs in Bugs.exe > Combat Team first."
	end
	close.MouseButton1Click:Connect(closePopup)
	attack.MouseButton1Click:Connect(function()
		if getCombatTeamCount() <= 0 then status.Text = "Equip bugs in Bugs.exe > Combat Team first."; return end
		print("[EnemySpawnController] Attack clicked", enemy.EnemyId)
		attack.Active = false; attack.Text = "Preparing..."; awaitingResult = true
		attack.BackgroundColor3 = Color3.fromRGB(122, 82, 78)
		print("[EnemySpawnController] Server attack request", enemy.EnemyId)
		context.Remotes.EnemyBugAttack:FireServer({ EnemyId = enemy.EnemyId })
		closePopup()
		openTerminalWaiting(enemy)
	end)
end

local function renderEnemy(enemy)
	clearEnemy()
	local world = context.UI.WorldLayer
	if not world then return end
	local root = Instance.new("ImageButton")
	root.Name = "EnemyBug_" .. enemy.EnemyId
	root.Size = UDim2.fromOffset(82, 82)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(enemy.Position.XScale, enemy.Position.YScale)
	root.BackgroundTransparency = 1
	root.Image = ""
	root.ClipsDescendants = false
	root.ZIndex = 4
	root.Parent = world
	local auraOuter = Instance.new("Frame")
	auraOuter.Size = UDim2.fromOffset(102, 102)
	auraOuter.AnchorPoint = Vector2.new(0.5, 0.5)
	auraOuter.Position = UDim2.fromScale(0.5, 0.48)
	auraOuter.BackgroundColor3 = Color3.fromRGB(120, 10, 10)
	auraOuter.BackgroundTransparency = 0.72
	auraOuter.ZIndex = 4
	auraOuter.Parent = root
	Instance.new("UICorner", auraOuter).CornerRadius = UDim.new(1, 0)
	local auraInner = Instance.new("Frame")
	auraInner.Size = UDim2.fromOffset(88, 88)
	auraInner.AnchorPoint = Vector2.new(0.5, 0.5)
	auraInner.Position = UDim2.fromScale(0.5, 0.48)
	auraInner.BackgroundColor3 = Color3.fromRGB(225, 24, 24)
	auraInner.BackgroundTransparency = 0.78
	auraInner.ZIndex = 5
	auraInner.Parent = root
	Instance.new("UICorner", auraInner).CornerRadius = UDim.new(1, 0)
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(76, 76)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.44)
	icon.BackgroundTransparency = 1
	icon.Image = enemy.Icon or ""
	icon.ZIndex = 6
	icon.Parent = root
	local nameplate = Instance.new("TextLabel")
	nameplate.Size = UDim2.fromOffset(176, 24)
	nameplate.AnchorPoint = Vector2.new(0.5, 0)
	nameplate.Position = UDim2.new(0.5, 0, 1, 2)
	nameplate.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	nameplate.TextColor3 = Color3.fromRGB(255, 72, 72)
	nameplate.Font = Enum.Font.GothamBold
	nameplate.TextSize = 13
	nameplate.Text = enemy.DisplayName
	nameplate.TextTruncate = Enum.TextTruncate.AtEnd
	nameplate.ZIndex = 7
	nameplate.Parent = root
	Instance.new("UICorner", nameplate).CornerRadius = UDim.new(1, 0)
	TweenService:Create(auraOuter, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.82 }):Play()
	TweenService:Create(auraInner, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.88 }):Play()
	root.MouseButton1Click:Connect(function() makePopup(enemy) end)
	enemyGui = root
end

function EnemySpawnController.Init(c) context = c end

function EnemySpawnController.Start()
	context.Remotes.EnemyBugSpawned.OnClientEvent:Connect(function(enemy)
		activeEnemy = enemy
		renderEnemy(enemy)
	end)
	context.Remotes.EnemyBugDespawned.OnClientEvent:Connect(function(payload)
		if not activeEnemy or not payload or payload.EnemyId ~= activeEnemy.EnemyId then return end
		activeEnemy = nil
		clearEnemy()
		if popup and currentPopupEnemyId == payload.EnemyId then closePopup() end
		if payload.Reason == "Expired" then
			if terminalOpen and awaitingResult then createTerminalLine("> Enemy escaped before battle completed.") end
		end
	end)
	context.Remotes.EnemyBugAttackResult.OnClientEvent:Connect(function(result)
		print("[EnemySpawnController] Client attack result", tostring(result and result.Success), tostring(result and result.Winner), tostring(result and result.Reason))
		awaitingResult = false
		if not result then return end
		if terminalOpen then
			if result.Success == false then
				createTerminalLine("> " .. friendlyFailure(tostring(result.Reason)), Color3.fromRGB(255, 132, 90))
				task.delay(0.8, closeTerminal)
				return
			end
			startTerminalPlayback(result)
		end
	end)
end

return EnemySpawnController
