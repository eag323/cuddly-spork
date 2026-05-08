--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Remotes"):WaitForChild("RemoteNames"))

local ColonyMapController = {}
local context: { [string]: any }
local markerByUserId: { [number]: Frame } = {}
local warnedMissingNameplateByUserId: { [number]: boolean } = {}
local profileSummaryByUserId: { [number]: any } = {}
local ProfileCard = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Components"):WaitForChild("ProfileCard"))

local selectedUserId: number? = nil

local function ensureRemote(name: string): RemoteEvent?
	local remotes = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Remotes")
	local remote = remotes:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

local getSummaryRemote: RemoteEvent? = nil

local function styleName(label: TextLabel, summary)
	local display = if summary and summary.DisplayName then summary.DisplayName else label.Text
	local textColor = Color3.fromRGB(255, 255, 255)
	if summary and summary.LeaderboardPlacements and #summary.LeaderboardPlacements > 0 then
		display = "🏆 " .. display
		textColor = Color3.fromRGB(255, 215, 80)
	end
	if summary and summary.Guild and summary.Guild.Tag then
		display = "[" .. summary.Guild.Tag .. "] " .. display
	end
	label.Text = display
	label.TextColor3 = textColor
end

local function CreateNameplate(player: Player): Frame
	local plate = Instance.new("Frame")
	plate.Name = "NameplateFrame"
	plate.Size = UDim2.fromOffset(116, 16)
	plate.Position = UDim2.fromOffset(2, 30)
	plate.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	plate.BackgroundTransparency = 0.25

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = plate

	local label = Instance.new("TextLabel")
	label.Name = "NameplateLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamSemibold
	label.Text = player == Players.LocalPlayer and "My Colony" or player.DisplayName
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
	icon.Text = "🪹"
	icon.Parent = marker

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

local function UpdateNameplate(userId: number)
	local marker = markerByUserId[userId]
	if not marker then
		return
	end

	local nameplate = marker:FindFirstChild("NameplateFrame")
	if not nameplate or not nameplate:IsA("Frame") then
		nameplate = CreateNameplate(Players:GetPlayerByUserId(userId) or Players.LocalPlayer)
		nameplate.Parent = marker
	end

	local label = nameplate:FindFirstChild("NameplateLabel")
	if not label or not label:IsA("TextLabel") then
		if not warnedMissingNameplateByUserId[userId] then
			warn("[BugsOS] Missing NameplateLabel for colony marker")
			warnedMissingNameplateByUserId[userId] = true
		end
		label = Instance.new("TextLabel")
		label.Name = "NameplateLabel"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamSemibold
		label.Parent = nameplate
	end

	local summary = profileSummaryByUserId[userId]
	if summary then
		styleName(label, summary)
	end
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
	warnedMissingNameplateByUserId[userId] = nil
end

function ColonyMapController.Init(initContext): ()
	context = initContext
	if context and context.UI and context.UI.WorldLayer and ProfileCard.SetParent then
		ProfileCard.SetParent(context.UI.WorldLayer)
	end
	if ProfileCard.Hide then
		ProfileCard.Hide()
	end
	getSummaryRemote = ensureRemote(RemoteNames.Profile_GetSummary)
	if getSummaryRemote then
		getSummaryRemote.OnClientEvent:Connect(function(summary)
			if type(summary) == "table" and summary.UserId then
				profileSummaryByUserId[summary.UserId] = summary
				UpdateNameplate(summary.UserId)
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
