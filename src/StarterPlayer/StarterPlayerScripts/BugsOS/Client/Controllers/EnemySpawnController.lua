--!strict
local TweenService = game:GetService("TweenService")

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

local activeBattleResult
local playbackIndex = 0
local playbackSkipped = false
local terminalOpen = false
local playbackToken = 0
local awaitingResult = false
local playbackStartedAt = 0

local BOOT_LINE_DELAY = 0.4
local ACTION_LINE_DELAY = 0.85
local FINAL_RESULT_DELAY = 1.25
local MIN_TERMINAL_DISPLAY = 4

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
	if type(combatSlots) ~= "table" then
		return 0
	end
	local count = 0
	for _, slot in pairs(combatSlots) do
		if slot ~= nil and slot ~= "" then
			count += 1
		end
	end
	return count
end

local function friendlyFailure(reason: string): string
	if reason == "NoCombatTeam" then
		return "Equip bugs in Bugs.exe > Combat Team first."
	elseif reason == "NoEnemy" then
		return "This enemy is no longer available."
	elseif reason == "EnemyExpired" then
		return "This enemy escaped."
	elseif reason == "InvalidPayload" then
		return "Attack failed. Try again."
	end
	return "Attack failed. Try again."
end

local function createTerminalLine(text: string, color: Color3?)
	if not terminalLinesFrame then return end
	local line = Instance.new("TextLabel")
	line.BackgroundTransparency = 1
	line.Size = UDim2.new(1, -8, 0, 22)
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.Text = text
	line.TextColor3 = color or Color3.fromRGB(80, 245, 140)
	line.Font = Enum.Font.Code
	line.TextSize = 16
	line.ZIndex = 63
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
	if terminalWindow then terminalWindow:Destroy() end
	terminalWindow = nil
	terminalLinesLayout = nil
	terminalLinesFrame = nil
	terminalSkipButton = nil
	terminalCloseButton = nil
end

local function showFinalPopup(result)
	print("[EnemySpawnController] Final result popup", tostring(result and result.Winner))
	local hud = context.UI.HUDLayer
	if not hud then return end
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(500, 380)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(8, 16, 30)
	frame.ZIndex = 70
	frame.Parent = hud
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
	local border = Instance.new("UIStroke", frame)
	border.Thickness = 2
	border.Color = (result.Winner == "Player" and Color3.fromRGB(88, 255, 170)) or (result.Winner == "Enemy" and Color3.fromRGB(255, 96, 96)) or Color3.fromRGB(240, 180, 120)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 48)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 34
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Text = (result.Winner == "Player" and "VICTORY!") or (result.Winner == "Enemy" and "DEFEAT") or "DRAW"
	title.TextColor3 = (result.Winner == "Player" and Color3.fromRGB(115, 255, 125)) or Color3.fromRGB(255, 105, 105)
	title.ZIndex = 71
	title.Parent = frame
	local enemyIcon = Instance.new("ImageLabel")
	enemyIcon.Size = UDim2.fromOffset(76, 76)
	enemyIcon.Position = UDim2.fromOffset(24, 66)
	enemyIcon.BackgroundTransparency = 1
	enemyIcon.Image = tostring(result.EnemyIcon or "")
	enemyIcon.ZIndex = 71
	enemyIcon.Parent = frame
	local enemyName = Instance.new("TextLabel")
	enemyName.Size = UDim2.new(1, -120, 0, 34)
	enemyName.Position = UDim2.fromOffset(112, 78)
	enemyName.BackgroundTransparency = 1
	enemyName.TextXAlignment = Enum.TextXAlignment.Left
	enemyName.Font = Enum.Font.GothamBold
	enemyName.TextSize = 20
	enemyName.TextColor3 = Color3.fromRGB(230, 242, 255)
	enemyName.Text = tostring(result.EnemyName or "Enemy")
	enemyName.ZIndex = 71
	enemyName.Parent = frame
	local detailRow = Instance.new("TextLabel")
	detailRow.Size = UDim2.new(1, -120, 0, 24)
	detailRow.Position = UDim2.fromOffset(112, 112)
	detailRow.BackgroundTransparency = 1
	detailRow.TextXAlignment = Enum.TextXAlignment.Left
	detailRow.Font = Enum.Font.Code
	detailRow.TextSize = 14
	detailRow.TextColor3 = Color3.fromRGB(120, 230, 185)
	detailRow.Text = string.format("Turns %s   |   Player %s   |   Enemy %s", tostring(result.Turns or "?"), tostring(result.PlayerRemaining or "?"), tostring(result.EnemyRemaining or "?"))
	detailRow.ZIndex = 71
	detailRow.Parent = frame
	local rewards = result.Rewards or {BugEssence = 0, BugDust = 0}
	if result.Winner ~= "Player" then rewards = {BugEssence = 0, BugDust = 0} end
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -40, 0, 54)
	info.Position = UDim2.fromOffset(20, 150)
	info.BackgroundTransparency = 1
	info.TextXAlignment = Enum.TextXAlignment.Center
	info.TextYAlignment = Enum.TextYAlignment.Center
	info.Font = Enum.Font.Gotham
	info.TextSize = 16
	info.TextColor3 = Color3.fromRGB(220, 230, 250)
	info.Text = result.Winner == "Player" and "Rewards granted." or "The enemy escaped after the battle."
	info.ZIndex = 71
	info.Parent = frame
	local function createRewardCard(xOffset, label, value)
		local card = Instance.new("Frame")
		card.Size = UDim2.fromOffset(210, 70)
		card.Position = UDim2.fromOffset(xOffset, 216)
		card.BackgroundColor3 = Color3.fromRGB(20, 36, 54)
		card.ZIndex = 71
		card.Parent = frame
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local stroke = Instance.new("UIStroke", card)
		stroke.Color = Color3.fromRGB(90, 240, 190)
		stroke.Transparency = 0.25
		local labelText = Instance.new("TextLabel")
		labelText.BackgroundTransparency = 1
		labelText.Size = UDim2.new(1, -16, 0, 24)
		labelText.Position = UDim2.fromOffset(8, 8)
		labelText.TextXAlignment = Enum.TextXAlignment.Left
		labelText.Font = Enum.Font.GothamSemibold
		labelText.TextSize = 14
		labelText.TextColor3 = Color3.fromRGB(196, 215, 255)
		labelText.Text = label
		labelText.ZIndex = 72
		labelText.Parent = card
		local amount = Instance.new("TextLabel")
		amount.BackgroundTransparency = 1
		amount.Size = UDim2.new(1, -16, 0, 30)
		amount.Position = UDim2.fromOffset(8, 30)
		amount.TextXAlignment = Enum.TextXAlignment.Left
		amount.Font = Enum.Font.GothamBlack
		amount.TextSize = 24
		amount.TextColor3 = Color3.fromRGB(125, 255, 170)
		amount.Text = "+0"
		amount.ZIndex = 72
		amount.Parent = card
		if result.Winner == "Player" then task.spawn(function() for i = 0, value do if not amount.Parent then return end amount.Text = "+" .. tostring(i) task.wait(0.02) end end) else amount.Text = "+0" end
		return card
	end
	local essenceCard = createRewardCard(24, "Bug Essence", tonumber(rewards.BugEssence) or 0)
	local dustCard = createRewardCard(266, "Bug Dust", tonumber(rewards.BugDust) or 0)
	if result.Winner == "Player" then
		for i = 1, 12 do task.delay(i * 0.05, function() if not frame.Parent then return end local sparkle = Instance.new("Frame") sparkle.Size = UDim2.fromOffset(math.random(4, 8), math.random(4, 8)) sparkle.Position = UDim2.new(0, math.random(20, 480), 0, math.random(20, 290)) sparkle.BorderSizePixel = 0 sparkle.BackgroundColor3 = Color3.fromRGB(130, 255, 190) sparkle.ZIndex = 73 sparkle.Parent = frame Instance.new("UICorner", sparkle).CornerRadius = UDim.new(1, 0) TweenService:Create(sparkle, TweenInfo.new(0.45), {BackgroundTransparency = 1}):Play() task.delay(0.5, function() if sparkle then sparkle:Destroy() end end) end) end
		TweenService:Create(essenceCard, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(220, 76)}):Play()
		TweenService:Create(dustCard, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(220, 76)}):Play()
	end
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(180, 42)
	closeBtn.Position = UDim2.new(0.5, -90, 1, -54)
	closeBtn.BackgroundColor3 = (result.Winner == "Player" and Color3.fromRGB(66, 236, 166)) or Color3.fromRGB(80, 86, 105)
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = result.Winner == "Player" and "Claim Rewards" or "Close"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.ZIndex = 71
	closeBtn.Parent = frame
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
	closeBtn.MouseButton1Click:Connect(function() frame:Destroy() end)
end

local function finishPlayback(result)
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
	playbackToken += 1
	local myToken = playbackToken
	playbackStartedAt = os.clock()
	if terminalSkipButton then
		terminalSkipButton.Active = true
		terminalSkipButton.AutoButtonColor = true
		terminalSkipButton.Text = "Skip"
	end
	print("[EnemySpawnController] Playback line delay started", tostring(result.EnemyId))
	local logs = result.Log or {}
	task.spawn(function()
		local bootLines = {
			"> BUG.OS COMBAT SIM v1.0",
			"> Target: " .. tostring(result.EnemyName or "Enemy"),
			"> Combat Team deployed.",
			"> Running turn simulation...",
			"> ---",
		}
		for _, bootLine in ipairs(bootLines) do
			if not terminalOpen or myToken ~= playbackToken then return end
			createTerminalLine(bootLine)
			if not playbackSkipped then task.wait(BOOT_LINE_DELAY) end
		end
		while terminalOpen and myToken == playbackToken and playbackIndex < #logs do
			if playbackSkipped then
				for i = playbackIndex + 1, #logs do createTerminalLine(string.format("[%02d] %s", i, tostring(logs[i]))) end
				playbackIndex = #logs
				break
			end
			playbackIndex += 1
			local logLine = tostring(logs[playbackIndex])
			local lowerLine = string.lower(logLine)
			local lineColor = Color3.fromRGB(80, 245, 140)
			if string.find(lowerLine, "crit", 1, true) then
				lineColor = Color3.fromRGB(255, 242, 130)
			elseif string.find(lowerLine, "defeat", 1, true) or string.find(lowerLine, "defeated", 1, true) then
				lineColor = Color3.fromRGB(255, 132, 90)
			end
			createTerminalLine(string.format("[%02d] %s", playbackIndex, logLine), lineColor)
			task.wait(ACTION_LINE_DELAY)
		end
		if not terminalOpen or myToken ~= playbackToken then return end
		createTerminalLine("> ---")
		local winner = string.lower(tostring(result.Winner or "Unknown"))
		local resultColor = Color3.fromRGB(255, 176, 120)
		if winner == "player" then resultColor = Color3.fromRGB(128, 255, 164)
		elseif winner == "enemy" then resultColor = Color3.fromRGB(255, 120, 120) end
		createTerminalLine("> RESULT: " .. string.upper(tostring(result.Winner or "Unknown")), resultColor)
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
	local hud = context.UI.HUDLayer
	if not hud then return end
	terminalOpen = true
	terminalWindow = Instance.new("Frame")
	terminalWindow.Size = UDim2.fromOffset(560, 360)
	terminalWindow.Position = UDim2.fromScale(0.5, 0.5)
	terminalWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	terminalWindow.BackgroundColor3 = Color3.fromRGB(5, 8, 8)
	terminalWindow.BorderColor3 = Color3.fromRGB(80, 255, 160)
	terminalWindow.BorderSizePixel = 1
	terminalWindow.ZIndex = 60
	terminalWindow.Parent = hud
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundColor3 = Color3.fromRGB(10, 24, 18)
	title.Text = "BUG.OS COMBAT SIM"
	title.TextColor3 = Color3.fromRGB(90, 255, 180)
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.ZIndex = 61
	title.Parent = terminalWindow
	terminalLinesFrame = Instance.new("ScrollingFrame")
	terminalLinesFrame.Size = UDim2.new(1, -20, 1, -84)
	terminalLinesFrame.Position = UDim2.fromOffset(10, 36)
	terminalLinesFrame.BackgroundColor3 = Color3.fromRGB(2, 4, 4)
	terminalLinesFrame.BorderSizePixel = 0
	terminalLinesFrame.ScrollBarThickness = 6
	terminalLinesFrame.ZIndex = 62
	terminalLinesFrame.Parent = terminalWindow
	terminalLinesLayout = Instance.new("UIListLayout")
	terminalLinesLayout.Padding = UDim.new(0, 4)
	terminalLinesLayout.Parent = terminalLinesFrame
	terminalSkipButton = Instance.new("TextButton")
	terminalSkipButton.Size = UDim2.fromOffset(110, 32)
	terminalSkipButton.Position = UDim2.fromOffset(10, 322)
	terminalSkipButton.BackgroundColor3 = Color3.fromRGB(26, 60, 44)
	terminalSkipButton.TextColor3 = Color3.fromRGB(130, 255, 200)
	terminalSkipButton.Font = Enum.Font.Code
	terminalSkipButton.TextSize = 14
	terminalSkipButton.Text = "Waiting..."
	terminalSkipButton.Active = false
	terminalSkipButton.AutoButtonColor = false
	terminalSkipButton.ZIndex = 62
	terminalSkipButton.Parent = terminalWindow
	terminalCloseButton = Instance.new("TextButton")
	terminalCloseButton.Size = UDim2.fromOffset(110, 32)
	terminalCloseButton.Position = UDim2.new(1, -120, 1, -38)
	terminalCloseButton.BackgroundColor3 = Color3.fromRGB(52, 52, 60)
	terminalCloseButton.TextColor3 = Color3.new(1,1,1)
	terminalCloseButton.Text = "Close"
	terminalCloseButton.Visible = false
	terminalCloseButton.Active = false
	terminalCloseButton.AutoButtonColor = false
	terminalCloseButton.ZIndex = 62
	terminalCloseButton.Parent = terminalWindow
	terminalCloseButton.MouseButton1Click:Connect(function() closeTerminal() end)
	terminalSkipButton.MouseButton1Click:Connect(function()
		if not activeBattleResult then return end
		print("[EnemySpawnController] Battle playback skipped", tostring(activeBattleResult.EnemyId))
		playbackSkipped = true
	end)
	createTerminalLine("> Awaiting server result...")
end

local function makePopup(enemy)
	closePopup()
	local hud = context.UI.HUDLayer
	if not hud then return end
	popup = Instance.new("Frame")
	popup.Name = "EnemyPopup"
	popup.Size = UDim2.fromOffset(440, 320)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(12, 18, 31)
	popup.BorderSizePixel = 0
	popup.ZIndex = 40
	popup.Parent = hud
	currentPopupEnemyId = enemy.EnemyId
	Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 12)
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -20, 0, 24)
	status.Position = UDim2.fromOffset(10, 248)
	status.BackgroundTransparency = 1
	status.Text = ""
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextColor3 = Color3.fromRGB(230, 238, 255)
	status.Font = Enum.Font.Gotham
	status.TextSize = 13
	status.ZIndex = 41
	status.Parent = popup
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(56, 56)
	icon.Position = UDim2.fromOffset(14, 14)
	icon.BackgroundTransparency = 1
	icon.Image = enemy.Icon or ""
	icon.ZIndex = 42
	icon.Parent = popup
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -88, 0, 194)
	info.Position = UDim2.fromOffset(78, 14)
	info.BackgroundTransparency = 1
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.TextWrapped = true
	info.Font = Enum.Font.Gotham
	info.TextSize = 14
	info.TextColor3 = Color3.fromRGB(230, 238, 255)
	info.ZIndex = 42
	info.Text = string.format("%s\n%s • %s\nPower: %d\nRole: %s\nSpecies: %s\nPossible Rewards: +%d Essence, +%d Dust", tostring(enemy.DisplayName), tostring(enemy.Tier), tostring(enemy.Rarity or "Unknown"), tonumber(enemy.Power) or 0, tostring(enemy.Role), tostring(enemy.Species), tonumber(enemy.RewardsPreview and enemy.RewardsPreview.BugEssence) or 0, tonumber(enemy.RewardsPreview and enemy.RewardsPreview.BugDust) or 0)
	info.Parent = popup
	local attack = Instance.new("TextButton")
	attack.Size = UDim2.fromOffset(170, 38)
	attack.Position = UDim2.fromOffset(10, 274)
	attack.TextColor3 = Color3.new(1,1,1)
	attack.Font = Enum.Font.GothamBold
	attack.TextSize = 14
	attack.ZIndex = 42
	attack.Parent = popup
	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(100, 38)
	close.Position = UDim2.fromOffset(330, 274)
	close.Text = "Close"
	close.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
	close.TextColor3 = Color3.new(1,1,1)
	close.Font = Enum.Font.Gotham
	close.TextSize = 14
	close.ZIndex = 42
	close.Parent = popup
	local hasTeam = getCombatTeamCount() > 0
	if hasTeam then
		attack.Active = true; attack.AutoButtonColor = true; attack.Text = "Attack"; attack.BackgroundColor3 = Color3.fromRGB(175, 45, 45)
	else
		attack.Active = false; attack.AutoButtonColor = false; attack.Text = "No Combat Team"; attack.BackgroundColor3 = Color3.fromRGB(85, 40, 40)
		status.Text = "Equip bugs in Bugs.exe > Combat Team first."
	end
	close.MouseButton1Click:Connect(closePopup)
	attack.MouseButton1Click:Connect(function()
		if getCombatTeamCount() <= 0 then
			status.Text = "Equip bugs in Bugs.exe > Combat Team first."
			return
		end
		print("[EnemySpawnController] Attack clicked", enemy.EnemyId)
		attack.Active = false
		attack.AutoButtonColor = false
		attack.Text = "Preparing..."
		awaitingResult = true
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
	root.ZIndex = 12
	root.Parent = world
	local auraOuter = Instance.new("Frame")
	auraOuter.Size = UDim2.fromOffset(102, 102)
	auraOuter.AnchorPoint = Vector2.new(0.5, 0.5)
	auraOuter.Position = UDim2.fromScale(0.5, 0.48)
	auraOuter.BackgroundColor3 = Color3.fromRGB(120, 10, 10)
	auraOuter.BackgroundTransparency = 0.72
	auraOuter.ZIndex = 10
	auraOuter.Parent = root
	Instance.new("UICorner", auraOuter).CornerRadius = UDim.new(1, 0)
	local auraInner = Instance.new("Frame")
	auraInner.Size = UDim2.fromOffset(88, 88)
	auraInner.AnchorPoint = Vector2.new(0.5, 0.5)
	auraInner.Position = UDim2.fromScale(0.5, 0.48)
	auraInner.BackgroundColor3 = Color3.fromRGB(225, 24, 24)
	auraInner.BackgroundTransparency = 0.78
	auraInner.ZIndex = 11
	auraInner.Parent = root
	Instance.new("UICorner", auraInner).CornerRadius = UDim.new(1, 0)
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(76, 76)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.44)
	icon.BackgroundTransparency = 1
	icon.Image = enemy.Icon or ""
	icon.ZIndex = 13
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
	nameplate.ZIndex = 15
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
				createTerminalLine("> " .. friendlyFailure(tostring(result.Reason)))
				task.delay(0.8, closeTerminal)
				return
			end
			startTerminalPlayback(result)
		end
	end)
end

return EnemySpawnController
