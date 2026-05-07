--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))

local BugFarmApp = {}
local windowRef
local root
local connA
local connB
local equippedFrame
local equippedRowsFrame
local invLabel
local invScroll
local eql

local function fmtPrimary(primary)
	if type(primary) ~= "table" then return "No primary stat" end
	local value = tonumber(primary.Value) or 0
	return string.format("%s: %s%%", tostring(primary.Attribute or primary.Stat or "Stat"), NumberUtil.FormatNumber(value * 100))
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
	if slotsUnlocked < 1 then slotsUnlocked = 1 end
	for i = 1, slotsUnlocked do
		local row = Instance.new("Frame"); row.Size=UDim2.new(1,0,0,58); row.BackgroundColor3=Color3.fromRGB(46,46,54); row.Parent=equippedRowsFrame
		local uid = eq[i]
		local bug = uid and inv[uid] or nil

		local title = Instance.new("TextLabel"); title.Size=UDim2.new(1,-110,0,24); title.Position=UDim2.fromOffset(8,4); title.BackgroundTransparency=1; title.TextXAlignment=Enum.TextXAlignment.Left; title.TextColor3=Color3.new(1,1,1); title.Text = bug and string.format("Slot %d: %s [%s]", i, tostring(bug.Species or bug.SpeciesId or "Unknown"), tostring(bug.Rarity or "Common")) or string.format("Slot %d: Empty", i); title.Parent=row

		local primary = Instance.new("TextLabel"); primary.Size=UDim2.new(1,-110,0,22); primary.Position=UDim2.fromOffset(8,30); primary.BackgroundTransparency=1; primary.TextXAlignment=Enum.TextXAlignment.Left; primary.TextColor3=Color3.fromRGB(210,210,210); primary.TextSize=14; primary.Text = bug and fmtPrimary(bug.Primary) or "No bug equipped"; primary.Parent=row

		if bug then local b=Instance.new("TextButton"); b.Size=UDim2.new(0,92,0,28); b.Position=UDim2.new(1,-100,0.5,-14); b.Text="Unequip"; b.Parent=row; b.Activated:Connect(function() context.Controllers.BugFarm.Unequip(i) end) end
	end
	local invLayout = Instance.new("UIListLayout"); invLayout.Padding = UDim.new(0, 6); invLayout.Parent = invScroll
	for uid, bug in pairs(inv) do
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,-8,0,74); row.BackgroundColor3=Color3.fromRGB(36,36,44); row.Parent=invScroll
		local label=Instance.new("TextLabel"); label.Size=UDim2.new(1,-310,1,0); label.BackgroundTransparency=1; label.TextXAlignment=Enum.TextXAlignment.Left; label.TextWrapped=true; label.TextColor3=Color3.new(1,1,1)
		local isEquipped = false; for _,v in pairs(eq) do if v==uid then isEquipped=true break end end
		label.Text=string.format("%s [%s]\n%s | Equipped: %s | Locked: %s", tostring(bug.Species or bug.SpeciesId), tostring(bug.Rarity or "Common"), fmtPrimary(bug.Primary), tostring(isEquipped), tostring(bug.Locked == true)); label.Parent=row
		for i=1,(tonumber(bugsData.SlotsUnlocked) or 5) do local eb=Instance.new("TextButton"); eb.Size=UDim2.fromOffset(40,22); eb.Position=UDim2.new(1,-300+((i-1)*44),0,6); eb.Text=tostring(i); eb.Parent=row; eb.Activated:Connect(function() context.Controllers.BugFarm.Equip(i, uid) end) end
		local lockB=Instance.new("TextButton"); lockB.Size=UDim2.fromOffset(90,22); lockB.Position=UDim2.new(1,-300,0,38); lockB.Text=(bug.Locked and "Unlock" or "Lock"); lockB.Parent=row; lockB.Activated:Connect(function() context.Controllers.BugFarm.ToggleLock(uid) end)
		local sacB=Instance.new("TextButton"); sacB.Size=UDim2.fromOffset(90,22); sacB.Position=UDim2.new(1,-204,0,38); sacB.Text="Sacrifice"; sacB.Parent=row; sacB.Activated:Connect(function() context.Controllers.BugFarm.Sacrifice(uid) end)
	end
	invScroll.CanvasSize = UDim2.fromOffset(0, invLayout.AbsoluteContentSize.Y + 8)
	task.defer(function()
		if not equippedRowsFrame or not invScroll then return end
		equippedRowsFrame.Size = UDim2.new(1, -8, 0, eql and eql.AbsoluteContentSize.Y or (slotsUnlocked * 58))
		invScroll.Position = UDim2.fromOffset(4, equippedRowsFrame.AbsolutePosition.Y - root.AbsolutePosition.Y + equippedRowsFrame.AbsoluteSize.Y + 34)
		invScroll.Size = UDim2.new(1, -8, 1, -(invScroll.Position.Y.Offset + 4))
		if invLabel then
			invLabel.Position = UDim2.fromOffset(4, invScroll.Position.Y.Offset - 24)
		end
	end)
end

function BugFarmApp.Mount(target: Instance, context): ()
	if root then return end
	windowRef = Window.Create({ Title = "Bug Farm.exe", Size = UDim2.fromOffset(760, 500), Position = UDim2.fromScale(0.08, 0.14), Parent = target, OnClose = function() context.Controllers.Window.Close("BugFarm") end })
	root = Instance.new("Frame"); root.Size=UDim2.fromScale(1,1); root.BackgroundTransparency=1; root.Parent=windowRef.Content
	equippedFrame = Instance.new("Frame"); equippedFrame.Size=UDim2.new(1,-8,0,312); equippedFrame.Position=UDim2.fromOffset(4,4); equippedFrame.BackgroundTransparency=1; equippedFrame.Parent=root
	local topLabel=Instance.new("TextLabel"); topLabel.Size=UDim2.new(1,0,0,24); topLabel.BackgroundTransparency=1; topLabel.TextXAlignment=Enum.TextXAlignment.Left; topLabel.TextColor3=Color3.new(1,1,1); topLabel.Text="Equipped Bug Slots"; topLabel.Parent=equippedFrame
	equippedRowsFrame = Instance.new("Frame"); equippedRowsFrame.Size = UDim2.new(1,0,1,-30); equippedRowsFrame.Position = UDim2.fromOffset(0,30); equippedRowsFrame.BackgroundTransparency = 1; equippedRowsFrame.Parent = equippedFrame
	eql=Instance.new("UIListLayout"); eql.Padding=UDim.new(0,5); eql.Parent=equippedRowsFrame
	invLabel=Instance.new("TextLabel"); invLabel.Size=UDim2.new(1,-8,0,24); invLabel.Position=UDim2.fromOffset(4,320); invLabel.BackgroundTransparency=1; invLabel.Text="Bug Inventory"; invLabel.TextXAlignment=Enum.TextXAlignment.Left; invLabel.TextColor3=Color3.new(1,1,1); invLabel.Parent=root
	invScroll = Instance.new("ScrollingFrame"); invScroll.Size=UDim2.new(1,-8,1,-350); invScroll.Position=UDim2.fromOffset(4,344); invScroll.BackgroundColor3=Color3.fromRGB(28,28,34); invScroll.BorderSizePixel=0; invScroll.ScrollBarThickness=8; invScroll.Parent=root
	connA = context.Remotes.StatePatch.OnClientEvent:Connect(function() refresh(context) end)
	connB = context.Remotes.StateFullSync.OnClientEvent:Connect(function() refresh(context) end)
	refresh(context)
end

function BugFarmApp.Unmount(): ()
	if connA then connA:Disconnect(); connA=nil end
	if connB then connB:Disconnect(); connB=nil end
	if windowRef then windowRef.Destroy() end
	windowRef=nil; root=nil; equippedFrame=nil; equippedRowsFrame=nil; invLabel=nil; invScroll=nil; eql=nil
end

return BugFarmApp
