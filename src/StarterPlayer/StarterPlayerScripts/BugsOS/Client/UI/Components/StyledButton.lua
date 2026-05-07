--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))
local StyledButton = {}
function StyledButton.Create(parent: Instance, text: string)
	local b = Instance.new("TextButton")
	b.Text = text
	b.BackgroundColor3 = UITheme.Colors.ButtonFace
	b.TextColor3 = UITheme.Colors.ButtonText
	b.BorderColor3 = Color3.fromRGB(40,40,40)
	b.Font = UITheme.Font
	b.TextSize = 16
	b.Parent = parent
	return b
end
return StyledButton
