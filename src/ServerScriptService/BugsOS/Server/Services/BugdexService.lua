--!strict

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local BugdexService = {}

local function ensureBugdexState(playerData)
	playerData.Bugdex = playerData.Bugdex or {}
	playerData.Bugdex.TotalCaughtBySpecies = playerData.Bugdex.TotalCaughtBySpecies or {}
	return playerData.Bugdex
end

function BugdexService.RecordCatch(player: Player, speciesId: string): ()
	if type(speciesId) ~= "string" or speciesId == "" then
		return
	end

	local playerData = ProfileService.GetPlayerData(player)
	if not playerData then
		return
	end

	local bugdex = ensureBugdexState(playerData)
	local currentCount = tonumber(bugdex.TotalCaughtBySpecies[speciesId]) or 0
	bugdex.TotalCaughtBySpecies[speciesId] = currentCount + 1

	ProfileService.PatchPlayerState(player, { "Bugdex" }, bugdex)
end

function BugdexService.Init(): () end
function BugdexService.Start(): () end

return BugdexService
