--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ConfigFolder = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config")
local ServicesFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server"):WaitForChild("Services")
local EconomyConfig = require(ConfigFolder:WaitForChild("EconomyConfig"))
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))

local BuffService = {}

export type BuffTotals = {
	AllFood: number,
	FoodPerSec: number,
	ClickPower: number,
	SellBonus: number,
	NectarChance: number,
	BugLuck: number,
	MinigameSpawnChance: number,
	MinigameTime: number,
	ExpeditionSpeed: number,
	OfflineEarnings: number,
	BugPoints: number,
}

local BUFF_KEYS = {
	"AllFood",
	"FoodPerSec",
	"ClickPower",
	"SellBonus",
	"NectarChance",
	"BugLuck",
	"MinigameSpawnChance",
	"MinigameTime",
	"ExpeditionSpeed",
	"OfflineEarnings",
	"BugPoints",
}

local function createEmptyBuffs(): BuffTotals
	return {
		AllFood = 0,
		FoodPerSec = 0,
		ClickPower = 0,
		SellBonus = 0,
		NectarChance = 0,
		BugLuck = 0,
		MinigameSpawnChance = 0,
		MinigameTime = 0,
		ExpeditionSpeed = 0,
		OfflineEarnings = 0,
		BugPoints = 0,
	}
end

local function applyStat(buffs: BuffTotals, statName: any, value: any): ()
	if type(statName) ~= "string" then
		return
	end
	if type(value) ~= "number" then
		return
	end
	if buffs[statName] == nil then
		return
	end
	buffs[statName] += value
end

function BuffService.GetPlayerBuffs(player: Player): BuffTotals
	local buffs = createEmptyBuffs()
	local playerData = ProfileService.GetPlayerData(player)
	if not playerData then
		return buffs
	end

	local bugs = playerData.Bugs
	if type(bugs) ~= "table" then
		return buffs
	end

	local equipped = bugs.Equipped
	local inventory = bugs.Inventory
	if type(equipped) ~= "table" or type(inventory) ~= "table" then
		return buffs
	end

	for _, uid in equipped do
		if type(uid) == "string" then
			local bug = inventory[uid]
			if type(bug) == "table" then
				local primary = bug.Primary
				if type(primary) == "table" then
					applyStat(buffs, primary.Stat or primary.Attribute, primary.Value)
				end
				local secondaries = bug.Secondaries
				if type(secondaries) == "table" then
					for _, secondary in secondaries do
						if type(secondary) == "table" then
							applyStat(buffs, secondary.Stat or secondary.Attribute, secondary.Value)
						end
					end
				end
			end
		end
	end

	if EconomyConfig.DEV_DEBUG_BUFFS then
		print(string.format("[BuffService] Player buffs calculated for %s", player.Name), buffs)
	end
	return buffs
end

function BuffService.GetMultiplier(player: Player, statName: string): number
	local buffs = BuffService.GetPlayerBuffs(player)
	local amount = buffs[statName] or 0
	return 1 + amount
end

function BuffService.Init(): () end
function BuffService.Start(): () end

return BuffService
