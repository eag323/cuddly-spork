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
local invScroll

local function fmtPrimary(primary)
	if type(primary) ~= "table" then return "No primary stat" end
	local value = tonumber(primary.Value) or 0
	return string.format("%s: %s%%", tostring(primary.Attribute or primary.Stat or "Stat"), NumberUtil.FormatNumber(value * 100))
end

local function refresh(context)
	if not root or not equippedFrame or not invScroll then return end
	equippedFrame:ClearAllChildren()
	invScroll:ClearAllChildren()
	local bugsData = ((context.State.PlayerData or {}).Bugs or {})
	local inv = bugsData.Inventory or {}
	local eq = bugsData.Equipped or {}
	for i = 1, 5 do
		local row = Instance.new("Frame"); row.Size=UDim2.new(1,0,0,46); row.BackgroundColor3=Color3.fromRGB(46,46,54); row.Parent=equippedFrame
		local uid = eq[i]
		local bug = uid and inv[uid] or nil
		local t = Instance.new("TextLabel"); t.Size=UDim2.new(0.75,0,1,0); t.BackgroundTransparency=1; t.TextXAlignment=Enum.TextXAlignment.Left; t.TextColor3=Color3.new(1,1,1); t.Text = string.format("Slot %d: %s | %s", i, bug and bug.Species or "Empty", bug and fmtPrimary(bug.Primary) or "No bug equipped"); t.Parent=row
		if bug then local b=Instance.new("TextButton"); b.Size=UDim2.new(0,100,0,30); b.Position=UDim2.new(1,-106,0.5,-15); b.Text="Unequip"; b.Parent=row; b.Activated:Connect(function() context.Controllers.BugFarm.Unequip(i) end) end
	end
	local invLayout = Instance.new("UIListLayout"); invLayout.Padding = UDim.new(0, 6); invLayout.Parent = invScroll
	for uid, bug in pairs(inv) do
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,-8,0,74); row.BackgroundColor3=Color3.fromRGB(36,36,44); row.Parent=invScroll
		local label=Instance.new("TextLabel"); label.Size=UDim2.new(1,-310,1,0); label.BackgroundTransparency=1; label.TextXAlignment=Enum.TextXAlignment.Left; label.TextWrapped=true; label.TextColor3=Color3.new(1,1,1)
		local isEquipped = false; for _,v in pairs(eq) do if v==uid then isEquipped=true break end end
		label.Text=string.format("%s [%s]\n%s | Equipped: %s | Locked: %s", tostring(bug.Species or bug.SpeciesId), tostring(bug.Rarity or "Common"), fmtPrimary(bug.Primary), tostring(isEquipped), tostring(bug.Locked == true)); label.Parent=row
		for i=1,5 do local eb=Instance.new("TextButton"); eb.Size=UDim2.fromOffset(40,22); eb.Position=UDim2.new(1,-300+((i-1)*44),0,6); eb.Text=tostring(i); eb.Parent=row; eb.Activated:Connect(function() context.Controllers.BugFarm.Equip(i, uid) end) end
		local lockB=Instance.new("TextButton"); lockB.Size=UDim2.fromOffset(90,22); lockB.Position=UDim2.new(1,-300,0,38); lockB.Text=(bug.Locked and "Unlock" or "Lock"); lockB.Parent=row; lockB.Activated:Connect(function() context.Controllers.BugFarm.ToggleLock(uid) end)
		local sacB=Instance.new("TextButton"); sacB.Size=UDim2.fromOffset(90,22); sacB.Position=UDim2.new(1,-204,0,38); sacB.Text="Sacrifice"; sacB.Parent=row; sacB.Activated:Connect(function() context.Controllers.BugFarm.Sacrifice(uid) end)
	end
	invScroll.CanvasSize = UDim2.fromOffset(0, invLayout.AbsoluteContentSize.Y + 8)
end

function BugFarmApp.Mount(target: Instance, context): ()
	if root then return end
	windowRef = Window.Create({ Title = "Bug Farm.exe", Size = UDim2.fromOffset(760, 500), Position = UDim2.fromScale(0.08, 0.14), Parent = target, OnClose = function() context.Controllers.Window.Close("BugFarm") end })
	root = Instance.new("Frame"); root.Size=UDim2.fromScale(1,1); root.BackgroundTransparency=1; root.Parent=windowRef.Content
	equippedFrame = Instance.new("Frame"); equippedFrame.Size=UDim2.new(1,-8,0,240); equippedFrame.Position=UDim2.fromOffset(4,4); equippedFrame.BackgroundTransparency=1; equippedFrame.Parent=root
	local topLabel=Instance.new("TextLabel"); topLabel.Size=UDim2.new(1,0,0,24); topLabel.BackgroundTransparency=1; topLabel.TextXAlignment=Enum.TextXAlignment.Left; topLabel.TextColor3=Color3.new(1,1,1); topLabel.Text="Equipped Bug Slots"; topLabel.Parent=equippedFrame
	local eql=Instance.new("UIListLayout"); eql.Padding=UDim.new(0,5); eql.Parent=equippedFrame
	invScroll = Instance.new("ScrollingFrame"); invScroll.Size=UDim2.new(1,-8,1,-254); invScroll.Position=UDim2.fromOffset(4,250); invScroll.BackgroundColor3=Color3.fromRGB(28,28,34); invScroll.BorderSizePixel=0; invScroll.ScrollBarThickness=8; invScroll.Parent=root
	local invLabel=Instance.new("TextLabel"); invLabel.Size=UDim2.new(1,0,0,24); invLabel.BackgroundTransparency=1; invLabel.Text="Bug Inventory"; invLabel.TextXAlignment=Enum.TextXAlignment.Left; invLabel.TextColor3=Color3.new(1,1,1); invLabel.Parent=invScroll
	connA = context.Remotes.StatePatch.OnClientEvent:Connect(function() refresh(context) end)
	connB = context.Remotes.StateFullSync.OnClientEvent:Connect(function() refresh(context) end)
	refresh(context)
end

function BugFarmApp.Unmount(): ()
	if connA then connA:Disconnect(); connA=nil end
	if connB then connB:Disconnect(); connB=nil end
	if windowRef then windowRef.Destroy() end
	windowRef=nil; root=nil; equippedFrame=nil; invScroll=nil
end

return BugFarmApp
