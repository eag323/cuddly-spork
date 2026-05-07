--!strict
local ListRow = {}
function ListRow.Create(parent: Instance)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Color3.fromRGB(26, 50, 88)
	row.BorderSizePixel = 0
	row.Parent = parent
	return row
end
return ListRow
