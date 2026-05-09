--!strict

--[[
	NumberFormatter: shared utility placeholder.
	TODO: Add reusable helper functions and unit tests.
]]

local NumberFormatter = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function NumberFormatter.Abbreviate(value: number?): string
	local n = tonumber(value) or 0
	local sign = if n < 0 then "-" else ""
	n = math.abs(n)
	if n < 1000 then
		return sign .. tostring(math.floor(n + 0.5))
	end

	local suffixIndex = 1
	while n >= 1000 and suffixIndex < #SUFFIXES do
		n /= 1000
		suffixIndex += 1
	end

	local formatted = if n >= 100 then string.format("%.0f", n) elseif n >= 10 then string.format("%.1f", n) else string.format("%.2f", n)
	formatted = formatted:gsub("%.00$", ""):gsub("(%..-)0$", "%1"):gsub("%.$", "")
	return sign .. formatted .. SUFFIXES[suffixIndex]
end

function NumberFormatter.FormatCompact(value: number?): string
	return NumberFormatter.Abbreviate(value)
end

return NumberFormatter
