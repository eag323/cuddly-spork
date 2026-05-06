--!strict

local FoodHarvestersApp = {}
local root: Frame?
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeneratorConfig = require(
	ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GeneratorConfig")
)

local generatorById = {}
for _, generator in ipairs(GeneratorConfig.Generators) do
	generatorById[generator.id] = generator
end

function FoodHarvestersApp.Refresh(context): ()
	if not root then return end
	local equipped = nil
	if context.State.PlayerData and context.State.PlayerData.Generators then
		equipped = context.State.PlayerData.Generators.Equipped
	end
	for i = 1, 3 do
		local label = root:FindFirstChild("SlotLabel" .. i) :: TextLabel
		local upgrade = root:FindFirstChild("SlotUpgrade" .. i) :: TextButton
		local entry = equipped and equipped[i]
		local generator = entry and generatorById[entry.GeneratorId] or nil
		local name = generator and generator.displayName or "Empty Slot"
		local level = entry and entry.Level or 0
		local baseFoodPerSec = generator and generator.baseFoodPerSec or 0
		local estimatedFoodPerSec = baseFoodPerSec * level
		label.Text = string.format("Slot %d | %s | Level %d | Food/sec %.1f", i, name, level, estimatedFoodPerSec)
		upgrade.Visible = entry ~= nil
	end
end

function FoodHarvestersApp.Mount(target: Instance, context): ()
	if root then return end
	root = Instance.new("Frame")
	root.Name = "FoodHarvestersWindow"
	root.Position = UDim2.fromScale(0.18, 0.1)
	root.Size = UDim2.fromScale(0.4, 0.56)
	root.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	root.Parent = target

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(30, 30)
	close.Position = UDim2.new(1, -35, 0, 5)
	close.Text = "X"
	close.Parent = root
	close.Activated:Connect(function() context.Controllers.Window.Close("FoodHarvesters") end)

	for i = 1, 3 do
		local label = Instance.new("TextLabel")
		label.Name = "SlotLabel" .. i
		label.Size = UDim2.new(0.65, 0, 0, 34)
		label.Position = UDim2.fromOffset(10, 40 + ((i - 1) * 70))
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = root

		local upgrade = Instance.new("TextButton")
		upgrade.Name = "SlotUpgrade" .. i
		upgrade.Size = UDim2.new(0.28, 0, 0, 30)
		upgrade.Position = UDim2.new(0.68, 0, 0, 42 + ((i - 1) * 70))
		upgrade.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		upgrade.TextColor3 = Color3.new(1, 1, 1)
		upgrade.Text = "Upgrade"
		upgrade.Parent = root
		upgrade.Activated:Connect(function()
			context.Controllers.Generator.Upgrade(i)
		end)

		local generatorButtons = {
			{ id = "plain_cracker", label = "Equip Plain Cracker" },
			{ id = "potato_chip", label = "Equip Potato Chip" },
			{ id = "cookie_crumb", label = "Equip Cookie Crumb" },
		}
		for buttonIndex, info in ipairs(generatorButtons) do
			local equip = Instance.new("TextButton")
			equip.Size = UDim2.new(0.28, 0, 0, 22)
			equip.Position = UDim2.new(0.68, 0, 0, 74 + ((i - 1) * 70) + ((buttonIndex - 1) * 24))
			equip.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			equip.TextColor3 = Color3.new(1, 1, 1)
			equip.Text = info.label
			equip.TextSize = 12
			equip.Parent = root
			equip.Activated:Connect(function()
				context.Controllers.Generator.Equip(i, info.id)
			end)
		end
	end

	FoodHarvestersApp.Refresh(context)
end

function FoodHarvestersApp.Unmount(): ()
	if root then root:Destroy() end
	root = nil
end

return FoodHarvestersApp
