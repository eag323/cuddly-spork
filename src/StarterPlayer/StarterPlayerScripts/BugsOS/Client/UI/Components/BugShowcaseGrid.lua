--!strict

local BugShowcaseGrid = {}

local RARITY_COLORS = {
	Common = Color3.fromRGB(122, 140, 160),
	Uncommon = Color3.fromRGB(96, 186, 94),
	Rare = Color3.fromRGB(84, 162, 255),
	Epic = Color3.fromRGB(177, 106, 255),
	Legendary = Color3.fromRGB(255, 173, 59),
	Mythic = Color3.fromRGB(255, 84, 140),
}

local function clear(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function BugShowcaseGrid.Create(parent: Instance, size: UDim2?): Frame
	local root = Instance.new("Frame")
	root.Name = "BugShowcaseGrid"
	root.BackgroundTransparency = 1
	root.Size = size or UDim2.fromOffset(272, 142)
	root.Parent = parent

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(60, 60)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.FillDirectionMaxCells = 4
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = root

	return root
end

function BugShowcaseGrid.Render(root: Frame, bugs: { [number]: any }?)
	clear(root)
	for i = 1, 8 do
		local bug = bugs and bugs[i] or nil
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.BackgroundColor3 = Color3.fromRGB(17, 30, 50)
		slot.BorderSizePixel = 0
		slot.LayoutOrder = i
		slot.Parent = root
		Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 12)

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = RARITY_COLORS[bug and bug.Rarity or ""] or Color3.fromRGB(58, 84, 118)
		stroke.Transparency = bug and 0.12 or 0.45
		stroke.Parent = slot

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.fromScale(1, 1)
		icon.BackgroundTransparency = 1
		icon.Font = Enum.Font.GothamBold
		icon.TextScaled = true
		icon.Text = bug and tostring(bug.Icon or "🐞") or ""
		icon.TextColor3 = Color3.fromRGB(246, 250, 255)
		icon.Parent = slot
	end
end

return BugShowcaseGrid
