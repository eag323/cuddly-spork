--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local BugLevelConfig = require(Shared:WaitForChild("Config"):WaitForChild("BugLevelConfig"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local BugLevelService = {}

local function normalizeBugLevelFields(bug)
	if type(bug) ~= "table" then return end
	local xp = math.max(0, math.floor(tonumber(bug.Xp) or tonumber(bug.XP) or 0))
	bug.Xp = xp
	bug.XP = nil
	bug.Level = BugLevelConfig.GetLevelFromXp(xp)
end

function BugLevelService.Init(): () end
function BugLevelService.Start(): () end

function BugLevelService.GrantCombatXp(player: Player, bugUids, xpAmount: number)
	local playerData = ProfileService.GetPlayerData(player)
	if not playerData then return {} end
	playerData.Bugs = playerData.Bugs or {}
	playerData.Bugs.Inventory = playerData.Bugs.Inventory or {}

	local inventory = playerData.Bugs.Inventory
	local safeXpAmount = math.max(0, math.floor(tonumber(xpAmount) or 0))
	local results = {}
	if safeXpAmount <= 0 or type(bugUids) ~= "table" then
		return results
	end

	local granted = {}
	for _, uidValue in pairs(bugUids) do
		local uid = tostring(uidValue)
		if not granted[uid] then
			local bug = inventory[uid]
			if type(bug) == "table" then
				normalizeBugLevelFields(bug)
				local oldXp = math.max(0, math.floor(tonumber(bug.Xp) or 0))
				local oldLevel = BugLevelConfig.GetLevelFromXp(oldXp)
				local maxXp = BugLevelConfig.GetTotalXpForLevel(BugLevelConfig.MaxLevel)
				local newXp = math.min(maxXp, oldXp + safeXpAmount)
				local newLevel = BugLevelConfig.GetLevelFromXp(newXp)
				bug.Xp = newXp
				bug.Level = newLevel

				local progress = BugLevelConfig.GetLevelProgress(newXp)
				table.insert(results, {
					Uid = uid,
					OldLevel = oldLevel,
					NewLevel = newLevel,
					OldXp = oldXp,
					NewXp = newXp,
					XpGained = newXp - oldXp,
					LeveledUp = newLevel > oldLevel,
					Progress = {
						Current = progress.Current,
						Required = progress.Required,
						Percent = progress.Percent,
					},
				})
				ProfileService.PatchPlayerState(player, { "Bugs", "Inventory", uid }, bug)
			end
			granted[uid] = true
		end
	end

	return results
end

return BugLevelService
