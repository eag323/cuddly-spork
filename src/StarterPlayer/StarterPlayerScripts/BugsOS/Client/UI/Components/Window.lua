--!strict

local Window = {}

export type WindowProps = {
	Title: string?,
	Size: UDim2?,
	Position: UDim2?,
	Parent: Instance,
	OnClose: (() -> ())?,
}

function Window.Create(props: WindowProps)
	local rootFrame = Instance.new("Frame")
	rootFrame.Name = "Window"
	rootFrame.Size = props.Size or UDim2.fromOffset(560, 380)
	rootFrame.Position = props.Position or UDim2.fromScale(0.2, 0.18)
	rootFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	rootFrame.BorderColor3 = Color3.fromRGB(80, 80, 88)
	rootFrame.BorderSizePixel = 1
	rootFrame.Parent = props.Parent

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 34)
	titleBar.BackgroundColor3 = Color3.fromRGB(45, 49, 60)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = rootFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -46, 1, 0)
	titleLabel.Position = UDim2.fromOffset(10, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = props.Title or "Window"
	titleLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Font = Enum.Font.GothamSemibold
	titleLabel.TextSize = 15
	titleLabel.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Size = UDim2.fromOffset(28, 24)
	closeButton.Position = UDim2.new(1, -6, 0, 5)
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 66, 66)
	closeButton.BorderSizePixel = 0
	closeButton.Parent = titleBar

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -16, 1, -48)
	contentFrame.Position = UDim2.fromOffset(8, 40)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = rootFrame

	local isDestroyed = false
	local function destroyWindow()
		if isDestroyed then
			return
		end
		isDestroyed = true
		if rootFrame.Parent then
			rootFrame:Destroy()
		end
	end

	closeButton.Activated:Connect(function()
		if props.OnClose then
			props.OnClose()
			return
		end
		destroyWindow()
	end)

	return {
		Root = rootFrame,
		Content = contentFrame,
		Destroy = destroyWindow,
	}
end

return Window
