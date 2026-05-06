--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClickToolConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("ClickToolConfig"))

local UpgradesApp = {}
local root: Frame?

function UpgradesApp.Refresh(context): ()
	if not root then return end
	for _, child in root:GetChildren() do
		if child:IsA("TextButton") and child.Name:find("Buy_") then
			local toolId = child:GetAttribute("ToolId")
			local level = 0
			if context.State.PlayerData and context.State.PlayerData.ClickTools then
				level = context.State.PlayerData.ClickTools[toolId] or 0
			end
			child.Text = string.format("Buy (%d)", level)
		end
	end
end

function UpgradesApp.Mount(target: Instance, context): ()
	if root then return end
	root = Instance.new("Frame")
	root.Name = "UpgradesWindow"
	root.Position = UDim2.fromScale(0.24, 0.16)
	root.Size = UDim2.fromScale(0.38, 0.55)
	root.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	root.Parent = target

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(30, 30)
	close.Position = UDim2.new(1, -35, 0, 5)
	close.Text = "X"
	close.Parent = root
	close.Activated:Connect(function() context.Controllers.Window.Close("Upgrades") end)

	for i, tool in ipairs(ClickToolConfig.Tools) do
		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(0.62, 0, 0, 28)
		name.Position = UDim2.fromOffset(10, 40 + ((i - 1) * 34))
		name.BackgroundTransparency = 1
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Text = tool.displayName
		name.Parent = root

		local buy = Instance.new("TextButton")
		buy.Name = "Buy_" .. tool.id
		buy:SetAttribute("ToolId", tool.id)
		buy.Size = UDim2.new(0.3, 0, 0, 26)
		buy.Position = UDim2.new(0.67, 0, 0, 41 + ((i - 1) * 34))
		buy.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		buy.TextColor3 = Color3.new(1, 1, 1)
		buy.Parent = root
		buy.Activated:Connect(function()
			context.Controllers.Upgrade.BuyTool(tool.id)
		end)
	end

	UpgradesApp.Refresh(context)
end

function UpgradesApp.Unmount(): ()
	if root then root:Destroy() end
	root = nil
end

return UpgradesApp
