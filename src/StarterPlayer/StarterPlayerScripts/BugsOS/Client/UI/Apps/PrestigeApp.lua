--!strict

local PrestigeApp = {}

local root: Frame?

local PRESTIGE_REQUIREMENT = 50000000

function PrestigeApp.Mount(target: Instance, context): ()
	if root then return end

	root = Instance.new("Frame")
	root.Name = "PrestigeWindow"
	root.Position = UDim2.fromScale(0.2, 0.2)
	root.Size = UDim2.fromScale(0.32, 0.34)
	root.BackgroundColor3 = Color3.fromRGB(36, 24, 52)
	root.Parent = target

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 32)
	title.Position = UDim2.fromOffset(10, 8)
	title.BackgroundTransparency = 1
	title.Text = "Prestige.exe"
	title.TextColor3 = Color3.fromRGB(255, 230, 120)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = root

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(30, 30)
	close.Position = UDim2.new(1, -35, 0, 5)
	close.Text = "X"
	close.Parent = root
	close.Activated:Connect(function() context.Controllers.Window.Close("Prestige") end)

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -20, 0, 92)
	body.Position = UDim2.fromOffset(10, 48)
	body.BackgroundTransparency = 1
	body.TextWrapped = true
	body.TextColor3 = Color3.new(1, 1, 1)
	body.Text = "Requirement: 50,000,000 Lifetime Food\nResets Food/Coins/ClickTools/Generators\nKeeps Lifetime Food + Prestige"
	body.Parent = root

	local confirm = Instance.new("TextButton")
	confirm.Size = UDim2.fromOffset(180, 36)
	confirm.Position = UDim2.fromOffset(14, 150)
	confirm.Text = "Prestige Now"
	confirm.BackgroundColor3 = Color3.fromRGB(92, 45, 130)
	confirm.TextColor3 = Color3.new(1, 1, 1)
	confirm.Parent = root

	confirm.Activated:Connect(function()
		local lifetimeFood = (((context.State.PlayerData or {}).Currencies or {}).LifetimeFood or 0)
		if lifetimeFood < PRESTIGE_REQUIREMENT then
			return
		end
		if type(context.UI.ShowConfirmPopup) == "function" then
			context.UI.ShowConfirmPopup("Prestige and reset current run progress?", function()
				context.Remotes.PrestigeRequest:FireServer({ Confirm = true })
			end)
		else
			context.Remotes.PrestigeRequest:FireServer({ Confirm = true })
		end
	end)
end

function PrestigeApp.Unmount(): ()
	if root then root:Destroy() end
	root = nil
end

return PrestigeApp
