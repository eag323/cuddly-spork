--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClickToolConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("ClickToolConfig"))

local UpgradesApp = {}
local root: Frame?

local function getToolLevel(context, toolId: string): number
	if context.State.PlayerData and context.State.PlayerData.ClickTools then
		return context.State.PlayerData.ClickTools[toolId] or 0
	end
	return 0
end

local function getNextUpgradeCost(tool, currentLevel: number): number
	local nextLevel = currentLevel + 1
	return tool.baseCost * (nextLevel ^ 2)
end

function UpgradesApp.Refresh(context): ()
	if not root then return end
	for _, child in root:GetChildren() do
		if child:IsA("Frame") and child.Name:find("Tool_") then
			local toolId = child:GetAttribute("ToolId")
			if type(toolId) == "string" then
				local tool
				for _, candidate in ClickToolConfig.Tools do
					if candidate.id == toolId then
						tool = candidate
						break
					end
				end
				if tool then
					local currentLevel = getToolLevel(context, toolId)
					local infoLabel = child:FindFirstChild("Info")
					local buyButton = child:FindFirstChild("Buy")
					if infoLabel and infoLabel:IsA("TextLabel") then
						infoLabel.Text = string.format(
							"%s | Lv %d/%d | +%d Food/click/level | Next: %d Coins",
							tool.displayName,
							currentLevel,
							tool.maxLevel,
							tool.foodPerClickPerLevel,
							getNextUpgradeCost(tool, currentLevel)
						)
					end
					if buyButton and buyButton:IsA("TextButton") then
						if currentLevel >= tool.maxLevel then
							buyButton.Text = "MAX"
						else
							buyButton.Text = string.format("Buy: %d Coins", getNextUpgradeCost(tool, currentLevel))
						end
					end
				end
			end
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
		local row = Instance.new("Frame")
		row.Name = "Tool_" .. tool.id
		row:SetAttribute("ToolId", tool.id)
		row.Size = UDim2.new(1, -20, 0, 52)
		row.Position = UDim2.fromOffset(10, 40 + ((i - 1) * 56))
		row.BackgroundTransparency = 1
		row.Parent = root

		local info = Instance.new("TextLabel")
		info.Name = "Info"
		info.Size = UDim2.new(0.67, 0, 1, 0)
		info.BackgroundTransparency = 1
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextYAlignment = Enum.TextYAlignment.Top
		info.TextColor3 = Color3.new(1, 1, 1)
		info.TextWrapped = true
		info.TextScaled = false
		info.Parent = row

		local buy = Instance.new("TextButton")
		buy.Name = "Buy"
		buy.Size = UDim2.new(0.3, 0, 0, 26)
		buy.Position = UDim2.new(0.7, 0, 0, 13)
		buy.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		buy.TextColor3 = Color3.new(1, 1, 1)
		buy.Parent = row
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
