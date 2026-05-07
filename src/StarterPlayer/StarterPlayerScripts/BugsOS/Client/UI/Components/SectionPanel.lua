--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))
local SectionPanel = {}
function SectionPanel.Create(parent: Instance)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = UITheme.Colors.Panel
	f.BorderColor3 = UITheme.Colors.PanelBorder
	f.BorderSizePixel = 1
	f.Parent = parent

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -2, 1, -2)
	inner.Position = UDim2.fromOffset(1, 1)
	inner.BackgroundTransparency = 1
	inner.BorderColor3 = UITheme.Colors.PanelBorderInner
	inner.BorderSizePixel = 1
	inner.Parent = f
	return f
end
return SectionPanel
