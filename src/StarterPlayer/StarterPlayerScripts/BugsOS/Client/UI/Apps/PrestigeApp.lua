--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("NumberFormatter"))
local PrestigeConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("PrestigeConfig"))

local PrestigeApp = {}
local root: Frame?
local windowRef
local refs = {}

local function makeLabel(parent, text, size, pos)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = Color3.fromRGB(220, 230, 255)
	l.Font = Enum.Font.Gotham
	l.TextSize = 14
	l.Text = text
	l.Size = size
	l.Position = pos
	l.Parent = parent
	return l
end

function PrestigeApp.Refresh(context)
	if not root then return end
	local data = context.State.PlayerData or {}
	local currencies = data.Currencies or {}
	local progression = data.Progression or {}
	local prestige = tonumber(progression.Prestige) or 0
	local lifetime = tonumber(currencies.LifetimeFood) or 0
	local nextLevel = prestige + 1
	local required = PrestigeConfig.GetRequiredLifetimeFood(nextLevel)
	local progress = math.clamp(lifetime / math.max(required, 1), 0, 1)
	local canPrestige = lifetime >= required
	refs.level.Text = string.format("Current Prestige Level: P%d", prestige)
	refs.mult.Text = string.format("Current Multiplier: x%.2f", PrestigeConfig.GetMultiplier(prestige))
	refs.progressText.Text = string.format("Progress: %s / %s (%.1f%%)", NumberFormatter.FormatCompact(lifetime), NumberFormatter.FormatCompact(required), progress * 100)
	refs.requirement.Text = string.format("Earn %s total Food to prestige", NumberFormatter.FormatCompact(required))
	refs.progressFill.Size = UDim2.fromScale(progress, 1)
	refs.confirm.Active = canPrestige
	refs.confirm.AutoButtonColor = canPrestige
	refs.confirm.BackgroundColor3 = canPrestige and Color3.fromRGB(92, 45, 130) or Color3.fromRGB(56, 56, 66)

	for _, c in ipairs(refs.roadmap:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local rows = PrestigeConfig.GetRoadmapRows(prestige, 6)
	for i, row in ipairs(rows) do
		local item = Instance.new("Frame")
		item.Size = UDim2.new(1, -8, 0, 32)
		item.Position = UDim2.fromOffset(4, (i - 1) * 34)
		item.BackgroundColor3 = Color3.fromRGB(20, 32, 56)
		item.BorderSizePixel = 0
		item.Parent = refs.roadmap
		makeLabel(item, string.format("P%d  x%.2f", row.level, row.multiplier), UDim2.new(0.35, 0, 1, 0), UDim2.fromOffset(8, 0))
		makeLabel(item, "Reward: Standard prestige boost", UDim2.new(0.35, 0, 1, 0), UDim2.new(0.35, 8, 0, 0))
		makeLabel(item, NumberFormatter.FormatCompact(row.requiredLifetimeFood) .. " Food", UDim2.new(0.2, -6, 1, 0), UDim2.new(0.72, 0, 0, 0)).TextXAlignment = Enum.TextXAlignment.Right
		makeLabel(item, row.level <= prestige and "✓" or "", UDim2.new(0.08, -6, 1, 0), UDim2.new(0.92, 0, 0, 0)).TextXAlignment = Enum.TextXAlignment.Center
	end
end

function PrestigeApp.Mount(target, context)
	if root then return end
	windowRef = Window.Create({Title="Prestige.exe", Size=UDim2.fromOffset(620,480), Position=UDim2.fromScale(0.2,0.12), Parent=target, OnClose=function() context.Controllers.Window.Close("Prestige") end, OnMinimize=function() context.Controllers.Window.Minimize("Prestige") end, OnFocus=function() context.Controllers.Window.Focus("Prestige") end})
	root = windowRef.Content
	root.BackgroundColor3 = Color3.fromRGB(9, 20, 40)
	refs.level = makeLabel(root, "", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 8))
	refs.mult = makeLabel(root, "", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 30))
	refs.progressText = makeLabel(root, "", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 52))
	local progressBg = Instance.new("Frame"); progressBg.Size = UDim2.new(1, -20, 0, 16); progressBg.Position = UDim2.fromOffset(10, 76); progressBg.BackgroundColor3 = Color3.fromRGB(27, 38, 63); progressBg.BorderSizePixel = 0; progressBg.Parent = root
	refs.progressFill = Instance.new("Frame"); refs.progressFill.Size = UDim2.fromScale(0, 1); refs.progressFill.BackgroundColor3 = Color3.fromRGB(80, 142, 255); refs.progressFill.BorderSizePixel = 0; refs.progressFill.Parent = progressBg
	refs.requirement = makeLabel(root, "", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 104))
	refs.confirm = Instance.new("TextButton"); refs.confirm.Size = UDim2.fromOffset(220, 40); refs.confirm.Position=UDim2.fromOffset(10, 134); refs.confirm.Text = "Prestige Now"; refs.confirm.TextColor3=Color3.new(1,1,1); refs.confirm.Parent = root
	refs.roadmap = Instance.new("Frame"); refs.roadmap.Size=UDim2.new(1,-20,1,-190); refs.roadmap.Position=UDim2.fromOffset(10,180); refs.roadmap.BackgroundColor3=Color3.fromRGB(12,27,46); refs.roadmap.BorderSizePixel=0; refs.roadmap.Parent=root
	local title = makeLabel(refs.roadmap, "Prestige Roadmap", UDim2.new(1, -10, 0, 24), UDim2.fromOffset(8, 4)); title.Font = Enum.Font.GothamBold
	local prestigeRequestRemote = context.Remotes and context.Remotes.PrestigeRequest
	refs.confirm.Activated:Connect(function()
		if not prestigeRequestRemote then return end
		prestigeRequestRemote:FireServer({Confirm=true})
	end)
	PrestigeApp.Refresh(context)
end
function PrestigeApp.Unmount() if windowRef then windowRef.Destroy() end; root=nil; windowRef=nil; refs={} end
return PrestigeApp
