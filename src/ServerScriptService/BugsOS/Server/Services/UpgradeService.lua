--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")
local ConfigFolder = SharedFolder:WaitForChild("Config")

local ServerFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server")
local ServicesFolder = ServerFolder:WaitForChild("Services")

local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))
local ClickToolConfig = require(ConfigFolder:WaitForChild("ClickToolConfig"))
local CurrencyService = require(ServicesFolder:WaitForChild("CurrencyService"))
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))

local upgradeBuyClickToolRemote: RemoteEvent? = nil

type ClickToolDef = {
	id: string,
	baseCost: number,
	maxLevel: number,
}

local UpgradeService = {}
local toolConfigById: { [string]: ClickToolDef } = {}

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

local function getClickToolLevel(playerData: { [string]: any }, toolId: string): number
	local clickTools = playerData.ClickTools
	if type(clickTools) ~= "table" then
		playerData.ClickTools = {}
		return 0
	end

	local level = clickTools[toolId]
	if type(level) ~= "number" then
		return 0
	end

	return level
end

local function onUpgradeBuyClickTool(player: Player, payload: any)
	if type(payload) ~= "table" then
		warn(string.format("[UpgradeService] Rejected Upgrade_BuyClickTool from %s: malformed payload", player.Name))
		return
	end

	local toolId = payload.ToolId
	if type(toolId) ~= "string" or toolId == "" then
		warn(string.format("[UpgradeService] Rejected Upgrade_BuyClickTool from %s: missing/invalid ToolId", player.Name))
		return
	end

	local playerData = ProfileService.GetPlayerData(player)
	if not playerData then
		warn(string.format("[UpgradeService] Rejected Upgrade_BuyClickTool for %s (%s): no player data", player.Name, toolId))
		return
	end

	local toolConfig = toolConfigById[toolId]
	if not toolConfig then
		warn(string.format("[UpgradeService] Rejected Upgrade_BuyClickTool for %s: unknown tool id %s", player.Name, toolId))
		return
	end

	local currentLevel = getClickToolLevel(playerData, toolId)
	if currentLevel >= toolConfig.maxLevel then
		warn(string.format("[UpgradeService] Rejected Upgrade_BuyClickTool for %s (%s): already at max level (%d)", player.Name, toolId, currentLevel))
		return
	end

	local nextLevel = currentLevel + 1
	local cost = toolConfig.baseCost * (nextLevel ^ 2)
	if not CurrencyService.CanAfford(player, "Coins", cost) then
		local coins = CurrencyService.GetBalance(player, "Coins")
		warn(string.format(
			"[UpgradeService] Rejected Upgrade_BuyClickTool for %s (%s): cannot afford cost=%d, coins=%d",
			player.Name,
			toolId,
			cost,
			coins
		))
		return
	end

	if not CurrencyService.RemoveCurrency(player, "Coins", cost) then
		warn(string.format("[UpgradeService] Rejected Upgrade_BuyClickTool for %s (%s): failed to remove coins", player.Name, toolId))
		return
	end

	playerData.ClickTools[toolId] = nextLevel
	ProfileService.PatchPlayerState(player, { "ClickTools", toolId }, nextLevel)

	print(string.format("[UpgradeService] %s upgraded %s to level %d for %d Coins", player.Name, toolId, nextLevel, cost))
end

function UpgradeService.Init(): ()
	for _, toolConfig in ClickToolConfig.Tools do
		if type(toolConfig) == "table" and type(toolConfig.id) == "string" then
			toolConfigById[toolConfig.id] = toolConfig :: ClickToolDef
		end
	end

	upgradeBuyClickToolRemote = getOrCreateRemoteEvent(RemoteNames.Upgrade_BuyClickTool or "Upgrade_BuyClickTool")
end

function UpgradeService.Start(): ()
	if not upgradeBuyClickToolRemote then
		warn("[UpgradeService] Upgrade_BuyClickTool remote missing at Start")
		return
	end

	upgradeBuyClickToolRemote.OnServerEvent:Connect(onUpgradeBuyClickTool)
end

return UpgradeService
