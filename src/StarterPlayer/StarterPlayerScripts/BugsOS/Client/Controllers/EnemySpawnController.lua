--!strict
local TweenService = game:GetService("TweenService")

local EnemySpawnController = {}
local context
local activeEnemy
local enemyGui
local popup
local currentPopupEnemyId: string? = nil
local attacking = false
local attackNonce = 0
local pendingResultByEnemyId: {[string]: any} = {}

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
		attacking = false
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

local function setAttackEnabled(attackButton: TextButton, isEnabled: boolean, text: string)
	attackButton.Active = isEnabled
	attackButton.AutoButtonColor = isEnabled
	attackButton.Text = text
	attackButton.BackgroundColor3 = isEnabled and Color3.fromRGB(175, 45, 45) or Color3.fromRGB(85, 40, 40)
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

local function makePopup(enemy)
	closePopup()
	local hud = context.UI.HUDLayer
	if not hud then
		return
	end

	popup = Instance.new("Frame")
	popup.Name = "EnemyPopup"
	popup.Size = UDim2.fromOffset(440, 460)
	popup.Position = UDim2.fromScale(0.5, 0.5)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(12, 18, 31)
	popup.BorderSizePixel = 0
	popup.ZIndex = 40
	popup.Parent = hud
	currentPopupEnemyId = enemy.EnemyId

	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 12)
	round.Parent = popup

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(68, 225, 255)
	stroke.Transparency = 0.35
	stroke.Parent = popup

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(1, 0, 0, 3)
	accent.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
	accent.BorderSizePixel = 0
	accent.ZIndex = 41
	accent.Parent = popup

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, -20, 0, 78)
	header.Position = UDim2.fromOffset(10, 12)
	header.BackgroundColor3 = Color3.fromRGB(20, 28, 44)
	header.BorderSizePixel = 0
	header.ZIndex = 41
	header.Parent = popup
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = header

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(56, 56)
	icon.Position = UDim2.fromOffset(10, 11)
	icon.BackgroundTransparency = 1
	icon.Image = enemy.Icon or ""
	icon.ZIndex = 42
	icon.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -84, 0, 28)
	title.Position = UDim2.fromOffset(74, 10)
	title.BackgroundTransparency = 1
	title.Text = enemy.DisplayName
	title.TextColor3 = Color3.fromRGB(255, 75, 75)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 42
	title.Parent = header

	local tier = Instance.new("TextLabel")
	tier.Size = UDim2.new(1, -84, 0, 20)
	tier.Position = UDim2.fromOffset(74, 42)
	tier.BackgroundTransparency = 1
	tier.Text = string.format("%s • %s", tostring(enemy.Tier), tostring(enemy.Rarity or "Unknown"))
	tier.TextColor3 = Color3.fromRGB(150, 210, 255)
	tier.Font = Enum.Font.Gotham
	tier.TextSize = 13
	tier.TextXAlignment = Enum.TextXAlignment.Left
	tier.ZIndex = 42
	tier.Parent = header

	local stats = Instance.new("TextLabel")
	stats.Size = UDim2.new(1, -20, 0, 76)
	stats.Position = UDim2.fromOffset(10, 98)
	stats.BackgroundColor3 = Color3.fromRGB(20, 28, 44)
	stats.BorderSizePixel = 0
	stats.TextXAlignment = Enum.TextXAlignment.Left
	stats.TextYAlignment = Enum.TextYAlignment.Top
	stats.TextWrapped = true
	stats.Font = Enum.Font.Gotham
	stats.TextSize = 13
	stats.TextColor3 = Color3.fromRGB(225, 235, 255)
	stats.Text = string.format("Power: %d\nRole: %s\nSpecies: %s", enemy.Power, tostring(enemy.Role), tostring(enemy.Species))
	stats.ZIndex = 41
	stats.Parent = popup
	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 8)
	statsCorner.Parent = stats

	local rewards = Instance.new("TextLabel")
	rewards.Size = UDim2.new(1, -20, 0, 56)
	rewards.Position = UDim2.fromOffset(10, 180)
	rewards.BackgroundColor3 = Color3.fromRGB(20, 28, 44)
	rewards.BorderSizePixel = 0
	rewards.TextXAlignment = Enum.TextXAlignment.Left
	rewards.TextYAlignment = Enum.TextYAlignment.Top
	rewards.Font = Enum.Font.Gotham
	rewards.TextSize = 13
	rewards.TextColor3 = Color3.fromRGB(235, 235, 235)
	rewards.Text = string.format("Possible Rewards\nBug Essence: %d   Bug Dust: %d", enemy.RewardsPreview.BugEssence or 0, enemy.RewardsPreview.BugDust or 0)
	rewards.ZIndex = 41
	rewards.Parent = popup
	local rewardsCorner = Instance.new("UICorner")
	rewardsCorner.CornerRadius = UDim.new(0, 8)
	rewardsCorner.Parent = rewards

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -20, 0, 28)
	status.Position = UDim2.fromOffset(10, 244)
	status.BackgroundTransparency = 1
	status.Text = ""
	status.TextColor3 = Color3.fromRGB(255, 255, 255)
	status.Font = Enum.Font.GothamBold
	status.TextSize = 16
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.ZIndex = 41
	status.Parent = popup

	local resultSummary = Instance.new("TextLabel")
	resultSummary.Name = "ResultSummary"
	resultSummary.Size = UDim2.new(1, -20, 0, 24)
	resultSummary.Position = UDim2.fromOffset(10, 272)
	resultSummary.BackgroundTransparency = 1
	resultSummary.Text = ""
	resultSummary.TextColor3 = Color3.fromRGB(165, 215, 255)
	resultSummary.Font = Enum.Font.Gotham
	resultSummary.TextSize = 13
	resultSummary.TextXAlignment = Enum.TextXAlignment.Left
	resultSummary.ZIndex = 41
	resultSummary.Parent = popup

	local logFrame = Instance.new("ScrollingFrame")
	logFrame.Name = "BattleLog"
	logFrame.Size = UDim2.new(1, -20, 0, 90)
	logFrame.Position = UDim2.fromOffset(10, 300)
	logFrame.BackgroundColor3 = Color3.fromRGB(10, 14, 23)
	logFrame.BorderSizePixel = 0
	logFrame.ScrollBarThickness = 6
	logFrame.CanvasSize = UDim2.fromOffset(0, 0)
	logFrame.ZIndex = 41
	logFrame.Parent = popup
	local logCorner = Instance.new("UICorner")
	logCorner.CornerRadius = UDim.new(0, 8)
	logCorner.Parent = logFrame

	local logLayout = Instance.new("UIListLayout")
	logLayout.Padding = UDim.new(0, 4)
	logLayout.Parent = logFrame

	local attack = Instance.new("TextButton")
	attack.Name = "AttackButton"
	attack.Size = UDim2.fromOffset(170, 38)
	attack.Position = UDim2.fromOffset(10, 410)
	attack.TextColor3 = Color3.new(1, 1, 1)
	attack.Font = Enum.Font.GothamBold
	attack.TextSize = 14
	attack.ZIndex = 41
	attack.Parent = popup
	local attackCorner = Instance.new("UICorner")
	attackCorner.CornerRadius = UDim.new(0, 8)
	attackCorner.Parent = attack

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(100, 38)
	close.Position = UDim2.fromOffset(330, 410)
	close.Text = "Close"
	close.BackgroundColor3 = Color3.fromRGB(65, 65, 72)
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.Gotham
	close.TextSize = 14
	close.ZIndex = 41
	close.Parent = popup
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = close

	close.MouseButton1Click:Connect(closePopup)

	local function setBattleLog(lines)
		for _, child in ipairs(logFrame:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local y = 0
		for i, line in ipairs(lines or {}) do
			local entry = Instance.new("TextLabel")
			entry.BackgroundTransparency = 1
			entry.Size = UDim2.new(1, -8, 0, 18)
			entry.TextXAlignment = Enum.TextXAlignment.Left
			entry.Text = string.format("%d. %s", i, tostring(line))
			entry.TextColor3 = Color3.fromRGB(215, 225, 245)
			entry.Font = Enum.Font.Code
			entry.TextSize = 13
			entry.ZIndex = 42
			entry.Parent = logFrame
			y += 22
		end
		logFrame.CanvasSize = UDim2.fromOffset(0, math.max(0, y))
	end

	local function refreshCombatTeamState()
		if getCombatTeamCount() <= 0 then
			setAttackEnabled(attack, false, "No Combat Team")
			status.Text = "Equip bugs in Bugs.exe > Combat Team first."
		else
			setAttackEnabled(attack, true, "Attack")
			if not attacking then
				status.Text = ""
			end
		end
	end

	refreshCombatTeamState()
	setBattleLog({})

	attack.MouseButton1Click:Connect(function()
		if attacking then
			return
		end
		if getCombatTeamCount() <= 0 then
			status.Text = "Equip bugs in Bugs.exe > Combat Team first."
			setAttackEnabled(attack, false, "No Combat Team")
			return
		end
		print("[EnemySpawnController] Attack clicked", enemy.EnemyId)
		attacking = true
		attackNonce += 1
		local myNonce = attackNonce
		setAttackEnabled(attack, false, "Attacking...")
		status.Text = "Battle in progress..."
		resultSummary.Text = ""
		setBattleLog({})
		context.Remotes.EnemyBugAttack:FireServer({ EnemyId = enemy.EnemyId })
		task.delay(6, function()
			if attacking and myNonce == attackNonce and popup and currentPopupEnemyId == enemy.EnemyId then
				attacking = false
				status.Text = "No response from server. Try again."
				setAttackEnabled(attack, true, "Attack")
			end
		end)
	end)

	local pending = pendingResultByEnemyId[enemy.EnemyId]
	if pending then
		pendingResultByEnemyId[enemy.EnemyId] = nil
		status.Text = pending.Success and "Result received." or friendlyFailure(tostring(pending.Reason))
	end
end

local function renderEnemy(enemy)
	clearEnemy()
	local world = context.UI.WorldLayer
	if not world then
		return
	end
	local root = Instance.new("ImageButton")
	root.Name = "EnemyBug_" .. enemy.EnemyId
	root.Size = UDim2.fromOffset(82, 82)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(enemy.Position.XScale, enemy.Position.YScale)
	root.BackgroundTransparency = 1
	root.Image = ""
	root.ZIndex = 12
	root.Parent = world

	local auraOuter = Instance.new("Frame")
	auraOuter.Size = UDim2.fromOffset(112, 112)
	auraOuter.AnchorPoint = Vector2.new(0.5, 0.5)
	auraOuter.Position = UDim2.fromScale(0.5, 0.5)
	auraOuter.BackgroundColor3 = Color3.fromRGB(120, 10, 10)
	auraOuter.BackgroundTransparency = 0.62
	auraOuter.ZIndex = 10
	auraOuter.Parent = root
	local outerCorner = Instance.new("UICorner")
	outerCorner.CornerRadius = UDim.new(1, 0)
	outerCorner.Parent = auraOuter

	local auraInner = Instance.new("Frame")
	auraInner.Size = UDim2.fromOffset(96, 96)
	auraInner.AnchorPoint = Vector2.new(0.5, 0.5)
	auraInner.Position = UDim2.fromScale(0.5, 0.5)
	auraInner.BackgroundColor3 = Color3.fromRGB(225, 24, 24)
	auraInner.BackgroundTransparency = 0.7
	auraInner.ZIndex = 11
	auraInner.Parent = root
	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(1, 0)
	innerCorner.Parent = auraInner

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(76, 76)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.46)
	icon.BackgroundTransparency = 1
	icon.Image = enemy.Icon or ""
	icon.ZIndex = 12
	icon.Parent = root

	local nameplate = Instance.new("TextLabel")
	nameplate.Size = UDim2.fromOffset(176, 24)
	nameplate.AnchorPoint = Vector2.new(0.5, 0)
	nameplate.Position = UDim2.new(0.5, 0, 1, 5)
	nameplate.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	nameplate.TextColor3 = Color3.fromRGB(255, 72, 72)
	nameplate.Font = Enum.Font.GothamBold
	nameplate.TextSize = 13
	nameplate.Text = enemy.DisplayName
	nameplate.TextTruncate = Enum.TextTruncate.AtEnd
	nameplate.ZIndex = 13
	nameplate.Parent = root
	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(1, 0)
	nc.Parent = nameplate
	local nstroke = Instance.new("UIStroke")
	nstroke.Thickness = 1
	nstroke.Color = Color3.fromRGB(150, 25, 25)
	nstroke.Transparency = 0.2
	nstroke.Parent = nameplate

	TweenService:Create(auraOuter, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.75 }):Play()
	TweenService:Create(auraInner, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.82 }):Play()

	root.MouseButton1Click:Connect(function()
		makePopup(enemy)
	end)
	enemyGui = root
end

function EnemySpawnController.Init(c)
	context = c
end

function EnemySpawnController.Start()
	context.Remotes.EnemyBugSpawned.OnClientEvent:Connect(function(enemy)
		activeEnemy = enemy
		renderEnemy(enemy)
	end)

	context.Remotes.EnemyBugDespawned.OnClientEvent:Connect(function(payload)
		if not activeEnemy or not payload or payload.EnemyId ~= activeEnemy.EnemyId then
			return
		end
		activeEnemy = nil
		clearEnemy()
		if popup and currentPopupEnemyId == payload.EnemyId then
			local status = popup:FindFirstChild("Status")
			if status and status:IsA("TextLabel") then
				if payload.Reason == "Expired" then
					status.Text = "Enemy escaped."
				elseif payload.Reason == "Defeated" then
					status.Text = "Enemy defeated."
				end
			end
			if payload.Reason == "Expired" and not attacking then
				task.delay(1.2, function()
					if popup and currentPopupEnemyId == payload.EnemyId then
						closePopup()
					end
				end)
			end
		end
	end)

	context.Remotes.EnemyBugAttackResult.OnClientEvent:Connect(function(result)
		print("[EnemySpawnController] Attack result", tostring(result and result.Success), tostring(result and result.Winner), tostring(result and result.Reason))
		local enemyId = result and result.EnemyId
		if enemyId then
			pendingResultByEnemyId[enemyId] = result
		end
		if not popup or not currentPopupEnemyId or not enemyId or currentPopupEnemyId ~= enemyId then
			attacking = false
			return
		end

		attacking = false
		local status = popup:FindFirstChild("Status")
		local summary = popup:FindFirstChild("ResultSummary")
		local attackButton = popup:FindFirstChild("AttackButton")
		local logFrame = popup:FindFirstChild("BattleLog")
		if not (status and status:IsA("TextLabel") and summary and summary:IsA("TextLabel") and attackButton and attackButton:IsA("TextButton") and logFrame and logFrame:IsA("ScrollingFrame")) then
			return
		end

		local function setLog(lines)
			for _, child in ipairs(logFrame:GetChildren()) do
				if child:IsA("TextLabel") then
					child:Destroy()
				end
			end
			local y = 0
			for i, line in ipairs(lines or {}) do
				local entry = Instance.new("TextLabel")
				entry.BackgroundTransparency = 1
				entry.Size = UDim2.new(1, -8, 0, 18)
				entry.TextXAlignment = Enum.TextXAlignment.Left
				entry.Text = string.format("%d. %s", i, tostring(line))
				entry.TextColor3 = Color3.fromRGB(215, 225, 245)
				entry.Font = Enum.Font.Code
				entry.TextSize = 13
				entry.ZIndex = 42
				entry.Parent = logFrame
				y += 22
			end
			logFrame.CanvasSize = UDim2.fromOffset(0, math.max(0, y))
		end

		if result.Success == false then
			status.Text = friendlyFailure(tostring(result.Reason))
			summary.Text = ""
			setAttackEnabled(attackButton, true, "Attack")
			setLog({})
			return
		end

		setLog(result.Log)
		summary.Text = string.format("Turns: %s | Player HP: %s | Enemy HP: %s", tostring(result.Turns or "?"), tostring(result.PlayerRemaining or "?"), tostring(result.EnemyRemaining or "?"))
		if result.Winner == "Player" then
			status.Text = string.format("Victory! +%d Essence, +%d Dust", (result.Rewards and result.Rewards.BugEssence) or 0, (result.Rewards and result.Rewards.BugDust) or 0)
			setAttackEnabled(attackButton, false, "Defeated")
		elseif result.Winner == "Enemy" then
			status.Text = "Defeat"
			setAttackEnabled(attackButton, true, "Retry")
		else
			status.Text = "Draw"
			setAttackEnabled(attackButton, true, "Retry")
		end
	end)
end

return EnemySpawnController
