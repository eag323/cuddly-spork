--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local RemotesFolder = Shared:WaitForChild("Remotes")

local AchievementConfig = require(ConfigFolder:WaitForChild("AchievementConfig"))
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

local ServicesFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server"):WaitForChild("Services")
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))
local CurrencyService = require(ServicesFolder:WaitForChild("CurrencyService"))
local StatsService = require(ServicesFolder:WaitForChild("StatsService"))

local AchievementService = {}
local claimRemote: RemoteEvent? = nil
local defsById = {}

local function getOrCreateRemoteEvent(remoteName: string): RemoteEvent
	local existingRemote = RemotesFolder:FindFirstChild(remoteName)
	if existingRemote and existingRemote:IsA("RemoteEvent") then return existingRemote end
	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = RemotesFolder
	return remote
end

local function isComplete(player: Player, def): boolean
	return StatsService.Get(player, def.stat) >= def.required
end

local function grantReward(player: Player, reward)
	if reward.Type == "Food" then CurrencyService.AddFood(player, reward.Amount)
	elseif reward.Type == "Coins" then CurrencyService.AddCoins(player, reward.Amount)
	elseif reward.Type == "Nectar" then CurrencyService.AddCurrency(player, "Nectar", reward.Amount)
	elseif reward.Type == "BugPoints" then StatsService.Increment(player, "BugPointsEarned", reward.Amount)
	elseif reward.Type == "Title" then
		local data = ProfileService.GetPlayerData(player)
		if data and type(data.Cosmetics) == "table" and type(data.Cosmetics.Owned) == "table" and type(data.Cosmetics.Owned.Titles) == "table" then
			data.Cosmetics.Owned.Titles[reward.Value] = true
			ProfileService.PatchPlayerState(player, { "Cosmetics", "Owned", "Titles", reward.Value }, true)
		end
	end
end

local function claimOne(player: Player, achievementId: string): boolean
	local def = defsById[achievementId]
	if not def then return false end
	local data = ProfileService.GetPlayerData(player)
	if not data then return false end
	if type(data.Achievements) ~= "table" then data.Achievements = { Claimed = {} } end
	if type(data.Achievements.Claimed) ~= "table" then data.Achievements.Claimed = {} end
	if data.Achievements.Claimed[achievementId] then return false end
	if not isComplete(player, def) then return false end
	data.Achievements.Claimed[achievementId] = true
	ProfileService.PatchPlayerState(player, { "Achievements", "Claimed", achievementId }, true)
	grantReward(player, def.reward)
	return true
end

local function onClaim(player: Player, payload)
	if type(payload) ~= "table" then return end
	if payload.CollectAll == true then
		local claimedCount = 0
		for _, def in ipairs(AchievementConfig.Definitions) do
			if claimOne(player, def.id) then claimedCount += 1 end
		end
		if claimedCount > 0 then
			ProfileService.PatchPlayerState(player, { "Achievements", "LastClaimAllCount" }, claimedCount)
		end
		return
	end
	if type(payload.AchievementId) == "string" then
		claimOne(player, payload.AchievementId)
	end
end

function AchievementService.Init(): ()
	for _, def in ipairs(AchievementConfig.Definitions) do defsById[def.id] = def end
	claimRemote = getOrCreateRemoteEvent(RemoteNames.Achievement_Claim)
end

function AchievementService.Start(): ()
	if claimRemote then claimRemote.OnServerEvent:Connect(onClaim) end
end

return AchievementService
