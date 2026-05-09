--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Remotes"):WaitForChild("RemoteNames"))
local ColonySkinConfig = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("ColonySkinConfig"))

local ColonyMapController = {}
local context: { [string]: any }
local markerByUserId: { [number]: Frame } = {}
local profileSummaryByUserId: { [number]: any } = {}
local ProfileCard = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("ProfileCard"))

local selectedUserId: number? = nil
local defaultColonySkin = ColonySkinConfig.Default

local function getColonySkinImage(summary: any): string
	local equippedSkinId = if summary and type(summary.EquippedColonySkin) == "string" then summary.EquippedColonySkin else "Default"
	local skinConfig = ColonySkinConfig[equippedSkinId] or defaultColonySkin
	local skinImage = if skinConfig and type(skinConfig.Image) == "string" then skinConfig.Image else nil
	local defaultImage = if defaultColonySkin and type(defaultColonySkin.Image) == "string" then defaultColonySkin.Image else ""
	return skinImage or defaultImage
end

local function ensureRemote(name: string): RemoteEvent?
	local remotes = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Remotes")
	local remote = remotes:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

local getSummaryRemote: RemoteEvent? = nil

local function sanitizeSummary(summary: any, fallbackUserId: number?): any
	if type(summary) ~= "table" then
		return nil
	end
	local normalized = table.clone(summary)
	normalized.UserId = tonumber(summary.UserId) or fallbackUserId
	normalized.DisplayName = tostring(summary.DisplayName or summary.Username or "Unknown")
	normalized.Prestige = tonumber(summary.Prestige) or 0
	normalized.FoodPerSec = tonumber(summary.FoodPerSec) or 0
	normalized.LifetimeFood = tonumber(summary.LifetimeFood) or 0
	normalized.CurrentNectar = tonumber(summary.CurrentNectar) or 0
	normalized.GeneratorCount = tonumber(summary.GeneratorCount) or tonumber(summary.GeneratorsOwned) or 0
	normalized.EquippedBugs = if type(summary.EquippedBugs) == "table" then summary.EquippedBugs else {}
	normalized.LeaderboardPlacements = if type(summary.LeaderboardPlacements) == "table" then summary.LeaderboardPlacements else {}
	return normalized
end

local function styleName(label: TextLabel, summary, fallbackDisplayName: string)
	local displayName = if summary and summary.DisplayName then summary.DisplayName else fallbackDisplayName
	local isTop = summary and summary.LeaderboardPlacements and #summary.LeaderboardPlacements > 0
	local guildTag = summary and summary.Guild and summary.Guild.Tag
	local guildColor = if summary and summary.Guild and summary.Guild.Color then summary.Guild.Color else nil
	local prefix = guildTag and ("[" .. guildTag .. "] ") or ""
	local trophy = isTop and "🏆 " or ""
	local nameColor = isTop and "#FFD750" or "#FFFFFF"
	if guildTag then
		local tagColor = (typeof(guildColor) == "Color3") and string.format("#%02X%02X%02X", math.floor(guildColor.R * 255), math.floor(guildColor.G * 255), math.floor(guildColor.B * 255)) or "#8FC2FF"
		label.RichText = true
		label.Text = string.format('<font color="%s">%s</font><font color="#FFFFFF">%s</font><font color="%s">%s</font>', tagColor, prefix, trophy, nameColor, displayName)
	else
		label.RichText = false
		label.Text = trophy .. displayName
		label.TextColor3 = isTop and Color3.fromRGB(255, 215, 80) or Color3.fromRGB(255, 255, 255)
	end
end

local function CreateNameplate(player: Player): Frame
	local plate = Instance.new("Frame")
	plate.Name = "NameplateFrame"
	plate.Size = UDim2.fromOffset(154, 24)
	plate.Position = UDim2.new(0.5, -77, 0, 60)
	plate.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	plate.BackgroundTransparency = 0.18

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = plate

	local label = Instance.new("TextLabel")
	label.Name = "NameplateLabel"
	label.Size = UDim2.new(1, -14, 1, 0)
	label.Position = UDim2.fromOffset(7, 0)
	label.BackgroundTransparency = 1
	label.TextScaled = false
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Font = Enum.Font.GothamSemibold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = player.DisplayName
	label.Parent = plate

	return plate
end

local function CreateColonyMarker(player: Player): Frame
	local marker = Instance.new("Frame")
	marker.Name = "ColonyFrame"
	marker.Size = UDim2.fromOffset(170, 88)
	marker.BackgroundTransparency = 1

	local icon = Instance.new("TextButton")
	icon.Name = "ColonyIcon"
	icon.Size = UDim2.fromOffset(57, 57)
	icon.Position = UDim2.new(0.5, -28, 0, 0)
	icon.Text = ""
	icon.BackgroundTransparency = 1
	icon.Parent = marker
	local iconImage = Instance.new("ImageLabel")
	iconImage.Name = "ColonyIconImage"
	iconImage.Size = UDim2.fromScale(1, 1)
	iconImage.BackgroundTransparency = 1
	iconImage.Image = getColonySkinImage(nil)
	iconImage.Parent = icon

	local nameplate = CreateNameplate(player)
	nameplate.Parent = marker

	icon.Activated:Connect(function()
		selectedUserId = player.UserId
		if getSummaryRemote then
			getSummaryRemote:FireServer(player.UserId)
		else
			warn("[BugsOS] Missing profile summary remote")
		end
	end)

	return marker
end

local function UpdateMarkerSkin(userId: number)
	local marker = markerByUserId[userId]
	if not marker then return end
	local icon = marker:FindFirstChild("ColonyIcon")
	if not icon or not icon:IsA("TextButton") then return end
	local iconImage = icon:FindFirstChild("ColonyIconImage")
	if not iconImage or not iconImage:IsA("ImageLabel") then return end
	iconImage.Image = getColonySkinImage(profileSummaryByUserId[userId])
end

local function UpdateNameplate(userId: number)
	local marker = markerByUserId[userId]
	if not marker then
		return
	end

	local nameplate = marker:FindFirstChild("NameplateFrame")
	local player = Players:GetPlayerByUserId(userId)
	if not nameplate or not nameplate:IsA("Frame") or not player then
		return
	end

	local label = nameplate:FindFirstChild("NameplateLabel")
	if not label or not label:IsA("TextLabel") then
		return
	end

	styleName(label, profileSummaryByUserId[userId], player.DisplayName)
end

local function UpdateMarkerPosition(userId: number, index: number)
	local marker = markerByUserId[userId]
	if not marker then
		return
	end
	local x = math.clamp(120 + (index * 100) % 600, 80, 760)
	local y = math.clamp(120 + math.floor(index / 7) * 96, 80, 500)
	marker.Position = UDim2.fromOffset(x, y)
end

local function DestroyMarker(userId: number)
	local marker = markerByUserId[userId]
	if marker then
		marker:Destroy()
	end
	markerByUserId[userId] = nil
	end

function ColonyMapController.Init(initContext): ()
	context = initContext
	getSummaryRemote = ensureRemote(RemoteNames.Profile_GetSummary)
	if getSummaryRemote then
		getSummaryRemote.OnClientEvent:Connect(function(summary)
			local normalizedSummary = sanitizeSummary(summary, selectedUserId)
			if normalizedSummary and normalizedSummary.UserId then
				profileSummaryByUserId[normalizedSummary.UserId] = normalizedSummary
				UpdateNameplate(normalizedSummary.UserId)
				UpdateMarkerSkin(normalizedSummary.UserId)
				if selectedUserId == normalizedSummary.UserId then
					if ProfileCard and ProfileCard.Show then
						ProfileCard.Show(normalizedSummary)
					else
						warn("[BugsOS] ProfileCard.Show is unavailable")
					end
				end
			end
		end)
	end
end

function ColonyMapController.Refresh(): () end
function ColonyMapController.Start(): ()
	local world = context.UI.WorldLayer
	if not world then
		return
	end
	if ProfileCard.SetParent then
		ProfileCard.SetParent(world)
	end
	if ProfileCard.Hide then
		ProfileCard.Hide()
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if not markerByUserId[p.UserId] then
			markerByUserId[p.UserId] = CreateColonyMarker(p)
			markerByUserId[p.UserId].Parent = world
		end
	end
	for index, p in ipairs(Players:GetPlayers()) do
		UpdateMarkerPosition(p.UserId, index)
		UpdateNameplate(p.UserId)
	end

	Players.PlayerRemoving:Connect(function(player)
		DestroyMarker(player.UserId)
	end)
end

return ColonyMapController
