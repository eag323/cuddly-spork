--!strict

local Players = game:GetService("Players")

local ColonyMapController = {}

local context: { [string]: any }
local markerByUserId: { [number]: Frame } = {}

local SAFE_LEFT_MARGIN = 130
local SAFE_RIGHT_MARGIN = 40
local SAFE_TOP_MARGIN = 80
local SAFE_BOTTOM_MARGIN = 60
local EDGE_PADDING = 14
local MARKER_SPACING = 56
local LOCAL_ICON_COLUMN_BUFFER = 44

local function hashToUnitInterval(userId: number, salt: number): number
	local value = (userId * 1103515245 + 12345 + salt * 2654435761) % 2147483647
	return value / 2147483647
end

local function createMarker(player: Player, isLocalPlayer: boolean): Frame
	local marker = Instance.new("Frame")
	marker.Name = "ColonyMarker_" .. tostring(player.UserId)
	marker.Size = UDim2.fromOffset(64, 44)
	marker.BackgroundTransparency = 1
	marker.ZIndex = 4

	local icon = Instance.new("TextLabel")
	icon.Name = "NestIcon"
	icon.Size = UDim2.fromOffset(26, 26)
	icon.Position = UDim2.fromOffset(19, 0)
	icon.BackgroundColor3 = if isLocalPlayer then Color3.fromRGB(90, 156, 255) else Color3.fromRGB(120, 89, 58)
	icon.Text = "🪹"
	icon.TextSize = 18
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.BorderSizePixel = 0
	icon.ZIndex = 4
	icon.Parent = marker

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = icon

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = if isLocalPlayer then 2 else 1
	stroke.Color = if isLocalPlayer then Color3.fromRGB(255, 242, 129) else Color3.fromRGB(45, 30, 18)
	stroke.Parent = icon

	if isLocalPlayer then
		local star = Instance.new("TextLabel")
		star.Name = "Star"
		star.Size = UDim2.fromOffset(14, 14)
		star.Position = UDim2.fromOffset(40, -2)
		star.BackgroundTransparency = 1
		star.Text = "★"
		star.TextColor3 = Color3.fromRGB(255, 245, 120)
		star.TextSize = 14
		star.Font = Enum.Font.GothamBold
		star.ZIndex = 5
		star.Parent = marker
	end

	local label = Instance.new("TextLabel")
	label.Name = "ColonyLabel"
	label.Size = UDim2.fromOffset(88, 16)
	label.Position = UDim2.fromOffset(-12, 28)
	label.BackgroundTransparency = 1
	label.Text = if isLocalPlayer then "My Colony" else (player.DisplayName ~= "" and player.DisplayName or player.Name)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.TextSize = 12
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.ZIndex = 4
	label.Parent = marker

	return marker
end

local function computeSafeArea(size: Vector2): (number, number, number, number)
	local minX = SAFE_LEFT_MARGIN + EDGE_PADDING
	local maxX = size.X - SAFE_RIGHT_MARGIN - EDGE_PADDING
	local minY = SAFE_TOP_MARGIN + EDGE_PADDING
	local maxY = size.Y - SAFE_BOTTOM_MARGIN - EDGE_PADDING
	return minX, maxX, minY, maxY
end

local function generatePositions(playersList: { Player }, containerSize: Vector2): { [number]: Vector2 }
	local positions: { [number]: Vector2 } = {}
	local minX, maxX, minY, maxY = computeSafeArea(containerSize)
	local width = math.max(0, maxX - minX)
	local height = math.max(0, maxY - minY)

	table.sort(playersList, function(a, b)
		return a.UserId < b.UserId
	end)

	local placed: { Vector2 } = {}
	for index, player in ipairs(playersList) do
		local targetX = minX + width * hashToUnitInterval(player.UserId, 17)
		local targetY = minY + height * hashToUnitInterval(player.UserId, 73)

		if player == Players.LocalPlayer then
			targetX = math.max(targetX, minX + LOCAL_ICON_COLUMN_BUFFER)
		end

		local pos = Vector2.new(targetX, targetY)
		local attempt = 0
		while attempt < 20 do
			local overlaps = false
			for _, existing in ipairs(placed) do
				if (existing - pos).Magnitude < MARKER_SPACING then
					overlaps = true
					break
				end
			end
			if not overlaps then
				break
			end
			attempt += 1
			local angle = attempt * 0.9 + index * 0.4
			local radius = 16 + attempt * 7
			pos = Vector2.new(
				math.clamp(targetX + math.cos(angle) * radius, minX, maxX),
				math.clamp(targetY + math.sin(angle) * radius, minY, maxY)
			)
		end

		table.insert(placed, pos)
		positions[player.UserId] = pos
	end

	return positions
end

function ColonyMapController.Init(initContext): ()
	context = initContext
end

function ColonyMapController.Refresh(): ()
	local worldLayer = context.UI.WorldLayer
	if not worldLayer then
		return
	end

	local list = Players:GetPlayers()
	local positions = generatePositions(list, worldLayer.AbsoluteSize)

	for userId, marker in pairs(markerByUserId) do
		if not positions[userId] then
			marker:Destroy()
			markerByUserId[userId] = nil
		end
	end

	for _, player in ipairs(list) do
		if not markerByUserId[player.UserId] then
			markerByUserId[player.UserId] = createMarker(player, player == Players.LocalPlayer)
			markerByUserId[player.UserId].Parent = worldLayer
		end
		local p = positions[player.UserId]
		if p then
			markerByUserId[player.UserId].Position = UDim2.fromOffset(math.floor(p.X - 32), math.floor(p.Y - 22))
		end
	end
end

function ColonyMapController.Start(): ()
	ColonyMapController.Refresh()
	Players.PlayerAdded:Connect(function()
		ColonyMapController.Refresh()
	end)
	Players.PlayerRemoving:Connect(function()
		ColonyMapController.Refresh()
	end)
	context.UI.WorldLayer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		ColonyMapController.Refresh()
	end)
end

return ColonyMapController
