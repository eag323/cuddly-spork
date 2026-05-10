--!strict

local UserInputService = game:GetService("UserInputService")
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))

local Window = {}
local TITLE_BAR_LEFT = Color3.fromRGB(0, 3, 129)
local TITLE_BAR_RIGHT = Color3.fromRGB(15, 131, 207)

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
	contentClipFrame.Size = UDim2.new(1, -12, 1, -UITheme.Window.TitleBarHeight - 13)
	contentClipFrame.Position = UDim2.fromOffset(6, UITheme.Window.TitleBarHeight + 7)
	contentClipFrame.BackgroundTransparency = 1
	contentClipFrame.BorderSizePixel = 0
	contentClipFrame.ClipsDescendants = true
	contentClipFrame.ZIndex = 1
	contentClipFrame.Parent = rootFrame

	local windowFrameImage = Instance.new("ImageLabel")
	windowFrameImage.Name = "WindowFrameImage"
	windowFrameImage.Size = UDim2.fromScale(1, 1)
	windowFrameImage.BackgroundTransparency = 1
	windowFrameImage.Image = UITheme.Assets.WindowFrame
	windowFrameImage.ScaleType = Enum.ScaleType.Slice
	windowFrameImage.SliceCenter = UITheme.Window.FrameSlice
	windowFrameImage.ZIndex = 2
	windowFrameImage.Parent = rootFrame

	local titleBar = Instance.new("TextButton")
	titleBar.Name = "TitleBar"
	titleBar.Text = ""
	titleBar.AutoButtonColor = false
	titleBar.Size = UDim2.new(1, -12, 0, UITheme.Window.TitleBarHeight)
	titleBar.Position = UDim2.fromOffset(6, 6)
	titleBar.BackgroundColor3 = TITLE_BAR_LEFT
	titleBar.BackgroundTransparency = 0
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 3
	titleBar.Parent = rootFrame

	local titleBarGradient = Instance.new("Frame")
	titleBarGradient.Name = "TitleBarGradient"
	titleBarGradient.Size = UDim2.fromScale(1, 1)
	titleBarGradient.Position = UDim2.fromScale(0, 0)
	titleBarGradient.BackgroundTransparency = 1
	titleBarGradient.BorderSizePixel = 0
	titleBarGradient.ZIndex = 3
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
		slice.ZIndex = 3
		slice.Parent = titleBarGradient
	end

	local titleBottomLine = Instance.new("Frame")
	titleBottomLine.Size = UDim2.new(1, 0, 0, 1)
	titleBottomLine.Position = UDim2.new(0, 0, 1, -1)
	titleBottomLine.BorderSizePixel = 0
	titleBottomLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	titleBottomLine.ZIndex = 4
	titleBottomLine.Parent = titleBar

	local appIcon = Instance.new("ImageLabel")
	appIcon.Name = "AppIcon"
	appIcon.Size = UDim2.fromOffset(16, 16)
	appIcon.Position = UDim2.fromOffset(6, 5)
	appIcon.BackgroundTransparency = 1
	appIcon.Image = props.IconImage or ""
	appIcon.ZIndex = 4
	appIcon.Parent = titleBar

	local fallbackIcon = Instance.new("TextLabel")
	fallbackIcon.Size = UDim2.fromOffset(16, 16)
	fallbackIcon.Position = UDim2.fromOffset(6, 5)
	fallbackIcon.BackgroundTransparency = 1
	fallbackIcon.Font = Enum.Font.ArialBold
	fallbackIcon.TextSize = 14
	fallbackIcon.TextColor3 = Color3.new(1, 1, 1)
	fallbackIcon.Text = props.Icon or "■"
	fallbackIcon.Visible = appIcon.Image == ""
	fallbackIcon.ZIndex = 4
	fallbackIcon.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleText"
	titleLabel.Size = UDim2.new(1, -96, 1, 0)
	titleLabel.Position = UDim2.fromOffset(26, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = props.Title or "Window.exe"
	titleLabel.TextColor3 = UITheme.Colors.TitleText
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.ArialBold
	titleLabel.TextSize = 14
	titleLabel.ZIndex = 4
	titleLabel.Parent = titleBar
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Thickness = 1
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Parent = titleLabel

	local function createCaptionButton(name: string, symbol: string, xOffset: number): ImageButton
		local button = Instance.new("ImageButton")
		button.Name = name
		button.AnchorPoint = Vector2.new(1, 0)
		button.Size = UDim2.fromOffset(18, 18)
		button.Position = UDim2.new(1, xOffset, 0, 4)
		button.BackgroundTransparency = 1
		button.Image = UITheme.Assets.WindowButton
		button.ZIndex = 4
		button.Parent = titleBar
		local symbolLabel = Instance.new("TextLabel")
		symbolLabel.Size = UDim2.fromScale(1, 1)
		symbolLabel.BackgroundTransparency = 1
		symbolLabel.Text = symbol
		symbolLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
		symbolLabel.Font = Enum.Font.ArialBold
		symbolLabel.TextSize = 14
		symbolLabel.ZIndex = 5
		symbolLabel.Parent = button
		return button
	end

	local minimizeButton = createCaptionButton("MinimizeButton", "-", -26)
	local closeButton = createCaptionButton("CloseButton", "x", -6)

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.fromScale(1, 1)
	contentFrame.Position = UDim2.fromOffset(0, 0)
	contentFrame.BackgroundColor3 = UITheme.Colors.AppBackground
	contentFrame.BorderSizePixel = 0
	contentFrame.ZIndex = 1
	contentFrame.Parent = contentClipFrame

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingLeft = UDim.new(0, UITheme.Window.ContentPadding)
	contentPadding.PaddingRight = UDim.new(0, UITheme.Window.ContentPadding)
	contentPadding.PaddingTop = UDim.new(0, UITheme.Window.ContentPadding)
	contentPadding.PaddingBottom = UDim.new(0, UITheme.Window.ContentPadding)
	contentPadding.Parent = contentFrame

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
		local function setIfGui(instance: Instance, zIndex: number)
			if instance:IsA("GuiObject") then
				instance.ZIndex = zIndex
			end
		end
		rootFrame.ZIndex = z
		setIfGui(contentClipFrame, z)
		setIfGui(contentFrame, z)
		setIfGui(windowFrameImage, z + 1)
		setIfGui(titleBar, z + 2)
		for _, gui in ipairs(titleBar:GetDescendants()) do
			if gui:IsA("GuiObject") then
				if gui.Name == "TitleBarGradient" or gui.Name:match("^Slice%d+$") then
					gui.ZIndex = z + 2
				else
					gui.ZIndex = z + 3
				end
			end
		end
		rootFrame.Visible = true
	end }
end

return Window
