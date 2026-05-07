--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))
local StyledButton = {}
function StyledButton.Create(parent: Instance, text: string)
	local b = Instance.new("TextButton")
	b.Text = text
	local lowerText = string.lower(text)
	local color = UITheme.Colors.ButtonFace
	if string.find(lowerText, "sell") or string.find(lowerText, "delete") then
		color = Color3.fromRGB(205, 100, 100)
	elseif string.find(lowerText, "buy") or string.find(lowerText, "upgrade") or string.find(lowerText, "start") then
		color = Color3.fromRGB(98, 179, 106)
	elseif string.find(lowerText, "claim") or string.find(lowerText, "open") or string.find(lowerText, "equip") then
		color = Color3.fromRGB(92, 173, 218)
	end
	b.BackgroundColor3 = color
	b.TextColor3 = UITheme.Colors.ButtonText
	b.BorderColor3 = UITheme.Colors.ButtonShadow
	b.AutoButtonColor = false
	b.Font = UITheme.Font
	b.TextSize = 15
	b.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = UITheme.Colors.ButtonHighlight
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b

	local function setHovered(hovered: boolean)
		b.BackgroundColor3 = hovered and color:Lerp(Color3.new(1, 1, 1), 0.12) or color
	end
	b.MouseEnter:Connect(function() setHovered(true) end)
	b.MouseLeave:Connect(function() setHovered(false) end)
	return b
end
return StyledButton
