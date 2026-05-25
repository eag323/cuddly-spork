--!strict
local BattleSimulator = {}
local function cloneUnit(unit, team)
 local stats=unit.Stats or {}
 return {Id=unit.Id,Name=unit.Name,Icon=unit.Icon,Rarity=unit.Rarity,Rank=unit.Rank,Team=team,Stats={HP=math.max(1,math.floor(tonumber(stats.HP)or 1)),ATK=math.max(0,math.floor(tonumber(stats.ATK)or 0)),DEF=math.max(0,math.floor(tonumber(stats.DEF)or 0)),SPD=math.max(0,math.floor(tonumber(stats.SPD)or 0)),CritRate=math.max(0,tonumber(stats.CritRate)or 0),CritDamage=math.max(100,tonumber(stats.CritDamage)or 100),RES=math.max(0,tonumber(stats.RES)or 0),ACC=math.max(0,tonumber(stats.ACC)or 0)},CurrentHP=math.max(1,math.floor(tonumber(stats.HP)or 1))}
end
local function alive(units, team) local r={} for _,u in ipairs(units) do if u.Team==team and u.CurrentHP>0 then table.insert(r,u) end end return r end
function BattleSimulator.Run(playerUnits, enemyUnits, seed, maxTurns)
 local rng=Random.new(math.floor(tonumber(seed)or os.time())); local turnsCap=math.max(1,math.floor(tonumber(maxTurns)or 40)); local units,log={},{}
 for _,u in ipairs(playerUnits or {}) do table.insert(units,cloneUnit(u,"Player")) end; for _,u in ipairs(enemyUnits or {}) do table.insert(units,cloneUnit(u,"Enemy")) end
 for turn=1,turnsCap do
  table.sort(units,function(a,b) if a.CurrentHP<=0 and b.CurrentHP>0 then return false end if b.CurrentHP<=0 and a.CurrentHP>0 then return true end if a.Stats.SPD==b.Stats.SPD then return tostring(a.Id)<tostring(b.Id) end return a.Stats.SPD>b.Stats.SPD end)
  for _,actor in ipairs(units) do if actor.CurrentHP<=0 then continue end
   local opponents=alive(units,actor.Team=="Player" and "Enemy" or "Player"); if #opponents==0 then return {Winner=actor.Team,Turns=turn,PlayerRemaining=#alive(units,"Player"),EnemyRemaining=#alive(units,"Enemy"),Log=log,FinalUnits=units} end
   local target=opponents[rng:NextInteger(1,#opponents)]; local damage=math.max(1,math.floor((actor.Stats.ATK*1.6)-(target.Stats.DEF*0.65))); local isCrit=rng:NextNumber(0,100)<=actor.Stats.CritRate; if isCrit then damage=math.max(1,math.floor(damage*(actor.Stats.CritDamage/100))) end
   target.CurrentHP=math.max(0,target.CurrentHP-damage); table.insert(log,string.format("%s%s hits %s for %d damage.",isCrit and "CRIT! " or "",actor.Name,target.Name,damage)); if target.CurrentHP<=0 then table.insert(log,string.format("%s is defeated.",target.Name)) end
  end
  if #alive(units,"Player")==0 or #alive(units,"Enemy")==0 then local winner=#alive(units,"Player")>0 and "Player" or "Enemy"; return {Winner=winner,Turns=turn,PlayerRemaining=#alive(units,"Player"),EnemyRemaining=#alive(units,"Enemy"),Log=log,FinalUnits=units} end
 end
 local function hpPct(team) local cur,max=0,0 for _,u in ipairs(units) do if u.Team==team then cur+=u.CurrentHP; max+=u.Stats.HP end end return max>0 and (cur/max) or 0 end
 local p,e=hpPct("Player"),hpPct("Enemy"); local winner="Draw"; if p>e then winner="Player" elseif e>p then winner="Enemy" end
 return {Winner=winner,Turns=turnsCap,PlayerRemaining=#alive(units,"Player"),EnemyRemaining=#alive(units,"Enemy"),Log=log,FinalUnits=units}
end
return BattleSimulator
