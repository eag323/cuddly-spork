--!strict
local ProgressBar = {}
function ProgressBar.Create(parent: Instance)
	local root = Instance.new("Frame")
	root.BackgroundColor3 = Color3.fromRGB(20, 34, 66)
	root.BorderSizePixel = 0
	root.Parent = parent
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0,1)
	fill.BackgroundColor3 = Color3.fromRGB(50, 220, 255)
	fill.BorderSizePixel = 0
	fill.Parent = root
	return root, fill
end
return ProgressBar
