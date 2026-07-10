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
local lastEventEndsAt: number? = nil

local function checkPriceAlerts()
	local marketState = context.State.Market or {}
	local alerts = marketState.Alerts or {}
	local alertState = marketState.AlertState or {}
	marketState.AlertState = alertState
	local price = tonumber(marketState.Price) or 0
	local above = tonumber(alerts.Above)
	local below = tonumber(alerts.Below)
	if above then
		if price >= above and alertState.AboveTriggered ~= true then
			alertState.AboveTriggered = true
			context.Controllers.Notification.Show(string.format("Market alert: price is above $%.2f", above), "Success")
		elseif price < above then
			alertState.AboveTriggered = false
		end
	end
	if below then
		if price <= below and alertState.BelowTriggered ~= true then
			alertState.BelowTriggered = true
			context.Controllers.Notification.Show(string.format("Market alert: price is below $%.2f", below), "Warning")
		elseif price > below then
			alertState.BelowTriggered = false
		end
	end
end

local function patchAtPath(root: { [any]: any }, path: { any }, value: any): ()
	if #path == 0 then
		return
	end
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

local function applyStatePatchPayload(payload: { [string]: any }): boolean
	if type(payload) ~= "table" then
		return false
	end
	if type(payload.PlayerData) == "table" then
		context.State.PlayerData = payload.PlayerData
		return true
	end
	if type(payload.Path) ~= "table" then
		return false
	end
	if type(context.State.PlayerData) ~= "table" then
		context.State.PlayerData = {}
	end
	patchAtPath(context.State.PlayerData, payload.Path, payload.Value)
	return true
end

local function refreshForPatch(path: { any }?): ()
	context.Controllers.CurrencyHUD.Refresh()

	if type(path) ~= "table" then
		MarketApp.Refresh(context)
		if context.Controllers.Upgrade then
			context.Controllers.Upgrade.Refresh()
		end
		if context.Controllers.Generator then
			context.Controllers.Generator.Refresh()
		end
		return
	end

	local root = path[1]
	local key = path[2]

	if root == "Market" then
		MarketApp.Refresh(context)
	end

	if (root == "Upgrades" or root == "ClickTools" or (root == "Currencies" and key == "Coins")) and context.Controllers.Upgrade then
		context.Controllers.Upgrade.Refresh()
	end

	if (root == "Generators" or root == "Prestige") and context.Controllers.Generator then
		context.Controllers.Generator.Refresh()
	end
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
		refreshForPatch(payload.Path)
		if context.Events and context.Events.StateChanged then
			context.Events.StateChanged:Fire(context.State.PlayerData)
		end
	end)

	context.Remotes.StatePatch.OnClientEvent:Connect(function(payload)
		local path = if type(payload) == "table" then payload.Path else nil
		local shouldTrackPassiveFood = type(path) == "table" and path[1] == "Currencies" and path[2] == "Food"
		local previousFoodValue = lastFoodValue
		if not applyStatePatchPayload(payload) then
			return
		end

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
		refreshForPatch(path)
		if context.Events and context.Events.StateChanged then
			context.Events.StateChanged:Fire(context.State.PlayerData)
		end
	end)


	if context.Remotes.CurrencyUpdated then
		context.Remotes.CurrencyUpdated.OnClientEvent:Connect(function(payload)
			if type(payload) ~= "table" then
				return
			end
			if type(context.State.PlayerData) ~= "table" then
				context.State.PlayerData = {}
			end
			if type(context.State.PlayerData.Currencies) ~= "table" then
				context.State.PlayerData.Currencies = {}
			end
			for key, value in pairs(payload) do
				if type(key) == "string" then
					context.State.PlayerData.Currencies[key] = value
				end
			end
			refreshForPatch({"Currencies"})
			if context.Events and context.Events.StateChanged then
				context.Events.StateChanged:Fire(context.State.PlayerData)
			end
		end)
	end

	context.Remotes.MarketPriceUpdated.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		context.State.Market.Price = payload.Price or context.State.Market.Price
		context.State.Market.History = payload.History or context.State.Market.History
		context.State.Market.ActiveEvent = payload.ActiveEvent
		context.State.Market.MarketCap = payload.MarketCap or context.State.Market.MarketCap
		context.State.Market.TickerHeadline = payload.TickerHeadline or context.State.Market.TickerHeadline
		if type(payload.ActiveEvent) == "table" and payload.ActiveEvent.EndsAt ~= lastEventEndsAt then
			lastEventEndsAt = payload.ActiveEvent.EndsAt
			if payload.ActiveEvent.Rare == true then
				context.Controllers.Notification.Show("Rare market event started: Golden Picnic", "Warning")
			else
				context.Controllers.Notification.Show(string.format("Market event started: %s", payload.ActiveEvent.Name or "Market Event"), "Info")
			end
		end
		checkPriceAlerts()
		MarketApp.Refresh(context)
	end)
end

return MarketController
