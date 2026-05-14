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
		Common = {Accent=Color3.fromRGB(170,188,210), Glow=0.78, Sparkles=2, Pulse=2},
		Uncommon = {Accent=Color3.fromRGB(102,224,133), Glow=0.68, Sparkles=8, Pulse=2},
		Rare = {Accent=Color3.fromRGB(94,174,255), Glow=0.58, Sparkles=10, Pulse=2},
		Epic = {Accent=Color3.fromRGB(196,112,255), Glow=0.48, Sparkles=14, Pulse=3},
		Legendary = {Accent=Color3.fromRGB(255,188,74), Glow=0.38, Sparkles=18, Pulse=3},
		Mythic = {Accent=Color3.fromRGB(255,104,162), Glow=0.28, Sparkles=24, Pulse=3},
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

local function getBonusStatEmoji(statName: string)
	local map = {
		["All Earnings"] = "💸", ["Food/sec"] = "🍽️", ["Click Power"] = "💰", ["Sell Bonus"] = "🪙", ["Bug Luck"] = "🍀",
		["Nectar Chance"] = "🍯", ["Bug Spawn Rate"] = "🐞", ["Minigame Time"] = "⏱️", ["Expedition Speed"] = "🧭",
		["Equipment Drop Rate"] = "🎒", ["Bug Essence Gain"] = "🧪", ["Bug Damage"] = "⚔️", ["Bug HP"] = "❤️", ["Boss Damage"] = "👑",
	}
	return map[statName] or "✨"
end

local function createQualityBadge(parent: Instance, quality: string)
	if quality ~= "Good" and quality ~= "Great" and quality ~= "Perfect" then return end
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(84, 24)
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, -10, 0.5, 0)
	badge.BackgroundColor3 = (quality == "Good" and Color3.fromRGB(96, 235, 248)) or (quality == "Great" and Color3.fromRGB(168, 128, 255)) or Color3.fromRGB(255, 209, 110)
	badge.TextColor3 = Color3.fromRGB(10, 24, 38)
	badge.Text = quality
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 12
	badge.Parent = parent
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke", badge)
	stroke.Color = Color3.fromRGB(245, 250, 255)
	stroke.Transparency = 0.35
	stroke.Thickness = 1
end

local function createBonusStatRow(parent: Instance, bonusData)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.BackgroundColor3 = Color3.fromRGB(16, 55, 67)
	row.BorderSizePixel = 0
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 11)
	local gradient = Instance.new("UIGradient", row)
	gradient.Color = ColorSequence.new(Color3.fromRGB(23, 72, 78), Color3.fromRGB(20, 46, 66))
	gradient.Rotation = 90
	local border = Instance.new("UIStroke", row)
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Thickness = 1.6
	border.Color = Color3.fromRGB(96, 225, 233)
	
	local statName = tostring(bonusData.DisplayName or "Bonus")
	local emoji = getBonusStatEmoji(statName)
	local valueText = BugBonusConfig.FormatBonus and BugBonusConfig.FormatBonus(bonusData) or string.format("+%d%% %s", math.floor(((tonumber(bonusData.Value) or 0) * 100) + 0.5), statName)
	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, -108, 1, 0)
	txt.Position = UDim2.fromOffset(12, 0)
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextColor3 = Color3.fromRGB(236, 248, 255)
	txt.Font = Enum.Font.GothamSemibold
	txt.TextSize = 14
	txt.Text = string.format("%s %s", emoji, valueText)
	txt.Parent = row

	createQualityBadge(row, tostring(bonusData.RollQuality or "Normal"))
	return row
end

local function createRewardButton(parent, text, color, outlineColor, textColor)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.5, -9, 1, 0)
	b.BackgroundColor3 = color
	b.AutoButtonColor = false
	b.Text = text
	b.TextColor3 = textColor or Color3.fromRGB(240, 250, 255)
	b.TextStrokeTransparency = 1
	b.TextSize = 18
	b.Font = Enum.Font.GothamBold
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 13)
	local stroke = Instance.new("UIStroke", b)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = outlineColor
	stroke.Thickness = 2
	local normal = color
	b.MouseEnter:Connect(function() b.BackgroundColor3 = normal:Lerp(Color3.new(1, 1, 1), 0.12) end)
	b.MouseLeave:Connect(function() b.BackgroundColor3 = normal end)
	b.MouseButton1Down:Connect(function() b.Size = UDim2.new(0.5, -11, 1, -2) end)
	b.MouseButton1Up:Connect(function() b.Size = UDim2.new(0.5, -9, 1, 0) end)
	return b
end

local function playCatchSuccessBurst()
	if not bugButton or not bugRoot then return end
	local button = bugButton
	TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.fromOffset(98, 98), BackgroundTransparency = 0.2}):Play()
	for _ = 1, 8 do
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
	local overlay = Instance.new("Frame"); overlay.Size = UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.new(0,0,0); overlay.BackgroundTransparency=0.35; overlay.Parent=context.UI.WorldLayer; activeRewardGui=overlay

	local card = Instance.new("Frame"); card.AnchorPoint=Vector2.new(0.5,0.5); card.Size=UDim2.fromOffset(560,690); card.Position=UDim2.fromScale(0.5,0.5); card.BackgroundColor3=Color3.fromRGB(9,22,45); card.Parent=overlay; card.ClipsDescendants=true
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,16)
	local cStroke = Instance.new("UIStroke", card); cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; cStroke.Thickness = (rarity=="Epic" or rarity=="Legendary" or rarity=="Mythic") and 2.8 or 2.2; cStroke.Color = style.Accent
	local pad = Instance.new("UIPadding", card); pad.PaddingTop=UDim.new(0,20); pad.PaddingBottom=UDim.new(0,16); pad.PaddingLeft=UDim.new(0,20); pad.PaddingRight=UDim.new(0,20)
	local rootLayout = Instance.new("UIListLayout", card); rootLayout.FillDirection=Enum.FillDirection.Vertical; rootLayout.Padding=UDim.new(0,8); rootLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center

	local title = Instance.new("TextLabel"); title.Size=UDim2.new(1,0,0,36); title.BackgroundTransparency=1; title.Text="BUG CAUGHT!"; title.Font=Enum.Font.GothamBlack; title.TextSize=32; title.TextColor3=Color3.fromRGB(240,247,255); title.Parent=card

	local revealSection = Instance.new("Frame"); revealSection.Size=UDim2.new(1,0,0,238); revealSection.BackgroundTransparency=1; revealSection.Parent=card
	local revealPadding = Instance.new("UIPadding", revealSection); revealPadding.PaddingTop=UDim.new(0,16)
	local revealLayout = Instance.new("UIListLayout", revealSection); revealLayout.FillDirection=Enum.FillDirection.Vertical; revealLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; revealLayout.VerticalAlignment=Enum.VerticalAlignment.Top

	local iconSection = Instance.new("Frame"); iconSection.Size=UDim2.new(0,260,0,206); iconSection.BackgroundTransparency=1; iconSection.ClipsDescendants=true; iconSection.Parent=revealSection
	local glow = Instance.new("Frame"); glow.Size=UDim2.fromOffset(194,194); glow.AnchorPoint=Vector2.new(0.5,0.5); glow.Position=UDim2.fromScale(0.5,0.5); glow.BackgroundColor3=style.Accent; glow.BackgroundTransparency=style.Glow; glow.Parent=iconSection; Instance.new("UICorner",glow).CornerRadius=UDim.new(1,0)
	local ring = Instance.new("Frame"); ring.Size=UDim2.fromOffset(226,226); ring.AnchorPoint=Vector2.new(0.5,0.5); ring.Position=UDim2.fromScale(0.5,0.5); ring.BackgroundTransparency=1; ring.Parent=iconSection
	local ringStroke = Instance.new("UIStroke", ring); ringStroke.Color=style.Accent; ringStroke.Thickness=2; ringStroke.Transparency=0.45
	Instance.new("UICorner",ring).CornerRadius=UDim.new(1,0)
	local icon = bug.icon or bug.Icon or cfg.icon or cfg.Icon or cfg.sprite or cfg.Sprite or "rbxasset://textures/ui/GuiImagePlaceholder.png"
	local bugImage = Instance.new("ImageLabel"); bugImage.Size=UDim2.fromOffset(136,136); bugImage.AnchorPoint=Vector2.new(0.5,0.5); bugImage.Position=UDim2.fromScale(0.5,0.5); bugImage.BackgroundTransparency=1; bugImage.ScaleType=Enum.ScaleType.Fit; bugImage.Image=tostring(icon); bugImage.ZIndex=3; bugImage.Parent=iconSection

	local identity = Instance.new("Frame"); identity.Size=UDim2.new(1,0,0,142); identity.BackgroundTransparency=1; identity.Parent=card
	local idLayout = Instance.new("UIListLayout", identity); idLayout.FillDirection=Enum.FillDirection.Vertical; idLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; idLayout.Padding=UDim.new(0,5)
	local bugName = Instance.new("TextLabel"); bugName.Size=UDim2.new(1,0,0,34); bugName.BackgroundTransparency=1; bugName.Font=Enum.Font.GothamBlack; bugName.TextSize=30; bugName.TextColor3=Color3.fromRGB(240,247,255); bugName.Text=tostring(payload.DisplayName or bug.DisplayName or cfg.displayName or cfg.species or "Unknown Bug"); bugName.TextTransparency=1; bugName.Parent=identity
	local rarityBadge = Instance.new("TextLabel"); rarityBadge.Size=UDim2.fromOffset(150,28); rarityBadge.BackgroundColor3=style.Accent; rarityBadge.BackgroundTransparency=1; rarityBadge.Text=tostring(rarity):upper(); rarityBadge.TextColor3=Color3.fromRGB(10,24,42); rarityBadge.TextTransparency=1; rarityBadge.TextSize=14; rarityBadge.Font=Enum.Font.GothamBold; rarityBadge.Parent=identity; Instance.new("UICorner",rarityBadge).CornerRadius=UDim.new(1,0)
	local roleSpecies = Instance.new("TextLabel"); roleSpecies.Size=UDim2.new(1,0,0,24); roleSpecies.BackgroundTransparency=1; roleSpecies.TextColor3=Color3.fromRGB(176,208,231); roleSpecies.TextSize=16; roleSpecies.Font=Enum.Font.GothamMedium; roleSpecies.Text=(cfg.role or bug.Role or "") .. ((cfg.role or bug.Role) and (cfg.species or bug.Species) and " • " or "") .. (cfg.species or bug.Species or ""); roleSpecies.Visible=roleSpecies.Text ~= ""; roleSpecies.Parent=identity
	if payload.WasNewDiscovery == true then
		local discovery = Instance.new("TextLabel"); discovery.Size=UDim2.fromOffset(280,26); discovery.BackgroundColor3=Color3.fromRGB(76,240,214); discovery.BackgroundTransparency=0.1; discovery.Text="NEW DISCOVERY! Added to Bugdex"; discovery.TextColor3=Color3.fromRGB(7,27,35); discovery.TextSize=13; discovery.Font=Enum.Font.GothamBold; discovery.Parent=identity; Instance.new("UICorner",discovery).CornerRadius=UDim.new(1,0)
		task.spawn(function() while activeRewardGui == overlay and discovery.Parent do TweenService:Create(discovery, TweenInfo.new(0.45), {BackgroundTransparency=0.0}):Play(); task.wait(0.45); TweenService:Create(discovery, TweenInfo.new(0.45), {BackgroundTransparency=0.18}):Play(); task.wait(0.45) end end)
	end

	local bonusSection = Instance.new("Frame"); bonusSection.Size=UDim2.new(1,0,0,180); bonusSection.BackgroundTransparency=1; bonusSection.Parent=card
	local bLay=Instance.new("UIListLayout", bonusSection); bLay.FillDirection=Enum.FillDirection.Vertical; bLay.Padding=UDim.new(0,4)
	local bonusHeader = Instance.new("TextLabel"); bonusHeader.Size=UDim2.new(1,0,0,22); bonusHeader.BackgroundTransparency=1; bonusHeader.Text="BONUS STATS"; bonusHeader.Font=Enum.Font.GothamBold; bonusHeader.TextSize=15; bonusHeader.TextColor3=Color3.fromRGB(91,233,244); bonusHeader.TextXAlignment=Enum.TextXAlignment.Left; bonusHeader.Parent=bonusSection
	local bonusRows = Instance.new("Frame"); bonusRows.Size=UDim2.new(1,0,1,-28); bonusRows.BackgroundTransparency=1; bonusRows.Parent=bonusSection
	local rowList=Instance.new("UIListLayout", bonusRows); rowList.FillDirection=Enum.FillDirection.Vertical; rowList.Padding=UDim.new(0,6)
	if #bonuses == 0 then
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,40); row.BackgroundColor3=Color3.fromRGB(20,34,53); row.Parent=bonusRows; Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
		local txt=Instance.new("TextLabel"); txt.Size=UDim2.new(1,0,1,0); txt.BackgroundTransparency=1; txt.Text="No bonus stats rolled"; txt.TextColor3=Color3.fromRGB(162,187,204); txt.Font=Enum.Font.GothamMedium; txt.TextSize=14; txt.Parent=row
	else
		for _, b in ipairs(bonuses) do
			createBonusStatRow(bonusRows, b)
		end
	end

	local pointsSection = Instance.new("Frame"); pointsSection.Size=UDim2.new(1,0,0,84); pointsSection.BackgroundTransparency=1; pointsSection.Parent=card
	local pLay=Instance.new("UIListLayout", pointsSection); pLay.FillDirection=Enum.FillDirection.Vertical; pLay.HorizontalAlignment=Enum.HorizontalAlignment.Center
	local points = Instance.new("TextLabel"); points.Size=UDim2.new(1,0,0,34); points.BackgroundTransparency=1; points.Text=string.format("Bug Points +%d", tonumber(payload.BugPointsAwarded) or 0); points.Font=Enum.Font.GothamBlack; points.TextSize=28; points.TextColor3=Color3.fromRGB(255,190,76); points.Parent=pointsSection
	local line = Instance.new("Frame"); line.Size=UDim2.fromOffset(200,3); line.BackgroundColor3=Color3.fromRGB(255,196,96); line.BorderSizePixel=0; line.Parent=pointsSection; Instance.new("UICorner", line).CornerRadius=UDim.new(1,0)
	local rollBonus = tonumber(payload.BugPointRollBonus) or 0
	local breakdown = type(payload.BugPointBreakdown)=="table" and payload.BugPointBreakdown or {}
	local hasHigh = false for _, e in ipairs(breakdown) do local q=tostring(e.RollQuality or ""); if q=="Great" or q=="Perfect" then hasHigh=true end end
	local rollLabel = Instance.new("TextLabel"); rollLabel.Size=UDim2.new(1,0,0,22); rollLabel.BackgroundTransparency=1; rollLabel.TextColor3=Color3.fromRGB(145,224,255); rollLabel.Font=Enum.Font.GothamSemibold; rollLabel.TextSize=15; rollLabel.Visible=rollBonus>0; rollLabel.Text=(rollBonus>0) and string.format("Includes +%d from stat rolls%s", rollBonus, hasHigh and " • Excellent stat rolls!" or "") or ""; rollLabel.Parent=pointsSection

	local buttonRow = Instance.new("Frame"); buttonRow.Size=UDim2.new(1,0,0,48); buttonRow.BackgroundTransparency=1; buttonRow.Parent=card
	local btnLayout=Instance.new("UIListLayout", buttonRow); btnLayout.FillDirection=Enum.FillDirection.Horizontal; btnLayout.Padding=UDim.new(0,16)
	local viewButton = createRewardButton(buttonRow, "View Bug", Color3.fromRGB(23,63,106), Color3.fromRGB(88,198,255))
	local continueButton = createRewardButton(buttonRow, "Continue", Color3.fromRGB(109,228,255), Color3.fromRGB(168,243,255), Color3.fromRGB(8,24,35))
	viewButton.Visible=false; continueButton.Visible=false; viewButton.Active=false; continueButton.Active=false

	local function closeReward() if activeRewardGui == overlay then clearRewardScreen() end end
	continueButton.Activated:Connect(closeReward)
	viewButton.Activated:Connect(function()
		closeReward()
		local controllers = context and context.Controllers
		local wc = controllers and (controllers.WindowController or controllers.Window)
		if wc and wc.Open then wc.Open("Bugs") return end
		if wc and wc.OpenApp then wc.OpenApp("Bugs") return end
	end)

	for i=1,style.Sparkles do
		task.delay(i*0.045, function()
			if activeRewardGui ~= overlay then return end
			local big = (rarity=="Epic" or rarity=="Legendary" or rarity=="Mythic") and (math.random()<0.25)
			local size = big and math.random(11,16) or math.random(6,10)
			local s=Instance.new("Frame"); s.Size=UDim2.fromOffset(size, size); s.BackgroundColor3=style.Accent; s.BackgroundTransparency=0.15; s.BorderSizePixel=0; s.AnchorPoint=Vector2.new(0.5,0.5); s.Position=UDim2.new(0.5, math.random(-22,22), 0.5, math.random(-22,22)); s.Parent=iconSection; s.ZIndex=4; Instance.new("UICorner",s).CornerRadius=UDim.new(1,0)
			local dur=math.random(16,24)/10
			TweenService:Create(s, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=UDim2.new(0.5, math.random(-150,150), 0.5, math.random(-120,120)), BackgroundTransparency=1}):Play()
			task.delay(dur + 0.05, function() if s then s:Destroy() end end)
		end)
	end
	task.spawn(function()
		TweenService:Create(bugImage, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.fromOffset(174,174)}):Play()
		TweenService:Create(bugName, TweenInfo.new(0.22), {TextTransparency=0}):Play()
		TweenService:Create(rarityBadge, TweenInfo.new(0.22), {TextTransparency=0, BackgroundTransparency=0.05}):Play()
		for _=1,style.Pulse do
			if activeRewardGui ~= overlay then return end
			TweenService:Create(glow, TweenInfo.new(0.32), {Size=UDim2.fromOffset(208,208), BackgroundTransparency=math.max(0.08, style.Glow-0.16)}):Play()
			TweenService:Create(ringStroke, TweenInfo.new(0.32), {Transparency=0.2}):Play()
			task.wait(0.34)
			if activeRewardGui ~= overlay then return end
			TweenService:Create(glow, TweenInfo.new(0.32), {Size=UDim2.fromOffset(194,194), BackgroundTransparency=style.Glow}):Play()
			TweenService:Create(ringStroke, TweenInfo.new(0.32), {Transparency=0.45}):Play()
			task.wait(0.34)
		end
	end)
	task.delay(1.65, function() if activeRewardGui == overlay then viewButton.Visible=true; continueButton.Visible=true; viewButton.Active=true; continueButton.Active=true end end)
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
