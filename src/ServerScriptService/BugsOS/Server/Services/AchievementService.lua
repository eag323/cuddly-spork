--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

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
local notificationPushRemote: RemoteEvent? = nil
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

local function pushNotification(player: Player, message: string, notificationType: string, eventId: string?): ()
	if not notificationPushRemote then
		return
	end
	notificationPushRemote:FireClient(player, {
		Message = message,
		Type = notificationType,
		EventId = eventId,
	})
end

local function formatRewardSummary(reward): string
	if reward.Type == "Title" then
		return string.format("Unlocked title: %s", tostring(reward.Value))
	end
	return string.format("%s +%s", tostring(reward.Type), tostring(reward.Amount))
end

local function notifyCompletedAchievements(player: Player): ()
	local data = ProfileService.GetPlayerData(player)
	if not data then
		return
	end
	if type(data.Achievements) ~= "table" then
		data.Achievements = {}
	end
	if type(data.Achievements.NotifiedCompleted) ~= "table" then
		data.Achievements.NotifiedCompleted = {}
	end
	local notifiedCompleted = data.Achievements.NotifiedCompleted
	local claimed = data.Achievements.Claimed or {}
	for _, def in ipairs(AchievementConfig.Definitions) do
		if isComplete(player, def) and claimed[def.id] ~= true and notifiedCompleted[def.id] ~= true then
			notifiedCompleted[def.id] = true
			ProfileService.PatchPlayerState(player, { "Achievements", "NotifiedCompleted", def.id }, true)
			pushNotification(player, string.format("Achievement complete: %s. Reward ready.", tostring(def.name)), "Success", string.format("achievement_complete_%s", def.id))
		end
	end
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

local function claimOne(player: Player, achievementId: string, notifyRewardClaimed: boolean?): boolean
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
	if notifyRewardClaimed ~= false then
		pushNotification(player, string.format("Achievement reward claimed: %s", formatRewardSummary(def.reward)), "Success", string.format("achievement_claim_%s", achievementId))
	end
	return true
end

local function onClaim(player: Player, payload)
	if type(payload) ~= "table" then return end
	if payload.CollectAll == true then
		local claimedCount = 0
		local rewardSummary = {}
		for _, def in ipairs(AchievementConfig.Definitions) do
			if claimOne(player, def.id, false) then
				claimedCount += 1
				table.insert(rewardSummary, formatRewardSummary(def.reward))
			end
		end
		if claimedCount > 0 then
			ProfileService.PatchPlayerState(player, { "Achievements", "LastClaimAllCount" }, claimedCount)
			local summaryMessage = string.format("Collect All claimed %d achievements.", claimedCount)
			if #rewardSummary > 0 and #rewardSummary <= 3 then
				summaryMessage = string.format("%s Rewards: %s", summaryMessage, table.concat(rewardSummary, ", "))
			end
			pushNotification(player, summaryMessage, "Success", string.format("achievement_claim_all_%d", os.time()))
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
	notificationPushRemote = getOrCreateRemoteEvent(RemoteNames.Notification_Push)
end

function AchievementService.Start(): ()
	if claimRemote then claimRemote.OnServerEvent:Connect(onClaim) end
	task.spawn(function()
		while true do
			task.wait(2)
			for _, player in ipairs(Players:GetPlayers()) do
				notifyCompletedAchievements(player)
			end
		end
	end)
end

return AchievementService
