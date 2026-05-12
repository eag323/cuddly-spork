--!strict

local UserInputService = game:GetService("UserInputService")
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))

local Window = {}
local TITLE_BAR_LEFT = Color3.fromRGB(0, 3, 129)
local TITLE_BAR_RIGHT = Color3.fromRGB(15, 131, 207)
local OUTER_BORDER = 6
local TITLE_BAR_HEIGHT = 28
local CONTENT_TOP = OUTER_BORDER + TITLE_BAR_HEIGHT
local WINDOW_FRAME_IMAGE = "rbxassetid://138529502428069"
local WINDOW_BUTTON_IMAGE = "rbxassetid://128179488793090"


local function createFrameBorderOverlay(rootFrame: Frame, zIndex: number): { ImageLabel }
	local SOURCE_SIZE = 64
	local BORDER = OUTER_BORDER
	local EDGE_SIZE = SOURCE_SIZE - (BORDER * 2)
	local pieces = {}

	local function createPiece(name: string, position: UDim2, size: UDim2, rectOffset: Vector2, rectSize: Vector2)
		local piece = Instance.new("ImageLabel")
		piece.Name = name
		piece.Position = position
		piece.Size = size
		piece.BackgroundTransparency = 1
		piece.BorderSizePixel = 0
		piece.Image = WINDOW_FRAME_IMAGE
		piece.ScaleType = Enum.ScaleType.Stretch
		piece.ImageRectOffset = rectOffset
		piece.ImageRectSize = rectSize
		piece.ZIndex = zIndex
		piece.Active = false
		piece.Selectable = false
		piece.Parent = rootFrame
		table.insert(pieces, piece)
		return piece
	end

	createPiece("FrameTopLeft", UDim2.fromOffset(0, 0), UDim2.fromOffset(BORDER, BORDER), Vector2.new(0, 0), Vector2.new(BORDER, BORDER))
	createPiece("FrameTopRight", UDim2.new(1, -BORDER, 0, 0), UDim2.fromOffset(BORDER, BORDER), Vector2.new(SOURCE_SIZE - BORDER, 0), Vector2.new(BORDER, BORDER))
	createPiece("FrameBottomLeft", UDim2.new(0, 0, 1, -BORDER), UDim2.fromOffset(BORDER, BORDER), Vector2.new(0, SOURCE_SIZE - BORDER), Vector2.new(BORDER, BORDER))
	createPiece("FrameBottomRight", UDim2.new(1, -BORDER, 1, -BORDER), UDim2.fromOffset(BORDER, BORDER), Vector2.new(SOURCE_SIZE - BORDER, SOURCE_SIZE - BORDER), Vector2.new(BORDER, BORDER))

	createPiece("FrameTop", UDim2.fromOffset(BORDER, 0), UDim2.new(1, -(BORDER * 2), 0, BORDER), Vector2.new(BORDER, 0), Vector2.new(EDGE_SIZE, BORDER))
	createPiece("FrameBottom", UDim2.new(0, BORDER, 1, -BORDER), UDim2.new(1, -(BORDER * 2), 0, BORDER), Vector2.new(BORDER, SOURCE_SIZE - BORDER), Vector2.new(EDGE_SIZE, BORDER))
	createPiece("FrameLeft", UDim2.new(0, 0, 0, BORDER), UDim2.new(0, BORDER, 1, -(BORDER * 2)), Vector2.new(0, BORDER), Vector2.new(BORDER, EDGE_SIZE))
	createPiece("FrameRight", UDim2.new(1, -BORDER, 0, BORDER), UDim2.new(0, BORDER, 1, -(BORDER * 2)), Vector2.new(SOURCE_SIZE - BORDER, BORDER), Vector2.new(BORDER, EDGE_SIZE))

	return pieces
end

export type WindowProps = {
	Title: string?,
	Icon: string?,
	IconImage: string?,
	AppId: string?,
	Size: UDim2?,
	Position: UDim2?,
	Parent: Instance,
	OnClose: (() -> ())?,
	OnMinimize: (() -> ())?,
	OnFocus: (() -> ())?,
}

function Window.Create(props: WindowProps)
	local rootFrame = Instance.new("Frame")
	rootFrame.Name = "WindowRoot"
	rootFrame.Size = props.Size or UDim2.fromOffset(560, 380)
	rootFrame.Position = props.Position or UDim2.fromScale(0.2, 0.18)
	rootFrame.BackgroundTransparency = 1
	rootFrame.Active = true
	rootFrame.Parent = props.Parent

	local contentClipFrame = Instance.new("Frame")
	contentClipFrame.Name = "ContentClipFrame"
	contentClipFrame.Position = UDim2.fromOffset(OUTER_BORDER, CONTENT_TOP)
	contentClipFrame.Size = UDim2.new(1, -(OUTER_BORDER * 2), 1, -(CONTENT_TOP + OUTER_BORDER))
	contentClipFrame.BackgroundColor3 = UITheme.Colors.AppBackground or Color3.fromRGB(5, 17, 33)
	contentClipFrame.BackgroundTransparency = 0
	contentClipFrame.BorderSizePixel = 0
	contentClipFrame.ClipsDescendants = true
	contentClipFrame.ZIndex = 10
	contentClipFrame.Parent = rootFrame

	local frameBorderPieces = createFrameBorderOverlay(rootFrame, 30)


	local titleBar = Instance.new("TextButton")
	titleBar.Name = "TitleBar"
	titleBar.Text = ""
	titleBar.AutoButtonColor = false
	titleBar.Size = UDim2.new(1, -(OUTER_BORDER * 2), 0, TITLE_BAR_HEIGHT)
	titleBar.Position = UDim2.fromOffset(OUTER_BORDER, OUTER_BORDER)
	titleBar.BackgroundColor3 = TITLE_BAR_LEFT
	titleBar.BackgroundTransparency = 0
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 20
	titleBar.Parent = rootFrame

	local titleBarGradient = Instance.new("Frame")
	titleBarGradient.Name = "TitleBarGradient"
	titleBarGradient.Size = UDim2.fromScale(1, 1)
	titleBarGradient.Position = UDim2.fromScale(0, 0)
	titleBarGradient.BackgroundTransparency = 1
	titleBarGradient.BorderSizePixel = 0
	titleBarGradient.ZIndex = 20
	titleBarGradient.Parent = titleBar

	local sliceCount = 256
	for i = 0, sliceCount - 1 do
		local t = if sliceCount > 1 then i / (sliceCount - 1) else 0
		local slice = Instance.new("Frame")
		slice.Name = string.format("Slice%d", i + 1)
		slice.Size = UDim2.new(1 / sliceCount, 0, 1, 0)
		slice.Position = UDim2.new(i / sliceCount, 0, 0, 0)
		slice.BackgroundColor3 = TITLE_BAR_LEFT:Lerp(TITLE_BAR_RIGHT, t)
		slice.BorderSizePixel = 0
		slice.ZIndex = 20
		slice.Parent = titleBarGradient
	end

	local titleBottomLine = Instance.new("Frame")
	titleBottomLine.Size = UDim2.new(1, 0, 0, 1)
	titleBottomLine.Position = UDim2.new(0, 0, 1, -1)
	titleBottomLine.BorderSizePixel = 0
	titleBottomLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	titleBottomLine.ZIndex = 20
	titleBottomLine.Parent = titleBar

	local appIcon = Instance.new("ImageLabel")
	appIcon.Name = "AppIcon"
	appIcon.Size = UDim2.fromOffset(16, 16)
	appIcon.Position = UDim2.fromOffset(10, 7)
	appIcon.BackgroundTransparency = 1
	appIcon.Image = props.IconImage or ""
	appIcon.ZIndex = 40
	appIcon.Parent = titleBar

	local fallbackIcon = Instance.new("TextLabel")
	fallbackIcon.Size = UDim2.fromOffset(16, 16)
	fallbackIcon.Position = UDim2.fromOffset(10, 7)
	fallbackIcon.BackgroundTransparency = 1
	fallbackIcon.Font = Enum.Font.ArialBold
	fallbackIcon.TextSize = 14
	fallbackIcon.TextColor3 = Color3.new(1, 1, 1)
	fallbackIcon.Text = props.Icon or "■"
	fallbackIcon.Visible = appIcon.Image == ""
	fallbackIcon.ZIndex = 40
	fallbackIcon.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleText"
	titleLabel.Size = UDim2.new(1, -96, 1, 0)
	titleLabel.Position = UDim2.fromOffset(33, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = props.Title or "Window.exe"
	titleLabel.TextColor3 = UITheme.Colors.TitleText
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.ArialBold
	titleLabel.TextSize = 14
	titleLabel.ZIndex = 40
	titleLabel.Parent = titleBar
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Thickness = 1
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Parent = titleLabel

	local function createCaptionButton(name: string, symbol: string, xOffset: number): ImageButton
		local button = Instance.new("ImageButton")
		button.Name = name
		button.AnchorPoint = Vector2.new(1, 0)
		button.Size = UDim2.fromOffset(23, 23)
		button.Position = UDim2.new(1, xOffset, 0, 2)
		button.BackgroundTransparency = 1
		button.Image = WINDOW_BUTTON_IMAGE
		button.ZIndex = 50
		button.Parent = titleBar
		local symbolLabel = Instance.new("TextLabel")
		symbolLabel.Size = UDim2.fromScale(1, 1)
		symbolLabel.BackgroundTransparency = 1
		symbolLabel.Text = symbol
		symbolLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
		symbolLabel.Font = Enum.Font.ArialBold
		symbolLabel.TextSize = 15
		symbolLabel.ZIndex = 51
		symbolLabel.Parent = button
		return button
	end

	local minimizeButton = createCaptionButton("MinimizeButton", "-", -33)
	local closeButton = createCaptionButton("CloseButton", "x", -8)

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.fromScale(1, 1)
	contentFrame.Position = UDim2.fromOffset(0, 0)
	contentFrame.BackgroundColor3 = UITheme.Colors.AppBackground or Color3.fromRGB(5, 17, 33)
	contentFrame.BackgroundTransparency = 0
	contentFrame.BorderSizePixel = 0
	contentFrame.ClipsDescendants = true
	contentFrame.ZIndex = 10
	contentFrame.Parent = contentClipFrame

	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.fromOffset(0, 0)

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = rootFrame.Position
			if props.OnFocus then props.OnFocus() end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			rootFrame.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	rootFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and props.OnFocus then props.OnFocus() end
	end)

	local isDestroyed = false
	local function destroyWindow()
		if isDestroyed then return end
		isDestroyed = true
		if rootFrame.Parent then rootFrame:Destroy() end
	end

	minimizeButton.Activated:Connect(function()
		rootFrame.Visible = false
		if props.OnMinimize then props.OnMinimize() end
	end)
	closeButton.Activated:Connect(function()
		if props.OnClose then props.OnClose() end
		destroyWindow()
	end)

	return { Root = rootFrame, Content = contentFrame, Destroy = destroyWindow, SetVisible = function(visible: boolean) rootFrame.Visible = visible end, SetZIndex = function(z)
		rootFrame.ZIndex = z
		contentClipFrame.ZIndex = z + 9
		contentFrame.ZIndex = z + 9
		titleBar.ZIndex = z + 19
		titleBarGradient.ZIndex = z + 19
		titleBottomLine.ZIndex = z + 19
		for _, gui in ipairs(titleBarGradient:GetChildren()) do
			if gui:IsA("GuiObject") then
				gui.ZIndex = z + 19
			end
		end
		for _, piece in ipairs(frameBorderPieces) do
			piece.ZIndex = z + 29
		end
		appIcon.ZIndex = z + 39
		fallbackIcon.ZIndex = z + 39
		titleLabel.ZIndex = z + 39
		minimizeButton.ZIndex = z + 49
		closeButton.ZIndex = z + 49
		for _, button in ipairs({ minimizeButton, closeButton }) do
			for _, gui in ipairs(button:GetChildren()) do
				if gui:IsA("GuiObject") then
					gui.ZIndex = z + 50
				end
			end
		end
		rootFrame.Visible = true
	end }
end

return Window
