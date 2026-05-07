--!strict

local UITheme = {}

UITheme.Colors = {
	DesktopBackground = Color3.fromRGB(22, 93, 156),
	DesktopBackgroundDark = Color3.fromRGB(10, 53, 102),
	DesktopPattern = Color3.fromRGB(39, 122, 184),
	WindowBody = Color3.fromRGB(6, 22, 50),
	WindowBorderLight = Color3.fromRGB(233, 238, 252),
	WindowBorderDark = Color3.fromRGB(54, 70, 106),
	WindowInnerBorder = Color3.fromRGB(20, 34, 64),
	TitleBar = Color3.fromRGB(9, 64, 208),
	TitleBarActive = Color3.fromRGB(27, 118, 236),
	TitleText = Color3.fromRGB(243, 248, 255),
	ButtonFace = Color3.fromRGB(201, 201, 201),
	ButtonText = Color3.fromRGB(0, 0, 0),
	ButtonShadow = Color3.fromRGB(68, 68, 68),
	ButtonHighlight = Color3.fromRGB(244, 244, 244),
	TaskbarFace = Color3.fromRGB(196, 196, 196),
	TaskbarBorderLight = Color3.fromRGB(241, 241, 241),
	TaskbarBorderDark = Color3.fromRGB(101, 101, 101),
	Panel = Color3.fromRGB(18, 47, 92),
	PanelBorder = Color3.fromRGB(55, 148, 224),
	PanelBorderInner = Color3.fromRGB(24, 75, 156),
	IconSelected = Color3.fromRGB(18, 88, 200),
}

UITheme.Window = {
	TitleBarHeight = 28,
	Border = 2,
	ContentPadding = 8,
}

UITheme.Font = Enum.Font.ArialBold

return UITheme
