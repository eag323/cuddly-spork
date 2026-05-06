--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugsOSFolder = ReplicatedStorage:WaitForChild("BugsOS")
local SharedFolder = BugsOSFolder:WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")

local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

local upgradeBuyClickToolRemote: RemoteEvent? = nil

local UpgradeService = {}

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

local function onUpgradeBuyClickTool(player: Player, payload: any)
	if type(payload) ~= "table" then
		warn(string.format("[UpgradeService] Ignoring malformed payload from %s", player.Name))
		return
	end

	-- TODO: Execute upgrade purchase once upgrade economy/state is implemented.
end

function UpgradeService.Init(): ()
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
