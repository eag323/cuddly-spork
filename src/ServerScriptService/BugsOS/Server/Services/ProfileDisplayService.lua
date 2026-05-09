--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local ConfigFolder = Shared:WaitForChild("Config")
local RemoteNames = require(Remotes:WaitForChild("RemoteNames"))
local BugConfig = require(ConfigFolder:WaitForChild("BugConfig"))
local GeneratorConfig = require(ConfigFolder:WaitForChild("GeneratorConfig"))
local ColonySkinConfig = require(Shared:WaitForChild("Configs"):WaitForChild("ColonySkinConfig"))
local ColonyAuraConfig = require(Shared:WaitForChild("Configs"):WaitForChild("ColonyAuraConfig"))
local ServicesFolder = ServerScriptService:WaitForChild("BugsOS"):WaitForChild("Server"):WaitForChild("Services")
local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))

local ProfileDisplayService = {}
local getSummaryRemote: RemoteEvent
local equipTitleRemote: RemoteEvent
local equipColonySkinRemote: RemoteEvent
local equipColonyAuraRemote: RemoteEvent

local function getOrCreateRemoteEvent(name: string): RemoteEvent
	local existing = Remotes:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then return existing end
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = Remotes
	return r
end

local rarityRank = {Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythic=6}
local generatorById = {}
for _, gen in ipairs(GeneratorConfig.Generators or {}) do
	generatorById[gen.id] = gen
end

local function calculateFoodPerSec(data): number
	local progression = (data.Progression or {})
	local prestige = tonumber(progression.Prestige) or 0
	local prestigeMult = 1 + (prestige * 0.1)
	local equipped = (((data.Generators or {}).Equipped) or {})
	local total = 0
	for _, slot in pairs(equipped) do
		if type(slot) == "table" and type(slot.GeneratorId) == "string" then
			local gen = generatorById[slot.GeneratorId]
			if gen then
				local level = math.max(1, math.floor(tonumber(slot.Level) or 1))
				total += (tonumber(gen.baseFoodPerSec) or 0) * (level ^ 1.55)
			end
		end
	end
	return total * prestigeMult
end
local function topBugs(data): {any}
	local inv = (((data or {}).Bugs or {}).Inventory) or {}
	local equippedSet = {}
	for _,uid in pairs((((data or {}).Bugs or {}).Equipped) or {}) do equippedSet[uid]=true end
	local items = {}
	for uid,bug in pairs(inv) do
		if type(bug)=="table" then
			table.insert(items,{Uid=uid,Bug=bug,Equipped=equippedSet[uid]==true})
		end
	end
	table.sort(items,function(a,b)
		if a.Equipped ~= b.Equipped then return a.Equipped end
		local ar = rarityRank[tostring(a.Bug.Rarity)] or 0
		local br = rarityRank[tostring(b.Bug.Rarity)] or 0
		if ar ~= br then return ar > br end
		local ap = tonumber(a.Bug.PrimaryValue) or tonumber(a.Bug.Power) or 0
		local bp = tonumber(b.Bug.PrimaryValue) or tonumber(b.Bug.Power) or 0
		if ap ~= bp then return ap > bp end
		return (tonumber(a.Bug.BugPoints) or 0) > (tonumber(b.Bug.BugPoints) or 0)
	end)
	local out = {}
	for i=1, math.min(8,#items) do
		local bug = items[i].Bug
		table.insert(out,{ConfigId=bug.SpeciesId or "Unknown",DisplayName=bug.DisplayName or "Bug",Rarity=bug.Rarity or "Common",Icon=BugConfig.RarityColors and "" or "",IsEquipped=items[i].Equipped})
	end
	return out
end

local function buildSummary(player: Player): {[string]: any}
	local data = ProfileService.GetPlayerData(player) or {}
	local cosmetics = (data.Cosmetics or {})
	local owned = cosmetics.Owned or {}
	local equipped = cosmetics.Equipped or {}
	local guild = data.Guild or {}
	local lb = data.LeaderboardStats or {}
	local top3 = {}
	if (lb.BugPoints or 0) > 0 then table.insert(top3, {Rank=1, Name="Bug Points"}) end
	return {
		UserId = player.UserId,
		DisplayName = player.DisplayName ~= "" and player.DisplayName or player.Name,
		Prestige = ((data.Progression or {}).Prestige) or 0,
		EquippedTitle = equipped.Title,
		UnlockedTitles = owned.Titles or {},
		EquippedColonySkin = equipped.ColonySkin or "Default",
		EquippedColonyAura = equipped.ColonyAura or "None",
		UnlockedColonySkins = owned.ColonySkins or {Default=true},
		UnlockedColonyAuras = owned.ColonyAuras or {None=true},
		GeneratorCount = #( (((data.Generators or {}).Equipped) or {}) ),
		FoodPerSec = calculateFoodPerSec(data),
		LifetimeFood = (((data.Currencies or {}).LifetimeFood) or 0),
		CurrentNectar = (((data.Currencies or {}).Nectar) or 0),
		TopBugs = topBugs(data),
		Guild = {Tag = guild.Tag, Name = guild.Name, Color = guild.Color},
		LeaderboardPlacements = top3,
		Stats = data.Stats or {},
		BugPoints = lb.BugPoints or 0,
	}
end

local function IsColonySkinUnlocked(player: Player, skinId: string): boolean
	local data = ProfileService.GetPlayerData(player)
	if not data then return false end
	local owned = (((data.Cosmetics or {}).Owned or {}).ColonySkins) or {}
	return owned[skinId] == true
end

local function IsColonyAuraUnlocked(player: Player, auraId: string): boolean
	local data = ProfileService.GetPlayerData(player)
	if not data then return false end
	local owned = (((data.Cosmetics or {}).Owned or {}).ColonyAuras) or {}
	return owned[auraId] == true
end

local function EquipColonySkin(player: Player, skinId: string): ()
	if ColonySkinConfig[skinId] == nil then return end
	if not IsColonySkinUnlocked(player, skinId) then return end
	local data = ProfileService.GetPlayerData(player)
	if not data then return end
	data.Cosmetics = data.Cosmetics or {Owned = {}, Equipped = {}}
	data.Cosmetics.Equipped = data.Cosmetics.Equipped or {}
	data.Cosmetics.Equipped.ColonySkin = skinId
	ProfileService.PatchPlayerState(player, {"Cosmetics", "Equipped", "ColonySkin"}, skinId)
end

local function EquipColonyAura(player: Player, auraId: string): ()
	if ColonyAuraConfig[auraId] == nil then return end
	if not IsColonyAuraUnlocked(player, auraId) then return end
	local data = ProfileService.GetPlayerData(player)
	if not data then return end
	data.Cosmetics = data.Cosmetics or {Owned = {}, Equipped = {}}
	data.Cosmetics.Equipped = data.Cosmetics.Equipped or {}
	data.Cosmetics.Equipped.ColonyAura = auraId
	ProfileService.PatchPlayerState(player, {"Cosmetics", "Equipped", "ColonyAura"}, auraId)
end

function ProfileDisplayService.Init(): ()
	getSummaryRemote = getOrCreateRemoteEvent(RemoteNames.Profile_GetSummary)
	equipTitleRemote = getOrCreateRemoteEvent(RemoteNames.Profile_EquipTitle)
	equipColonySkinRemote = getOrCreateRemoteEvent(RemoteNames.Profile_EquipColonySkin or "Profile_EquipColonySkin")
	equipColonyAuraRemote = getOrCreateRemoteEvent(RemoteNames.Profile_EquipColonyAura or "Profile_EquipColonyAura")
end

function ProfileDisplayService.Start(): ()
	getSummaryRemote.OnServerEvent:Connect(function(player, targetUserId)
		local target = player
		if type(targetUserId)=="number" then
			local p = Players:GetPlayerByUserId(targetUserId)
			if p then target = p end
		end
		getSummaryRemote:FireClient(player, buildSummary(target))
	end)
	equipTitleRemote.OnServerEvent:Connect(function(player, titleId)
		if type(titleId)~="string" and titleId ~= nil then return end
		local data = ProfileService.GetPlayerData(player)
		if not data then return end
		data.Cosmetics = data.Cosmetics or {Owned={Titles={}},Equipped={}}
		data.Cosmetics.Owned = data.Cosmetics.Owned or {Titles={}}
		data.Cosmetics.Equipped = data.Cosmetics.Equipped or {}
		if titleId ~= nil and data.Cosmetics.Owned.Titles[titleId] ~= true then return end
		data.Cosmetics.Equipped.Title = titleId
		ProfileService.PatchPlayerState(player,{"Cosmetics","Equipped","Title"},titleId)
		getSummaryRemote:FireClient(player, buildSummary(player))
	end)
	equipColonySkinRemote.OnServerEvent:Connect(function(player, skinId)
		if type(skinId) ~= "string" then return end
		EquipColonySkin(player, skinId)
		getSummaryRemote:FireClient(player, buildSummary(player))
	end)
	equipColonyAuraRemote.OnServerEvent:Connect(function(player, auraId)
		if type(auraId) ~= "string" then return end
		EquipColonyAura(player, auraId)
		getSummaryRemote:FireClient(player, buildSummary(player))
	end)
end

return ProfileDisplayService
