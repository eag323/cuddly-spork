--!strict

local MarketApp = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Apps"):WaitForChild("MarketApp"))

local MarketController = {}

local context: { [string]: any }

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
		refreshAll()
	end)

	context.Remotes.StatePatch.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" or type(payload.Path) ~= "table" then
			return
		end
		if type(context.State.PlayerData) ~= "table" then
			context.State.PlayerData = {}
		end
		patchAtPath(context.State.PlayerData, payload.Path, payload.Value)
		refreshAll()
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
