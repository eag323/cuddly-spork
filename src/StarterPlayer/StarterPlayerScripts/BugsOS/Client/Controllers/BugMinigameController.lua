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
local awardOverlay: Frame?

local function clear()
	if bugRoot then bugRoot:Destroy(); bugRoot=nil end
	bugButton=nil; headerLabel=nil; activeId=nil; hitsRemaining=0
end

local function closeAward()
	if awardOverlay then awardOverlay:Destroy(); awardOverlay=nil end
end

local function updateHeader(displayName: string, rarity: string)
	if headerLabel then headerLabel.Text = string.format("%s [%s] Hits: %d", displayName, rarity, math.max(hitsRemaining, 0)) end
end

local function formatBonus(bonus)
	local line = BugBonusConfig.FormatBonus(bonus)
	local quality = tostring(bonus.RollQuality or "")
	if quality == "Good" or quality == "Great" or quality == "Perfect" then return line .. " [" .. quality .. "]" end
	return line
end

local function showAward(payload)
	closeAward()
	local bug = type(payload.Bug)=="table" and payload.Bug or {}
	local speciesId = bug.BugId or bug.SpeciesId or payload.SpeciesId
	local cfg = (type(speciesId)=="string" and (BugConfig.GetBug(speciesId) or BugConfig.Bugs[speciesId])) or nil
	local overlay = Instance.new("Frame"); overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.new(0,0,0); overlay.BackgroundTransparency=0.35; overlay.Parent=context.UI.WorldLayer; awardOverlay=overlay
	local card = Instance.new("Frame"); card.Size=UDim2.fromOffset(430,460); card.Position=UDim2.fromScale(0.5,0.5)-UDim2.fromOffset(215,230); card.BackgroundColor3=Color3.fromRGB(12,27,45); card.BorderSizePixel=0; card.Parent=overlay; Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	local rarity = tostring(payload.Rarity or bug.Rarity or (cfg and cfg.rarity) or "Common")
	local rcolor = ({Common=Color3.fromRGB(190,193,203),Uncommon=Color3.fromRGB(108,216,136),Rare=Color3.fromRGB(92,176,255),Epic=Color3.fromRGB(188,107,255),Legendary=Color3.fromRGB(255,183,75),Mythic=Color3.fromRGB(255,106,174)})[rarity] or Color3.new(1,1,1)
	local stroke=Instance.new("UIStroke"); stroke.Color=rcolor; stroke.Thickness=2; stroke.Transparency=0.1; stroke.Parent=card
	local title=Instance.new("TextLabel"); title.BackgroundTransparency=1; title.Size=UDim2.new(1,0,0,34); title.Position=UDim2.fromOffset(0,14); title.Font=Enum.Font.GothamBold; title.TextSize=28; title.TextColor3=Color3.fromRGB(242,248,255); title.Text="BUG CAUGHT!"; title.Parent=card
	local icon=Instance.new("ImageLabel"); icon.BackgroundTransparency=1; icon.Size=UDim2.fromOffset(120,120); icon.Position=UDim2.new(0.5,-60,0,56); icon.Image=tostring((cfg and cfg.icon) or ""); icon.Parent=card
	if icon.Image=="" then local e=Instance.new("TextLabel"); e.BackgroundTransparency=1; e.Size=UDim2.fromScale(1,1); e.Text="🐞"; e.TextScaled=true; e.Parent=icon end
	local nm=Instance.new("TextLabel"); nm.BackgroundTransparency=1; nm.Size=UDim2.new(1,-20,0,30); nm.Position=UDim2.fromOffset(10,182); nm.Font=Enum.Font.GothamBold; nm.TextSize=24; nm.Text=tostring(payload.DisplayName or bug.Species or (cfg and cfg.displayName) or "Unknown Bug"); nm.TextColor3=Color3.fromRGB(242,248,255); nm.Parent=card
	local rb=Instance.new("TextLabel"); rb.BackgroundColor3=rcolor; rb.Size=UDim2.fromOffset(110,24); rb.Position=UDim2.new(0.5,-55,0,216); rb.Text=rarity; rb.Font=Enum.Font.GothamBold; rb.TextSize=13; rb.TextColor3=Color3.fromRGB(8,18,30); rb.Parent=card; Instance.new("UICorner",rb).CornerRadius=UDim.new(1,0)
	if payload.WasNewDiscovery == true then local nd=Instance.new("TextLabel"); nd.BackgroundColor3=Color3.fromRGB(68,190,164); nd.Size=UDim2.fromOffset(140,22); nd.Position=UDim2.new(0.5,-70,0,246); nd.Text="NEW DISCOVERY"; nd.Font=Enum.Font.GothamBold; nd.TextSize=12; nd.TextColor3=Color3.fromRGB(8,24,20); nd.Parent=card; Instance.new("UICorner",nd).CornerRadius=UDim.new(1,0) end
	local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-30,0,20); lbl.Position=UDim2.fromOffset(15,276); lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=14; lbl.Text="BONUS STATS"; lbl.TextColor3=Color3.fromRGB(90,235,245); lbl.Parent=card
	local bonuses = payload.BonusStats or bug.BonusStats or {}
	local list=Instance.new("TextLabel"); list.BackgroundTransparency=1; list.Size=UDim2.new(1,-30,0,90); list.Position=UDim2.fromOffset(15,298); list.TextXAlignment=Enum.TextXAlignment.Left; list.TextYAlignment=Enum.TextYAlignment.Top; list.Font=Enum.Font.Gotham; list.TextSize=13; list.TextColor3=Color3.fromRGB(132,245,170); list.TextWrapped=true; list.Parent=card
	if type(bonuses)=="table" and #bonuses>0 then local lines={} for _,b in ipairs(bonuses) do table.insert(lines, formatBonus(b)) end list.Text=table.concat(lines,"\n") else list.Text="No bonus stats" end
	local points=Instance.new("TextLabel"); points.BackgroundTransparency=1; points.Size=UDim2.new(1,-30,0,24); points.Position=UDim2.fromOffset(15,388); points.Font=Enum.Font.GothamBold; points.TextSize=15; points.TextXAlignment=Enum.TextXAlignment.Left; points.Text=string.format("Bug Points: +%d", tonumber(payload.BugPointsAwarded) or 0); points.TextColor3=Color3.fromRGB(255,185,55); points.Parent=card
	local btn=Instance.new("TextButton"); btn.Size=UDim2.fromOffset(150,36); btn.Position=UDim2.new(0.5,-75,1,-48); btn.BackgroundColor3=Color3.fromRGB(90,235,245); btn.Text="Continue"; btn.Font=Enum.Font.GothamBold; btn.TextSize=14; btn.TextColor3=Color3.fromRGB(8,20,34); btn.Parent=card; Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
	btn.Activated:Connect(closeAward)
end

-- existing movement + start kept simple
local function hitFeedback(button) local up=TweenService:Create(button,TweenInfo.new(0.08),{Size=UDim2.fromOffset(92,92)}); local down=TweenService:Create(button,TweenInfo.new(0.1),{Size=UDim2.fromOffset(84,84)}); up.Completed:Once(function() down:Play() end); up:Play() end
local function startMovement(button, behavior) task.spawn(function() task.wait(0.5); while button.Parent do local pos=UDim2.fromScale(math.random(20,80)/100,math.random(20,75)/100); local d=1.6; if behavior=="ZigZagger" then d=1.0 end if behavior=="Dasher" then d=0.65 task.wait(0.5) end TweenService:Create(button,TweenInfo.new(d,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Position=pos}):Play(); task.wait(d) end end) end
function BugMinigameController.Init(c) context=c end
function BugMinigameController.Start()
	context.Remotes.BugSpawned.OnClientEvent:Connect(function(payload)
		clear(); closeAward(); activeId=payload.ActiveBugId; hitsRemaining=payload.HitsRequired
		local holder=Instance.new("Frame"); holder.Size=UDim2.fromScale(1,1); holder.BackgroundTransparency=1; holder.Parent=context.UI.WorldLayer; bugRoot=holder
		local label=Instance.new("TextLabel"); label.Size=UDim2.fromOffset(360,24); label.Position=UDim2.fromOffset(12,12); label.BackgroundTransparency=1; label.TextColor3=Color3.new(1,1,1); label.TextXAlignment=Enum.TextXAlignment.Left; label.Font=Enum.Font.GothamSemibold; label.TextSize=15; label.Parent=holder; headerLabel=label; updateHeader(payload.DisplayName,payload.Rarity)
		local bug=Instance.new("TextButton"); bug.Size=UDim2.fromOffset(84,84); bug.Position=UDim2.fromScale(0.5,0.5); bug.Text="🐞"; bug.TextScaled=true; bug.BackgroundColor3=Color3.fromRGB(80,40,40); bug.Parent=holder; Instance.new("UICorner",bug).CornerRadius=UDim.new(1,0); bugButton=bug
		bug.Activated:Connect(function() if not activeId then return end context.Remotes.BugAttemptCatch:FireServer({ActiveBugId=activeId}) end)
		startMovement(bug,payload.Behavior)
	end)
	context.Remotes.BugHitUpdate.OnClientEvent:Connect(function(payload) if type(payload)=="table" and payload.ActiveBugId==activeId then hitsRemaining=tonumber(payload.HitsRemaining) or hitsRemaining; if bugButton then hitFeedback(bugButton) end end end)
	context.Remotes.BugCaptured.OnClientEvent:Connect(function(payload) if type(payload)=="table" and context.Controllers.Notification then context.Controllers.Notification.Show(string.format("Caught %s %s", payload.Rarity or "Bug", payload.DisplayName or "Bug"), "Success") end clear(); if type(payload)=="table" then showAward(payload) end end)
	context.Remotes.BugEscaped.OnClientEvent:Connect(function(payload) if type(payload)=="table" and context.Controllers.Notification then context.Controllers.Notification.Show(string.format("%s escaped", payload.DisplayName or "Bug"), "Warning") end clear() end)
end
return BugMinigameController
