--!strict

local UserInputService = game:GetService("UserInputService")
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))

local Window = {}

export type WindowProps = {
	Title: string?,
	Icon: string?,
	AppId: string?,
	Size: UDim2?,
	Position: UDim2?,
	Parent: Instance,
	OnClose: (() -> ())?,
	OnFocus: (() -> ())?,
}

function Window.Create(props: WindowProps)
	local rootFrame = Instance.new("Frame")
	rootFrame.Name = "Window"
	rootFrame.Size = props.Size or UDim2.fromOffset(560, 380)
	rootFrame.Position = props.Position or UDim2.fromScale(0.2, 0.18)
	rootFrame.BackgroundColor3 = UITheme.Colors.WindowBody
	rootFrame.BorderColor3 = UITheme.Colors.WindowBorderLight
	rootFrame.BorderSizePixel = UITheme.Window.Border
	rootFrame.Active = true
	rootFrame.Parent = props.Parent

	local innerBorder = Instance.new("Frame")
	innerBorder.Name = "InnerBorder"
	innerBorder.Size = UDim2.new(1, -4, 1, -4)
	innerBorder.Position = UDim2.fromOffset(2, 2)
	innerBorder.BackgroundTransparency = 1
	innerBorder.BorderColor3 = UITheme.Colors.WindowInnerBorder
	innerBorder.BorderSizePixel = 1
	innerBorder.Parent = rootFrame

	local titleBar = Instance.new("TextButton")
	titleBar.Name = "TitleBar"
	titleBar.Text = ""
	titleBar.AutoButtonColor = false
	titleBar.Size = UDim2.new(1, 0, 0, UITheme.Window.TitleBarHeight)
	titleBar.BackgroundColor3 = UITheme.Colors.TitleBar
	titleBar.BorderSizePixel = 0
	titleBar.Parent = rootFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -82, 1, 0)
	titleLabel.Position = UDim2.fromOffset(6, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = string.format("%s  %s", props.Icon or "🗔", props.Title or "Window")
	titleLabel.TextColor3 = UITheme.Colors.TitleText
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = UITheme.Font
	titleLabel.TextSize = 16
	titleLabel.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Size = UDim2.fromOffset(22, 18)
	closeButton.Position = UDim2.new(1, -4, 0, 5)
	closeButton.Text = "×"
	closeButton.Font = UITheme.Font
	closeButton.TextSize = 14
	closeButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	closeButton.BackgroundColor3 = UITheme.Colors.ButtonFace
	closeButton.BorderColor3 = UITheme.Colors.ButtonShadow
	closeButton.Parent = titleBar

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -12, 1, -UITheme.Window.TitleBarHeight - 10)
	contentFrame.Position = UDim2.fromOffset(6, UITheme.Window.TitleBarHeight + 4)
	contentFrame.BackgroundColor3 = UITheme.Colors.WindowBody
	contentFrame.BorderColor3 = UITheme.Colors.WindowInnerBorder
	contentFrame.BorderSizePixel = 1
	contentFrame.Parent = rootFrame

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingLeft = UDim.new(0, UITheme.Window.ContentPadding)
	contentPadding.PaddingRight = UDim.new(0, UITheme.Window.ContentPadding)
	contentPadding.PaddingTop = UDim.new(0, UITheme.Window.ContentPadding)
	contentPadding.PaddingBottom = UDim.new(0, UITheme.Window.ContentPadding)
	contentPadding.Parent = contentFrame

	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.fromOffset(0,0)

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
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	rootFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and props.OnFocus then
			props.OnFocus()
		end
	end)

	local isDestroyed = false
	local function destroyWindow()
		if isDestroyed then return end
		isDestroyed = true
		if rootFrame.Parent then rootFrame:Destroy() end
	end

	closeButton.Activated:Connect(function()
		if props.OnClose then
			props.OnClose()
			if rootFrame.Parent then
				destroyWindow()
			end
			return
		end
		destroyWindow()
	end)

	return { Root = rootFrame, Content = contentFrame, Destroy = destroyWindow, SetZIndex = function(z)
		for _, gui in ipairs(rootFrame:GetDescendants()) do
			if gui:IsA("GuiObject") then gui.ZIndex = z end
		end
		rootFrame.ZIndex = z
		titleBar.BackgroundColor3 = UITheme.Colors.TitleBarActive
	end }
end

return Window
