--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("NumberFormatter"))
local RemoteNames = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Remotes"):WaitForChild("RemoteNames"))

local ProfileApp = {}
local context; local windowRef
function ProfileApp.Init(c) context = c end
function ProfileApp.Mount(target: Instance): ()
	windowRef = Window.Create({Title="Profile.exe", Size=UDim2.fromOffset(760,560), Position=UDim2.fromScale(0.12,0.08), Parent=target, OnClose=function() context.Controllers.Window.Close("Profile") end})
	local content = windowRef.Content
	local summary = Instance.new("TextLabel"); summary.Size=UDim2.new(1,-16,0,90); summary.Position=UDim2.fromOffset(8,8); summary.TextXAlignment=Enum.TextXAlignment.Left; summary.TextYAlignment=Enum.TextYAlignment.Top; summary.BackgroundTransparency=1; summary.Parent=content
	local d = context.State.PlayerData or {}
	summary.Text = string.format("%s\nPrestige: %s\nEquipped Title: %s\nLifetime Food: %s", Players.LocalPlayer.DisplayName, tostring((((d.Progression or {}).Prestige) or 0)), tostring(((((d.Cosmetics or {}).Equipped) or {}).Title) or "None"), NumberFormatter.Format(((((d.Currencies or {}).LifetimeFood) or 0))))
end
function ProfileApp.Unmount(): () if windowRef then windowRef.Root:Destroy() windowRef=nil end end
return ProfileApp
