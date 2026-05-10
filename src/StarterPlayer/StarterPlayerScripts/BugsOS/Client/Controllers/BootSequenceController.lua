--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIAssets = require(script.Parent.Parent.UI.UIAssets)

local BootSequenceController = {}

local context: { [string]: any }
local hasRun = false

local BootSequenceEnabled = true
local SkipBootSequenceInStudio = false
local SkipInputEnabled = true
local MinimumSkipDelaySeconds = 1
local BootTerminalFont = Enum.Font.Code
local BootTerminalColor = Color3.fromRGB(0, 255, 70)
local BootTerminalShadowColor = Color3.fromRGB(0, 80, 25)
local StartupSoundVolume = 0.5
local TypingSoundVolume = 0.3
local TypingSoundThrottleSeconds = 0.05

local BIOS_LINES = {
	"Bugs OS BIOS v1.0.0",
	"Copyright (c) 2026 BugSoft Inc.",
	"",
	"Detecting colony profile........ OK",
	"Calibrating bug sensors......... OK",
	"Loading Bugdex database......... 300 species found",
	"Checking food cache............. OK",
	"Initializing backyard map....... OK",
	"Starting Bugs.OS...",
}

local function safeDestroy(instance: Instance?)
	if instance and instance.Parent then
		instance:Destroy()
	end
end

local function createFullScreenFrame(parent: Instance, name: string, bgColor: Color3, zIndex: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = bgColor
	frame.BorderSizePixel = 0
	frame.ZIndex = zIndex
	frame.Parent = parent
	return frame
end

local function resolveBootTerminalFont(): Enum.Font
	local preferred = {
		BootTerminalFont,
		Enum.Font.Code,
		Enum.Font.RobotoMono,
		Enum.Font.Legacy,
		Enum.Font.Arcade,
	}
	for _, font in ipairs(preferred) do
		if font ~= nil then
			return font
		end
	end
	return Enum.Font.Code
end

local function createBootSound(parent: Instance, name: string, soundId: any, volume: number): Sound?
	if type(soundId) ~= "string" then
		return nil
	end
	local trimmed = soundId:gsub("%s+", "")
	if trimmed == "" or trimmed == "rbxassetid://0" then
		return nil
	end
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Sound") then
		return existing
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = trimmed
	sound.Volume = volume
	sound.Looped = false
	sound.RollOffMaxDistance = 20
	sound.Parent = parent
	return sound
end

local function runSequence()
	if hasRun then
		return
	end
	hasRun = true

	if not BootSequenceEnabled then
		return
	end

	if SkipBootSequenceInStudio and game:GetService("RunService"):IsStudio() then
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local bootGui = Instance.new("ScreenGui")
	bootGui.Name = "BugsOSBootSequence"
	bootGui.ResetOnSpawn = false
	bootGui.IgnoreGuiInset = true
	bootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	bootGui.DisplayOrder = 9999
	bootGui.Parent = playerGui

	local bootBlocker = Instance.new("TextButton")
	bootBlocker.Name = "BootBlocker"
	bootBlocker.Size = UDim2.fromScale(1, 1)
	bootBlocker.BackgroundTransparency = 1
	bootBlocker.Text = ""
	bootBlocker.AutoButtonColor = false
	bootBlocker.ZIndex = 10000
	bootBlocker.Parent = bootGui

	local canSkip = false
	if SkipInputEnabled then
		task.delay(MinimumSkipDelaySeconds, function()
			canSkip = true
		end)
	end

	local skipRequested = false
	local function onSkipInput()
		if canSkip then
			skipRequested = true
		end
	end

	local skipButtonConnection = bootBlocker.Activated:Connect(onSkipInput)
	local skipInputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space then
			onSkipInput()
		end
	end)

	local statusText: TextLabel? = nil
	local soundContainer = Instance.new("Folder")
	soundContainer.Name = "BootSequenceSounds"
	soundContainer.Parent = bootGui
	local startupSound = createBootSound(soundContainer, "StartupSound", UIAssets.Boot and UIAssets.Boot.StartupSound, StartupSoundVolume)
	local typingSound = createBootSound(soundContainer, "TypingSound", UIAssets.Boot and UIAssets.Boot.TypingSound, TypingSoundVolume)
	local lastTypingSoundTime = 0

	local function shouldSkip(): boolean
		return skipRequested
	end

	local function cleanup()
		skipButtonConnection:Disconnect()
		skipInputConnection:Disconnect()
		safeDestroy(bootGui)
	end

	local ok, err = pcall(function()
		local biosFrame = createFullScreenFrame(bootGui, "BIOSFrame", Color3.fromRGB(0, 0, 0), 10001)
		if startupSound then
			pcall(function()
				startupSound:Play()
			end)
		end
		local biosLog = Instance.new("TextLabel")
		biosLog.Name = "BIOSLog"
		biosLog.Size = UDim2.new(1, -40, 1, -40)
		biosLog.Position = UDim2.fromOffset(20, 20)
		biosLog.BackgroundTransparency = 1
		biosLog.TextXAlignment = Enum.TextXAlignment.Left
		biosLog.TextYAlignment = Enum.TextYAlignment.Top
		biosLog.TextColor3 = BootTerminalColor
		biosLog.Font = resolveBootTerminalFont()
		biosLog.TextSize = 20
		biosLog.TextWrapped = true
		biosLog.RichText = false
		biosLog.ZIndex = 10002
		biosLog.Parent = biosFrame
		local biosGlow = biosLog:Clone()
		biosGlow.Name = "BIOSLogGlow"
		biosGlow.Position = biosLog.Position + UDim2.fromOffset(1, 1)
		biosGlow.TextColor3 = BootTerminalShadowColor
		biosGlow.ZIndex = 10001
		biosGlow.Parent = biosFrame

		local built = ""
		for _, line in ipairs(BIOS_LINES) do
			if shouldSkip() then
				break
			end
			if built == "" then
				built = line
			else
				built = built .. "\n" .. line
			end
			biosLog.Text = built
			biosGlow.Text = built
			task.wait(0.35)
		end
		task.wait(0.45)

		if shouldSkip() then
			cleanup()
			return
		end

		biosFrame.Visible = false
		local logoFrame = createFullScreenFrame(bootGui, "LogoFrame", Color3.fromRGB(0, 0, 0), 10001)
		local logoText = Instance.new("TextLabel")
		logoText.Size = UDim2.fromOffset(420, 160)
		logoText.AnchorPoint = Vector2.new(0.5, 0.5)
		logoText.Position = UDim2.fromScale(0.5, 0.43)
		logoText.BackgroundTransparency = 1
		logoText.Text = "🐞 BUG.OS"
		logoText.TextColor3 = Color3.fromRGB(240, 240, 240)
		logoText.Font = Enum.Font.Arcade
		logoText.TextScaled = true
		logoText.ZIndex = 10002
		logoText.Parent = logoFrame

		statusText = Instance.new("TextLabel")
		statusText.Size = UDim2.fromOffset(360, 30)
		statusText.AnchorPoint = Vector2.new(0.5, 0)
		statusText.Position = UDim2.fromScale(0.5, 0.58)
		statusText.BackgroundTransparency = 1
		statusText.Text = "Starting Bugs.OS..."
		statusText.TextColor3 = Color3.fromRGB(225, 225, 225)
		statusText.Font = Enum.Font.Code
		statusText.TextSize = 22
		statusText.ZIndex = 10002
		statusText.Parent = logoFrame

		local barFrame = Instance.new("Frame")
		barFrame.Size = UDim2.fromOffset(420, 26)
		barFrame.AnchorPoint = Vector2.new(0.5, 0)
		barFrame.Position = UDim2.fromScale(0.5, 0.66)
		barFrame.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
		barFrame.BorderSizePixel = 1
		barFrame.BorderColor3 = Color3.fromRGB(90, 90, 90)
		barFrame.ZIndex = 10002
		barFrame.Parent = logoFrame

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0, 0, 1, -4)
		fill.Position = UDim2.fromOffset(2, 2)
		fill.BackgroundColor3 = Color3.fromRGB(35, 100, 220)
		fill.BorderSizePixel = 0
		fill.ZIndex = 10003
		fill.Parent = barFrame

		TweenService:Create(fill, TweenInfo.new(2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Size = UDim2.new(1, -4, 1, -4) }):Play()
		for _ = 1, 24 do
			if shouldSkip() then
				break
			end
			task.wait(0.1)
		end

		if shouldSkip() then
			cleanup()
			return
		end

		logoFrame.Visible = false
		local loginFrame = createFullScreenFrame(bootGui, "LoginFrame", Color3.fromRGB(0, 128, 128), 10001)
		local loginWindow = Instance.new("Frame")
		loginWindow.Size = UDim2.fromOffset(450, 250)
		loginWindow.AnchorPoint = Vector2.new(0.5, 0.5)
		loginWindow.Position = UDim2.fromScale(0.5, 0.5)
		loginWindow.BackgroundColor3 = Color3.fromRGB(192, 192, 192)
		loginWindow.BorderSizePixel = 1
		loginWindow.BorderColor3 = Color3.fromRGB(64, 64, 64)
		loginWindow.ZIndex = 10002
		loginWindow.Parent = loginFrame

		local titleBar = Instance.new("Frame")
		titleBar.Size = UDim2.new(1, 0, 0, 30)
		titleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 160)
		titleBar.BorderSizePixel = 0
		titleBar.ZIndex = 10003
		titleBar.Parent = loginWindow

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -12, 1, 0)
		title.Position = UDim2.fromOffset(8, 0)
		title.BackgroundTransparency = 1
		title.Text = "Log On to Bugs.OS"
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.Font = Enum.Font.ArialBold
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 10004
		title.Parent = titleBar

		local avatar = Instance.new("ImageLabel")
		avatar.Size = UDim2.fromOffset(88, 88)
		avatar.Position = UDim2.fromOffset(24, 62)
		avatar.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
		avatar.BorderSizePixel = 1
		avatar.BorderColor3 = Color3.fromRGB(128, 128, 128)
		avatar.ScaleType = Enum.ScaleType.Fit
		avatar.Image = ""
		avatar.ZIndex = 10003
		avatar.Parent = loginWindow

		local thumbOk, thumbContent = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if thumbOk and type(thumbContent) == "string" then
			avatar.Image = thumbContent
		end

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromOffset(280, 24)
		nameLabel.Position = UDim2.fromOffset(130, 62)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = player.DisplayName
		nameLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		nameLabel.Font = Enum.Font.ArialBold
		nameLabel.TextSize = 20
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 10003
		nameLabel.Parent = loginWindow

		local userLabel = Instance.new("TextLabel")
		userLabel.Size = UDim2.fromOffset(280, 20)
		userLabel.Position = UDim2.fromOffset(130, 88)
		userLabel.BackgroundTransparency = 1
		userLabel.Text = "@" .. player.Name
		userLabel.TextColor3 = Color3.fromRGB(52, 52, 52)
		userLabel.Font = Enum.Font.Arial
		userLabel.TextSize = 16
		userLabel.TextXAlignment = Enum.TextXAlignment.Left
		userLabel.ZIndex = 10003
		userLabel.Parent = loginWindow

		local passwordLabel = Instance.new("TextLabel")
		passwordLabel.Size = UDim2.fromOffset(80, 22)
		passwordLabel.Position = UDim2.fromOffset(130, 124)
		passwordLabel.BackgroundTransparency = 1
		passwordLabel.Text = "Password:"
		passwordLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		passwordLabel.Font = Enum.Font.Arial
		passwordLabel.TextSize = 16
		passwordLabel.TextXAlignment = Enum.TextXAlignment.Left
		passwordLabel.ZIndex = 10003
		passwordLabel.Parent = loginWindow

		local passwordBox = Instance.new("TextLabel")
		passwordBox.Size = UDim2.fromOffset(190, 24)
		passwordBox.Position = UDim2.fromOffset(216, 122)
		passwordBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		passwordBox.BorderSizePixel = 1
		passwordBox.BorderColor3 = Color3.fromRGB(112, 112, 112)
		passwordBox.Text = ""
		passwordBox.TextXAlignment = Enum.TextXAlignment.Left
		passwordBox.TextColor3 = Color3.fromRGB(0, 0, 0)
		passwordBox.Font = Enum.Font.Code
		passwordBox.TextSize = 18
		passwordBox.ZIndex = 10003
		passwordBox.Parent = loginWindow

		local okButton = Instance.new("TextButton")
		okButton.Size = UDim2.fromOffset(84, 28)
		okButton.Position = UDim2.fromOffset(244, 170)
		okButton.BackgroundColor3 = Color3.fromRGB(214, 214, 214)
		okButton.BorderColor3 = Color3.fromRGB(90, 90, 90)
		okButton.Text = "OK"
		okButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		okButton.Font = Enum.Font.Arial
		okButton.TextSize = 16
		okButton.AutoButtonColor = false
		okButton.ZIndex = 10003
		okButton.Parent = loginWindow

		local cancelButton = Instance.new("TextButton")
		cancelButton.Size = UDim2.fromOffset(84, 28)
		cancelButton.Position = UDim2.fromOffset(336, 170)
		cancelButton.BackgroundColor3 = Color3.fromRGB(214, 214, 214)
		cancelButton.BorderColor3 = Color3.fromRGB(90, 90, 90)
		cancelButton.Text = "Cancel"
		cancelButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		cancelButton.Font = Enum.Font.Arial
		cancelButton.TextSize = 16
		cancelButton.AutoButtonColor = false
		cancelButton.ZIndex = 10003
		cancelButton.Parent = loginWindow

		for i = 1, 8 do
			if shouldSkip() then
				break
			end
			passwordBox.Text = string.rep("*", i)
			if typingSound then
				local nowTime = os.clock()
				if nowTime - lastTypingSoundTime >= TypingSoundThrottleSeconds then
					lastTypingSoundTime = nowTime
					pcall(function()
						typingSound.TimePosition = 0
						typingSound:Play()
					end)
				end
			end
			task.wait(0.1)
		end

		okButton.BackgroundColor3 = Color3.fromRGB(188, 188, 188)
		task.wait(0.18)
		okButton.BackgroundColor3 = Color3.fromRGB(214, 214, 214)
		task.wait(0.1)

		local fade = Instance.new("Frame")
		fade.Size = UDim2.fromScale(1, 1)
		fade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		fade.BackgroundTransparency = 1
		fade.BorderSizePixel = 0
		fade.ZIndex = 10010
		fade.Parent = bootGui
		TweenService:Create(fade, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
		task.wait(0.45)
	end)

	if not ok then
		warn("[BugsOS] Boot sequence failed: " .. tostring(err))
	end

	cleanup()
end

function BootSequenceController.Init(initContext): ()
	context = initContext
end

function BootSequenceController.Start(): ()
	task.defer(runSequence)
end

return BootSequenceController
