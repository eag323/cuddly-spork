--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BugsOSFolder = ServerScriptService:WaitForChild("BugsOS")
local ServerFolder = BugsOSFolder:WaitForChild("Server")
local ServicesFolder = ServerFolder:WaitForChild("Services")

local ProfileService = require(ServicesFolder:WaitForChild("ProfileService"))

local SharedFolder = ReplicatedStorage:WaitForChild("BugsOS"):WaitForChild("Shared")
local RemotesFolder = SharedFolder:WaitForChild("Remotes")
local RemoteNames = require(RemotesFolder:WaitForChild("RemoteNames"))

type PlayerData = { [string]: any }

local CurrencyService = {}

local function isPositiveFiniteNumber(value: any): boolean
	return type(value) == "number" and value > 0 and value == value and value ~= math.huge and value ~= -math.huge
end

local function getPlayerData(player: Player): PlayerData?
	return ProfileService.GetPlayerData(player)
end

local function getCurrencyBalance(playerData: PlayerData, currencyName: string): number?
	local currencies = playerData.Currencies
	if type(currencies) ~= "table" then
		return nil
	end

	local balance = currencies[currencyName]
	if type(balance) ~= "number" then
		return nil
	end

	return balance
end

local function patchCurrency(player: Player, currencyName: string, amount: number): ()
	ProfileService.PatchPlayerState(player, { "Currencies", currencyName }, amount)
end

function CurrencyService.GetBalance(player: Player, currencyName: string): number
	local playerData = getPlayerData(player)
	if not playerData then
		return 0
	end

	local balance = getCurrencyBalance(playerData, currencyName)
	if not balance then
		return 0
	end

	return balance
end

function CurrencyService.AddCurrency(player: Player, currencyName: string, amount: number): boolean
	if not isPositiveFiniteNumber(amount) then
		return false
	end

	local playerData = getPlayerData(player)
	if not playerData then
		return false
	end

	local currentBalance = getCurrencyBalance(playerData, currencyName)
	if currentBalance == nil then
		return false
	end

	local newBalance = currentBalance + amount
	playerData.Currencies[currencyName] = newBalance
	patchCurrency(player, currencyName, newBalance)

	return true
end

function CurrencyService.RemoveCurrency(player: Player, currencyName: string, amount: number): boolean
	if not isPositiveFiniteNumber(amount) then
		return false
	end

	local playerData = getPlayerData(player)
	if not playerData then
		return false
	end

	local currentBalance = getCurrencyBalance(playerData, currencyName)
	if currentBalance == nil or currentBalance < amount then
		return false
	end

	local newBalance = currentBalance - amount
	playerData.Currencies[currencyName] = newBalance
	patchCurrency(player, currencyName, newBalance)

	return true
end

function CurrencyService.CanAfford(player: Player, currencyName: string, amount: number): boolean
	if not isPositiveFiniteNumber(amount) then
		return false
	end

	local balance = CurrencyService.GetBalance(player, currencyName)
	return balance >= amount
end

function CurrencyService.AddFood(player: Player, amount: number): boolean
	if not isPositiveFiniteNumber(amount) then
		return false
	end

	local playerData = getPlayerData(player)
	if not playerData then
		return false
	end

	if not CurrencyService.AddCurrency(player, "Food", amount) then
		return false
	end

	local lifetimeFood = getCurrencyBalance(playerData, "LifetimeFood")
	if lifetimeFood == nil then
		return false
	end

	local newLifetimeFood = lifetimeFood + amount
	playerData.Currencies.LifetimeFood = newLifetimeFood
	patchCurrency(player, "LifetimeFood", newLifetimeFood)

	return true
end

function CurrencyService.RemoveFood(player: Player, amount: number): boolean
	return CurrencyService.RemoveCurrency(player, "Food", amount)
end

function CurrencyService.AddCoins(player: Player, amount: number): boolean
	return CurrencyService.AddCurrency(player, "Coins", amount)
end

function CurrencyService.Init(): ()
	local remoteName = RemoteNames.Currency_Updated or "Currency_Updated"
	local existing = RemotesFolder:FindFirstChild(remoteName)
	if existing and existing:IsA("RemoteEvent") then
		return
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = RemotesFolder
end

function CurrencyService.Start(): ()
	-- Intentionally no-op; no runtime loops needed yet.
end

return CurrencyService
