--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))

local DesktopIcon = {}

function DesktopIcon.Create(parent: Instance, title: string, iconText: string, onActivate: () -> ())
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(92, 92)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = parent

	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.fromOffset(48, 48)
	iconFrame.Position = UDim2.fromOffset(22, 4)
	iconFrame.BackgroundColor3 = Color3.fromRGB(216, 225, 245)
	iconFrame.BorderColor3 = Color3.fromRGB(250, 250, 255)
	iconFrame.BorderSizePixel = 1
	iconFrame.Parent = button

	local iconShadow = Instance.new("Frame")
	iconShadow.Size = UDim2.new(1, 0, 1, 0)
	iconShadow.Position = UDim2.fromOffset(1, 1)
	iconShadow.BackgroundColor3 = Color3.fromRGB(76, 89, 130)
	iconShadow.BorderSizePixel = 0
	iconShadow.ZIndex = 0
	iconShadow.Parent = iconFrame

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, -4, 1, -4)
	icon.Position = UDim2.fromOffset(2, 2)
	icon.BackgroundColor3 = Color3.fromRGB(248, 251, 255)
	icon.BorderColor3 = Color3.fromRGB(108, 126, 176)
	icon.BorderSizePixel = 1
	icon.Text = iconText
	icon.Font = UITheme.Font
	icon.TextSize = 24
	icon.TextColor3 = Color3.fromRGB(36, 42, 58)
	icon.Parent = iconFrame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -6, 0, 36)
	label.Position = UDim2.fromOffset(3, 56)
	label.BackgroundColor3 = Color3.fromRGB(8, 45, 102)
	label.BackgroundTransparency = 0.4
	label.TextWrapped = true
	label.Text = title
	label.Font = UITheme.Font
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = button

	local labelStroke = Instance.new("UIStroke")
	labelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	labelStroke.Color = Color3.fromRGB(130, 178, 230)
	labelStroke.Thickness = 1
	labelStroke.Transparency = 0.45
	labelStroke.Parent = label

	local function setSelected(isSelected: boolean)
		label.BackgroundTransparency = isSelected and 0.08 or 0.4
		label.BackgroundColor3 = isSelected and UITheme.Colors.IconSelected or Color3.fromRGB(8, 45, 102)
		icon.BackgroundColor3 = isSelected and Color3.fromRGB(226, 239, 255) or Color3.fromRGB(248, 251, 255)
	end

	button.MouseEnter:Connect(function()
		if not button:GetAttribute("Selected") then
			setSelected(true)
		end
	end)

	button.MouseLeave:Connect(function()
		if not button:GetAttribute("Selected") then
			setSelected(false)
		end
	end)

	button.MouseButton1Down:Connect(function()
		button:SetAttribute("Selected", true)
		setSelected(true)
		task.delay(0.3, function()
			if button.Parent then
				button:SetAttribute("Selected", false)
				setSelected(false)
			end
		end)
	end)

	label.Parent = button

	button.Activated:Connect(onActivate)
	return button
end

return DesktopIcon
