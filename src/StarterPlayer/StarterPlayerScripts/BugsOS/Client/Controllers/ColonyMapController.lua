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
	plate.Size = UDim2.fromOffset(116, 16)
	plate.Position = UDim2.fromOffset(2, 30)
	plate.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	plate.BackgroundTransparency = 0.18

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = plate

	local label = Instance.new("TextLabel")
	label.Name = "NameplateLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamSemibold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = player.DisplayName
	label.Parent = plate

	return plate
end

local function CreateColonyMarker(player: Player): Frame
	local marker = Instance.new("Frame")
	marker.Name = "ColonyFrame"
	marker.Size = UDim2.fromOffset(120, 46)
	marker.BackgroundTransparency = 1

	local icon = Instance.new("TextButton")
	icon.Name = "ColonyIcon"
	icon.Size = UDim2.fromOffset(28, 28)
	icon.Position = UDim2.fromOffset(46, 0)
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
	marker.Position = UDim2.fromOffset(120 + (index * 90) % 600, 120 + math.floor(index / 7) * 80)
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
			if type(summary) == "table" and summary.UserId then
				profileSummaryByUserId[summary.UserId] = summary
				UpdateNameplate(summary.UserId)
				UpdateMarkerSkin(summary.UserId)
				if selectedUserId == summary.UserId then
					if ProfileCard and ProfileCard.Show then
						ProfileCard.Show(summary)
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
