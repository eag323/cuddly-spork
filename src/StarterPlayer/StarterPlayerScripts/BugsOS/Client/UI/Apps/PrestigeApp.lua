--!strict
local Window = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Window"))
local PrestigeApp = {}
local root: Frame?
local windowRef
local PRESTIGE_REQUIREMENT = 50000000
function PrestigeApp.Mount(target, context)
 if root then return end
 windowRef=Window.Create({Title="Prestige.exe", Size=UDim2.fromOffset(520,300), Position=UDim2.fromScale(0.22,0.2), Parent=target, OnClose=function() context.Controllers.Window.Close("Prestige") end})
 root=windowRef.Content
 local body=Instance.new("TextLabel"); body.Size=UDim2.new(1,-12,0,120); body.BackgroundTransparency=1; body.TextWrapped=true; body.TextColor3=Color3.new(1,1,1); body.TextXAlignment=Enum.TextXAlignment.Left; body.TextYAlignment=Enum.TextYAlignment.Top; body.Text="Requirement: 50,000,000 Lifetime Food\nResets Food/Coins/ClickTools/Generators\nKeeps Lifetime Food + Prestige"; body.Parent=root
 local confirm=Instance.new("TextButton"); confirm.Size=UDim2.fromOffset(220,40); confirm.Position=UDim2.fromOffset(0,140); confirm.Text="Prestige Now"; confirm.BackgroundColor3=Color3.fromRGB(92,45,130); confirm.TextColor3=Color3.new(1,1,1); confirm.Parent=root
 local prestigeRequestRemote = context.Remotes and context.Remotes.PrestigeRequest
 confirm.Activated:Connect(function()
  local lf=((((context.State.PlayerData or {}).Currencies or {}).LifetimeFood) or 0)
  if lf<PRESTIGE_REQUIREMENT or not prestigeRequestRemote then return end
  local showConfirmPopup = context.UI and context.UI.ShowConfirmPopup
  if type(showConfirmPopup)=="function" then
   showConfirmPopup("Prestige and reset current run progress?", function()
    prestigeRequestRemote:FireServer({Confirm=true})
   end)
  else
   prestigeRequestRemote:FireServer({Confirm=true})
  end
 end)
end
function PrestigeApp.Unmount() if windowRef then windowRef.Destroy() end; root=nil; windowRef=nil end
return PrestigeApp
