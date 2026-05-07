--!strict
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))
local SectionPanel = {}
function SectionPanel.Create(parent: Instance)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = UITheme.Colors.Panel
	f.BorderColor3 = UITheme.Colors.PanelBorder
	f.BorderSizePixel = 1
	f.Parent = parent
	return f
end
return SectionPanel
