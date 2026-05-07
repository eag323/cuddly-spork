--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))

local DesktopIcon = {}

function DesktopIcon.Create(parent: Instance, title: string, iconText: string, onActivate: () -> ())
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(82, 92)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = parent

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromOffset(54, 54)
	icon.Position = UDim2.fromOffset(14, 4)
	icon.BackgroundColor3 = UITheme.Colors.Panel
	icon.BorderColor3 = UITheme.Colors.WindowBorderLight
	icon.BorderSizePixel = 1
	icon.Text = iconText
	icon.Font = UITheme.Font
	icon.TextSize = 28
	icon.TextColor3 = UITheme.Colors.TitleText
	icon.Parent = button

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 30)
	label.Position = UDim2.fromOffset(0, 60)
	label.BackgroundTransparency = 1
	label.TextWrapped = true
	label.Text = title
	label.Font = UITheme.Font
	label.TextSize = 14
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = button

	button.Activated:Connect(onActivate)
	return button
end

return DesktopIcon
