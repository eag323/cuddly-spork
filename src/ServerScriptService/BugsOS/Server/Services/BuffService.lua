--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ConfigFolder = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config")
local ServicesFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server"):WaitForChild("Services")
local EconomyConfig = require(ConfigFolder:WaitForChild("EconomyConfig"))
local BugBonusConfig = require(ConfigFolder:WaitForChild("BugBonusConfig"))
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))

local BuffService = {}
local FARMER = { AllFood=true, FoodPerSec=true, ClickPower=true, SellBonus=true, NectarChance=true, BugLuck=true, BugSpawnRate=true, MinigameTime=true, ExpeditionSpeed=true, EquipmentDropRate=true, BugEssenceGain=true, OfflineEarnings=true, MinigameSpawnChance=true, BugPoints=true }
local COMBAT = { BugDamage=true, BugHP=true, BossDamage=true }

local function createEmptyBuffs()
	return { AllFood=0, FoodPerSec=0, ClickPower=0, SellBonus=0, NectarChance=0, BugLuck=0, BugSpawnRate=0, MinigameSpawnChance=0, MinigameTime=0, ExpeditionSpeed=0, EquipmentDropRate=0, BugEssenceGain=0, BugDamage=0, BugHP=0, BossDamage=0, OfflineEarnings=0, BugPoints=0 }
end

local function applyStat(buffs, statName, value, allowed)
	if type(statName)~='string' or type(value)~='number' or not allowed[statName] then return end
	if buffs[statName] ~= nil then buffs[statName] += value end
end

local function applyBugBonuses(buffs, bug, allowed)
	if type(bug) ~= 'table' then return end
	if type(bug.BonusStats) == 'table' and #bug.BonusStats > 0 then
		for _, bonus in ipairs(bug.BonusStats) do
			if type(bonus) == 'table' then applyStat(buffs, bonus.Id, bonus.Value, allowed) end
		end
		return
	end
	local p = bug.Primary
	if type(p) == 'table' then applyStat(buffs, p.Stat or p.Attribute, p.Value, allowed) end
	if type(bug.Secondaries) == 'table' then for _, s in ipairs(bug.Secondaries) do if type(s)=='table' then applyStat(buffs, s.Stat or s.Attribute, s.Value, allowed) end end end
end

function BuffService.GetPlayerBuffs(player)
	local buffs = createEmptyBuffs()
	local data = ProfileService.GetPlayerData(player)
	if not data or type(data.Bugs) ~= 'table' then return buffs end
	local bugs = data.Bugs
	local inv = bugs.Inventory
	if type(inv) ~= 'table' then return buffs end
	for _, uid in pairs(bugs.FarmerSlots or bugs.Equipped or {}) do if type(uid)=='string' then applyBugBonuses(buffs, inv[uid], FARMER) end end
	for _, uid in pairs(bugs.CombatSlots or {}) do if type(uid)=='string' then applyBugBonuses(buffs, inv[uid], COMBAT) end end
	buffs.MinigameSpawnChance = buffs.BugSpawnRate
	if EconomyConfig.DEV_DEBUG_BUFFS then print(string.format('[BuffService] Player buffs calculated for %s', player.Name), buffs) end
	return buffs
end

function BuffService.GetMultiplier(player, statName)
	local amount = BuffService.GetPlayerBuffs(player)[statName] or 0
	return 1 + amount
end
function BuffService.Init(): () end
function BuffService.Start(): () end
return BuffService
