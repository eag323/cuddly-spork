--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")

local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

local ServerScriptService = game:GetService("ServerScriptService")
local BugsOSServerFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server")
local ServicesFolder = BugsOSServerFolder:WaitForChild("Services")

local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))

local PrestigeService = {}

local PRESTIGE_ONE_REQUIREMENT = 50000000
local prestigeRequestRemote: RemoteEvent? = nil

local function getOrCreateRemoteEvent(remoteName: string): RemoteEvent
	local existingRemote = RemotesFolder:FindFirstChild(remoteName)
	if existingRemote and existingRemote:IsA("RemoteEvent") then
		return existingRemote
	end

	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = remoteName
	remoteEvent.Parent = RemotesFolder
	return remoteEvent
end

function PrestigeService.GetPrestigeMultiplier(player: Player): number
	local playerData = ProfileService.GetPlayerData(player)
	if not playerData or type(playerData.Progression) ~= "table" then
		return 1
	end

	local prestige = playerData.Progression.Prestige
	if type(prestige) ~= "number" or prestige < 0 then
		return 1
	end

	return 1 + (prestige * 0.1)
end

local function onPrestigeRequest(player: Player, payload: any): ()
	if type(payload) ~= "table" or payload.Confirm ~= true then
		return
	end

	local playerData = ProfileService.GetPlayerData(player)
	if not playerData or type(playerData.Currencies) ~= "table" or type(playerData.Progression) ~= "table" then
		return
	end

	local lifetimeFood = playerData.Currencies.LifetimeFood
	if type(lifetimeFood) ~= "number" or lifetimeFood < PRESTIGE_ONE_REQUIREMENT then
		return
	end

	local prestige = playerData.Progression.Prestige
	if type(prestige) ~= "number" then
		prestige = 0
	end
	playerData.Progression.Prestige = prestige + 1

	playerData.Currencies.Food = 0
	playerData.Currencies.Coins = 0
	playerData.ClickTools = {}
	playerData.Generators = {
		SlotsUnlocked = 3,
		Equipped = {},
	}

	ProfileService.PatchPlayerState(player, { "Progression", "Prestige" }, playerData.Progression.Prestige)
	ProfileService.PatchPlayerState(player, { "Currencies", "Food" }, 0)
	ProfileService.PatchPlayerState(player, { "Currencies", "Coins" }, 0)
	ProfileService.PatchPlayerState(player, { "ClickTools" }, playerData.ClickTools)
	ProfileService.PatchPlayerState(player, { "Generators" }, playerData.Generators)
end

function PrestigeService.Init(): ()
	local prestigeRequestName = RemoteNames.Prestige_Request or "Prestige_Request"
	prestigeRequestRemote = getOrCreateRemoteEvent(prestigeRequestName)
end

function PrestigeService.Start(): ()
	if prestigeRequestRemote then
		prestigeRequestRemote.OnServerEvent:Connect(onPrestigeRequest)
	end
end

return PrestigeService
