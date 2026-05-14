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

local function clear() if bugRoot then bugRoot:Destroy(); bugRoot=nil end bugButton=nil; headerLabel=nil; activeId=nil; hitsRemaining=0 end
local function clearRewardScreen() if activeRewardGui then activeRewardGui:Destroy(); activeRewardGui=nil end end
local function updateHeader(displayName: string, rarity: string) if headerLabel then headerLabel.Text = string.format("%s [%s] Hits: %d", displayName, rarity, math.max(hitsRemaining, 0)) end end

local function getRarityStyle(rarity: string)
	local styles = {
		Common = {Accent=Color3.fromRGB(170,188,210), Glow=0.78, Sparkles=0, Pulse=2},
		Uncommon = {Accent=Color3.fromRGB(102,224,133), Glow=0.68, Sparkles=9, Pulse=2},
		Rare = {Accent=Color3.fromRGB(94,174,255), Glow=0.58, Sparkles=10, Pulse=2},
		Epic = {Accent=Color3.fromRGB(196,112,255), Glow=0.48, Sparkles=12, Pulse=3},
		Legendary = {Accent=Color3.fromRGB(255,188,74), Glow=0.38, Sparkles=16, Pulse=3},
		Mythic = {Accent=Color3.fromRGB(255,104,162), Glow=0.28, Sparkles=20, Pulse=3},
	}
	return styles[rarity] or styles.Common
end

local function getBugConfigFromPayload(payload)
	local bug = type(payload.Bug)=="table" and payload.Bug or {}
	local speciesId = bug.BugId or bug.SpeciesId or payload.SpeciesId
	if type(speciesId)=="string" then return BugConfig.GetBug(speciesId) or BugConfig.Bugs[speciesId] end
	local name = string.lower(tostring(payload.DisplayName or bug.Species or "")):gsub("%s+", "_")
	return BugConfig.Bugs[name]
end

local function createText(parent, text, size, font, color, pos, sx, sy)
	local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.TextStrokeTransparency=1; l.Text=text; l.TextSize=size; l.Font=font; l.TextColor3=color; l.Position=pos; l.Size=UDim2.new(1,-20,sy or 0,sx or 24); l.Parent=parent; return l
end
local function createBadge(parent,text,color,pos,width,height)
	local b=Instance.new("TextLabel"); b.BackgroundColor3=color; b.BackgroundTransparency=0.12; b.TextStrokeTransparency=1; b.Text=text; b.TextColor3=Color3.fromRGB(8,18,32); b.Font=Enum.Font.GothamBold; b.TextSize=13; b.Position=pos; b.Size=UDim2.fromOffset(width,height); b.Parent=parent; Instance.new("UICorner",b).CornerRadius=UDim.new(1,0); return b
end

local function playCatchSuccessBurst()
	if not bugButton or not bugRoot then return end
	local button = bugButton
	TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.fromOffset(98, 98), BackgroundTransparency = 0.2}):Play()
	for i = 1, 8 do
		local p = Instance.new("Frame")
		p.Size = UDim2.fromOffset(4, 4)
		p.Position = UDim2.new(button.Position.X.Scale, button.Position.X.Offset + 42, button.Position.Y.Scale, button.Position.Y.Offset + 42)
		p.BackgroundColor3 = Color3.fromRGB(255, 210, 105)
		p.BackgroundTransparency = 0.15
		p.BorderSizePixel = 0
		p.Parent = bugRoot
		Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
		local dx, dy = math.random(-45,45), math.random(-45,45)
		TweenService:Create(p, TweenInfo.new(0.24), {Position = UDim2.new(p.Position.X.Scale, p.Position.X.Offset+dx, p.Position.Y.Scale, p.Position.Y.Offset+dy), BackgroundTransparency = 1}):Play()
		task.delay(0.26, function() if p then p:Destroy() end end)
	end
	TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
end

local function showRewardScreen(payload)
	clearRewardScreen()
	local bug = type(payload.Bug)=="table" and payload.Bug or {}
	local cfg = getBugConfigFromPayload(payload) or {}
	local rarity = tostring(payload.Rarity or bug.Rarity or cfg.rarity or "Common")
	local style = getRarityStyle(rarity)
	local bonuses = type(payload.BonusStats)=="table" and payload.BonusStats or (type(bug.BonusStats)=="table" and bug.BonusStats or {})
	local overlay = Instance.new("Frame"); overlay.Size = UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.new(0,0,0); overlay.BackgroundTransparency=1; overlay.Parent=context.UI.WorldLayer; activeRewardGui=overlay
	local card = Instance.new("Frame"); card.AnchorPoint=Vector2.new(0.5,0.5); card.Size=UDim2.fromOffset(550,670); card.Position=UDim2.fromScale(0.5,0.5); card.BackgroundColor3=Color3.fromRGB(10,24,42); card.Parent=overlay; Instance.new("UICorner",card).CornerRadius=UDim.new(0,16)
	local glow = Instance.new("Frame"); glow.Size=UDim2.fromOffset(210,210); glow.Position=UDim2.new(0.5,-105,0,60); glow.BackgroundColor3=style.Accent; glow.BackgroundTransparency=style.Glow; glow.Parent=card; Instance.new("UICorner",glow).CornerRadius=UDim.new(1,0)
	local title = createText(card,"BUG CAUGHT!",30,Enum.Font.GothamBlack,Color3.fromRGB(240,247,255),UDim2.fromOffset(10,14),36,0); title.TextXAlignment=Enum.TextXAlignment.Center
	local points = createText(card,string.format("Bug Points +%d", tonumber(payload.BugPointsAwarded) or 0),26,Enum.Font.GothamBlack,Color3.fromRGB(255,190,76),UDim2.fromOffset(24,564),32,0); points.TextXAlignment=Enum.TextXAlignment.Left
	local bonusLine = createText(card,"",15,Enum.Font.GothamSemibold,Color3.fromRGB(145,224,255),UDim2.fromOffset(24,596),20,0); bonusLine.TextXAlignment=Enum.TextXAlignment.Left; bonusLine.Visible=false
	local breakdown = type(payload.BugPointBreakdown)=="table" and payload.BugPointBreakdown or {}
	local hasGreatOrPerfect = false
	for _, entry in ipairs(breakdown) do local q=tostring(entry.RollQuality or ""); if q=="Great" or q=="Perfect" then hasGreatOrPerfect=true end end
	local rollBonus = tonumber(payload.BugPointRollBonus) or 0
	if rollBonus > 0 then bonusLine.Text = string.format("Includes +%d from stat rolls", rollBonus); bonusLine.Visible = true end
	if hasGreatOrPerfect and bonusLine.Visible then bonusLine.Text = bonusLine.Text .. "  High-roll bonus!" end

	local bonusHeader = createText(card, "BONUS STATS", 15, Enum.Font.GothamBold, Color3.fromRGB(91,233,244), UDim2.fromOffset(24, 388), 20, 0)
	bonusHeader.TextXAlignment = Enum.TextXAlignment.Left
	local bonusContainer = Instance.new("Frame"); bonusContainer.BackgroundTransparency=1; bonusContainer.Position=UDim2.fromOffset(24,416); bonusContainer.Size=UDim2.new(1,-48,0,0); bonusContainer.AutomaticSize=Enum.AutomaticSize.Y; bonusContainer.Parent=card
	local list = Instance.new("UIListLayout"); list.FillDirection=Enum.FillDirection.Vertical; list.Padding=UDim.new(0,6); list.Parent=bonusContainer
	for _, b in ipairs(bonuses) do
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,40); row.BackgroundColor3=Color3.fromRGB(24,44,44); row.BackgroundTransparency=0.1; row.BorderSizePixel=0; row.ClipsDescendants=true; row.Parent=bonusContainer; Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
		local txt=Instance.new("TextLabel"); txt.BackgroundTransparency=1; txt.TextStrokeTransparency=1; txt.Size=UDim2.new(1,-96,1,0); txt.Position=UDim2.fromOffset(12,0); txt.TextXAlignment=Enum.TextXAlignment.Left; txt.TextYAlignment=Enum.TextYAlignment.Center; txt.TextWrapped=false; txt.TextColor3=Color3.fromRGB(232,245,252); txt.Font=Enum.Font.GothamSemibold; txt.TextSize=14; txt.Text=BugBonusConfig.FormatBonus(b); txt.Parent=row
		local q=tostring(b.RollQuality or "Normal")
		if q=="Good" or q=="Great" or q=="Perfect" then
			local qc=(q=="Good" and Color3.fromRGB(100,228,240)) or (q=="Great" and Color3.fromRGB(161,138,255)) or Color3.fromRGB(255,194,112)
			createBadge(row, q == "Great" and "GREAT ROLL" or q, qc, UDim2.new(1,-84,0.5,-11),72,22)
		end
	end

	local function closeReward() if activeRewardGui == overlay then clearRewardScreen() end end
	local viewButton = Instance.new("TextButton"); viewButton.Size=UDim2.fromOffset(220,42); viewButton.Position=UDim2.new(0.5,-236,1,-58); viewButton.Text="View Bug"; viewButton.Parent=card
	local continueButton = Instance.new("TextButton"); continueButton.Size=UDim2.fromOffset(220,42); continueButton.Position=UDim2.new(0.5,16,1,-58); continueButton.Text="Continue"; continueButton.Parent=card
	for _, b in ipairs({viewButton, continueButton}) do b.TextStrokeTransparency=1; b.Visible=false; b.Active=false; b.AutoButtonColor=false end
	continueButton.Activated:Connect(closeReward)
	viewButton.Activated:Connect(function() closeReward(); if context.Controllers and context.Controllers.Window and context.Controllers.Window.Open then context.Controllers.Window.Open("Bugs") end end)

	TweenService:Create(points, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 30}):Play()
	task.delay(0.2, function() if activeRewardGui == overlay then TweenService:Create(points, TweenInfo.new(0.16), {TextSize = 26}):Play() end end)
	local sparkleCount = style.Sparkles
	for i=1,sparkleCount do
		task.delay(i*0.04, function()
			if activeRewardGui ~= overlay then return end
			local s=Instance.new("Frame"); s.Size=UDim2.fromOffset(math.random(5,9), math.random(5,9)); s.BackgroundColor3=style.Accent; s.BackgroundTransparency=0.2; s.BorderSizePixel=0; s.Position=UDim2.new(0.5, math.random(-24,24), 0, 165+math.random(-24,24)); s.Parent=card; Instance.new("UICorner",s).CornerRadius=UDim.new(1,0)
			local dur=math.random(14,22)/10
			TweenService:Create(s, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=UDim2.new(0.5, math.random(-170,170), 0, 175+math.random(-120,170)), BackgroundTransparency=1}):Play()
			task.delay(dur + 0.05, function() if s then s:Destroy() end end)
		end)
	end
	task.spawn(function()
		for _=1,style.Pulse do
			if activeRewardGui ~= overlay then return end
			TweenService:Create(glow, TweenInfo.new(0.3), {Size=UDim2.fromOffset(230,230), Position=UDim2.new(0.5,-115,0,50), BackgroundTransparency=math.max(0.12, style.Glow-0.12)}):Play()
			task.wait(0.3)
			if activeRewardGui ~= overlay then return end
			TweenService:Create(glow, TweenInfo.new(0.3), {Size=UDim2.fromOffset(210,210), Position=UDim2.new(0.5,-105,0,60), BackgroundTransparency=style.Glow}):Play()
			task.wait(0.3)
		end
	end)
	task.delay(1.75, function() if activeRewardGui == overlay then viewButton.Visible=true; continueButton.Visible=true; viewButton.Active=true; continueButton.Active=true end end)
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
	context.Remotes.BugCaptured.OnClientEvent:Connect(function(payload) if bugButton and bugRoot then playCatchSuccessBurst(); task.delay(0.3, function() clear(); if type(payload)=="table" then showRewardScreen(payload) end end) else clear(); if type(payload)=="table" then showRewardScreen(payload) end end end)
	context.Remotes.BugEscaped.OnClientEvent:Connect(function(payload) if type(payload)=="table" and context.Controllers.Notification then context.Controllers.Notification.Show(string.format("%s escaped", payload.DisplayName or "Bug"), "Warning") end clear() end)
end
return BugMinigameController
