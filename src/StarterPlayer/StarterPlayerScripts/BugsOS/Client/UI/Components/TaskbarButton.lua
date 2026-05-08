--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))
local UIAssets = require(script.Parent.Parent:WaitForChild("UIAssets"))

local TaskbarButton = {}

function TaskbarButton.ToDisplayTitle(title: string): string
	return string.gsub(title, "%.exe$", "")
end

function TaskbarButton.Create(parent: Instance, title: string, iconImage: string?, isStartButton: boolean?, onActivate: () -> ())
	local b = Instance.new("ImageButton")
	b.Size = isStartButton and UDim2.fromOffset(108, 30) or UDim2.fromOffset(168, 30)
	b.BackgroundTransparency = 1
	b.Image = UIAssets.TaskbarTabDefaultImage
	b.ScaleType = Enum.ScaleType.Slice
	b.SliceCenter = UIAssets.SliceCenter
	b.AutoButtonColor = false
	b.Parent = parent

	local iconSize = 16
	if not isStartButton and type(iconImage) == "string" and iconImage ~= "" and iconImage ~= "rbxassetid://0" then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.fromOffset(iconSize, iconSize)
		icon.Position = UDim2.fromOffset(8, 7)
		icon.BackgroundTransparency = 1
		icon.Image = iconImage
		icon.Parent = b
	end

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -(isStartButton and 8 or 32), 1, 0)
	label.Position = UDim2.fromOffset(isStartButton and 4 or 28, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(0, 0, 0)
	label.TextXAlignment = isStartButton and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Font = UITheme.Font
	label.TextSize = 13
	label.Text = isStartButton and "🐞 Start" or TaskbarButton.ToDisplayTitle(title)
	label.Parent = b

	local function setActive(isActive: boolean)
		b.Image = isActive and UIAssets.TaskbarTabPressedImage or UIAssets.TaskbarTabDefaultImage
	end

	b.Activated:Connect(onActivate)
	return b, setActive
end

return TaskbarButton
