--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))

local BugFarmApp = {}
local windowRef
local root
local stateChangedConn
local equippedPanel
local equippedRowsFrame
local invLabel
local invScroll
local eql
local buffsPanel
local buffsLabel

local function fmtPrimary(primary)
	if type(primary) ~= "table" then return "No primary stat" end
	local value = tonumber(primary.Value) or 0
	return string.format("%s: %s%%", tostring(primary.Attribute or primary.Stat or "Stat"), NumberUtil.FormatNumber(value * 100))
end


local function totalBuffText(bugsData)
	local inv = bugsData.Inventory or {}
	local eq = bugsData.Equipped or {}
	local totals = { AllFood=0, FoodPerSec=0, ClickPower=0, SellBonus=0, BugLuck=0, MinigameSpawnChance=0, MinigameTime=0, NectarChance=0 }
	for _, uid in pairs(eq) do
		local bug = inv[uid]
		if type(bug) == "table" then
			local stats = { bug.Primary, table.unpack(bug.Secondaries or {}) }
			for _, st in ipairs(stats) do
				if type(st) == "table" and type(st.Value) == "number" then
					local key = st.Stat or st.Attribute
					if totals[key] ~= nil then totals[key] += st.Value end
				end
			end
		end
	end
	local rows = {}
	local map = {
		{"All Food","AllFood"},{"Food/sec","FoodPerSec"},{"Click Power","ClickPower"},{"Sell Bonus","SellBonus"},{"Bug Luck","BugLuck"},{"Spawn Chance","MinigameSpawnChance"},{"Minigame Time","MinigameTime"},{"Nectar Chance","NectarChance"},
	}
	for _, pair in ipairs(map) do
		local value = totals[pair[2]] or 0
		if value ~= 0 then table.insert(rows, string.format("%s: %s%%", pair[1], NumberUtil.FormatNumber(value * 100))) end
	end
	if #rows == 0 then return "Active Buffs: 0%" end
	return "Active Buffs\n" .. table.concat(rows, "\n")
end

local function refresh(context)
	if not root or not equippedRowsFrame or not invScroll then return end
	for _, child in ipairs(equippedRowsFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	invScroll:ClearAllChildren()
	local bugsData = ((context.State.PlayerData or {}).Bugs or {})
	local inv = bugsData.Inventory or {}
	local eq = bugsData.Equipped or {}
	local slotsUnlocked = tonumber(bugsData.SlotsUnlocked) or 5
	if buffsLabel then buffsLabel.Text = totalBuffText(bugsData) end
	if slotsUnlocked < 1 then slotsUnlocked = 1 end
	for i = 1, slotsUnlocked do
		local row = Instance.new("Frame"); row.Size=UDim2.new(1,0,0,58); row.BackgroundColor3=Color3.fromRGB(46,46,54); row.BorderSizePixel = 0; row.Parent=equippedRowsFrame
		local uid = eq[i]
		local bug = uid and inv[uid] or nil

		local title = Instance.new("TextLabel"); title.Size=UDim2.new(1,-118,0,24); title.Position=UDim2.fromOffset(8,4); title.BackgroundTransparency=1; title.TextXAlignment=Enum.TextXAlignment.Left; title.TextColor3=Color3.new(1,1,1); title.TextSize=16; title.Text = bug and string.format("Slot %d: %s [%s]", i, tostring(bug.Species or bug.SpeciesId or "Unknown"), tostring(bug.Rarity or "Common")) or string.format("Slot %d: Empty", i); title.Parent=row

		local primary = Instance.new("TextLabel"); primary.Size=UDim2.new(1,-118,0,22); primary.Position=UDim2.fromOffset(8,30); primary.BackgroundTransparency=1; primary.TextXAlignment=Enum.TextXAlignment.Left; primary.TextColor3=Color3.fromRGB(210,210,210); primary.TextSize=14; primary.Text = bug and fmtPrimary(bug.Primary) or "No bug equipped"; primary.Parent=row

		if bug then local b=Instance.new("TextButton"); b.Size=UDim2.new(0,92,0,28); b.Position=UDim2.new(1,-100,0.5,-14); b.Text="Unequip"; b.TextSize=14; b.Parent=row; b.Activated:Connect(function() context.Controllers.BugFarm.Unequip(i) end) end
	end
	local invLayout = Instance.new("UIListLayout"); invLayout.Padding = UDim.new(0, 6); invLayout.Parent = invScroll
	for uid, bug in pairs(inv) do
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,-8,0,82); row.BackgroundColor3=Color3.fromRGB(36,36,44); row.BorderSizePixel = 0; row.Parent=invScroll
		local label=Instance.new("TextLabel"); label.Size=UDim2.new(1,-8,0,38); label.Position=UDim2.fromOffset(8,6); label.BackgroundTransparency=1; label.TextXAlignment=Enum.TextXAlignment.Left; label.TextYAlignment=Enum.TextYAlignment.Top; label.TextWrapped=true; label.TextColor3=Color3.new(1,1,1); label.TextSize=15
		local isEquipped = false; for _,v in pairs(eq) do if v==uid then isEquipped=true break end end
		label.Text=string.format(
			"Bug: %s  |  Rarity: %s  |  %s\nEquipped: %s  |  Locked: %s",
			tostring(bug.Species or bug.SpeciesId or "Unknown"),
			tostring(bug.Rarity or "Common"),
			fmtPrimary(bug.Primary),
			tostring(isEquipped),
			tostring(bug.Locked == true)
		); label.Parent=row
		for i=1,(tonumber(bugsData.SlotsUnlocked) or 5) do
			local eb=Instance.new("TextButton"); eb.Size=UDim2.fromOffset(72,24); eb.Position=UDim2.fromOffset(8 + ((i-1) * 74), 50); eb.Text=string.format("Equip %d", i); eb.TextSize=12; eb.Parent=row; eb.Activated:Connect(function() context.Controllers.BugFarm.Equip(i, uid) end)
		end
		local lockB=Instance.new("TextButton"); lockB.Size=UDim2.fromOffset(96,24); lockB.Position=UDim2.new(1,-204,0,50); lockB.Text=(bug.Locked and "Unlock" or "Lock"); lockB.Parent=row; lockB.Activated:Connect(function() context.Controllers.BugFarm.ToggleLock(uid) end)
		local sacB=Instance.new("TextButton"); sacB.Size=UDim2.fromOffset(96,24); sacB.Position=UDim2.new(1,-104,0,50); sacB.Text="Sacrifice"; sacB.Parent=row
		local sacrificeDisabled = (bug.Locked == true) or isEquipped
		if sacrificeDisabled then
			sacB.Active = false
			sacB.AutoButtonColor = false
			sacB.BackgroundColor3 = Color3.fromRGB(90, 90, 96)
			sacB.TextColor3 = Color3.fromRGB(180, 180, 180)
		else
			sacB.Activated:Connect(function() context.Controllers.BugFarm.Sacrifice(uid) end)
		end
	end
	invScroll.CanvasSize = UDim2.fromOffset(0, invLayout.AbsoluteContentSize.Y + 8)
	task.defer(function()
		if not equippedRowsFrame or not invScroll then return end
		equippedRowsFrame.Size = UDim2.new(1, -8, 1, -36)
		if eql then
			equippedRowsFrame.CanvasSize = UDim2.fromOffset(0, eql.AbsoluteContentSize.Y + 8)
		end
		if invLabel then
			invLabel.Position = UDim2.fromOffset(8, 218)
		end
	end)
	print("[BugsOS] BugFarmApp refreshed")
end

function BugFarmApp.Mount(target: Instance, context): ()
	if root then return end
	windowRef = Window.Create({ Title = "Bug Farm.exe", Size = UDim2.fromOffset(760, 500), Position = UDim2.fromScale(0.08, 0.14), Parent = target, OnClose = function() context.Controllers.Window.Close("BugFarm") end })
	root = Instance.new("Frame"); root.Size=UDim2.fromScale(1,1); root.BackgroundTransparency=1; root.Parent=windowRef.Content
	equippedPanel = Instance.new("Frame"); equippedPanel.Size=UDim2.new(0.62,-8,0,206); equippedPanel.Position=UDim2.fromOffset(8,8); equippedPanel.BackgroundColor3=Color3.fromRGB(28,28,34); equippedPanel.BorderSizePixel=0; equippedPanel.Parent=root
	local topLabel=Instance.new("TextLabel"); topLabel.Size=UDim2.new(1,-16,0,24); topLabel.Position = UDim2.fromOffset(8,6); topLabel.BackgroundTransparency=1; topLabel.TextXAlignment=Enum.TextXAlignment.Left; topLabel.TextColor3=Color3.new(1,1,1); topLabel.Text="Equipped Bug Slots"; topLabel.TextSize=17; topLabel.Parent=equippedPanel
	equippedRowsFrame = Instance.new("ScrollingFrame"); equippedRowsFrame.Size = UDim2.new(1,-16,1,-38); equippedRowsFrame.Position = UDim2.fromOffset(8,30); equippedRowsFrame.BackgroundTransparency = 1; equippedRowsFrame.BorderSizePixel = 0; equippedRowsFrame.ScrollBarThickness = 6; equippedRowsFrame.Parent = equippedPanel
	eql=Instance.new("UIListLayout"); eql.Padding=UDim.new(0,5); eql.Parent=equippedRowsFrame
	buffsPanel = Instance.new("Frame"); buffsPanel.Size=UDim2.new(0.38,-12,0,206); buffsPanel.Position=UDim2.new(0.62,4,0,8); buffsPanel.BackgroundColor3=Color3.fromRGB(28,28,34); buffsPanel.BorderSizePixel=0; buffsPanel.Parent=root
	local buffsTitle = Instance.new("TextLabel"); buffsTitle.Size = UDim2.new(1,-16,0,24); buffsTitle.Position = UDim2.fromOffset(8,6); buffsTitle.BackgroundTransparency = 1; buffsTitle.TextXAlignment = Enum.TextXAlignment.Left; buffsTitle.Text = "Active Buffs"; buffsTitle.TextSize = 17; buffsTitle.TextColor3 = Color3.new(1,1,1); buffsTitle.Parent = buffsPanel
	buffsLabel=Instance.new("TextLabel"); buffsLabel.Size=UDim2.new(1,-16,1,-36); buffsLabel.Position=UDim2.fromOffset(8,30); buffsLabel.BackgroundTransparency=1; buffsLabel.TextXAlignment=Enum.TextXAlignment.Left; buffsLabel.TextYAlignment=Enum.TextYAlignment.Top; buffsLabel.TextWrapped=true; buffsLabel.TextColor3=Color3.fromRGB(220,240,220); buffsLabel.TextSize=14; buffsLabel.Parent=buffsPanel
	invLabel=Instance.new("TextLabel"); invLabel.Size=UDim2.new(1,-16,0,24); invLabel.Position=UDim2.fromOffset(8,218); invLabel.BackgroundTransparency=1; invLabel.Text="Bug Inventory"; invLabel.TextXAlignment=Enum.TextXAlignment.Left; invLabel.TextColor3=Color3.new(1,1,1); invLabel.TextSize=17; invLabel.Parent=root
	invScroll = Instance.new("ScrollingFrame"); invScroll.Size=UDim2.new(1,-16,1,-250); invScroll.Position=UDim2.fromOffset(8,246); invScroll.BackgroundColor3=Color3.fromRGB(28,28,34); invScroll.BorderSizePixel=0; invScroll.ScrollBarThickness=8; invScroll.Parent=root
	if stateChangedConn then
		stateChangedConn:Disconnect()
		stateChangedConn = nil
	end
	if context.Events and context.Events.StateChanged then
		stateChangedConn = context.Events.StateChanged.Event:Connect(function()
			refresh(context)
		end)
	end
	refresh(context)
end

function BugFarmApp.Unmount(): ()
	if stateChangedConn then stateChangedConn:Disconnect(); stateChangedConn=nil end
	if windowRef then windowRef.Destroy() end
	windowRef=nil; root=nil; equippedPanel=nil; equippedRowsFrame=nil; invLabel=nil; invScroll=nil; eql=nil; buffsPanel=nil; buffsLabel=nil
end

return BugFarmApp
