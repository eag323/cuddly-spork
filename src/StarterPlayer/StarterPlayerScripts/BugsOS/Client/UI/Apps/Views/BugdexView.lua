--!strict

local BugdexApp = require(script.Parent.Parent:WaitForChild("BugdexApp"))

local BugdexView = {}

function BugdexView.Mount(parent: Instance, context)
	BugdexApp.Mount(parent, context)
end

function BugdexView.Unmount()
	BugdexApp.Unmount()
end

return BugdexView
