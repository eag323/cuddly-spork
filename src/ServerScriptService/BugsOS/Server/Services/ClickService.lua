--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local ConfigFolder = SharedFolder:WaitForChild("Config")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")

local ClickToolConfig = require(ConfigFolder:WaitForChild("ClickToolConfig"))
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

local ServerScriptService = game:GetService("ServerScriptService")
local BugsOSServerFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server")
local ServicesFolder = BugsOSServerFolder:WaitForChild("Services")

local CurrencyService = require(ServicesFolder:WaitForChild("CurrencyService"))
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))
local PrestigeService = require(ServicesFolder:WaitForChild("PrestigeService"))

type PlayerData = { [string]: any }

type ClickToolEntry = {
	id: string,
	foodPerClickPerLevel: number,
}

local ClickService = {}

local CLICK_COOLDOWN_SECONDS = 0.08

local clickRequestRemote: RemoteEvent? = nil
local clickResultRemote: RemoteEvent? = nil
local toolBonusById: { [string]: number } = {}
local lastClickAtByUserId: { [number]: number } = {}

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

local function buildToolBonusLookup(): ()
	toolBonusById = {}

	local tools = ClickToolConfig.Tools
	if type(tools) ~= "table" then
		return
	end

	for _, toolEntry in tools do
		local entry = toolEntry :: ClickToolEntry
		if type(entry.id) == "string" and type(entry.foodPerClickPerLevel) == "number" then
			toolBonusById[entry.id] = entry.foodPerClickPerLevel
		end
	end
end

local function getPlayerData(player: Player): PlayerData?
	return ProfileService.GetPlayerData(player)
end

local function isClickOffCooldown(player: Player): boolean
	local now = os.clock()
	local lastClickAt = lastClickAtByUserId[player.UserId]
	if lastClickAt and now - lastClickAt < CLICK_COOLDOWN_SECONDS then
		return false
	end

	lastClickAtByUserId[player.UserId] = now
	return true
end

local function computeFoodPerClick(playerData: PlayerData): number
	local total = 1
	local clickTools = playerData.ClickTools
	if type(clickTools) ~= "table" then
		return total
	end

	for toolId, levelValue in clickTools do
		if type(toolId) == "string" and type(levelValue) == "number" and levelValue > 0 then
			local toolBonus = toolBonusById[toolId]
			if type(toolBonus) == "number" then
				total += toolBonus * levelValue
			end
		end
	end

	return total
end

local function onClickRequest(player: Player): ()
	if not isClickOffCooldown(player) then
		return
	end

	local playerData = getPlayerData(player)
	if not playerData then
		return
	end

	local foodPerClick = computeFoodPerClick(playerData) * PrestigeService.GetPrestigeMultiplier(player)
	if foodPerClick <= 0 then
		return
	end

	CurrencyService.AddFood(player, foodPerClick)

	if clickResultRemote then
		clickResultRemote:FireClient(player, {
			FoodGained = foodPerClick,
		})
	end
end

function ClickService.Init(): ()
	buildToolBonusLookup()
	local clickRequestName = RemoteNames.Click_Request or "Click_Request"
	local clickResultName = RemoteNames.Click_Result or "Click_Result"
	clickRequestRemote = getOrCreateRemoteEvent(clickRequestName)
	clickResultRemote = getOrCreateRemoteEvent(clickResultName)
end

function ClickService.Start(): ()
	if not clickRequestRemote then
		return
	end

	clickRequestRemote.OnServerEvent:Connect(onClickRequest)
end

return ClickService
