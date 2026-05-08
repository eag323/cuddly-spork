--!strict
local Players = game:GetService("Players")
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))

local ProfileApp = {}
local context
local windowRef

local warnedMissingState = false

local STAT_FIELDS = {
	{ "Lifetime Food", "LifetimeFood" },
	{ "Bugs Caught", "BugsCaught" },
	{ "Unique Bugs Discovered", "UniqueBugsDiscovered" },
	{ "Total Clicks", "TotalClicks" },
	{ "Market Sales", "MarketSales" },
	{ "Current Nectar", "CurrentNectar" },
	{ "Bug Points", "BugPoints" },
}

local function safeGet(tbl, ...)
	local cur = tbl
	for _, key in ipairs({ ... }) do
		if type(cur) ~= "table" then return nil end
		cur = cur[key]
	end
	return cur
end

local function buildSummary(deps)
	local localPlayer = Players.LocalPlayer
	local data = if deps then deps.State and deps.State.PlayerData else nil
	if not deps or not deps.State then
		if not warnedMissingState then
			warnedMissingState = true
			warn("[BugsOS] ProfileApp missing State dependency")
		end
	end
	return {
		DisplayName = localPlayer and localPlayer.DisplayName or "Player",
		EquippedTitle = safeGet(data, "Cosmetics", "Equipped", "Title") or "None",
		Prestige = safeGet(data, "Progression", "Prestige") or 0,
		Stats = {
			LifetimeFood = safeGet(data, "Currencies", "LifetimeFood") or 0,
			BugsCaught = safeGet(data, "Stats", "BugsCaught") or 0,
			UniqueBugsDiscovered = safeGet(data, "Stats", "UniqueBugsDiscovered") or 0,
			TotalClicks = safeGet(data, "Stats", "TotalClicks") or 0,
			MarketSales = safeGet(data, "Stats", "MarketSales") or 0,
			CurrentNectar = safeGet(data, "Currencies", "Nectar") or 0,
			BugPoints = safeGet(data, "Currencies", "BugPoints") or 0,
		},
		Titles = safeGet(data, "Cosmetics", "UnlockedTitles") or {},
	}
end

function ProfileApp.Init(c)
	context = c
end

function ProfileApp.Mount(target: Instance, depsArg): ()
	local deps = depsArg or (context and context.AppDependencies or nil)
	local summary = buildSummary(deps)

	windowRef = Window.Create({
		Title = "Profile.exe",
		Size = UDim2.fromOffset(760, 560),
		Position = UDim2.fromScale(0.12, 0.08),
		Parent = target,
		OnClose = function()
			if context and context.Controllers and context.Controllers.Window then
				context.Controllers.Window.Close("Profile")
			end
		end,
	})

	local content = windowRef.Content
	local y = 8
	local function addLabel(text, h, bold)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -16, 0, h)
		l.Position = UDim2.fromOffset(8, y)
		y += h + 4
		l.BackgroundTransparency = 1
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Top
		l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
		l.TextSize = bold and 16 or 14
		l.TextWrapped = true
		l.Text = text
		l.Parent = content
		return l
	end

	addLabel("Player: " .. summary.DisplayName, 24, true)
	addLabel("Equipped Title: " .. tostring(summary.EquippedTitle), 20, false)
	addLabel("Prestige: " .. tostring(summary.Prestige), 20, false)
	addLabel("Stats", 22, true)

	for _, entry in ipairs(STAT_FIELDS) do
		local label = entry[1]
		local key = entry[2]
		addLabel(string.format("- %s: %s", label, tostring(summary.Stats[key] or "0")), 18, false)
	end

	addLabel("Titles", 22, true)
	if #summary.Titles == 0 then
		addLabel("No titles unlocked yet", 18, false)
	else
		for _, title in ipairs(summary.Titles) do
			local equipped = (title == summary.EquippedTitle) and " (Equipped)" or ""
			addLabel("- " .. tostring(title) .. equipped, 18, false)
		end
		addLabel("Title equip is read-only until server remote support is available.", 18, false)
	end

	addLabel("Colony Skin", 22, true)
	addLabel("Default skin equipped", 18, false)
	addLabel("Colony Aura", 22, true)
	addLabel("No aura equipped", 18, false)
end

function ProfileApp.Unmount(): ()
	if windowRef then windowRef.Root:Destroy() windowRef=nil end
end

return ProfileApp
