--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local Shared=ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local Remotes=Shared:WaitForChild("Remotes")
local Config=Shared:WaitForChild("Config")
local RemoteNames=require(Remotes:WaitForChild("RemoteNames"))
local BugConfig=require(Config:WaitForChild("BugConfig"))
local BugAscensionConfig=require(Config:WaitForChild("BugAscensionConfig"))
local EnemySpawnConfig=require(Config:WaitForChild("EnemySpawnConfig"))
local BattleSimulator=require(Shared:WaitForChild("Combat"):WaitForChild("BattleSimulator"))
local ProfileService=require(script.Parent:WaitForChild("ProfileService"))
local S={} local remotes={} local activeByUserId={}
local function ensureRemote(name) local e=Remotes:FindFirstChild(name); if e and e:IsA("RemoteEvent") then return e end local r=Instance.new("RemoteEvent"); r.Name=name; r.Parent=Remotes; return r end
local function power(st) return math.floor((st.HP or 0)+((st.ATK or 0)*4)+((st.DEF or 0)*3)+((st.SPD or 0)*2)+((st.CritRate or 0)*8)+(st.CritDamage or 0)+((st.RES or 0)*2)+((st.ACC or 0)*2)) end
local function tierRoll() local total=0 for _,t in pairs(EnemySpawnConfig.Tiers) do total+=t.Weight end local r=math.random()*total; local acc=0 for name,t in pairs(EnemySpawnConfig.Tiers) do acc+=t.Weight if r<=acc then return name,t end end return "CommonEnemy", EnemySpawnConfig.Tiers.CommonEnemy end
local function randomBug() local ids={} for id,_ in pairs(BugConfig.Bugs) do table.insert(ids,id) end if #ids==0 then return nil end return BugConfig.Bugs[ids[math.random(1,#ids)]] end
local function spawnForPlayer(player)
 if activeByUserId[player.UserId] then return end
 local cfg=randomBug(); if not cfg then return end; local tierName,tier=tierRoll(); local mult=tonumber(tier.StatMultiplier) or 1
 local bs=cfg.stats or {} local stats={HP=math.max(1,math.floor((bs.HP or 1)*mult)),ATK=math.max(1,math.floor((bs.ATK or 1)*mult)),DEF=math.max(0,math.floor((bs.DEF or 0)*mult)),SPD=math.max(1,math.floor((bs.SPD or 1)*mult)),CritRate=math.floor(bs.CritRate or 0),CritDamage=math.floor(bs.CritDamage or 100),RES=math.floor(bs.RES or 0),ACC=math.floor(bs.ACC or 0)}
 local rewards={BugEssence=math.random(tier.RewardBugEssence.Min,tier.RewardBugEssence.Max)}
 local enemyId=HttpService:GenerateGUID(false); local prefix=tierName=="CommonEnemy" and "Enemy" or string.gsub(tierName,"Enemy$","")
 local enemy={EnemyId=enemyId,BugId=cfg.id,DisplayName=string.format("%s %s",prefix,cfg.displayName),Rarity=cfg.rarity,Species=cfg.species,Role=cfg.role,Icon=cfg.icon or cfg.sprite,Tier=tierName,Power=power(stats),Position={XScale=math.random(12,88)/100,YScale=math.random(15,78)/100},RewardsPreview=rewards,Stats=stats,ExpiresAt=os.time()+EnemySpawnConfig.EnemyLifetimeSeconds}
 activeByUserId[player.UserId]=enemy; remotes.Spawned:FireClient(player,enemy)
 task.delay(EnemySpawnConfig.EnemyLifetimeSeconds,function() local cur=activeByUserId[player.UserId]; if cur and cur.EnemyId==enemyId then activeByUserId[player.UserId]=nil; remotes.Despawned:FireClient(player,{EnemyId=enemyId,Reason="Expired"}) end end)
end
local function buildCombatTeam(player)
 local d=ProfileService.GetPlayerData(player); if not d then return nil,"NoCombatTeam" end local inv=((d.Bugs or {}).Inventory) or {}; local slots=((d.Bugs or {}).CombatSlots) or {}; local team={}
 for _,uid in pairs(slots) do local entry=inv[uid]; if entry then local cfg=BugConfig.GetBug(entry.BugId) or BugConfig.Bugs[entry.BugId]; if cfg then local mult=BugAscensionConfig.GetCombatMultiplier(tonumber(entry.Ascension) or 0); local s=cfg.stats; table.insert(team,{Id=uid,Name=entry.Nickname or cfg.displayName,Icon=cfg.icon,Rarity=cfg.rarity,Rank=tonumber(entry.Ascension) or 0,Team="Player",Stats={HP=math.floor(s.HP*mult),ATK=math.floor(s.ATK*mult),DEF=math.floor(s.DEF*mult),SPD=math.floor(s.SPD*mult),CritRate=s.CritRate,CritDamage=s.CritDamage,RES=s.RES,ACC=s.ACC}}) end end end
 if #team==0 then return nil,"NoCombatTeam" end return team,nil,d end
function S.Init() remotes.Spawned=ensureRemote(RemoteNames.EnemyBug_Spawned); remotes.Despawned=ensureRemote(RemoteNames.EnemyBug_Despawned); remotes.Attack=ensureRemote(RemoteNames.EnemyBug_Attack); remotes.AttackResult=ensureRemote(RemoteNames.EnemyBug_AttackResult) end
function S.Start()
 Players.PlayerRemoving:Connect(function(p) activeByUserId[p.UserId]=nil end)
 task.spawn(function() while true do for _,p in ipairs(Players:GetPlayers()) do if ProfileService.GetPlayerData(p) and not activeByUserId[p.UserId] then spawnForPlayer(p) end end task.wait(math.random(EnemySpawnConfig.SpawnIntervalSecondsMin,EnemySpawnConfig.SpawnIntervalSecondsMax)) end end)
 remotes.Attack.OnServerEvent:Connect(function(player,payload)
  local requestEnemyId = type(payload)=="table" and payload.EnemyId or nil
  print("[EnemySpawnService] Attack request", player.Name, tostring(requestEnemyId))

  if type(payload)~="table" or type(payload.EnemyId)~="string" then warn("[EnemySpawnService] Attack rejected: InvalidPayload"); remotes.AttackResult:FireClient(player,{Success=false,Reason="InvalidPayload",EnemyId=requestEnemyId}); return end
  local enemy=activeByUserId[player.UserId]; if not enemy then warn("[EnemySpawnService] Attack rejected: NoEnemy"); remotes.AttackResult:FireClient(player,{Success=false,Reason="NoEnemy",EnemyId=payload.EnemyId}); return end
  if enemy.EnemyId~=payload.EnemyId then warn("[EnemySpawnService] Attack rejected: NoEnemy"); remotes.AttackResult:FireClient(player,{Success=false,Reason="NoEnemy",EnemyId=payload.EnemyId}); return end
  if os.time()>enemy.ExpiresAt then activeByUserId[player.UserId]=nil; warn("[EnemySpawnService] Attack rejected: EnemyExpired"); remotes.Despawned:FireClient(player,{EnemyId=enemy.EnemyId,Reason="Expired"}); remotes.AttackResult:FireClient(player,{Success=false,Reason="EnemyExpired",EnemyId=enemy.EnemyId}); return end
  local team,reason,d=buildCombatTeam(player); if not team then warn("[EnemySpawnService] Attack rejected: "..tostring(reason)); remotes.AttackResult:FireClient(player,{Success=false,Reason=reason,EnemyId=enemy.EnemyId}); return end
  local res=BattleSimulator.Run(team,{{Id=enemy.EnemyId,Name=enemy.DisplayName,Icon=enemy.Icon,Rarity=enemy.Rarity,Rank=0,Team="Enemy",Stats=enemy.Stats}},os.time(),40)
  local out={
   Success=true,
   EnemyId=enemy.EnemyId,
   Winner=res.Winner,
   Turns=res.Turns,
   PlayerRemaining=res.PlayerRemaining,
   EnemyRemaining=res.EnemyRemaining,
   Rewards={BugEssence=0},
   Log=res.Log,
   FinalUnits=res.FinalUnits,
   EnemyName=enemy.DisplayName,
   EnemyIcon=enemy.Icon
  }
  print("[EnemySpawnService] Attack resolved", tostring(res.Winner), enemy.EnemyId)
  if res.Winner=="Player" then d.Currencies=d.Currencies or {}; d.Currencies.BugEssence=(tonumber(d.Currencies.BugEssence)or 0)+(enemy.RewardsPreview.BugEssence or 0); out.Rewards={BugEssence=enemy.RewardsPreview.BugEssence or 0}
   ProfileService.PatchPlayerState(player,{"Currencies","BugEssence"},d.Currencies.BugEssence)
  end
  activeByUserId[player.UserId]=nil
  remotes.AttackResult:FireClient(player,out)
  local resultReason=(res.Winner=="Player") and "Defeated" or "EscapedAfterBattle"
  task.delay(0.5,function() remotes.Despawned:FireClient(player,{EnemyId=enemy.EnemyId,Reason=resultReason}) end)
 end)
end
return S
