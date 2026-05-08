--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ProfileCard = {}

local parentGui: Instance? = nil
local root: Frame? = nil
local outsideConn: RBXScriptConnection? = nil
local closeConn: RBXScriptConnection? = nil
local warned: { [string]: boolean } = {}

local function warnOnce(key: string, message: string)
	if warned[key] then
		return
	end
	warned[key] = true
	warn(message)
end

local function formatCount(value: any): string
	if type(value) == "number" then
		return string.format("%d", value)
	end
	return "0"
end

local function isInBounds(guiObject: GuiObject, point: Vector2): boolean
	local pos = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return point.X >= pos.X and point.Y >= pos.Y and point.X <= (pos.X + size.X) and point.Y <= (pos.Y + size.Y)
end

function ProfileCard.SetParent(parent: Instance)
	parentGui = parent
	if root then
		root.Parent = parentGui
	end
end

function ProfileCard.Hide()
	if outsideConn then
		outsideConn:Disconnect()
		outsideConn = nil
	end
	if closeConn then
		closeConn:Disconnect()
		closeConn = nil
	end
	if root then
		root.Visible = false
	end
end

function ProfileCard.Show(summary)
	if not parentGui then
		warnOnce("missing_parent", "[BugsOS] ProfileCard.Show called before SetParent")
		return
	end
	if type(summary) ~= "table" then
		warnOnce("bad_summary", "[BugsOS] ProfileCard.Show requires profile summary table")
		return
	end

	if not root then
		root = Instance.new("Frame")
		root.Name = "ProfileCard"
		root.Size = UDim2.fromOffset(320, 270)
		root.Position = UDim2.fromScale(0.62, 0.2)
		root.BackgroundColor3 = Color3.fromRGB(12, 27, 54)
		root.Visible = false
		root.ZIndex = 40
		root.Parent = parentGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = root

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "CloseButton"
		closeBtn.Size = UDim2.fromOffset(26, 26)
		closeBtn.Position = UDim2.new(1, -32, 0, 6)
		closeBtn.BackgroundColor3 = Color3.fromRGB(32, 50, 84)
		closeBtn.Text = "✕"
		closeBtn.TextColor3 = Color3.new(1, 1, 1)
		closeBtn.ZIndex = 41
		closeBtn.Parent = root
		Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

		local name = Instance.new("TextLabel")
		name.Name = "DisplayName"
		name.Size = UDim2.fromOffset(286, 24)
		name.Position = UDim2.fromOffset(12, 10)
		name.BackgroundTransparency = 1
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Font = Enum.Font.GothamBold
		name.TextSize = 18
		name.TextColor3 = Color3.new(1, 1, 1)
		name.ZIndex = 41
		name.Parent = root

		local info = Instance.new("TextLabel")
		info.Name = "Info"
		info.Size = UDim2.fromOffset(296, 210)
		info.Position = UDim2.fromOffset(12, 46)
		info.BackgroundTransparency = 1
		info.TextWrapped = true
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextYAlignment = Enum.TextYAlignment.Top
		info.Font = Enum.Font.Gotham
		info.TextSize = 14
		info.TextColor3 = Color3.fromRGB(218, 231, 255)
		info.ZIndex = 41
		info.Parent = root
	end

	local displayName = root:FindFirstChild("DisplayName")
	local info = root:FindFirstChild("Info")
	if not displayName or not displayName:IsA("TextLabel") or not info or not info:IsA("TextLabel") then
		warnOnce("bad_card", "[BugsOS] ProfileCard missing expected labels")
		return
	end

	displayName.Text = tostring(summary.DisplayName or summary.Username or "Unknown Player")
	info.Text = string.format(
		"Title: %s\nPrestige: %s\nFood/sec: %s\nLifetime Food: %s\nNectar: %s\nBugs Caught: %s",
		tostring(summary.EquippedTitle or "None"),
		formatCount(summary.Prestige),
		formatCount(summary.FoodPerSec),
		formatCount(summary.LifetimeFood),
		formatCount(summary.CurrentNectar),
		formatCount(summary.BugsCaught)
	)

	root.Visible = true
	root.Parent = parentGui

	if closeConn then closeConn:Disconnect() end
	local closeBtn = root:FindFirstChild("CloseButton")
	if closeBtn and closeBtn:IsA("TextButton") then
		closeConn = closeBtn.Activated:Connect(ProfileCard.Hide)
	end

	if outsideConn then outsideConn:Disconnect() end
	outsideConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not root or not root.Visible then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local p = input.Position
			if not isInBounds(root, Vector2.new(p.X, p.Y)) then
				ProfileCard.Hide()
			end
		end
	end)
end

return ProfileCard
