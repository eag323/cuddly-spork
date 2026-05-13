--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local BugConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugConfig"))
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local BugFarmApp = {}

local root, windowRef, stateConn
local selectedTab = "Farmers"
local selectedRecycle: {[string]: boolean} = {}

local function getBugCfg(id) return BugConfig.Bugs[id] end
local function getBugs(context) return ((context.State.PlayerData or {}).Bugs or {}) end
local function ownedList(inv) local t={} for uid,b in pairs(inv or {}) do table.insert(t,{Uid=uid,Bug=b}) end table.sort(t,function(a,b) return a.Uid < b.Uid end) return t end
local function clear(frame) for _,c in ipairs(frame:GetChildren()) do c:Destroy() end end

local function render(context)
	if not root then return end
	clear(root)
	local bugs = getBugs(context)
	local inv = bugs.Inventory or {}
	local farmer = bugs.FarmerSlots or {}
	local combat = bugs.CombatSlots or {}
	local top = Instance.new("Frame"); top.Size=UDim2.new(1,-16,0,36); top.Position=UDim2.fromOffset(8,8); top.BackgroundTransparency=1; top.Parent=root
	for i,name in ipairs({"Farmers","Combat Team","Recycling"}) do
		local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(150,30); b.Position=UDim2.fromOffset((i-1)*158,0); b.Text=name; b.TextSize=14; b.BorderSizePixel=0; b.BackgroundColor3=(selectedTab==name) and Color3.fromRGB(32,80,120) or Color3.fromRGB(25,32,45); b.TextColor3=Color3.new(1,1,1); b.Parent=top; b.Activated:Connect(function() selectedTab=name; render(context) end)
	end
	local list = Instance.new("ScrollingFrame"); list.Size=UDim2.new(1,-16,1,-56); list.Position=UDim2.fromOffset(8,48); list.BackgroundColor3=Color3.fromRGB(17,24,39); list.BorderSizePixel=0; list.ScrollBarThickness=8; list.Parent=root
	local ui=Instance.new("UIListLayout"); ui.Padding=UDim.new(0,6); ui.Parent=list
	local slots = (selectedTab=="Combat Team") and 5 or (5 + tonumber((((context.State.PlayerData or {}).Progression or {}).Prestige) or 0) + tonumber(bugs.ExtraFarmerSlotsPurchased or 0))
	if selectedTab ~= "Recycling" then
		for i=1,slots do
			local uid = (selectedTab=="Combat Team") and combat[i] or farmer[i]
			local row=Instance.new("Frame"); row.Size=UDim2.new(1,-8,0,56); row.BackgroundColor3=Color3.fromRGB(30,41,59); row.BorderSizePixel=0; row.Parent=list
			local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,-220,1,0); t.Position=UDim2.fromOffset(8,0); t.BackgroundTransparency=1; t.TextXAlignment=Enum.TextXAlignment.Left; t.TextColor3=Color3.new(1,1,1); t.TextSize=14; t.Parent=row
			if uid and inv[uid] then local cfg=getBugCfg(inv[uid].BugId); t.Text=(cfg and cfg.displayName or inv[uid].BugId).." ["..tostring((cfg and cfg.rarity) or inv[uid].Rarity or "Common").."]" else t.Text=(selectedTab=="Combat Team") and "+ Add Combat Bug" or "+ Add Bug" end
			local ub=Instance.new("TextButton"); ub.Size=UDim2.fromOffset(90,28); ub.Position=UDim2.new(1,-98,0.5,-14); ub.Text="Unequip"; ub.Parent=row; ub.Activated:Connect(function() if selectedTab=="Combat Team" then context.Controllers.BugFarm.UnequipCombat(i) else context.Controllers.BugFarm.UnequipFarmer(i) end end)
		end
	end
	for _,it in ipairs(ownedList(inv)) do
		local uid,bug=it.Uid,it.Bug; local cfg=getBugCfg(bug.BugId)
		local row=Instance.new("Frame"); row.Size=UDim2.new(1,-8,0,70); row.BackgroundColor3=Color3.fromRGB(15,23,42); row.BorderSizePixel=0; row.Parent=list
		local bugId = bug and bug.BugId
		local displayName = (cfg and cfg.displayName) or bugId or "Unknown Bug"
		local rarity = (cfg and cfg.rarity) or bug.Rarity or "Common"
		local tx=Instance.new("TextLabel"); tx.Size=UDim2.new(1,-260,1,0); tx.Position=UDim2.fromOffset(8,0); tx.BackgroundTransparency=1; tx.TextXAlignment=Enum.TextXAlignment.Left; tx.TextSize=14; tx.TextColor3=Color3.fromRGB(230,240,255); tx.Text=tostring(displayName).."  "..tostring(rarity); tx.Parent=row
		local lock=Instance.new("TextButton"); lock.Size=UDim2.fromOffset(70,24); lock.Position=UDim2.new(1,-250,0.5,-12); lock.Text=(bug.Locked and "Unlock" or "Lock"); lock.Parent=row; lock.Activated:Connect(function() context.Controllers.BugFarm.ToggleLock(uid) end)
		if selectedTab=="Recycling" then
			local sel=Instance.new("TextButton"); sel.Size=UDim2.fromOffset(70,24); sel.Position=UDim2.new(1,-170,0.5,-12); sel.Text=(selectedRecycle[uid] and "Selected" or "Select"); sel.Parent=row
			sel.Activated:Connect(function() if not bug.Locked and not table.find(farmer, uid) and not table.find(combat, uid) then selectedRecycle[uid]=not selectedRecycle[uid]; render(context) end end)
		else
			local eq=Instance.new("TextButton"); eq.Size=UDim2.fromOffset(70,24); eq.Position=UDim2.new(1,-170,0.5,-12); eq.Text="Equip"; eq.Parent=row
			eq.Activated:Connect(function() if selectedTab=="Combat Team" then context.Controllers.BugFarm.EquipCombat(uid,nil) else context.Controllers.BugFarm.EquipFarmer(uid,nil) end end)
		end
	end
	if selectedTab=="Recycling" then
		local actions=Instance.new("Frame"); actions.Size=UDim2.new(1,-8,0,46); actions.BackgroundTransparency=1; actions.Parent=list
		local recycle=Instance.new("TextButton"); recycle.Size=UDim2.fromOffset(160,32); recycle.Position=UDim2.fromOffset(0,6); recycle.Text="Recycle Selected"; recycle.Parent=actions; recycle.Activated:Connect(function() local uids={} for uid,s in pairs(selectedRecycle) do if s then table.insert(uids,uid) end end context.Controllers.BugFarm.RecycleSelected(uids); selectedRecycle={} end)
	end
	list.CanvasSize=UDim2.fromOffset(0,ui.AbsoluteContentSize.Y+8)
end

function BugFarmApp.Mount(target, context)
	if root then return end
	windowRef = Window.Create({ Title = "Bug Farm.exe", Size = UDim2.fromOffset(920, 620), Position = UDim2.fromScale(0.08, 0.1), Parent = target, OnClose = function() context.Controllers.Window.Close("BugFarm") end })
	root = Instance.new("Frame"); root.Size=UDim2.fromScale(1,1); root.BackgroundColor3=Color3.fromRGB(2,6,23); root.BorderSizePixel=0; root.Parent=windowRef.Content
	if context.Events and context.Events.StateChanged then
		stateConn = context.Events.StateChanged.Event:Connect(function() render(context) end)
	end
	render(context)
end

function BugFarmApp.Unmount()
	if stateConn then stateConn:Disconnect() end
	if windowRef then windowRef.Destroy() end
	root=nil; windowRef=nil; stateConn=nil
end

return BugFarmApp
