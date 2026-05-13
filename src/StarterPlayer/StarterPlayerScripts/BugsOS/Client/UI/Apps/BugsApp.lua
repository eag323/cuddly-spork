--!strict

local BugFarmApp = require(script.Parent:WaitForChild("BugFarmApp"))

local BugsApp = {}

-- Unified Bugs.exe app wrapper.
-- For now this delegates to the polished BugFarm hub which already contains
-- Farmers, Combat Team, and Recycling. This module is the canonical app id.

function BugsApp.Mount(target, context)
	BugFarmApp.Mount(target, context)
end

function BugsApp.Unmount()
	BugFarmApp.Unmount()
end

return BugsApp
