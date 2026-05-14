--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local BugConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugConfig"))
local UidUtil = require(Shared:WaitForChild("Util"):WaitForChild("UidUtil"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local BugBonusConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugBonusConfig"))

local BugInventoryService = {}

local function createUid(): string
	if type((UidUtil :: any).New) == "function" then
		return tostring((UidUtil :: any).New())
	end
	if type((UidUtil :: any).Generate) == "function" then
		return tostring((UidUtil :: any).Generate())
	end
	return string.format("bug_%d_%d_%d", os.time(), math.random(1000, 9999), math.floor(os.clock() * 1000000))
end

function BugInventoryService.Init(): () end
function BugInventoryService.Start(): () end

function BugInventoryService.CreateBug(player: Player, speciesId: string, rarity: string)
	local playerData = ProfileService.GetPlayerData(player)
	if not playerData then return nil end
	playerData.Bugs = playerData.Bugs or { Inventory = {}, Equipped = {}, SlotsUnlocked = 5 }
	playerData.Bugs.Inventory = playerData.Bugs.Inventory or {}
	local inventoryCount = 0
	for _ in pairs(playerData.Bugs.Inventory) do inventoryCount += 1 end
	if inventoryCount >= (tonumber(BugConfig.MaxOwnedBugs) or 1000) then
		return nil, "InventoryFull"
	end

	local bugCfg = BugConfig.GetBug(speciesId)
	local species = bugCfg
	if not species then
		for _, s in ipairs(BugConfig.Species or {}) do
			if s.id == speciesId then
				species = s
				break
			end
		end
	end
	if not species then return nil end

	local bonusStats = BugBonusConfig.RollBonusStats(species, rarity)
	local uid = createUid()
	while playerData.Bugs.Inventory[uid] ~= nil do
		uid = createUid()
	end

	local bug = {
		Uid = uid,
		BugId = speciesId,
		SpeciesId = speciesId,
		Species = species.displayName or species.species or speciesId,
		Rarity = rarity,
		Ascension = 0,
		Equipment = {},
		CaughtAt = os.time(),
		BonusStats = bonusStats,
		Primary = bonusStats[1] and {
			Stat = bonusStats[1].Id,
			Attribute = bonusStats[1].Id,
			Value = bonusStats[1].Value,
		} or nil,
		Secondaries = {},
		Modifier = nil,
		Locked = false,
		Favorited = false,
		CreatedAt = os.time(),
	}
	for i = 2, #bonusStats do
		local bonus = bonusStats[i]
		table.insert(bug.Secondaries, { Stat = bonus.Id, Attribute = bonus.Id, Value = bonus.Value })
	end
	playerData.Bugs.Inventory[uid] = bug
	ProfileService.PatchPlayerState(player, { "Bugs" }, playerData.Bugs)
	return bug, nil
end

return BugInventoryService
