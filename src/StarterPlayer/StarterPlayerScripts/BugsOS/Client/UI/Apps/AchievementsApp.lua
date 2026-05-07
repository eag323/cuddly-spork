--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local AchievementConfig = require(Shared:WaitForChild("Config"):WaitForChild("AchievementConfig"))
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))

local AchievementsApp = {}
local windowRef, root, summaryLabel, claimableLabel, collectAllButton, listFrame, stateChangedConn

local function getProgress(data, statId)
	local stats = if type(data.Stats) == "table" then data.Stats else {}
	local value = stats[statId]
	return if type(value) == "number" then value else 0
end

local function rewardText(reward)
	if reward.Type == "Title" or reward.Type == "Item" then return tostring(reward.Value) end
	return string.format("%s %s", NumberUtil.FormatNumber(reward.Amount or 0), reward.Type)
end

local function refresh(context)
	local playerData = context.State.PlayerData or {}
	local claimed = ((playerData.Achievements or {}).Claimed) or {}
	for _, child in ipairs(listFrame:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
	local completed, claimable, total = 0, 0, #AchievementConfig.Definitions
	for _, def in ipairs(AchievementConfig.Definitions) do
		local progress = getProgress(playerData, def.stat)
		local isCompleted = progress >= def.required
		local isClaimed = claimed[def.id] == true
		if isCompleted then completed += 1 end
		if isCompleted and not isClaimed then claimable += 1 end
		local row = Instance.new("Frame"); row.Size=UDim2.new(1,-10,0,72); row.BackgroundColor3= isClaimed and Color3.fromRGB(30,70,42) or (isCompleted and Color3.fromRGB(39,90,50) or Color3.fromRGB(34,34,40)); row.BorderSizePixel=0; row.Parent=listFrame
		local name = Instance.new("TextLabel"); name.Size=UDim2.new(0.45,0,0,22); name.Position=UDim2.fromOffset(8,6); name.BackgroundTransparency=1; name.TextXAlignment=Enum.TextXAlignment.Left; name.TextColor3=Color3.new(1,1,1); name.Text=def.name; name.Parent=row
		local obj=Instance.new("TextLabel"); obj.Size=UDim2.new(0.45,0,0,18); obj.Position=UDim2.fromOffset(8,28); obj.BackgroundTransparency=1; obj.TextXAlignment=Enum.TextXAlignment.Left; obj.TextColor3=Color3.fromRGB(190,190,190); obj.TextSize=13; obj.Text=def.description; obj.Parent=row
		local rw=Instance.new("TextLabel"); rw.Size=UDim2.new(0,170,0,20); rw.Position=UDim2.new(1,-178,0,8); rw.BackgroundTransparency=1; rw.TextXAlignment=Enum.TextXAlignment.Right; rw.Text='Reward: '..rewardText(def.reward); rw.TextColor3=Color3.fromRGB(236,208,121); rw.TextSize=13; rw.Parent=row
		if not isCompleted then local bar=Instance.new('Frame'); bar.Size=UDim2.new(0.4,0,0,8); bar.Position=UDim2.fromOffset(8,52); bar.BackgroundColor3=Color3.fromRGB(50,50,58); bar.BorderSizePixel=0; bar.Parent=row; local fill=Instance.new('Frame'); fill.Size=UDim2.fromScale(math.clamp(progress/def.required,0,1),1); fill.BackgroundColor3=Color3.fromRGB(102,173,255); fill.BorderSizePixel=0; fill.Parent=bar end
		if isCompleted and not isClaimed then local b=Instance.new('TextButton'); b.Size=UDim2.fromOffset(90,28); b.Position=UDim2.new(1,-100,0.5,-14); b.Text='Claim'; b.Parent=row; b.Activated:Connect(function() context.Remotes.AchievementClaim:FireServer({AchievementId=def.id}) end) end
	end
	summaryLabel.Text = string.format("Completed %d / %d", completed, total)
	claimableLabel.Text = string.format("Claimable rewards: %d", claimable)
	collectAllButton.Visible = claimable > 1
	collectAllButton.Text = string.format("Collect All (%d)", claimable)
	local layout = listFrame:FindFirstChildOfClass("UIListLayout")
	if layout then listFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 10) end
end

function AchievementsApp.Mount(target, context)
	if root then return end
	windowRef = Window.Create({Title="Achievements.exe", Size=UDim2.fromOffset(760,520), Position=UDim2.fromScale(0.13,0.1), Parent=target, OnClose=function() context.Controllers.Window.Close("Achievements") end})
	root = Instance.new("Frame"); root.Size = UDim2.fromScale(1,1); root.BackgroundTransparency=1; root.Parent=windowRef.Content
	summaryLabel = Instance.new("TextLabel"); summaryLabel.Size=UDim2.new(0.3,0,0,24); summaryLabel.Position=UDim2.fromOffset(8,8); summaryLabel.BackgroundTransparency=1; summaryLabel.TextXAlignment=Enum.TextXAlignment.Left; summaryLabel.TextColor3=Color3.new(1,1,1); summaryLabel.Parent=root
	claimableLabel = Instance.new("TextLabel"); claimableLabel.Size=UDim2.new(0.3,0,0,24); claimableLabel.Position=UDim2.fromOffset(230,8); claimableLabel.BackgroundTransparency=1; claimableLabel.TextXAlignment=Enum.TextXAlignment.Left; claimableLabel.TextColor3=Color3.fromRGB(185,227,255); claimableLabel.Parent=root
	collectAllButton = Instance.new("TextButton"); collectAllButton.Size=UDim2.fromOffset(160,30); collectAllButton.Position=UDim2.new(1,-170,0,6); collectAllButton.Text="Collect All"; collectAllButton.Visible=false; collectAllButton.Parent=root; collectAllButton.Activated:Connect(function() context.Remotes.AchievementClaim:FireServer({CollectAll=true}) end)
	listFrame = Instance.new("ScrollingFrame"); listFrame.Size=UDim2.new(1,-16,1,-52); listFrame.Position=UDim2.fromOffset(8,44); listFrame.BackgroundColor3=Color3.fromRGB(24,24,30); listFrame.BorderSizePixel=0; listFrame.ScrollBarThickness=8; listFrame.Parent=root
	local ll=Instance.new("UIListLayout"); ll.Padding=UDim.new(0,6); ll.Parent=listFrame
	stateChangedConn = context.Events.StateChanged.Event:Connect(function() refresh(context) end)
	refresh(context)
end

function AchievementsApp.Unmount()
	if stateChangedConn then stateChangedConn:Disconnect() end
	stateChangedConn=nil
	if windowRef then windowRef.Destroy() end
	windowRef=nil; root=nil
end

return AchievementsApp
