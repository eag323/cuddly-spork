--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local BugConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugConfig"))
local UidUtil = require(Shared:WaitForChild("Util"):WaitForChild("UidUtil"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local BugInventoryService = {}

local RARITY_RANGES = {
	Common = { 0.01, 0.05 },
	Uncommon = { 0.03, 0.08 },
	Rare = { 0.06, 0.14 },
	Epic = { 0.1, 0.22 },
	Legendary = { 0.16, 0.32 },
	Mythic = { 0.24, 0.45 },
}

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

	local species = nil
	for _, s in ipairs(BugConfig.Species) do
		if s.id == speciesId then
			species = s
			break
		end
	end
	if not species then return nil end

	local statPool = BugConfig.StatTypes or {}
	if #statPool == 0 then return nil end
	local statId = species.primaryStatType
	if type(statId) ~= "string" or statId == "" then
		statId = statPool[math.random(1, #statPool)]
	end
	local range = RARITY_RANGES[rarity] or RARITY_RANGES.Common
	local baseValue = tonumber(species.primaryStatValue) or Random.new():NextNumber(range[1], range[2])
	local value = math.clamp(baseValue * Random.new():NextNumber(0.95, 1.05), range[1], range[2])
	local uid = createUid()
	while playerData.Bugs.Inventory[uid] ~= nil do
		uid = createUid()
	end

	local bug = {
		Uid = uid,
		SpeciesId = speciesId,
		Species = species.displayName,
		Rarity = rarity,
		Primary = {
			Stat = statId,
			Attribute = statId,
			Value = value,
		},
		Secondaries = {},
		Modifier = nil,
		Locked = false,
		Favorited = false,
		CreatedAt = os.time(),
	}
	playerData.Bugs.Inventory[uid] = bug
	ProfileService.PatchPlayerState(player, { "Bugs" }, playerData.Bugs)
	return bug
end

return BugInventoryService
