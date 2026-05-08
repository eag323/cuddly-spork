--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("NumberFormatter"))

local ProfileApp = {}
local context
local windowRef

local function getDeps(runtimeContext)
	local deps = runtimeContext and runtimeContext.AppDependencies
	if not deps then
		warn("[BugsOS] ProfileApp missing State dependency")
		return nil
	end
	if not deps.State then
		warn("[BugsOS] ProfileApp missing State dependency")
		return nil
	end
	return deps
end

function ProfileApp.Init(c)
	context = c
end

function ProfileApp.Mount(target: Instance): ()
	local deps = getDeps(context)
	windowRef = Window.Create({
		Title = "Profile.exe",
		Size = UDim2.fromOffset(760, 560),
		Position = UDim2.fromScale(0.12, 0.08),
		Parent = target,
		OnClose = function()
			if context and context.Controllers and context.Controllers.Window then
				context.Controllers.Window.Close("Profile")
			end
		end,
	})

	local content = windowRef.Content
	local summary = Instance.new("TextLabel")
	summary.Size = UDim2.new(1, -16, 0, 90)
	summary.Position = UDim2.fromOffset(8, 8)
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.TextYAlignment = Enum.TextYAlignment.Top
	summary.BackgroundTransparency = 1
	summary.Parent = content

	if not deps then
		summary.Text = "Profile data is loading..."
		return
	end

	local d = deps.State.PlayerData or {}
	summary.Text = string.format(
		"%s\nPrestige: %s\nEquipped Title: %s\nLifetime Food: %s",
		Players.LocalPlayer.DisplayName,
		tostring((((d.Progression or {}).Prestige) or 0)),
		tostring(((((d.Cosmetics or {}).Equipped) or {}).Title) or "None"),
		NumberFormatter.Format(((((d.Currencies or {}).LifetimeFood) or 0)))
	)
end

function ProfileApp.Unmount(): ()
	if windowRef then windowRef.Root:Destroy() windowRef=nil end
end

return ProfileApp
