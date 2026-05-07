--!strict
local TaskbarButton = {}

function TaskbarButton.Create(parent: Instance, text: string, onActivate: () -> ())
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(142, 30)
	b.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	b.BorderColor3 = Color3.fromRGB(80, 80, 80)
	b.TextColor3 = Color3.new(0, 0, 0)
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Font = Enum.Font.ArialBold
	b.TextSize = 14
	b.Text = "  " .. text
	b.Parent = parent
	b.Activated:Connect(onActivate)
	return b
end

return TaskbarButton
