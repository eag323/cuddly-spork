--!strict
local Players = game:GetService("Players")
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local BugShowcaseGrid = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("BugShowcaseGrid"))

local ProfileApp = {}
local context
local windowRef

local function safeGet(tbl, ...)
	local cur = tbl
	for _, key in ipairs({ ... }) do if type(cur) ~= "table" then return nil end cur = cur[key] end
	return cur
end

local function buildSummary(deps)
	local data = deps and deps.State and deps.State.PlayerData or {}
	return {
		DisplayName = Players.LocalPlayer.DisplayName,
		EquippedTitle = safeGet(data, "Cosmetics", "Equipped", "Title") or "None",
		Prestige = safeGet(data, "Progression", "Prestige") or 0,
		Stats = safeGet(data, "Stats") or {},
		Currencies = safeGet(data, "Currencies") or {},
		Titles = safeGet(data, "Cosmetics", "UnlockedTitles") or {},
		EquippedBugs = safeGet(data, "Loadout", "EquippedBugs") or {},
	}
end

function ProfileApp.Init(c) context = c end

function ProfileApp.Mount(target: Instance, deps)
	local summary = buildSummary(deps)
	windowRef = Window.Create({
		Title = "Profile.exe", Size = UDim2.fromOffset(820, 600), Position = UDim2.fromScale(0.1, 0.08), Parent = target,
		OnClose = function()
			if context and context.Controllers and context.Controllers.Window then
				context.Controllers.Window.Close("Profile")
			end
		end,
	})
	local content = windowRef.Content
	content.BackgroundColor3 = Color3.fromRGB(10, 22, 40)
	content.BorderSizePixel = 0
	local layout = Instance.new("UIListLayout", content); layout.Padding=UDim.new(0,8); layout.SortOrder=Enum.SortOrder.LayoutOrder

	local function section(title, h)
		local s=Instance.new("Frame"); s.Size=UDim2.new(1,0,0,h); s.BackgroundColor3=Color3.fromRGB(15,31,55); s.Parent=content; Instance.new("UICorner", s).CornerRadius=UDim.new(0,10); Instance.new("UIStroke", s).Color=Color3.fromRGB(63,96,140)
		local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,-16,0,20); t.Position=UDim2.fromOffset(8,6); t.BackgroundTransparency=1; t.TextXAlignment=Enum.TextXAlignment.Left; t.Font=Enum.Font.GothamBold; t.TextSize=14; t.TextColor3=Color3.fromRGB(236,244,255); t.Text=title; t.Parent=s
		return s
	end
	local header=section("Profile",92)
	local body=(Instance.new("TextLabel")); body.Size=UDim2.new(1,-16,1,-30); body.Position=UDim2.fromOffset(8,26); body.BackgroundTransparency=1; body.TextXAlignment=Enum.TextXAlignment.Left; body.TextYAlignment=Enum.TextYAlignment.Top; body.Font=Enum.Font.Gotham; body.TextSize=14; body.TextColor3=Color3.fromRGB(214,231,255); body.RichText=true; body.Text=string.format("<b>%s</b>\n<font color='#8AC8FF'>%s</font>\n<font color='#FFD750'>Prestige %s</font>", summary.DisplayName, summary.EquippedTitle, tostring(summary.Prestige)); body.Parent=header

	local stats=section("Stats",120)
	local st=Instance.new("TextLabel"); st.Size=UDim2.new(1,-16,1,-30); st.Position=UDim2.fromOffset(8,26); st.BackgroundTransparency=1; st.TextXAlignment=Enum.TextXAlignment.Left; st.TextYAlignment=Enum.TextYAlignment.Top; st.Font=Enum.Font.Gotham; st.TextSize=13; st.TextColor3=Color3.fromRGB(208,225,247); st.Text=string.format("Lifetime Food: %s\nBugs Caught: %s\nNectar: %s", tostring(summary.Currencies.LifetimeFood or 0), tostring(summary.Stats.BugsCaught or 0), tostring(summary.Currencies.Nectar or 0)); st.Parent=stats
	local titles=section("Titles Collection",90)
	local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,-16,1,-30); tl.Position=UDim2.fromOffset(8,26); tl.BackgroundTransparency=1; tl.TextXAlignment=Enum.TextXAlignment.Left; tl.TextYAlignment=Enum.TextYAlignment.Top; tl.Font=Enum.Font.Gotham; tl.TextSize=13; tl.TextColor3=Color3.fromRGB(208,225,247); tl.Text=((#summary.Titles>0) and table.concat(summary.Titles, ", ") or "No titles unlocked"); tl.Parent=titles
	section("Colony Skin Selection",52)
	section("Aura Selection",52)
	local bugs=section("Equipped Bug Showcase",172)
	local grid=BugShowcaseGrid.Create(bugs, UDim2.fromOffset(312,136)); grid.Position=UDim2.fromOffset(16,28); BugShowcaseGrid.Render(grid, summary.EquippedBugs)
end

function ProfileApp.Unmount()
	if windowRef then windowRef.Destroy(); windowRef=nil end
end

return ProfileApp
