--!strict

local UITheme = {}

UITheme.Colors = {
	DesktopBackground = Color3.fromRGB(22, 93, 156),
	DesktopBackgroundDark = Color3.fromRGB(10, 53, 102),
	DesktopPattern = Color3.fromRGB(39, 122, 184),
	WindowBody = Color3.fromRGB(6, 22, 50),
	AppBackground = Color3.fromRGB(5, 17, 33),
	PanelBackground = Color3.fromRGB(14, 35, 61),
	PanelDarker = Color3.fromRGB(7, 20, 38),
	CardBackground = Color3.fromRGB(18, 45, 78),
	BorderCyan = Color3.fromRGB(0, 210, 255),
	AccentYellow = Color3.fromRGB(255, 190, 0),
	AccentGreen = Color3.fromRGB(0, 220, 130),
	AccentRed = Color3.fromRGB(255, 65, 85),
	TextMuted = Color3.fromRGB(145, 170, 200),
	WindowBorderLight = Color3.fromRGB(233, 238, 252),
	WindowBorderDark = Color3.fromRGB(54, 70, 106),
	WindowInnerBorder = Color3.fromRGB(20, 34, 64),
	TitleBarDark = Color3.fromRGB(0, 18, 130),
	TitleBarLight = Color3.fromRGB(0, 115, 210),
	TitleText = Color3.fromRGB(243, 248, 255),
}

UITheme.Assets = {
	WindowFrame = "rbxassetid://138529502428069",
	WindowButton = "rbxassetid://128179488793090",
}

UITheme.Window = {
	TitleBarHeight = 28,
	ContentPadding = 8,
	FrameSlice = Rect.new(10, 10, 54, 54),
}

function UITheme.CreatePanel(parent: Instance, size: UDim2, position: UDim2): Frame
	local panel = Instance.new("Frame")
	panel.Size = size
	panel.Position = position
	panel.BackgroundColor3 = UITheme.Colors.PanelBackground
	panel.BorderSizePixel = 0
	panel.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = UITheme.Colors.BorderCyan
	stroke.Thickness = 1
	stroke.Parent = panel
	return panel
end

UITheme.Font = Enum.Font.ArialBold

return UITheme
