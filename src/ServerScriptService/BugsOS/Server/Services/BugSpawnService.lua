--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("BugConfig"))
local BugBonusConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("BugBonusConfig"))
local BugInventoryService = require(script.Parent:WaitForChild("BugInventoryService"))
local BugdexService = require(script.Parent:WaitForChild("BugdexService"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("EconomyConfig"))
local BuffService = require(script.Parent:WaitForChild("BuffService"))
local RemoteNames = require(ReplicatedStorage.BugsOS.Shared.Remotes.RemoteNames)
local StatsService = require(script.Parent:WaitForChild("StatsService"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local Remotes = ReplicatedStorage.BugsOS.Shared.Remotes

local BugSpawnService = {}
local activeByUser, sinceSpawn, lastHit, lastForcedSpawn = {}, {}, {}, {}
local notificationPushRemote: RemoteEvent? = nil
local RARITY_PRIORITY = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
local ROLL_QUALITY_MULTIPLIER = { Normal = 0.05, Good = 0.25, Great = 0.75, Perfect = 1.50 }

local function pushNotification(player: Player, message: string, notificationType: string): ()
	if notificationPushRemote then notificationPushRemote:FireClient(player, { Message = message, Type = notificationType }) end
end

local function calculateCaptureBugPoints(rarity: string, bonusStats: {any}?, buffs: any)
	local basePoints = BugConfig.BaseBugPoints[rarity] or 1
	local rollBonusPoints = 0
	local breakdown = {}
	if type(bonusStats) == "table" then
		for _, bonus in ipairs(bonusStats) do
			if type(bonus) == "table" then
				local def = BugBonusConfig.GetDefinition(tostring(bonus.Id or ""))
				if def then
					local span = def.Max - def.Min
					local normalized = 0
					if span > 0 then
						normalized = math.clamp(((tonumber(bonus.Value) or def.Min) - def.Min) / span, 0, 1)
					end
					local quality = tostring(bonus.RollQuality or "Normal")
					local qMul = ROLL_QUALITY_MULTIPLIER[quality] or ROLL_QUALITY_MULTIPLIER.Normal
					local points = math.max(1, math.floor(basePoints * (qMul + normalized * 0.15) + 0.5))
					rollBonusPoints += points
					table.insert(breakdown, { Id = def.Id, DisplayName = def.DisplayName, RollQuality = quality, Normalized = normalized, Points = points })
				end
			end
		end
	end
	local rawPoints = basePoints + rollBonusPoints
	local buffMultiplier = 1 + (tonumber(buffs and buffs.BugPoints) or 0)
	local finalPoints = math.max(1, math.floor(rawPoints * buffMultiplier + 0.5))
	return finalPoints, rollBonusPoints, breakdown
end

local function pickWeighted(map)
	local total = 0
	for _, w in map do total += w end
	local r = Random.new():NextNumber(0, total)
	local c = 0
	for k, w in map do c += w if r <= c then return k end end
end

local function withBugLuckWeights(baseWeights, bugLuck)
	local boosted = table.clone(baseWeights)
	boosted.Epic = (boosted.Epic or 0) * (1 + bugLuck * 0.5)
	boosted.Legendary = (boosted.Legendary or 0) * (1 + bugLuck * 0.75)
	boosted.Mythic = (boosted.Mythic or 0) * (1 + bugLuck)
	return boosted
end

local function pickSpecies(rarity)
	local pool, totalWeight = {}, 0
	for _, s in ipairs(BugConfig.Species) do
		if s.rarity == rarity then
			local weight = tonumber(s.spawnWeight) or 1
			if weight > 0 then totalWeight += weight; table.insert(pool, { species = s, weight = weight }) end
		end
	end
	if #pool == 0 or totalWeight <= 0 then return nil end
	local roll = Random.new():NextNumber(0, totalWeight)
	local cursor = 0
	for _, entry in ipairs(pool) do cursor += entry.weight if roll <= cursor then return entry.species end end
	return pool[#pool].species
end

local function clear(player) activeByUser[player.UserId] = nil end

local function spawnFor(player, spawnedRemote: RemoteEvent)
	local buffs = BuffService.GetPlayerBuffs(player)
	local effectiveBugLuck = tonumber(buffs.BugLuck) or 0
	if EconomyConfig.DEV_MODE == true and EconomyConfig.DEV_INSANE_BUG_LUCK == true then
		effectiveBugLuck += tonumber(EconomyConfig.DEV_INSANE_BUG_LUCK_AMOUNT) or 25
	end
	local rarity = nil
	local devForcedRarity = EconomyConfig.DEV_MODE == true and tostring(EconomyConfig.DEV_FORCE_RARITY or "") or ""
	if devForcedRarity ~= "" and BugConfig.RarityWeights[devForcedRarity] then
		rarity = devForcedRarity
		print(string.format("[BugSpawnService] DEV_FORCE_RARITY active: %s", devForcedRarity))
	else
		local rarityWeights = withBugLuckWeights(BugConfig.RarityWeights, effectiveBugLuck)
		rarity = pickWeighted(rarityWeights)
	end
	local species = pickSpecies(rarity)
	if not species then return end
	local id = tostring(player.UserId) .. ":" .. tostring(math.floor(os.clock() * 1000))
	local behavior = species.behaviorPool[Random.new():NextInteger(1, #species.behaviorPool)]
	local now = os.clock()
	local duration = species.baseTimer * (1 + buffs.MinigameTime)
	activeByUser[player.UserId] = { ActiveBugId = id, SpeciesId = species.id, DisplayName = species.displayName, Rarity = rarity, HitsRequired = species.hitsRequired, HitsLanded = 0, ExpiresAt = now + duration, SpawnedAt = now, Behavior = behavior }
	sinceSpawn[player.UserId] = 0
	spawnedRemote:FireClient(player, { SpeciesId = species.id, DisplayName = species.displayName, Rarity = rarity, HitsRequired = species.hitsRequired, Duration = duration, Behavior = behavior, ActiveBugId = id })
end

local function ensureRemoteEvent(remoteName: string): RemoteEvent local e = Remotes:FindFirstChild(remoteName); if e and e:IsA("RemoteEvent") then return e end; local r = Instance.new("RemoteEvent"); r.Name = remoteName; r.Parent = Remotes; return r end
function BugSpawnService.Init() ensureRemoteEvent(RemoteNames.Bug_Spawned); ensureRemoteEvent(RemoteNames.Bug_Escaped); ensureRemoteEvent(RemoteNames.Bug_Captured); ensureRemoteEvent(RemoteNames.Bug_AttemptCatch); ensureRemoteEvent(RemoteNames.Bug_HitUpdate); notificationPushRemote = ensureRemoteEvent(RemoteNames.Notification_Push) end

function BugSpawnService.Start()
local spawnedRemote = Remotes:WaitForChild(RemoteNames.Bug_Spawned) :: RemoteEvent
local escapedRemote = Remotes:WaitForChild(RemoteNames.Bug_Escaped) :: RemoteEvent
local capturedRemote = Remotes:WaitForChild(RemoteNames.Bug_Captured) :: RemoteEvent
local attemptCatchRemote = Remotes:WaitForChild(RemoteNames.Bug_AttemptCatch) :: RemoteEvent
local hitUpdateRemote = Remotes:WaitForChild(RemoteNames.Bug_HitUpdate) :: RemoteEvent
Players.PlayerRemoving:Connect(function(p) activeByUser[p.UserId]=nil; sinceSpawn[p.UserId]=nil; lastHit[p.UserId]=nil; lastForcedSpawn[p.UserId]=nil end)

-- loop unchanged
	task.spawn(function() while true do task.wait(1); local now=os.clock(); for _,p in ipairs(Players:GetPlayers()) do local st=activeByUser[p.UserId]; if st then if now>=st.ExpiresAt then clear(p); escapedRemote:FireClient(p,{SpeciesId=st.SpeciesId,Rarity=st.Rarity,DisplayName=st.DisplayName}) end else local devInterval=EconomyConfig.DEV_FORCE_BUG_SPAWN_INTERVAL; local forceDevSpawn=EconomyConfig.DEV_MODE==true and type(devInterval)=="number" and devInterval>0; if forceDevSpawn then local last=lastForcedSpawn[p.UserId] or 0; if (now-last)>=devInterval then spawnFor(p,spawnedRemote); lastForcedSpawn[p.UserId]=now end else sinceSpawn[p.UserId]=(sinceSpawn[p.UserId] or 0)+1; local buffs=BuffService.GetPlayerBuffs(p); local baseChance=0.02+((sinceSpawn[p.UserId])*0.0015); local spawnRateBonus=buffs.BugSpawnRate or buffs.MinigameSpawnChance or 0; local chance=baseChance*(1+spawnRateBonus); if Random.new():NextNumber()<=chance then spawnFor(p,spawnedRemote) end end end end end end)

	attemptCatchRemote.OnServerEvent:Connect(function(player, payload)
		local st = activeByUser[player.UserId]
		if not st then return end
		if type(payload) ~= "table" or payload.ActiveBugId ~= st.ActiveBugId then return end
		local now = os.clock()
		if now >= st.ExpiresAt then clear(player); return end
		if lastHit[player.UserId] and now - lastHit[player.UserId] < 0.08 then return end
		lastHit[player.UserId] = now
		st.HitsLanded += 1
		if st.HitsLanded < st.HitsRequired then
			hitUpdateRemote:FireClient(player, { ActiveBugId = st.ActiveBugId, HitsLanded = st.HitsLanded, HitsRequired = st.HitsRequired, HitsRemaining = st.HitsRequired - st.HitsLanded })
			return
		end

		clear(player)
		local buffs = BuffService.GetPlayerBuffs(player)
		local createdBug = nil
		local createReason = nil
		local wasNewDiscovery = false
		local ok, err = pcall(function()
			createdBug, createReason = BugInventoryService.CreateBug(player, st.SpeciesId, st.Rarity)
			if createdBug then
				BugdexService.RecordCatch(player, st.SpeciesId)
			end
		end)
		if not ok then warn(string.format("[BugSpawnService] Failed to create captured bug for %s: %s", player.Name, tostring(err))) end
		if createdBug == nil and createReason == "InventoryFull" then
			pushNotification(player, "Bug inventory full.", "Warning")
			return
		end
		local finalPoints, rollBonusPoints, breakdown = calculateCaptureBugPoints(st.Rarity, createdBug and createdBug.BonusStats or nil, buffs)
		if createdBug == nil then finalPoints, rollBonusPoints, breakdown = calculateCaptureBugPoints(st.Rarity, nil, buffs) end

		local pdata = player:FindFirstChild("PlayerData")
		if pdata and pdata:IsA("Folder") then local bp = pdata:FindFirstChild("BugPoints") :: NumberValue; if bp then bp.Value += finalPoints end end
		StatsService.Increment(player, "BugsCaught", 1)
		StatsService.Increment(player, "BugPointsEarned", finalPoints)
		StatsService.Increment(player, st.Rarity .. "BugsCaught", 1)

		if createdBug then
			local playerData = ProfileService.GetPlayerData(player)
			if playerData and type(playerData.Bugdex) == "table" and type(playerData.Bugdex.TotalCaughtBySpecies) == "table" then
				wasNewDiscovery = tonumber(playerData.Bugdex.TotalCaughtBySpecies[st.SpeciesId]) == 1
			end
			if wasNewDiscovery then pushNotification(player, string.format("New bug discovered: %s (%s)", st.DisplayName, st.Rarity), "Success") end
			if (RARITY_PRIORITY[st.Rarity] or 0) >= RARITY_PRIORITY.Rare then pushNotification(player, string.format("%s catch: %s", st.Rarity, st.DisplayName), "Success") end
		end
		capturedRemote:FireClient(player, { SpeciesId = st.SpeciesId, DisplayName = st.DisplayName, Rarity = st.Rarity, BugPointsAwarded = finalPoints, BugPointRollBonus = rollBonusPoints, BugPointBreakdown = breakdown, Bug = createdBug, BonusStats = createdBug and createdBug.BonusStats or {}, WasNewDiscovery = wasNewDiscovery })
	end)
end

return BugSpawnService
