--!strict

local MarketApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("MarketApp"))
local FoodHarvestersApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("FoodHarvestersApp"))

local MarketController = {}

local context: { [string]: any }
local lastFoodValue: number? = nil
local passiveAccumulatedFood = 0
local passiveFlushAt = 0

local PASSIVE_FEEDBACK_WINDOW = 1
local ACTIVE_CLICK_GRACE_SECONDS = 0.25

local function patchAtPath(root: { [any]: any }, path: { string }, value: any): ()
	local node = root
	for i = 1, #path - 1 do
		local key = path[i]
		if type(node[key]) ~= "table" then
			node[key] = {}
		end
		node = node[key]
	end
	node[path[#path]] = value
end

local function refreshAll(): ()
	context.Controllers.CurrencyHUD.Refresh()
	MarketApp.Refresh(context)
	context.Controllers.Upgrade.Refresh()
	context.Controllers.Generator.Refresh()
end

function MarketController.Init(initContext): ()
	context = initContext
end

function MarketController.Start(): ()
	context.Remotes.StateFullSync.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		context.State.PlayerData = payload.PlayerData
		if type(payload.PlayerData) == "table" and type(payload.PlayerData.Currencies) == "table" then
			lastFoodValue = payload.PlayerData.Currencies.Food
		end
		passiveAccumulatedFood = 0
		passiveFlushAt = os.clock() + PASSIVE_FEEDBACK_WINDOW
		refreshAll()
		if context.Events and context.Events.StateChanged then
			context.Events.StateChanged:Fire(context.State.PlayerData)
		end
	end)

	context.Remotes.StatePatch.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" or type(payload.Path) ~= "table" then
			return
		end
		if type(context.State.PlayerData) ~= "table" then
			context.State.PlayerData = {}
		end

		local shouldTrackPassiveFood = payload.Path[1] == "Currencies" and payload.Path[2] == "Food"
		local previousFoodValue = lastFoodValue
		patchAtPath(context.State.PlayerData, payload.Path, payload.Value)

		if shouldTrackPassiveFood and type(payload.Value) == "number" then
			local now = os.clock()
			if type(previousFoodValue) == "number" and payload.Value > previousFoodValue then
				local gained = payload.Value - previousFoodValue
				local timeSinceClick = now - (context.State.LastClickAt or 0)
				if timeSinceClick > ACTIVE_CLICK_GRACE_SECONDS then
					passiveAccumulatedFood += gained
				end
			end

			lastFoodValue = payload.Value

			if now >= passiveFlushAt then
				if passiveAccumulatedFood > 0 then
					FoodHarvestersApp.ShowPassiveIncomeFeedback(context, passiveAccumulatedFood)
				end
				passiveAccumulatedFood = 0
				passiveFlushAt = now + PASSIVE_FEEDBACK_WINDOW
			end
		end
		refreshAll()
		if context.Events and context.Events.StateChanged then
			context.Events.StateChanged:Fire(context.State.PlayerData)
		end
	end)

	context.Remotes.MarketPriceUpdated.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		context.State.Market.Price = payload.Price or context.State.Market.Price
		context.State.Market.History = payload.History or context.State.Market.History
		MarketApp.Refresh(context)
	end)
end

return MarketController
