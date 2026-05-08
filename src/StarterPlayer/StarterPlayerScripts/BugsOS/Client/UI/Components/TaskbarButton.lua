--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))
local UIAssets = require(script.Parent.Parent:WaitForChild("UIAssets"))
local TaskbarButton = {}

function TaskbarButton.Create(parent: Instance, text: string, onActivate: () -> ())
	local b = Instance.new("ImageButton")
	b.Size = UDim2.fromOffset(136, 24)
	b.BackgroundTransparency = 1
	b.Image = UIAssets.TaskbarTabDefaultImage
	b.ScaleType = Enum.ScaleType.Slice
	b.SliceCenter = UIAssets.SliceCenter
	b.AutoButtonColor = false
	b.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -8, 1, 0)
	label.Position = UDim2.fromOffset(6, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(0, 0, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = UITheme.Font
	label.TextSize = 13
	label.Text = text
	label.Parent = b

	local function setActive(isActive: boolean)
		b.Image = isActive and UIAssets.TaskbarTabPressedImage or UIAssets.TaskbarTabDefaultImage
	end

	b.Activated:Connect(onActivate)
	return b, setActive
end

return TaskbarButton
