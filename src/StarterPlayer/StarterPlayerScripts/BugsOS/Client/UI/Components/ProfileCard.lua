--!strict

local UserInputService = game:GetService("UserInputService")
local NumberFormatter = require(game:GetService("ReplicatedStorage"):WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("NumberFormatter"))
local BugShowcaseGrid = require(script.Parent:WaitForChild("BugShowcaseGrid"))

local ProfileCard = {}
local parentGui: Instance? = nil
local root: Frame? = nil
local bugGrid: Frame? = nil
local outsideConn: RBXScriptConnection? = nil
local inputConn: RBXScriptConnection? = nil

local function close()
	if root then root.Visible = false end
end

local function safeAbbreviate(value: number?): string
	local abbreviate = NumberFormatter and NumberFormatter.Abbreviate
	if type(abbreviate) == "function" then
		return abbreviate(value)
	end
	return tostring(tonumber(value) or 0)
end

local function bindCloseHandlers()
	if outsideConn then outsideConn:Disconnect() end
	outsideConn = UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not root or not root.Visible then return end
		if input.KeyCode == Enum.KeyCode.Escape then close() return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local p = input.Position
			local pos, size = root.AbsolutePosition, root.AbsoluteSize
			if p.X < pos.X or p.X > pos.X + size.X or p.Y < pos.Y or p.Y > pos.Y + size.Y then close() end
		end
	end)
end

function ProfileCard.SetParent(parent: Instance)
	parentGui = parent
	if root then root.Parent = parent end
end

function ProfileCard.Hide() close() end

function ProfileCard.Show(summary)
	if not parentGui or type(summary) ~= "table" then return end
	if not root then
		root = Instance.new("Frame")
		root.Name = "ProfileCard"
		root.Size = UDim2.fromOffset(400, 390)
		root.Position = UDim2.fromScale(0.57, 0.18)
		root.BackgroundColor3 = Color3.fromRGB(12, 24, 46)
		root.ZIndex = 60
		root.Visible = false
		root.Parent = parentGui
		Instance.new("UICorner", root).CornerRadius = UDim.new(0, 14)
		local stroke = Instance.new("UIStroke", root)
		stroke.Color = Color3.fromRGB(70, 110, 165)

		local closeBtn = Instance.new("TextButton")
		closeBtn.Size = UDim2.fromOffset(24, 24)
		closeBtn.Position = UDim2.new(1, -30, 0, 6)
		closeBtn.Text = "✕"
		closeBtn.BackgroundColor3 = Color3.fromRGB(34, 50, 74)
		closeBtn.TextColor3 = Color3.new(1,1,1)
		closeBtn.Parent = root
		Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
		closeBtn.Activated:Connect(close)

		local info = Instance.new("TextLabel"); info.Name="Header"; info.Size=UDim2.fromOffset(330,115); info.Position=UDim2.fromOffset(58,12); info.BackgroundTransparency=1; info.TextXAlignment=Enum.TextXAlignment.Left; info.TextYAlignment=Enum.TextYAlignment.Top; info.RichText=true; info.TextWrapped=true; info.Font=Enum.Font.Gotham; info.TextSize=14; info.TextColor3=Color3.fromRGB(220,234,255); info.Parent=root
		local avatar = Instance.new("TextLabel"); avatar.Name="Avatar"; avatar.Size=UDim2.fromOffset(46,46); avatar.Position=UDim2.fromOffset(10,14); avatar.Text="👤"; avatar.TextScaled=true; avatar.BackgroundColor3=Color3.fromRGB(26,42,68); avatar.Parent=root; Instance.new("UICorner", avatar).CornerRadius=UDim.new(1,0)
		local online = Instance.new("Frame"); online.Size=UDim2.fromOffset(10,10); online.Position=UDim2.fromOffset(50,14); online.BackgroundColor3=Color3.fromRGB(72,230,125); online.Parent=root; Instance.new("UICorner", online).CornerRadius=UDim.new(1,0)
		local panel = Instance.new("Frame"); panel.Size=UDim2.fromOffset(372,172); panel.Position=UDim2.fromOffset(14,126); panel.BackgroundColor3=Color3.fromRGB(19,34,58); panel.Parent=root; Instance.new("UICorner", panel).CornerRadius=UDim.new(0,12)
		bugGrid = BugShowcaseGrid.Create(panel, UDim2.fromOffset(312,136)); bugGrid.Position=UDim2.fromOffset(30,18)
		local footer = Instance.new("TextLabel"); footer.Name="Footer"; footer.Size=UDim2.fromOffset(372,72); footer.Position=UDim2.fromOffset(14,304); footer.BackgroundTransparency=1; footer.TextXAlignment=Enum.TextXAlignment.Left; footer.TextYAlignment=Enum.TextYAlignment.Top; footer.RichText=true; footer.Font=Enum.Font.Gotham; footer.TextSize=13; footer.TextColor3=Color3.fromRGB(198,222,250); footer.TextWrapped=true; footer.Parent=root
	end

	local titleColor = "#9DD2FF"
	local displayName = tostring(summary.DisplayName or summary.Username or "Unknown")
	local prestige = tostring(summary.Prestige or 0)
	local foodPs = safeAbbreviate(summary.FoodPerSec or 0)
	local life = safeAbbreviate(summary.LifetimeFood or 0)
	local nectar = safeAbbreviate(summary.CurrentNectar or 0)
	local generators = tostring(summary.GeneratorsOwned or 0)
	local headerLabel = root and root:FindFirstChild("Header")
	if headerLabel and headerLabel:IsA("TextLabel") then
		headerLabel.Text = string.format("<b>%s</b>\n<font color='%s'>%s</font>\n<font color='#FFD750'>Prestige %s</font>\nFarm: %s Generators • %s/s\nLifetime Food: %s • Nectar: %s", displayName, titleColor, tostring(summary.EquippedTitle or "No Title"), prestige, generators, foodPs, life, nectar)
	end

	local footerLines = {}
	if summary.Guild and summary.Guild.Name then table.insert(footerLines, "Guild: " .. tostring(summary.Guild.Name)) end
	for _, placement in ipairs(summary.LeaderboardPlacements or {}) do
		table.insert(footerLines, string.format("🏆 #%s %s", tostring(placement.Rank or "?"), tostring(placement.Name or "Leaderboard")))
	end
	local footerLabel = root and root:FindFirstChild("Footer")
	if footerLabel and footerLabel:IsA("TextLabel") then
		footerLabel.Text = table.concat(footerLines, "\n")
	end

	if bugGrid and bugGrid:IsA("Frame") and type(BugShowcaseGrid.Render) == "function" then
		BugShowcaseGrid.Render(bugGrid, summary.EquippedBugs)
	end

	if root then
		root.Visible = true
	end
	bindCloseHandlers()
end

return ProfileCard
