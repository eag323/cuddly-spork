--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))

local DesktopIcon = {}

function DesktopIcon.Create(parent: Instance, title: string, iconImage: string, onActivate: () -> ())
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(92, 92)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = parent

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(48, 48)
	icon.Position = UDim2.fromOffset(22, 4)
	icon.BackgroundTransparency = 1
	icon.Image = iconImage
	icon.Parent = button

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
		icon.ImageColor3 = isSelected and Color3.fromRGB(215, 235, 255) or Color3.new(1, 1, 1)
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
