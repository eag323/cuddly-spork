--!strict
local TweenService = game:GetService("TweenService")
local BugMinigameController = {}
local context; local bugRoot; local activeId
local function clear() if bugRoot then bugRoot:Destroy(); bugRoot=nil; activeId=nil end end
local function startMovement(button,behavior)
 task.spawn(function()
  while button.Parent do
   local pos=UDim2.fromScale(math.random(10,90)/100, math.random(15,80)/100)
   local d=behavior=="ZigZagger" and 0.45 or (behavior=="Dasher" and 0.2 or 1.0)
   if behavior=="Dasher" then task.wait(0.4) end
   TweenService:Create(button,TweenInfo.new(d,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{Position=pos}):Play()
   task.wait(d)
  end
 end)
end
function BugMinigameController.Init(c) context=c end
function BugMinigameController.Start()
 context.Remotes.BugSpawned.OnClientEvent:Connect(function(payload)
  clear()
  activeId=payload.ActiveBugId
  local holder=Instance.new("Frame"); holder.Name="BugMinigame"; holder.Size=UDim2.fromScale(1,1); holder.BackgroundTransparency=1; holder.Parent=context.UI.WorldLayer; bugRoot=holder
  local label=Instance.new("TextLabel"); label.Size=UDim2.fromOffset(320,24); label.Position=UDim2.fromOffset(12,12); label.BackgroundTransparency=1; label.TextColor3=Color3.new(1,1,1); label.TextXAlignment=Enum.TextXAlignment.Left; label.Text=string.format("%s [%s] Hits: %d",payload.DisplayName,payload.Rarity,payload.HitsRequired); label.Parent=holder
  local timer=Instance.new("Frame"); timer.Size=UDim2.fromOffset(320,8); timer.Position=UDim2.fromOffset(12,38); timer.BackgroundColor3=Color3.fromRGB(50,50,50); timer.Parent=holder
  local fill=Instance.new("Frame"); fill.Size=UDim2.fromScale(1,1); fill.BackgroundColor3=Color3.fromRGB(110,230,110); fill.Parent=timer
  local bug=Instance.new("TextButton"); bug.Size=UDim2.fromOffset(56,56); bug.Position=UDim2.fromScale(0.5,0.5); bug.Text="🐞"; bug.TextScaled=true; bug.BackgroundColor3=Color3.fromRGB(80,40,40); local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=bug; bug.Parent=holder
  local hits=payload.HitsRequired
  bug.Activated:Connect(function() if not activeId then return end; hits-=1; label.Text=string.format("%s [%s] Hits: %d",payload.DisplayName,payload.Rarity,math.max(hits,0)); context.Remotes.BugAttemptCatch:FireServer({ActiveBugId=activeId}) end)
  startMovement(bug,payload.Behavior)
  local duration=payload.Duration or 8; task.spawn(function() local s=os.clock(); while holder.Parent do local t=math.clamp(1-((os.clock()-s)/duration),0,1); fill.Size=UDim2.fromScale(t,1); if t<=0 then break end; task.wait(0.05) end end)
 end)
 context.Remotes.BugCaptured.OnClientEvent:Connect(function() clear() end)
 context.Remotes.BugEscaped.OnClientEvent:Connect(function() clear() end)
end
return BugMinigameController
