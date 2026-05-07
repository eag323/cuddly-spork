--!strict

local UITheme = {}

UITheme.Colors = {
	DesktopBackground = Color3.fromRGB(24, 102, 148),
	WindowBody = Color3.fromRGB(6, 22, 50),
	WindowBorderLight = Color3.fromRGB(212, 224, 255),
	WindowBorderDark = Color3.fromRGB(20, 34, 64),
	TitleBar = Color3.fromRGB(12, 45, 148),
	TitleBarActive = Color3.fromRGB(20, 101, 194),
	TitleText = Color3.fromRGB(243, 248, 255),
	ButtonFace = Color3.fromRGB(194, 194, 194),
	ButtonText = Color3.fromRGB(0, 0, 0),
	Panel = Color3.fromRGB(18, 47, 92),
	PanelBorder = Color3.fromRGB(48, 120, 202),
}

UITheme.Window = {
	TitleBarHeight = 28,
	Border = 2,
}

UITheme.Font = Enum.Font.ArialBold

return UITheme
