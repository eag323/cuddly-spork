--!strict
local TweenService=game:GetService("TweenService")
local EnemySpawnController={} local context; local activeEnemy; local enemyGui; local popup
local function clearEnemy() if enemyGui then enemyGui:Destroy(); enemyGui=nil end end
local function closePopup() if popup then popup:Destroy(); popup=nil end end
local function makePopup(enemy)
 closePopup(); local hud=context.UI.HUDLayer; if not hud then return end
 popup=Instance.new("Frame"); popup.Size=UDim2.fromOffset(360,340); popup.Position=UDim2.fromScale(0.5,0.5); popup.AnchorPoint=Vector2.new(0.5,0.5); popup.BackgroundColor3=Color3.fromRGB(20,20,20); popup.BorderSizePixel=0; popup.ZIndex=40; popup.Parent=hud
 local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-20,0,28); title.Position=UDim2.fromOffset(10,8); title.BackgroundTransparency=1; title.Text=enemy.DisplayName; title.TextColor3=Color3.fromRGB(255,70,70); title.Font=Enum.Font.GothamBold; title.TextSize=18; title.ZIndex=41; title.Parent=popup
 local info=Instance.new("TextLabel"); info.Size=UDim2.new(1,-20,0,120); info.Position=UDim2.fromOffset(10,44); info.BackgroundTransparency=1; info.TextXAlignment=Enum.TextXAlignment.Left; info.TextYAlignment=Enum.TextYAlignment.Top; info.TextWrapped=true; info.Font=Enum.Font.Gotham; info.TextSize=14; info.TextColor3=Color3.fromRGB(230,230,230); info.Text=string.format("Tier: %s\nPower: %d\nRole: %s\nSpecies: %s\nRewards: Bug Essence %d, Bug Dust %d",enemy.Tier,enemy.Power,enemy.Role,enemy.Species,enemy.RewardsPreview.BugEssence or 0,enemy.RewardsPreview.BugDust or 0); info.ZIndex=41; info.Parent=popup
 local warn=Instance.new("TextLabel"); warn.Size=UDim2.new(1,-20,0,40); warn.Position=UDim2.fromOffset(10,168); warn.BackgroundTransparency=1; warn.Text="Equip bugs in Bugs.exe > Combat Team first."; warn.TextWrapped=true; warn.TextColor3=Color3.fromRGB(255,190,120); warn.Font=Enum.Font.Gotham; warn.TextSize=13; warn.ZIndex=41; warn.Parent=popup
 local result=Instance.new("TextLabel"); result.Name="Result"; result.Size=UDim2.new(1,-20,0,24); result.Position=UDim2.fromOffset(10,210); result.BackgroundTransparency=1; result.TextColor3=Color3.fromRGB(255,255,255); result.Font=Enum.Font.GothamBold; result.TextSize=14; result.ZIndex=41; result.Parent=popup
 local attack=Instance.new("TextButton"); attack.Size=UDim2.fromOffset(150,36); attack.Position=UDim2.fromOffset(10,294); attack.Text="Attack"; attack.BackgroundColor3=Color3.fromRGB(160,40,40); attack.TextColor3=Color3.new(1,1,1); attack.Font=Enum.Font.GothamBold; attack.TextSize=14; attack.ZIndex=41; attack.Parent=popup
 local close=Instance.new("TextButton"); close.Size=UDim2.fromOffset(90,36); close.Position=UDim2.fromOffset(260,294); close.Text="Close"; close.BackgroundColor3=Color3.fromRGB(55,55,55); close.TextColor3=Color3.new(1,1,1); close.Font=Enum.Font.Gotham; close.TextSize=14; close.ZIndex=41; close.Parent=popup
 close.MouseButton1Click:Connect(closePopup)
 attack.MouseButton1Click:Connect(function() attack.Active=false; attack.Text="Attacking..."; context.Remotes.EnemyBugAttack:FireServer({EnemyId=enemy.EnemyId}) end)
end
local function renderEnemy(enemy)
 clearEnemy(); local world=context.UI.WorldLayer; if not world then return end
 local root=Instance.new("ImageButton"); root.Name="EnemyBug_"..enemy.EnemyId; root.Size=UDim2.fromOffset(76,76); root.AnchorPoint=Vector2.new(0.5,0.5); root.Position=UDim2.fromScale(enemy.Position.XScale,enemy.Position.YScale); root.BackgroundTransparency=1; root.Image=enemy.Icon or ""; root.ZIndex=12; root.Parent=world
 local aura=Instance.new("Frame"); aura.Size=UDim2.fromOffset(108,108); aura.AnchorPoint=Vector2.new(0.5,0.5); aura.Position=UDim2.fromScale(0.5,0.5); aura.BackgroundColor3=Color3.fromRGB(255,0,0); aura.BackgroundTransparency=0.45; aura.ZIndex=11; aura.Parent=root; local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=aura
 local nameplate=Instance.new("TextLabel"); nameplate.Size=UDim2.fromOffset(170,24); nameplate.AnchorPoint=Vector2.new(0.5,0); nameplate.Position=UDim2.new(0.5,0,1,6); nameplate.BackgroundColor3=Color3.new(0,0,0); nameplate.TextColor3=Color3.fromRGB(255,70,70); nameplate.Font=Enum.Font.GothamBold; nameplate.TextSize=13; nameplate.Text=enemy.DisplayName; nameplate.ZIndex=13; nameplate.Parent=root; local nc=Instance.new("UICorner"); nc.CornerRadius=UDim.new(1,0); nc.Parent=nameplate
 TweenService:Create(aura,TweenInfo.new(0.9,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=0.7}):Play()
 root.MouseButton1Click:Connect(function() makePopup(enemy) end); enemyGui=root
end
function EnemySpawnController.Init(c) context=c end
function EnemySpawnController.Start()
 context.Remotes.EnemyBugSpawned.OnClientEvent:Connect(function(enemy) activeEnemy=enemy; renderEnemy(enemy) end)
 context.Remotes.EnemyBugDespawned.OnClientEvent:Connect(function(payload) if activeEnemy and payload and payload.EnemyId==activeEnemy.EnemyId then activeEnemy=nil; clearEnemy() closePopup() end end)
 context.Remotes.EnemyBugAttackResult.OnClientEvent:Connect(function(result)
  if not popup then return end local label=popup:FindFirstChild("Result")
  if label and label:IsA("TextLabel") then
   if result.Success==false then label.Text="Failed: "..tostring(result.Reason)
   elseif result.Winner=="Player" then label.Text=string.format("Victory! +%d Essence, +%d Dust",result.Rewards.BugEssence or 0,result.Rewards.BugDust or 0)
   else label.Text="Result: "..tostring(result.Winner) end
  end
 end)
end
return EnemySpawnController
