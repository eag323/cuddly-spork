--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Window = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("Window"))
local EquipmentConfig = require(
	ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("EquipmentConfig")
)

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
local terminalCenterDetailLabel
local terminalMomentumLabel
local terminalTeamHpLabel
local terminalEnemyHpLabel
local terminalMomentumPlayerFill
local terminalMomentumEnemyFill
local terminalEventBadgeLabel
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
	terminalCenterDetailLabel = nil
	terminalMomentumLabel = nil
	terminalTeamHpLabel = nil
	terminalEnemyHpLabel = nil
	terminalMomentumPlayerFill = nil
	terminalMomentumEnemyFill = nil
	terminalEventBadgeLabel = nil
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
	local team = unit.Team and tostring(unit.Team) or nil
	terminalUnitState[name] = {CurrentHP = maxHp, MaxHP = maxHp, Team = team}
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

local function getTeamHpTotals(teamName: string): (number, number)
	local currentHp = 0
	local maxHp = 0
	for _, state in pairs(terminalUnitState) do
		if state.Team == teamName then
			currentHp += math.max(0, tonumber(state.CurrentHP) or 0)
			maxHp += math.max(0, tonumber(state.MaxHP) or 0)
		end
	end
	return currentHp, maxHp
end

local function updateMomentumMeter()
	local playerCurrentHp, playerMaxHp = getTeamHpTotals("Player")
	local enemyCurrentHp, enemyMaxHp = getTeamHpTotals("Enemy")
	local playerHpPct = playerMaxHp > 0 and (playerCurrentHp / playerMaxHp) or 0
	local enemyHpPct = enemyMaxHp > 0 and (enemyCurrentHp / enemyMaxHp) or 0
	local totalPct = playerHpPct + enemyHpPct
	local playerShare = totalPct > 0 and (playerHpPct / totalPct) or 0.5
	playerShare = math.clamp(playerShare, 0, 1)

	if terminalMomentumLabel then
		if playerHpPct > enemyHpPct + 0.10 then
			terminalMomentumLabel.Text = "Your Team Advantage"
			terminalMomentumLabel.TextColor3 = Color3.fromRGB(128, 255, 188)
		elseif enemyHpPct > playerHpPct + 0.10 then
			terminalMomentumLabel.Text = "Enemy Advantage"
			terminalMomentumLabel.TextColor3 = Color3.fromRGB(255, 146, 94)
		else
			terminalMomentumLabel.Text = "Even Match"
			terminalMomentumLabel.TextColor3 = Color3.fromRGB(255, 218, 112)
		end
	end
	if terminalTeamHpLabel then terminalTeamHpLabel.Text = string.format("Team HP: %d / %d", playerCurrentHp, playerMaxHp) end
	if terminalEnemyHpLabel then terminalEnemyHpLabel.Text = string.format("Enemy HP: %d / %d", enemyCurrentHp, enemyMaxHp) end
	if terminalMomentumPlayerFill then terminalMomentumPlayerFill.Size = UDim2.new(playerShare, 0, 1, 0) end
	if terminalMomentumEnemyFill then terminalMomentumEnemyFill.Size = UDim2.new(1 - playerShare, 0, 1, 0) end
end

local function updateCenterStatus(phase: string, detailText: string?, badgeText: string?)
	if terminalPhaseLabel then terminalPhaseLabel.Text = string.upper(phase) end
	if terminalCenterDetailLabel then terminalCenterDetailLabel.Text = detailText or "Combat link established" end
	if terminalEventBadgeLabel then
		terminalEventBadgeLabel.Text = badgeText or ""
		terminalEventBadgeLabel.Visible = badgeText ~= nil and badgeText ~= ""
		if badgeText == "CRIT" then
			terminalEventBadgeLabel.TextColor3 = Color3.fromRGB(255, 242, 130)
			terminalEventBadgeLabel.BorderColor3 = Color3.fromRGB(255, 242, 130)
		elseif badgeText == "KO" or badgeText == "DEFEAT" then
			terminalEventBadgeLabel.TextColor3 = Color3.fromRGB(255, 132, 90)
			terminalEventBadgeLabel.BorderColor3 = Color3.fromRGB(255, 132, 90)
		elseif badgeText == "VICTORY" then
			terminalEventBadgeLabel.TextColor3 = Color3.fromRGB(128, 255, 164)
			terminalEventBadgeLabel.BorderColor3 = Color3.fromRGB(128, 255, 164)
		else
			terminalEventBadgeLabel.TextColor3 = Color3.fromRGB(128, 245, 218)
			terminalEventBadgeLabel.BorderColor3 = Color3.fromRGB(104, 232, 255)
		end
	end
	updateMomentumMeter()
end

local function applyFinalUnitHealth(result)
	for _, unit in ipairs(result.FinalUnits or {}) do
		local name = tostring(unit.Name or unit.Id or "Unit")
		local state = terminalUnitState[name]
		if state then
			state.CurrentHP = math.max(0, tonumber(unit.CurrentHP) or 0)
			state.MaxHP = math.max(1, tonumber(unit.Stats and unit.Stats.HP) or tonumber(state.MaxHP) or 1)
			state.Team = unit.Team and tostring(unit.Team) or state.Team
			updateUnitPanel(name)
		end
	end
	updateMomentumMeter()
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
		local badgeText = isCrit and "CRIT" or "HIT"
		updateTopStatus("Simulating battle...", nil, nil)
		updateCenterStatus("SIMULATING", "Tactical telemetry updating", badgeText)
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
		updateMomentumMeter()
		return
	end

	local defeatedName = (event and event.Defeated and event.TargetName) or string.match(logLine, "^(.-) is defeated%.")
	if defeatedName or string.find(lowerLine, "defeated", 1, true) then
		defeatedName = defeatedName or "Unit"
		updateTopStatus("Simulating battle...", nil, nil)
		updateCenterStatus("SIMULATING", "Unit count changed", "KO")
		local state = terminalUnitState[tostring(defeatedName)]
		if state then state.CurrentHP = 0; updateUnitPanel(tostring(defeatedName)) end
		updateMomentumMeter()
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


local EQUIPMENT_ICONS_READY = false

local function getEquipmentDisplayName(item: any): string
	if type(item) ~= "table" then return "Equipment" end
	local setName = tostring(item.SetName or "Bug")
	local slot = tostring(item.Slot or "Equipment")
	return setName .. " " .. slot
end

local function getEquipmentRarityColor(rarity: any): Color3
	return EquipmentConfig.GetRarityColor(tostring(rarity or "Common"))
end

local function getEquipmentPlaceholderVisual(slot: any): { PlaceholderSymbol: string, PlaceholderLabel: string }
	return EquipmentConfig.GetPlaceholderVisual(tostring(slot or "Equipment"))
end

local function shouldRenderEquipmentIcon(item: any): boolean
	if not EQUIPMENT_ICONS_READY or type(item) ~= "table" then
		return false
	end
	local iconAsset = tostring(item.Icon or "")
	return iconAsset ~= ""
end

local function formatStatLine(statEntry: any): string
	if type(statEntry) ~= "table" then return "—" end
	local stat = tostring(statEntry.Stat or "Stat")
	local value = tonumber(statEntry.Value) or 0
	return string.format("%s +%s", stat, tostring(value))
end

local function formatStars(stars: any): string
	local starCount = math.max(1, math.min(6, tonumber(stars) or 1))
	return tostring(starCount) .. "★"
end

local function formatSubStats(subStats: any): string
	if type(subStats) ~= "table" or #subStats == 0 then
		return "Sub stats: None"
	end
	local parts = {}
	for index, statEntry in ipairs(subStats) do
		if index > 2 then break end
		table.insert(parts, formatStatLine(statEntry))
	end
	return "Sub stats: " .. table.concat(parts, "  •  ")
end

local function renderEquipmentSlotVisual(parent: Instance, item: any, pos: UDim2, size: UDim2, z: number, rarityColor: Color3)
	local slotVisual = createInsetPanel(parent, pos, size, z, Color3.fromRGB(10, 12, 18))
	slotVisual.BorderColor3 = rarityColor
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarityColor
	stroke.Thickness = 3
	stroke.Transparency = 0.04
	stroke.Parent = slotVisual

	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(1, -14, 1, -14)
	glow.Position = UDim2.fromOffset(7, 7)
	glow.BackgroundColor3 = rarityColor
	glow.BackgroundTransparency = 0.88
	glow.BorderSizePixel = 0
	glow.ZIndex = z + 1
	glow.Parent = slotVisual

	local inset = Instance.new("Frame")
	inset.Size = UDim2.new(1, -22, 1, -22)
	inset.Position = UDim2.fromOffset(11, 11)
	inset.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
	inset.BorderSizePixel = 1
	inset.BorderColor3 = Color3.fromRGB(0, 0, 0)
	inset.ZIndex = z + 2
	inset.Parent = slotVisual

	if shouldRenderEquipmentIcon(item) then
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(1, -18, 1, -18)
		icon.Position = UDim2.fromOffset(9, 9)
		icon.BackgroundTransparency = 1
		icon.Image = tostring(item.Icon or "")
		icon.ZIndex = z + 4
		icon.Parent = slotVisual
		return slotVisual
	end

	local placeholder = getEquipmentPlaceholderVisual(item and item.Slot)
	local symbol = tostring(placeholder.PlaceholderSymbol or "")
	local labelText = tostring(placeholder.PlaceholderLabel or item.Slot or "Gear")
	if symbol == "" then
		symbol = string.upper(string.sub(labelText, 1, 5))
	end

	local symbolLabel = Instance.new("TextLabel")
	symbolLabel.Size = UDim2.new(1, -14, 0, 56)
	symbolLabel.Position = UDim2.fromOffset(7, 20)
	symbolLabel.BackgroundTransparency = 1
	symbolLabel.Font = Enum.Font.ArialBold
	symbolLabel.TextSize = #symbol > 4 and 19 or 24
	symbolLabel.TextColor3 = rarityColor
	symbolLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	symbolLabel.TextStrokeTransparency = 0.25
	symbolLabel.Text = symbol
	symbolLabel.ZIndex = z + 4
	symbolLabel.Parent = slotVisual

	local slotLabel = Instance.new("TextLabel")
	slotLabel.Size = UDim2.new(1, -12, 0, 18)
	slotLabel.Position = UDim2.new(0, 6, 1, -26)
	slotLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	slotLabel.BackgroundTransparency = 0.25
	slotLabel.BorderSizePixel = 0
	slotLabel.Font = Enum.Font.ArialBold
	slotLabel.TextSize = 11
	slotLabel.TextColor3 = Color3.fromRGB(232, 238, 248)
	slotLabel.TextTruncate = Enum.TextTruncate.AtEnd
	slotLabel.Text = labelText
	slotLabel.ZIndex = z + 5
	slotLabel.Parent = slotVisual

	local cornerTag = Instance.new("TextLabel")
	cornerTag.Size = UDim2.fromOffset(34, 16)
	cornerTag.Position = UDim2.new(1, -40, 0, 6)
	cornerTag.BackgroundColor3 = rarityColor
	cornerTag.BorderSizePixel = 1
	cornerTag.BorderColor3 = Color3.fromRGB(255, 255, 255)
	cornerTag.Font = Enum.Font.ArialBold
	cornerTag.TextSize = 9
	cornerTag.TextColor3 = Color3.fromRGB(12, 12, 14)
	cornerTag.Text = string.upper(string.sub(labelText, 1, 4))
	cornerTag.ZIndex = z + 6
	cornerTag.Parent = slotVisual
	return slotVisual
end

local function createEquipmentDropCard(parent: Instance, item: any, pos: UDim2, size: UDim2, z: number): Frame
	local rarity = tostring(item.Rarity or "Common")
	local rarityColor = getEquipmentRarityColor(rarity)
	local card = createInsetPanel(parent, pos, size, z, Color3.fromRGB(28, 29, 38))
	card.BorderColor3 = rarityColor
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarityColor
	stroke.Thickness = rarity == "Common" and 2 or 3
	stroke.Transparency = rarity == "Common" and 0.16 or 0
	stroke.Parent = card

	local accentStrip = Instance.new("Frame")
	accentStrip.Size = UDim2.new(1, -8, 0, 5)
	accentStrip.Position = UDim2.fromOffset(4, 4)
	accentStrip.BackgroundColor3 = rarityColor
	accentStrip.BackgroundTransparency = rarity == "Common" and 0.35 or 0.1
	accentStrip.BorderSizePixel = 0
	accentStrip.ZIndex = z + 2
	accentStrip.Parent = card

	renderEquipmentSlotVisual(card, item, UDim2.fromOffset(16, 26), UDim2.fromOffset(104, 104), z + 3, rarityColor)

	local sectionLabel = Instance.new("TextLabel")
	sectionLabel.Size = UDim2.new(1, -34, 0, 18)
	sectionLabel.Position = UDim2.fromOffset(16, 8)
	sectionLabel.BackgroundTransparency = 1
	sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	sectionLabel.Font = Enum.Font.ArialBold
	sectionLabel.TextSize = 12
	sectionLabel.TextColor3 = Color3.fromRGB(240, 246, 255)
	sectionLabel.Text = "EQUIPMENT DROP!"
	sectionLabel.ZIndex = z + 5
	sectionLabel.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -246, 0, 28)
	nameLabel.Position = UDim2.fromOffset(136, 26)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Font = Enum.Font.ArialBold
	nameLabel.TextSize = 20
	nameLabel.TextColor3 = rarity == "Common" and Color3.fromRGB(246, 246, 246) or rarityColor
	nameLabel.Text = getEquipmentDisplayName(item)
	nameLabel.ZIndex = z + 5
	nameLabel.Parent = card

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(88, 24)
	badge.Position = UDim2.new(1, -104, 0, 28)
	badge.BackgroundColor3 = rarityColor
	badge.BorderSizePixel = 1
	badge.BorderColor3 = Color3.fromRGB(255, 255, 255)
	badge.Font = Enum.Font.ArialBold
	badge.TextSize = 12
	badge.TextColor3 = Color3.fromRGB(12, 12, 14)
	badge.TextTruncate = Enum.TextTruncate.AtEnd
	badge.Text = rarity
	badge.ZIndex = z + 6
	badge.Parent = card

	local starsBadge = Instance.new("TextLabel")
	starsBadge.Size = UDim2.fromOffset(54, 22)
	starsBadge.Position = UDim2.fromOffset(136, 56)
	starsBadge.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
	starsBadge.BorderSizePixel = 1
	starsBadge.BorderColor3 = rarityColor
	starsBadge.Font = Enum.Font.ArialBold
	starsBadge.TextSize = 13
	starsBadge.TextColor3 = Color3.fromRGB(255, 232, 120)
	starsBadge.Text = formatStars(item.Stars)
	starsBadge.ZIndex = z + 6
	starsBadge.Parent = card

	local slotSetLabel = Instance.new("TextLabel")
	slotSetLabel.Size = UDim2.new(1, -212, 0, 20)
	slotSetLabel.Position = UDim2.fromOffset(198, 57)
	slotSetLabel.BackgroundTransparency = 1
	slotSetLabel.TextXAlignment = Enum.TextXAlignment.Left
	slotSetLabel.TextTruncate = Enum.TextTruncate.AtEnd
	slotSetLabel.Font = Enum.Font.Code
	slotSetLabel.TextSize = 12
	slotSetLabel.TextColor3 = Color3.fromRGB(220, 224, 232)
	slotSetLabel.Text = string.format("%s slot • %s set", tostring(item.Slot or "Slot"), tostring(item.SetName or "Bug"))
	slotSetLabel.ZIndex = z + 5
	slotSetLabel.Parent = card

	local mainStatLabel = Instance.new("TextLabel")
	mainStatLabel.Size = UDim2.new(1, -154, 0, 20)
	mainStatLabel.Position = UDim2.fromOffset(136, 82)
	mainStatLabel.BackgroundTransparency = 1
	mainStatLabel.TextXAlignment = Enum.TextXAlignment.Left
	mainStatLabel.TextTruncate = Enum.TextTruncate.AtEnd
	mainStatLabel.Font = Enum.Font.ArialBold
	mainStatLabel.TextSize = 14
	mainStatLabel.TextColor3 = Color3.fromRGB(255, 244, 188)
	mainStatLabel.Text = "Main: " .. formatStatLine(item.MainStat)
	mainStatLabel.ZIndex = z + 5
	mainStatLabel.Parent = card

	local subStatLabel = Instance.new("TextLabel")
	subStatLabel.Size = UDim2.new(1, -154, 0, 20)
	subStatLabel.Position = UDim2.fromOffset(136, 104)
	subStatLabel.BackgroundTransparency = 1
	subStatLabel.TextXAlignment = Enum.TextXAlignment.Left
	subStatLabel.TextTruncate = Enum.TextTruncate.AtEnd
	subStatLabel.Font = Enum.Font.Code
	subStatLabel.TextSize = 12
	subStatLabel.TextColor3 = Color3.fromRGB(190, 230, 255)
	subStatLabel.Text = formatSubStats(item.SubStats)
	subStatLabel.ZIndex = z + 5
	subStatLabel.Parent = card

	local addedLabel = Instance.new("TextLabel")
	addedLabel.Size = UDim2.fromOffset(126, 22)
	addedLabel.Position = UDim2.new(1, -142, 1, -34)
	addedLabel.BackgroundColor3 = Color3.fromRGB(16, 76, 48)
	addedLabel.BorderSizePixel = 1
	addedLabel.BorderColor3 = Color3.fromRGB(120, 255, 178)
	addedLabel.Font = Enum.Font.ArialBold
	addedLabel.TextSize = 12
	addedLabel.TextColor3 = Color3.fromRGB(150, 255, 190)
	addedLabel.Text = "Added to inventory."
	addedLabel.ZIndex = z + 6
	addedLabel.Parent = card

	if rarity ~= "Common" then
		TweenService:Create(stroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true), {Transparency = 0.18}):Play()
	end

	return card
end

local function createEssenceRewardChip(parent: Instance, pos: UDim2, size: UDim2, z: number, essence: number, isVictory: boolean, isPrimary: boolean): (Frame, TextLabel)
	local chip = createInsetPanel(parent, pos, size, z, isPrimary and Color3.fromRGB(8, 86, 64) or Color3.fromRGB(10, 72, 60))
	chip.BorderColor3 = Color3.fromRGB(90, 235, 210)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.64, -12, 1, 0)
	label.Position = UDim2.fromOffset(10, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.ArialBold
	label.TextSize = isPrimary and 18 or 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(196, 255, 246)
	label.Text = "Bug Essence"
	label.ZIndex = z + 3
	label.Parent = chip
	local value = Instance.new("TextLabel")
	value.Size = UDim2.new(0.36, -12, 1, 0)
	value.Position = UDim2.new(0.64, 2, 0, 0)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.ArialBold
	value.TextSize = isPrimary and 28 or 20
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.TextColor3 = isVictory and Color3.fromRGB(120, 255, 178) or Color3.fromRGB(255, 150, 150)
	value.Text = "+" .. tostring(essence)
	value.ZIndex = z + 3
	value.Parent = chip
	return chip, value
end

local function createNoEquipmentCard(parent: Instance, pos: UDim2, size: UDim2, z: number, isVictory: boolean): Frame
	local card = createInsetPanel(parent, pos, size, z, isVictory and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(206, 198, 190))
	local equipmentText = Instance.new("TextLabel")
	equipmentText.Size = UDim2.new(1, -20, 1, 0)
	equipmentText.Position = UDim2.fromOffset(10, 0)
	equipmentText.BackgroundTransparency = 1
	equipmentText.TextXAlignment = Enum.TextXAlignment.Left
	equipmentText.Font = Enum.Font.ArialBold
	equipmentText.TextSize = 14
	equipmentText.TextColor3 = Color3.fromRGB(55, 55, 55)
	equipmentText.Text = "Equipment Drop: None"
	equipmentText.ZIndex = z + 3
	equipmentText.Parent = card
	return card
end

local function showFinalPopup(result)
	print("[EnemySpawnController] Final result popup", tostring(result and result.Winner))
	local windowRef = createOsWindow("Battle Results", UDim2.fromOffset(560, 462), REWARD_Z, nil)
	if not windowRef then return end
	local frame = windowRef.Content
	local winner = tostring(result.Winner or "Draw")
	local isVictory = winner == "Player"
	local isDefeat = winner == "Enemy"
	local resultText = isVictory and "VICTORY" or (isDefeat and "DEFEAT" or "DRAW")
	local accent = isVictory and Color3.fromRGB(100, 255, 160) or (isDefeat and Color3.fromRGB(255, 96, 96) or Color3.fromRGB(255, 196, 92))
	local rewards = (isVictory and result.Rewards) or {BugEssence = 0}
	local essence = tonumber(rewards and rewards.BugEssence) or 0
	local droppedEquipment = (isVictory and type(rewards) == "table") and rewards.Equipment or nil
	if type(droppedEquipment) == "table" then
		print(
			"[EnemySpawnController] Showing equipment drop",
			getEquipmentDisplayName(droppedEquipment),
			tostring(droppedEquipment.Rarity or "Common"),
			tostring(droppedEquipment.Stars or 1)
		)
	else
		print("[EnemySpawnController] No equipment drop in result")
	end

	local bannerBg = isVictory and Color3.fromRGB(5, 54, 32) or (isDefeat and Color3.fromRGB(58, 22, 22) or Color3.fromRGB(62, 42, 12))
	local banner = createInsetPanel(frame, UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 44), REWARD_Z + 12, bannerBg)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 28)
	title.Position = UDim2.fromOffset(12, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.ArialBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Text = resultText
	title.TextColor3 = accent
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextStrokeTransparency = 0.35
	title.ZIndex = REWARD_Z + 18
	title.Parent = banner
	local enemyLine = Instance.new("TextLabel")
	enemyLine.Size = UDim2.new(1, -24, 0, 15)
	enemyLine.Position = UDim2.fromOffset(12, 27)
	enemyLine.BackgroundTransparency = 1
	enemyLine.Font = Enum.Font.Code
	enemyLine.TextSize = 11
	enemyLine.TextXAlignment = Enum.TextXAlignment.Center
	enemyLine.TextTruncate = Enum.TextTruncate.AtEnd
	enemyLine.TextColor3 = Color3.fromRGB(235, 238, 242)
	enemyLine.Text = tostring(result.EnemyName or "Enemy")
	enemyLine.ZIndex = REWARD_Z + 18
	enemyLine.Parent = banner

	local summaryPanel = createInsetPanel(frame, UDim2.fromOffset(14, 60), UDim2.new(1, -28, 0, 78), REWARD_Z + 12, Color3.fromRGB(22, 34, 48))
	local enemyIcon = Instance.new("ImageLabel")
	enemyIcon.Size = UDim2.fromOffset(48, 48)
	enemyIcon.Position = UDim2.fromOffset(12, 15)
	enemyIcon.BackgroundTransparency = 1
	enemyIcon.Image = tostring(result.EnemyIcon or "")
	enemyIcon.ZIndex = REWARD_Z + 16
	enemyIcon.Parent = summaryPanel
	local enemyName = Instance.new("TextLabel")
	enemyName.Size = UDim2.new(0.39, -72, 0, 24)
	enemyName.Position = UDim2.fromOffset(72, 14)
	enemyName.BackgroundTransparency = 1
	enemyName.TextXAlignment = Enum.TextXAlignment.Left
	enemyName.TextTruncate = Enum.TextTruncate.AtEnd
	enemyName.Font = Enum.Font.ArialBold
	enemyName.TextSize = 17
	enemyName.TextColor3 = Color3.fromRGB(244, 248, 255)
	enemyName.Text = tostring(result.EnemyName or "Enemy")
	enemyName.ZIndex = REWARD_Z + 16
	enemyName.Parent = summaryPanel
	local detailRow = Instance.new("TextLabel")
	detailRow.Size = UDim2.new(0.39, -72, 0, 20)
	detailRow.Position = UDim2.fromOffset(72, 39)
	detailRow.BackgroundTransparency = 1
	detailRow.TextXAlignment = Enum.TextXAlignment.Left
	detailRow.TextTruncate = Enum.TextTruncate.AtEnd
	detailRow.Font = Enum.Font.Code
	detailRow.TextSize = 12
	detailRow.TextColor3 = isVictory and Color3.fromRGB(130, 240, 200) or Color3.fromRGB(230, 210, 180)
	detailRow.Text = isVictory and "Rewards granted." or "The enemy escaped."
	detailRow.ZIndex = REWARD_Z + 16
	detailRow.Parent = summaryPanel

	local statsPanel = Instance.new("Frame")
	statsPanel.Size = UDim2.new(0.61, -16, 1, -24)
	statsPanel.Position = UDim2.new(0.39, 4, 0, 12)
	statsPanel.BackgroundTransparency = 1
	statsPanel.ZIndex = REWARD_Z + 14
	statsPanel.Parent = summaryPanel
	local statNames = {"Turns", "Player", "Enemy"}
	local statValues = {tostring(result.Turns or "?"), tostring(result.PlayerRemaining or "?"), tostring(result.EnemyRemaining or "?")}
	for index, statName in ipairs(statNames) do
		local statWidth = 98
		local stat = createInsetPanel(statsPanel, UDim2.fromOffset((index - 1) * (statWidth + 8), 0), UDim2.fromOffset(statWidth, 54), REWARD_Z + 15, Color3.fromRGB(224, 224, 224))
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -8, 0, 18)
		label.Position = UDim2.fromOffset(4, 5)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.Font = Enum.Font.ArialBold
		label.TextSize = 11
		label.TextColor3 = Color3.fromRGB(42, 42, 42)
		label.Text = statName
		label.ZIndex = REWARD_Z + 18
		label.Parent = stat
		local value = Instance.new("TextLabel")
		value.Size = UDim2.new(1, -8, 0, 25)
		value.Position = UDim2.fromOffset(4, 23)
		value.BackgroundTransparency = 1
		value.TextXAlignment = Enum.TextXAlignment.Center
		value.Font = Enum.Font.ArialBold
		value.TextSize = 18
		value.TextColor3 = Color3.fromRGB(10, 10, 10)
		value.Text = statValues[index]
		value.ZIndex = REWARD_Z + 18
		value.Parent = stat
	end

	local lootBg = isVictory and Color3.fromRGB(15, 58, 42) or (isDefeat and Color3.fromRGB(54, 36, 36) or Color3.fromRGB(58, 50, 36))
	local lootPanel = createInsetPanel(frame, UDim2.fromOffset(14, 148), UDim2.new(1, -28, 0, 230), REWARD_Z + 12, lootBg)
	local rewardHeader = Instance.new("TextLabel")
	rewardHeader.Size = UDim2.new(1, -24, 0, 22)
	rewardHeader.Position = UDim2.fromOffset(12, 8)
	rewardHeader.BackgroundTransparency = 1
	rewardHeader.TextXAlignment = Enum.TextXAlignment.Left
	rewardHeader.Font = Enum.Font.ArialBold
	rewardHeader.TextSize = 16
	rewardHeader.TextColor3 = Color3.fromRGB(236, 252, 244)
	rewardHeader.Text = type(droppedEquipment) == "table" and "Reward Reveal" or "Battle Loot"
	rewardHeader.ZIndex = REWARD_Z + 16
	rewardHeader.Parent = lootPanel

	local essenceLabel: TextLabel
	local equipmentCard: Frame? = nil
	if type(droppedEquipment) == "table" then
		local _, chipValue = createEssenceRewardChip(lootPanel, UDim2.fromOffset(144, 34), UDim2.fromOffset(240, 38), REWARD_Z + 14, 0, isVictory, false)
		essenceLabel = chipValue
		equipmentCard = createEquipmentDropCard(lootPanel, droppedEquipment, UDim2.fromOffset(35, 82), UDim2.fromOffset(462, 140), REWARD_Z + 14)
	else
		local _, chipValue = createEssenceRewardChip(lootPanel, UDim2.fromOffset(105, 48), UDim2.fromOffset(320, 70), REWARD_Z + 14, isVictory and 0 or essence, isVictory, true)
		essenceLabel = chipValue
		createNoEquipmentCard(lootPanel, UDim2.fromOffset(148, 134), UDim2.fromOffset(234, 44), REWARD_Z + 14, isVictory)
		local lootNote = Instance.new("TextLabel")
		lootNote.Size = UDim2.new(1, -24, 0, 20)
		lootNote.Position = UDim2.new(0, 12, 1, -28)
		lootNote.BackgroundTransparency = 1
		lootNote.TextXAlignment = Enum.TextXAlignment.Center
		lootNote.Font = Enum.Font.Code
		lootNote.TextSize = 12
		lootNote.TextColor3 = Color3.fromRGB(210, 235, 220)
		lootNote.Text = isVictory and "No equipment drop." or "The enemy escaped."
		lootNote.ZIndex = REWARD_Z + 16
		lootNote.Parent = lootPanel
	end

	local buttonText = isVictory and "Claim Loot" or "Close"
	local closeBtn = createButton(frame, buttonText, UDim2.new(0.5, -112, 1, -42), UDim2.fromOffset(224, 36), REWARD_Z + 15, isVictory and Color3.fromRGB(40, 190, 92) or Color3.fromRGB(204, 204, 204))
	styleButton(closeBtn, closeBtn.BackgroundColor3, isVictory and Color3.fromRGB(54, 220, 110) or Color3.fromRGB(224, 224, 224), isVictory and Color3.fromRGB(28, 150, 70) or Color3.fromRGB(170, 170, 170), isVictory and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20))
	closeBtn.MouseButton1Click:Connect(function() windowRef.Destroy() end)
	if isVictory then
		lootPanel.Position = UDim2.fromOffset(14, 154)
		TweenService:Create(lootPanel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(14, 148)}):Play()
		if equipmentCard then
			equipmentCard.Size = UDim2.fromOffset(438, 126)
			equipmentCard.Position = UDim2.fromOffset(47, 89)
			TweenService:Create(equipmentCard, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(462, 140), Position = UDim2.fromOffset(35, 82)}):Play()
		end
		task.spawn(function()
			for i = 0, essence do
				if not essenceLabel.Parent then return end
				essenceLabel.Text = "+" .. tostring(i)
				task.wait(math.max(0.015, math.min(0.04, 0.5 / math.max(essence, 1))))
			end
		end)
		for i = 1, 8 do
			task.delay(i * 0.045, function()
				if not frame.Parent then return end
				local sparkle = Instance.new("Frame")
				sparkle.Size = UDim2.fromOffset(math.random(3, 7), math.random(3, 7))
				sparkle.Position = UDim2.new(0.5, math.random(-205, 205), 0, math.random(190, 346))
				sparkle.BorderSizePixel = 0
				sparkle.BackgroundColor3 = type(droppedEquipment) == "table" and getEquipmentRarityColor(droppedEquipment.Rarity) or Color3.fromRGB(138, 255, 186)
				sparkle.ZIndex = REWARD_Z + 22
				sparkle.Parent = frame
				Instance.new("UICorner", sparkle).CornerRadius = UDim.new(1, 0)
				local startPos = sparkle.Position
				TweenService:Create(sparkle, TweenInfo.new(0.55), {BackgroundTransparency = 1, Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + math.random(-28, 28), startPos.Y.Scale, startPos.Y.Offset + math.random(-36, 8))}):Play()
				task.delay(0.6, function() if sparkle then sparkle:Destroy() end end)
			end)
		end
	else
		essenceLabel.Text = "+0"
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
		updateCenterStatus("INITIALIZING", "Combat link established", nil)
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
			updateTopStatus("Simulating battle...", tostring(result.EnemyName or "Enemy"), string.format("Action %d / %d", playbackIndex, #logs))
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
		applyFinalUnitHealth(result)
		updateTopStatus("Battle complete", tostring(result.EnemyName or "Enemy"), string.format("Action %d / %d", #logs, #logs))
		updateCenterStatus("BATTLE COMPLETE", "Final battle state locked", resultWord)
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
	createCombatantCard(terminalEnemyPanel, {Name = enemy.DisplayName, Icon = enemy.Icon, Stats = enemy.Stats, Team = "Enemy"}, 34)
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
	terminalMomentumLabel = Instance.new("TextLabel")
	terminalMomentumLabel.Size = UDim2.new(1, -20, 0, 20)
	terminalMomentumLabel.Position = UDim2.fromOffset(10, 80)
	terminalMomentumLabel.BackgroundTransparency = 1
	terminalMomentumLabel.Font = Enum.Font.ArialBold
	terminalMomentumLabel.TextSize = 15
	terminalMomentumLabel.TextColor3 = Color3.fromRGB(255, 218, 112)
	terminalMomentumLabel.Text = "Even Match"
	terminalMomentumLabel.ZIndex = MODAL_Z + 18
	terminalMomentumLabel.Parent = terminalCenterPanel
	local meterBack = Instance.new("Frame")
	meterBack.Size = UDim2.new(1, -24, 0, 12)
	meterBack.Position = UDim2.fromOffset(12, 106)
	meterBack.BackgroundColor3 = Color3.fromRGB(48, 56, 58)
	meterBack.BorderSizePixel = 1
	meterBack.BorderColor3 = Color3.fromRGB(96, 96, 96)
	meterBack.ZIndex = MODAL_Z + 18
	meterBack.Parent = terminalCenterPanel
	terminalMomentumEnemyFill = Instance.new("Frame")
	terminalMomentumEnemyFill.AnchorPoint = Vector2.new(1, 0)
	terminalMomentumEnemyFill.Position = UDim2.fromScale(1, 0)
	terminalMomentumEnemyFill.Size = UDim2.new(0.5, 0, 1, 0)
	terminalMomentumEnemyFill.BackgroundColor3 = Color3.fromRGB(196, 74, 50)
	terminalMomentumEnemyFill.BorderSizePixel = 0
	terminalMomentumEnemyFill.ZIndex = MODAL_Z + 19
	terminalMomentumEnemyFill.Parent = meterBack
	terminalMomentumPlayerFill = Instance.new("Frame")
	terminalMomentumPlayerFill.Size = UDim2.new(0.5, 0, 1, 0)
	terminalMomentumPlayerFill.BackgroundColor3 = Color3.fromRGB(80, 220, 168)
	terminalMomentumPlayerFill.BorderSizePixel = 0
	terminalMomentumPlayerFill.ZIndex = MODAL_Z + 20
	terminalMomentumPlayerFill.Parent = meterBack
	terminalTeamHpLabel = Instance.new("TextLabel")
	terminalTeamHpLabel.Size = UDim2.new(1, -20, 0, 20)
	terminalTeamHpLabel.Position = UDim2.fromOffset(10, 126)
	terminalTeamHpLabel.BackgroundTransparency = 1
	terminalTeamHpLabel.Font = Enum.Font.Code
	terminalTeamHpLabel.TextSize = 12
	terminalTeamHpLabel.TextXAlignment = Enum.TextXAlignment.Left
	terminalTeamHpLabel.TextColor3 = Color3.fromRGB(128, 255, 188)
	terminalTeamHpLabel.Text = "Team HP: 0 / 0"
	terminalTeamHpLabel.ZIndex = MODAL_Z + 18
	terminalTeamHpLabel.Parent = terminalCenterPanel
	terminalEnemyHpLabel = Instance.new("TextLabel")
	terminalEnemyHpLabel.Size = UDim2.new(1, -20, 0, 20)
	terminalEnemyHpLabel.Position = UDim2.fromOffset(10, 146)
	terminalEnemyHpLabel.BackgroundTransparency = 1
	terminalEnemyHpLabel.Font = Enum.Font.Code
	terminalEnemyHpLabel.TextSize = 12
	terminalEnemyHpLabel.TextXAlignment = Enum.TextXAlignment.Left
	terminalEnemyHpLabel.TextColor3 = Color3.fromRGB(255, 150, 106)
	terminalEnemyHpLabel.Text = "Enemy HP: 0 / 0"
	terminalEnemyHpLabel.ZIndex = MODAL_Z + 18
	terminalEnemyHpLabel.Parent = terminalCenterPanel
	terminalCenterDetailLabel = Instance.new("TextLabel")
	terminalCenterDetailLabel.Size = UDim2.new(1, -20, 0, 18)
	terminalCenterDetailLabel.Position = UDim2.fromOffset(10, 168)
	terminalCenterDetailLabel.BackgroundTransparency = 1
	terminalCenterDetailLabel.Font = Enum.Font.Code
	terminalCenterDetailLabel.TextSize = 11
	terminalCenterDetailLabel.TextWrapped = true
	terminalCenterDetailLabel.TextColor3 = Color3.fromRGB(128, 245, 218)
	terminalCenterDetailLabel.Text = "Combat link established"
	terminalCenterDetailLabel.ZIndex = MODAL_Z + 18
	terminalCenterDetailLabel.Parent = terminalCenterPanel
	terminalEventBadgeLabel = Instance.new("TextLabel")
	terminalEventBadgeLabel.Size = UDim2.new(0, 82, 0, 24)
	terminalEventBadgeLabel.Position = UDim2.new(0.5, -41, 1, -30)
	terminalEventBadgeLabel.BackgroundColor3 = Color3.fromRGB(8, 20, 24)
	terminalEventBadgeLabel.BorderSizePixel = 1
	terminalEventBadgeLabel.BorderColor3 = Color3.fromRGB(104, 232, 255)
	terminalEventBadgeLabel.Font = Enum.Font.ArialBold
	terminalEventBadgeLabel.TextSize = 15
	terminalEventBadgeLabel.TextColor3 = Color3.fromRGB(128, 245, 218)
	terminalEventBadgeLabel.Text = ""
	terminalEventBadgeLabel.Visible = false
	terminalEventBadgeLabel.ZIndex = MODAL_Z + 18
	terminalEventBadgeLabel.Parent = terminalCenterPanel
	updateCenterStatus("INITIALIZING", "Combat link established", nil)
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
