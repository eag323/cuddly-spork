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

local function createTerminalLine(text: string)
	if not terminalLinesFrame then return end
	local line = Instance.new("TextLabel")
	line.BackgroundTransparency = 1
	line.Size = UDim2.new(1, -8, 0, 18)
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.Text = text
	line.TextColor3 = Color3.fromRGB(80, 245, 140)
	line.Font = Enum.Font.Code
	line.TextSize = 14
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
	frame.Size = UDim2.fromOffset(420, 280)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
	frame.ZIndex = 70
	frame.Parent = hud
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 36)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 26
	title.Text = (result.Winner == "Player" and "Victory!") or (result.Winner == "Enemy" and "Defeat") or "Draw"
	title.TextColor3 = (result.Winner == "Player" and Color3.fromRGB(115, 255, 125)) or Color3.fromRGB(255, 105, 105)
	title.ZIndex = 71
	title.Parent = frame
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -20, 0, 150)
	info.Position = UDim2.fromOffset(10, 56)
	info.BackgroundTransparency = 1
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.Font = Enum.Font.Gotham
	info.TextSize = 14
	info.TextColor3 = Color3.fromRGB(220, 230, 250)
	local rewards = result.Rewards or {BugEssence = 0, BugDust = 0}
	if result.Winner ~= "Player" then rewards = {BugEssence = 0, BugDust = 0} end
	local extra = result.Winner == "Player" and "Rewards granted." or "The enemy escaped after the battle."
	info.Text = string.format("Enemy: %s\nTurns: %s\nPlayer Remaining: %s\nEnemy Remaining: %s\nBug Essence: +%d\nBug Dust: +%d\n%s", tostring(result.EnemyName or "Enemy"), tostring(result.Turns or "?"), tostring(result.PlayerRemaining or "?"), tostring(result.EnemyRemaining or "?"), tonumber(rewards.BugEssence) or 0, tonumber(rewards.BugDust) or 0, extra)
	info.ZIndex = 71
	info.Parent = frame
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(130, 36)
	closeBtn.Position = UDim2.new(1, -140, 1, -46)
	closeBtn.BackgroundColor3 = Color3.fromRGB(70, 74, 92)
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = result.Winner == "Player" and "Claim" or "Close"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
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
	if terminalSkipButton then
		terminalSkipButton.Active = true
		terminalSkipButton.AutoButtonColor = true
		terminalSkipButton.Text = "Skip"
	end
	createTerminalLine("> BUG.OS COMBAT SIM v1.0")
	createTerminalLine("> Target: " .. tostring(result.EnemyName or "Enemy"))
	createTerminalLine("> Combat Team deployed.")
	createTerminalLine("> ---")
	local logs = result.Log or {}
	task.spawn(function()
		while terminalOpen and myToken == playbackToken and playbackIndex < #logs do
			if playbackSkipped then
				for i = playbackIndex + 1, #logs do createTerminalLine(string.format("[%02d] %s", i, tostring(logs[i]))) end
				playbackIndex = #logs
				break
			end
			playbackIndex += 1
			createTerminalLine(string.format("[%02d] %s", playbackIndex, tostring(logs[playbackIndex])))
			task.wait(0.42)
		end
		if not terminalOpen or myToken ~= playbackToken then return end
		createTerminalLine("> ---")
		createTerminalLine("> RESULT: " .. string.upper(tostring(result.Winner or "Unknown")))
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
	createTerminalLine("> Initializing combat simulation...")
	createTerminalLine("> Loading Combat Team...")
	createTerminalLine("> Target acquired: " .. tostring(enemy.DisplayName))
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
