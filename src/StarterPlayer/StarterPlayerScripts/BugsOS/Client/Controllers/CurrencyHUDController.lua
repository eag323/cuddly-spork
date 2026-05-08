--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local ClickToolConfig = require(Shared:WaitForChild("Config"):WaitForChild("ClickToolConfig"))
local GeneratorConfig = require(Shared:WaitForChild("Config"):WaitForChild("GeneratorConfig"))
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local UITheme = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UITheme"))
local UIAssets = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIAssets"))
local CurrencyHUDController = {}
local context; local labels={}; local generatorById={}; local clickToolBonusById={}

local function getBugBuffs(d)
 local buffs={AllFood=0,FoodPerSec=0,ClickPower=0}
 local bugs=((d or {}).Bugs or {})
 local inv=bugs.Inventory or {}
 local eq=bugs.Equipped or {}
 for _,uid in pairs(eq) do
  local bug=inv[uid]
  if type(bug)=="table" then
   local p=bug.Primary
   if type(p)=="table" and type(p.Value)=="number" then if buffs[p.Stat or p.Attribute]~=nil then buffs[p.Stat or p.Attribute]+=p.Value end end
   local ss=bug.Secondaries
   if type(ss)=="table" then for _,s in pairs(ss) do if type(s)=="table" and type(s.Value)=="number" and buffs[s.Stat or s.Attribute]~=nil then buffs[s.Stat or s.Attribute]+=s.Value end end end
  end
 end
 return buffs
end
local function sanitizeLevel(v) if type(v)~='number' or v<1 then return 1 end return math.floor(v) end
local function prestigeMult(d) local p=(((d or {}).Progression or {}).Prestige or 0); return 1 + (0.1*p) end
local function calcFPS(d) local eq=((((d or {}).Generators or {}).Equipped)); if type(eq)~="table" then return 0 end local t=0; local m=prestigeMult(d); for _,s in eq do if type(s)=="table" and type(s.GeneratorId)=="string" then local g=generatorById[s.GeneratorId]; if g then local l=sanitizeLevel(s.Level); t += (g.baseFoodPerSec or 1)*(l^1.55) end end end; local b=getBugBuffs(d); return t*m*(1+b.AllFood)*(1+b.FoodPerSec) end
local function calcFPC(d) local t=1; local tools=(d or {}).ClickTools; if type(tools)~="table" then return t end for id,l in tools do if type(l)=="number" and l>0 and clickToolBonusById[id] then t += clickToolBonusById[id]*l end end local b=getBugBuffs(d); return t*prestigeMult(d)*(1+b.AllFood)*(1+b.ClickPower) end
local function refresh()
 local data=context.State.PlayerData; if type(data)~='table' then return end
 labels.Food.Text="Food: "..NumberUtil.FormatNumber((data.Currencies or {}).Food or 0)
 labels.Coins.Text="Coins: "..NumberUtil.FormatNumber((data.Currencies or {}).Coins or 0)
 local bugPoints = data.BugPoints
 if type(bugPoints) ~= 'number' then
  bugPoints = ((data.LeaderboardStats or {}).BugPoints) or 0
 end
 labels.BugPoints.Text="Bug Points: "..NumberUtil.FormatNumber(bugPoints)
 labels.FPS.Text="Food/sec: "..NumberUtil.FormatNumber(calcFPS(data))
 labels.FPC.Text="Food/click: "..NumberUtil.FormatNumber(calcFPC(data))
 labels.Prestige.Text="Prestige: "..tostring((((data.Progression or {}).Prestige) or 0))
end
function CurrencyHUDController.Init(c) context=c; for _,e in ClickToolConfig.Tools do clickToolBonusById[e.id]=e.foodPerClickPerLevel end for _,e in GeneratorConfig.Generators do if e.classId=='snack' then generatorById[e.id]=e end end end
function CurrencyHUDController.Start()
 local frame=Instance.new('ImageLabel'); frame.Name='CurrencyTray'; frame.AnchorPoint=Vector2.new(1,0.5); frame.Position=UDim2.new(1,-8,0.5,0); frame.Size=UDim2.fromOffset(296,38); frame.BackgroundTransparency=1; frame.Image=UIAssets.TaskbarTabPressedImage; frame.ScaleType=Enum.ScaleType.Slice; frame.SliceCenter=UIAssets.SliceCenter; frame.Parent=context.UI.Taskbar
 local list=Instance.new("UIListLayout"); list.FillDirection=Enum.FillDirection.Horizontal; list.Padding=UDim.new(0,8); list.VerticalAlignment=Enum.VerticalAlignment.Center; list.Parent=frame
 local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8); pad.Parent=frame
 local names={'Food','Coins','BugPoints','FPS','FPC','Prestige'}
 for _,id in ipairs(names) do
  local item=Instance.new("Frame"); item.Size=UDim2.fromOffset(44,30); item.BackgroundTransparency=1; item.Parent=frame
  local icon=Instance.new("ImageLabel"); icon.Size=UDim2.fromOffset(12,12); icon.Position=UDim2.fromOffset(0,9); icon.BackgroundTransparency=1; icon.Image=UIAssets.CurrencyIconImages[id]; icon.Parent=item
  local l=Instance.new('TextLabel'); l.Size=UDim2.new(1,-14,1,0); l.Position=UDim2.fromOffset(14,0); l.BackgroundTransparency=1; l.TextColor3=Color3.new(0,0,0); l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=UITheme.Font; l.TextSize=11; l.Parent=item; labels[id]=l
 end
 refresh()
end
function CurrencyHUDController.Refresh() refresh() end
return CurrencyHUDController
