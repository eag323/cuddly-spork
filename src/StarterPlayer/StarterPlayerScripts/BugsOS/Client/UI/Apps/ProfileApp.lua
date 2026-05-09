--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local BugShowcaseGrid = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("BugShowcaseGrid"))
local ColonySkinConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("ColonySkinConfig"))
local ColonyAuraConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("ColonyAuraConfig"))

local ProfileApp = {}
local context
local windowRef
local activeDeps

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
		EquippedColonySkin = safeGet(data, "Cosmetics", "Equipped", "ColonySkin") or "Default",
		EquippedColonyAura = safeGet(data, "Cosmetics", "Equipped", "ColonyAura") or "None",
	}
end

function ProfileApp.Init(c) context = c end

function ProfileApp.Mount(target: Instance, deps)
	if windowRef and windowRef.Content and windowRef.Content.Parent then
		return
	end
	windowRef = nil
	activeDeps = deps
	local summary = buildSummary(deps)
	windowRef = Window.Create({
		Title = "Profile.exe", Size = UDim2.fromOffset(820, 600), Position = UDim2.fromScale(0.1, 0.08), Parent = target,
		OnClose = function()
			local windowController = nil
			if context and context.Controllers then
				windowController = context.Controllers.Window
			elseif activeDeps and activeDeps.Controllers then
				windowController = activeDeps.Controllers.Window
			end
			if windowController then
				windowController.Close("Profile")
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
	local colonySection = section("Colony Skin Selection",78)
	local equippedSkin = ColonySkinConfig[summary.EquippedColonySkin] or ColonySkinConfig.Default
	local colonyText = Instance.new("TextLabel")
	colonyText.Size = UDim2.new(1, -16, 1, -30)
	colonyText.Position = UDim2.fromOffset(8, 26)
	colonyText.BackgroundTransparency = 1
	colonyText.TextXAlignment = Enum.TextXAlignment.Left
	colonyText.TextYAlignment = Enum.TextYAlignment.Top
	colonyText.Font = Enum.Font.Gotham
	colonyText.TextSize = 13
	colonyText.TextColor3 = Color3.fromRGB(208,225,247)
	colonyText.Text = string.format("Equipped: %s\nRarity: %s", equippedSkin.DisplayName, equippedSkin.Rarity)
	colonyText.Parent = colonySection

	local auraSection = section("Aura Selection",78)
	local equippedAura = ColonyAuraConfig[summary.EquippedColonyAura] or ColonyAuraConfig.None
	local auraText = colonyText:Clone()
	auraText.Text = string.format("Equipped: %s\nType: %s", equippedAura.DisplayName, equippedAura.EffectType)
	auraText.Parent = auraSection
	local bugs=section("Equipped Bug Showcase",172)
	local grid=BugShowcaseGrid.Create(bugs, UDim2.fromOffset(312,136)); grid.Position=UDim2.fromOffset(16,28); BugShowcaseGrid.Render(grid, summary.EquippedBugs)
end

function ProfileApp.Unmount()
	if windowRef then windowRef.Destroy(); windowRef=nil end
	activeDeps = nil
end

return ProfileApp
