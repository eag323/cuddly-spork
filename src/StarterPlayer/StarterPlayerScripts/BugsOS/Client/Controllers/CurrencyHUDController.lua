--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local ClickToolConfig = require(Shared:WaitForChild("Config"):WaitForChild("ClickToolConfig"))
local GeneratorConfig = require(Shared:WaitForChild("Config"):WaitForChild("GeneratorConfig"))
local NumberUtil = require(Shared:WaitForChild("Util"):WaitForChild("NumberUtil"))
local CurrencyHUDController = {}
local context; local labels={}; local generatorById={}; local clickToolBonusById={}
local function sanitizeLevel(v) if type(v)~='number' or v<1 then return 1 end return math.floor(v) end
local function prestigeMult(d) local p=(((d or {}).Progression or {}).Prestige or 0); return 1 + (0.1*p) end
local function calcFPS(d) local eq=((((d or {}).Generators or {}).Equipped)); if type(eq)~='table' then return 0 end local t=0; local m=prestigeMult(d); for _,s in eq do if type(s)=='table' and type(s.GeneratorId)=='string' then local g=generatorById[s.GeneratorId]; if g then local l=sanitizeLevel(s.Level); t += (g.baseFoodPerSec or 1)*(l^1.55)*m end end end; return t end
local function calcFPC(d) local t=1; local tools=(d or {}).ClickTools; if type(tools)~='table' then return t end for id,l in tools do if type(l)=='number' and l>0 and clickToolBonusById[id] then t += clickToolBonusById[id]*l end end return t end
local function refresh()
 local data=context.State.PlayerData; if type(data)~='table' then return end
 labels.Food.Text="Food: "..NumberUtil.FormatNumber((data.Currencies or {}).Food or 0)
 labels.Coins.Text="Coins: "..NumberUtil.FormatNumber((data.Currencies or {}).Coins or 0)
 labels.FPS.Text="Food/sec: "..NumberUtil.FormatNumber(calcFPS(data))
 labels.FPC.Text="Food/click: "..NumberUtil.FormatNumber(calcFPC(data))
 labels.Prestige.Text="Prestige: "..tostring((((data.Progression or {}).Prestige) or 0))
end
function CurrencyHUDController.Init(c) context=c; for _,e in ClickToolConfig.Tools do clickToolBonusById[e.id]=e.foodPerClickPerLevel end for _,e in GeneratorConfig.Generators do if e.classId=='snack' then generatorById[e.id]=e end end end
function CurrencyHUDController.Start()
 local frame=Instance.new('Frame'); frame.Name='CurrencyHUD'; frame.Position=UDim2.fromOffset(12,52); frame.Size=UDim2.fromOffset(240,158); frame.BackgroundColor3=Color3.fromRGB(0,0,0); frame.BackgroundTransparency=0.35; frame.Parent=context.UI.HUDLayer
 local names={{'Food',4},{'Coins',34},{'FPS',64},{'FPC',94},{'Prestige',124}}
 for _,n in ipairs(names) do local l=Instance.new('TextLabel'); l.Size=UDim2.new(1,-10,0,28); l.Position=UDim2.fromOffset(5,n[2]); l.BackgroundTransparency=1; l.TextColor3=Color3.new(1,1,1); l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=Enum.Font.GothamSemibold; l.TextSize=14; l.Parent=frame; labels[n[1]]=l end
 refresh()
end
function CurrencyHUDController.Refresh() refresh() end
return CurrencyHUDController
