--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))
local TaskbarButton = {}

function TaskbarButton.Create(parent: Instance, text: string, onActivate: () -> ())
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(136, 24)
	b.BackgroundColor3 = UITheme.Colors.ButtonFace
	b.BorderColor3 = UITheme.Colors.TaskbarBorderDark
	b.BorderSizePixel = 1
	b.TextColor3 = Color3.new(0, 0, 0)
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Font = UITheme.Font
	b.TextSize = 13
	b.Text = " " .. text
	b.AutoButtonColor = false
	b.Parent = parent

	local function setActive(isActive: boolean)
		if isActive then
			b.BackgroundColor3 = Color3.fromRGB(173, 173, 173)
			b.BorderColor3 = UITheme.Colors.TaskbarBorderDark
		else
			b.BackgroundColor3 = UITheme.Colors.ButtonFace
			b.BorderColor3 = UITheme.Colors.TaskbarBorderDark
		end
	end

	b.Activated:Connect(onActivate)
	return b, setActive
end

return TaskbarButton
