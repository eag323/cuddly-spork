--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BugConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("BugConfig"))
local BugInventoryService = require(script.Parent:WaitForChild("BugInventoryService"))
local BugdexService = require(script.Parent:WaitForChild("BugdexService"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("EconomyConfig"))
local BuffService = require(script.Parent:WaitForChild("BuffService"))
local RemoteNames = require(ReplicatedStorage.BugsOS.Shared.Remotes.RemoteNames)
local Remotes = ReplicatedStorage.BugsOS.Shared.Remotes

local BugSpawnService = {}
local activeByUser, sinceSpawn, lastHit, lastForcedSpawn = {}, {}, {}, {}

local function pickWeighted(map)
	local total = 0
	for _, w in map do
		total += w
	end
	local r = Random.new():NextNumber(0, total)
	local c = 0
	for k, w in map do
		c += w
		if r <= c then
			return k
		end
	end
end

local function withBugLuckWeights(baseWeights, bugLuck)
	local boosted = table.clone(baseWeights)
	boosted.Epic = (boosted.Epic or 0) * (1 + bugLuck * 0.5)
	boosted.Legendary = (boosted.Legendary or 0) * (1 + bugLuck * 0.75)
	boosted.Mythic = (boosted.Mythic or 0) * (1 + bugLuck)
	return boosted
end

local function pickSpecies(rarity)
	local pool = {}
	for _, s in ipairs(BugConfig.Species) do
		if s.rarity == rarity then
			table.insert(pool, s)
		end
	end
	if #pool == 0 then return nil end
	return pool[Random.new():NextInteger(1, #pool)]
end

local function clear(player)
	activeByUser[player.UserId] = nil
end

local function spawnFor(player, spawnedRemote: RemoteEvent)
	local buffs = BuffService.GetPlayerBuffs(player)
	local rarityWeights = withBugLuckWeights(BugConfig.RarityWeights, buffs.BugLuck)
	local rarity = pickWeighted(rarityWeights)
	local species = pickSpecies(rarity)
	if not species then return end
	local id = tostring(player.UserId) .. ":" .. tostring(math.floor(os.clock() * 1000))
	local behavior = species.behaviorPool[Random.new():NextInteger(1, #species.behaviorPool)]
	local now = os.clock()
	local duration = species.baseTimer * (1 + buffs.MinigameTime)
	activeByUser[player.UserId] = { ActiveBugId = id, SpeciesId = species.id, DisplayName = species.displayName, Rarity = rarity, HitsRequired = species.hitsRequired, HitsLanded = 0, ExpiresAt = now + duration, SpawnedAt = now, Behavior = behavior }
	sinceSpawn[player.UserId] = 0
	spawnedRemote:FireClient(player, { SpeciesId = species.id, DisplayName = species.displayName, Rarity = rarity, HitsRequired = species.hitsRequired, Duration = duration, Behavior = behavior, ActiveBugId = id })
	print(string.format("[BugSpawnService] Spawn buffs for %s chance/time/luck: %.3f %.3f %.3f", player.Name, buffs.MinigameSpawnChance, buffs.MinigameTime, buffs.BugLuck))
end

local function ensureRemoteEvent(remoteName: string): RemoteEvent
	local existingRemote = Remotes:FindFirstChild(remoteName)
	if existingRemote and existingRemote:IsA("RemoteEvent") then return existingRemote end
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = remoteName
	remoteEvent.Parent = Remotes
	return remoteEvent
end

function BugSpawnService.Init()
	ensureRemoteEvent(RemoteNames.Bug_Spawned)
	ensureRemoteEvent(RemoteNames.Bug_Escaped)
	ensureRemoteEvent(RemoteNames.Bug_Captured)
	ensureRemoteEvent(RemoteNames.Bug_AttemptCatch)
	ensureRemoteEvent(RemoteNames.Bug_HitUpdate)
end

function BugSpawnService.Start()
	local spawnedRemote = Remotes:WaitForChild(RemoteNames.Bug_Spawned) :: RemoteEvent
	local escapedRemote = Remotes:WaitForChild(RemoteNames.Bug_Escaped) :: RemoteEvent
	local capturedRemote = Remotes:WaitForChild(RemoteNames.Bug_Captured) :: RemoteEvent
	local attemptCatchRemote = Remotes:WaitForChild(RemoteNames.Bug_AttemptCatch) :: RemoteEvent
	local hitUpdateRemote = Remotes:WaitForChild(RemoteNames.Bug_HitUpdate) :: RemoteEvent

	Players.PlayerRemoving:Connect(function(p)
		activeByUser[p.UserId] = nil
		sinceSpawn[p.UserId] = nil
		lastHit[p.UserId] = nil
		lastForcedSpawn[p.UserId] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for _, p in ipairs(Players:GetPlayers()) do
				local st = activeByUser[p.UserId]
				if st then
					if now >= st.ExpiresAt then
						clear(p)
						escapedRemote:FireClient(p, { SpeciesId = st.SpeciesId, Rarity = st.Rarity, DisplayName = st.DisplayName })
					end
				else
					local devInterval = EconomyConfig.DEV_FORCE_BUG_SPAWN_INTERVAL
					local forceDevSpawn = EconomyConfig.DEV_MODE == true and type(devInterval) == "number" and devInterval > 0
					if forceDevSpawn then
						-- DEVELOPMENT ONLY: force-spawn bugs at a fixed interval for balancing pass.
						local last = lastForcedSpawn[p.UserId] or 0
						if (now - last) >= devInterval then
							spawnFor(p, spawnedRemote)
							lastForcedSpawn[p.UserId] = now
						end
					else
						sinceSpawn[p.UserId] = (sinceSpawn[p.UserId] or 0) + 1
						local buffs = BuffService.GetPlayerBuffs(p)
					local baseChance = 0.02 + ((sinceSpawn[p.UserId]) * 0.0015)
					local chance = baseChance * (1 + buffs.MinigameSpawnChance)
						if Random.new():NextNumber() <= chance then
							spawnFor(p, spawnedRemote)
						end
					end
				end
			end
		end
	end)

	attemptCatchRemote.OnServerEvent:Connect(function(player, payload)
		local st = activeByUser[player.UserId]
		if not st then return end
		if type(payload) ~= "table" or payload.ActiveBugId ~= st.ActiveBugId then return end
		local now = os.clock()
		if now >= st.ExpiresAt then clear(player); return end
		if lastHit[player.UserId] and now - lastHit[player.UserId] < 0.08 then return end
		lastHit[player.UserId] = now
		st.HitsLanded += 1

		if st.HitsLanded >= st.HitsRequired then
			local basePoints = BugConfig.BaseBugPoints[st.Rarity] or 1
			local buffs = BuffService.GetPlayerBuffs(player)
			local finalPoints = math.floor((basePoints * (1 + buffs.BugPoints)) + 0.5)
			local pdata = player:FindFirstChild("PlayerData")
			if pdata and pdata:IsA("Folder") then
				local bp = pdata:FindFirstChild("BugPoints") :: NumberValue
				if bp then bp.Value += finalPoints end
			end
			clear(player)
			local createdBug = nil
			local ok, err = pcall(function()
				createdBug = BugInventoryService.CreateBug(player, st.SpeciesId, st.Rarity)
				BugdexService.RecordCatch(player, st.SpeciesId)
			end)
			if not ok then
				warn(string.format("[BugSpawnService] Failed to create captured bug for %s: %s", player.Name, tostring(err)))
			end
			capturedRemote:FireClient(player, { SpeciesId = st.SpeciesId, DisplayName = st.DisplayName, Rarity = st.Rarity, BugPointsAwarded = finalPoints, Bug = createdBug })
		else
			hitUpdateRemote:FireClient(player, {
				ActiveBugId = st.ActiveBugId,
				HitsLanded = st.HitsLanded,
				HitsRequired = st.HitsRequired,
				HitsRemaining = st.HitsRequired - st.HitsLanded,
			})
		end
	end)
end

return BugSpawnService
