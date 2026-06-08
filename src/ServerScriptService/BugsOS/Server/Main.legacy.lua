-- BugsOS server entrypoint

local ServicesFolder = script.Parent:WaitForChild("Services")

type ServiceEntry = {
	name: string,
	module: any,
}

local serviceOrder = {
	"ProfileService",
	"CurrencyService",
	"StatsService",
	"BuffService",
	"MarketService",
	"UpgradeService",
	"GeneratorService",
	"PrestigeService",
	"ClickService",
	"BugInventoryService",
	"BugFarmService",
	"BugdexService",
	"AchievementService",
	"ProfileDisplayService",
	"BugSpawnService",
	"EquipmentService",
	"EnemySpawnService",
}

local services: { ServiceEntry } = {}

local function requireService(name: string): ServiceEntry?
	local ok, result = pcall(function()
		return require(ServicesFolder:WaitForChild(name))
	end)

	if not ok then
		warn(string.format("[ServerBoot] Failed to require %s: %s", name, tostring(result)))
		return nil
	end

	print(string.format("[ServerBoot] Required %s", name))
	return {
		name = name,
		module = result,
	}
end

local function runLifecycle(methodName: "Init" | "Start")
	for _, service in services do
		local method = service.module[methodName]
		if type(method) == "function" then
			local ok, err = pcall(method)
			if ok then
				print(string.format("[ServerBoot] %s.%s complete", service.name, methodName))
			else
				warn(string.format("[ServerBoot] %s.%s failed: %s", service.name, methodName, tostring(err)))
			end
		else
			print(string.format("[ServerBoot] %s has no %s", service.name, methodName))
		end
	end
end

print("[ServerBoot] Bootstrapping services...")
for _, serviceName in serviceOrder do
	local service = requireService(serviceName)
	if service then
		table.insert(services, service)
	end
end

print("[ServerBoot] Running Init...")
runLifecycle("Init")

print("[ServerBoot] Running Start...")
runLifecycle("Start")

print("[ServerBoot] Service boot complete.")
