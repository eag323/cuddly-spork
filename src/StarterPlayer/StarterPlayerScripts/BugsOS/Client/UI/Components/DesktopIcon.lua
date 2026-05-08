--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))
local TaskbarButton = require(script.Parent:WaitForChild("TaskbarButton"))

local DesktopIcon = {}

function DesktopIcon.Create(parent: Instance, title: string, iconImage: string, onActivate: () -> ())
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(88, 96)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = parent

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(48, 48)
	icon.Position = UDim2.fromOffset(20, 4)
	icon.BackgroundTransparency = 1
	icon.Image = iconImage
	icon.Parent = button

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -6, 0, 36)
	label.Position = UDim2.fromOffset(3, 56)
	label.BackgroundTransparency = 1
	label.TextWrapped = true
	label.Text = TaskbarButton.ToDisplayTitle(title)
	label.Font = UITheme.Font
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
	label.TextStrokeTransparency = 0.55
	label.Parent = button

	button.MouseEnter:Connect(function()
		icon.ImageColor3 = Color3.fromRGB(232, 242, 255)
	end)

	button.MouseLeave:Connect(function()
		icon.ImageColor3 = Color3.new(1, 1, 1)
	end)

	button.Activated:Connect(onActivate)
	return button
end

return DesktopIcon
