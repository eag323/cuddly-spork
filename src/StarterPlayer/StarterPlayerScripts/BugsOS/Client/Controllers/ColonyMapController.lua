--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormatter = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("NumberFormatter"))
local RemoteNames = require(ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Remotes"):WaitForChild("RemoteNames"))

local ColonyMapController = {}
local context: { [string]: any }
local markerByUserId: { [number]: Frame } = {}
local profileSummaryByUserId: {[number]: any} = {}
local card: Frame? = nil

local function ensureRemote(name: string): RemoteEvent?
	local remotes = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared"):WaitForChild("Remotes")
	local r = remotes:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then return r end
	return nil
end

local getSummaryRemote: RemoteEvent? = nil
local function styleName(label: TextLabel, summary)
	local display = if summary and summary.DisplayName then summary.DisplayName else label.Text
	local textColor = Color3.fromRGB(255,255,255)
	if summary and summary.LeaderboardPlacements and #summary.LeaderboardPlacements > 0 then
		display = "🏆 " .. display
		textColor = Color3.fromRGB(255,215,80)
	end
	if summary and summary.Guild and summary.Guild.Tag then
		display = "["..summary.Guild.Tag.."] " .. display
	end
	label.Text = display
	label.TextColor3 = textColor
end

local function createMarker(player: Player): Frame
	local marker = Instance.new("Frame") marker.Size = UDim2.fromOffset(120,46) marker.BackgroundTransparency=1
	local button=Instance.new("TextButton") button.Size=UDim2.fromOffset(28,28) button.Position=UDim2.fromOffset(46,0) button.Text="🪹" button.Parent=marker
	local plate=Instance.new("Frame") plate.Size=UDim2.fromOffset(116,16) plate.Position=UDim2.fromOffset(2,30) plate.BackgroundColor3=Color3.fromRGB(0,0,0) plate.BackgroundTransparency=0.25 plate.Parent=marker
	local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,8) c.Parent=plate
	local lbl=Instance.new("TextLabel") lbl.Name="NameplateLabel" lbl.Size=UDim2.fromScale(1,1) lbl.BackgroundTransparency=1 lbl.TextScaled=true lbl.Font=Enum.Font.GothamSemibold lbl.Text = player==Players.LocalPlayer and "My Colony" or player.DisplayName lbl.Parent=plate
	button.Activated:Connect(function()
		if getSummaryRemote then getSummaryRemote:FireServer(player.UserId) end
	end)
	return marker
end

local function showCard(summary)
	if not context.UI.WorldLayer then return end
	if card then card:Destroy() end
	card=Instance.new("Frame") card.Size=UDim2.fromOffset(300,250) card.Position=UDim2.fromScale(0.62,0.2) card.BackgroundColor3=Color3.fromRGB(12,27,54) card.Parent=context.UI.WorldLayer
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,12)
	local n=Instance.new("TextLabel") n.Size=UDim2.fromOffset(280,24) n.Position=UDim2.fromOffset(12,10) n.BackgroundTransparency=1 n.TextXAlignment=Enum.TextXAlignment.Left n.Font=Enum.Font.GothamBold n.TextColor3=Color3.new(1,1,1) n.Text=summary.DisplayName n.Parent=card
	local t=Instance.new("TextLabel") t.Size=UDim2.fromOffset(280,18) t.Position=UDim2.fromOffset(12,36) t.BackgroundTransparency=1 t.TextXAlignment=Enum.TextXAlignment.Left t.TextColor3=Color3.fromRGB(0,255,120) t.Text="● Online" t.Parent=card
	local st=Instance.new("TextLabel") st.Size=UDim2.fromOffset(280,52) st.Position=UDim2.fromOffset(12,58) st.BackgroundTransparency=1 st.TextXAlignment=Enum.TextXAlignment.Left st.TextYAlignment=Enum.TextYAlignment.Top st.TextWrapped=true st.Text=string.format("Prestige: %d | Farm: %d Generators\nFood/sec: %s | Lifetime Food: %s\nNectar: %s", summary.Prestige or 0, summary.GeneratorCount or 0, NumberFormatter.Format(summary.FoodPerSec or 0), NumberFormatter.Format(summary.LifetimeFood or 0), NumberFormatter.Format(summary.CurrentNectar or 0)) st.Parent=card
end

function ColonyMapController.Init(initContext): ()
	context = initContext
	getSummaryRemote = ensureRemote(RemoteNames.Profile_GetSummary)
	if getSummaryRemote then
		getSummaryRemote.OnClientEvent:Connect(function(summary)
			if type(summary)=="table" and summary.UserId then
				profileSummaryByUserId[summary.UserId]=summary
				local m=markerByUserId[summary.UserId]
				if m then styleName(m.NameplateLabel, summary) end
				showCard(summary)
			end
		end)
	end
end

function ColonyMapController.Refresh(): () end
function ColonyMapController.Start(): ()
	local world = context.UI.WorldLayer
	for i,p in ipairs(Players:GetPlayers()) do
		local m=createMarker(p); m.Parent=world; m.Position=UDim2.fromOffset(120 + (i*90)%600, 120 + math.floor(i/7)*80); markerByUserId[p.UserId]=m
		if getSummaryRemote then getSummaryRemote:FireServer(p.UserId) end
	end
end

return ColonyMapController
