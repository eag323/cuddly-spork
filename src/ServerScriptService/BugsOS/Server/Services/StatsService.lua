--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local ServicesFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server"):WaitForChild("Services")
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))

type PlayerData = { [string]: any }

local StatsService = {}

local function getData(player: Player): PlayerData?
	return ProfileService.GetPlayerData(player)
end

function StatsService.Get(player: Player, statId: string): number
	local data = getData(player)
	if not data then return 0 end
	local stats = data.Stats
	if type(stats) ~= "table" then return 0 end
	local value = stats[statId]
	if type(value) ~= "number" then return 0 end
	return value
end

function StatsService.Increment(player: Player, statId: string, amount: number?): number
	local data = getData(player)
	if not data then return 0 end
	if type(data.Stats) ~= "table" then data.Stats = {} end
	local delta = if type(amount) == "number" then amount else 1
	local current = data.Stats[statId]
	if type(current) ~= "number" then current = 0 end
	local nextValue = current + delta
	data.Stats[statId] = nextValue
	ProfileService.PatchPlayerState(player, { "Stats", statId }, nextValue)
	return nextValue
end

function StatsService.Set(player: Player, statId: string, value: number): number
	local data = getData(player)
	if not data then return 0 end
	if type(data.Stats) ~= "table" then data.Stats = {} end
	data.Stats[statId] = value
	ProfileService.PatchPlayerState(player, { "Stats", statId }, value)
	return value
end

function StatsService.Init(): () end
function StatsService.Start(): ()
	Players.PlayerAdded:Connect(function(player)
		local data = getData(player)
		if data and type(data.Stats) ~= "table" then
			data.Stats = {}
			ProfileService.PatchPlayerState(player, { "Stats" }, data.Stats)
		end
	end)
end

return StatsService
