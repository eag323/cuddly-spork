--!strict

local NumberUtil = {}

local SUFFIXES = {
	"",
	"K",
	"M",
	"B",
	"T",
	"Qa",
	"Qi",
	"Sx",
	"Sp",
	"Oc",
	"No",
	"Dc",
}

function NumberUtil.FormatNumber(value: any): string
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return "0"
	end

	if value == 0 then
		return "0"
	end

	local isNegative = value < 0
	local absoluteValue = math.abs(value)
	local suffixIndex = 1

	while absoluteValue >= 1000 do
		absoluteValue /= 1000
		suffixIndex += 1
	end

	local suffix = SUFFIXES[suffixIndex]
	if not suffix then
		suffix = "e" .. tostring((suffixIndex - 1) * 3)
	end

	local roundedTwo = math.floor((absoluteValue * 100) + 0.5) / 100
	if roundedTwo >= 1000 then
		roundedTwo /= 1000
		suffixIndex += 1
		suffix = SUFFIXES[suffixIndex] or ("e" .. tostring((suffixIndex - 1) * 3))
	end

	local decimals = if roundedTwo >= 100 then 0 elseif roundedTwo >= 10 then 1 else 2
	local formattedNumber = string.format("%0." .. tostring(decimals) .. "f", roundedTwo)
	formattedNumber = formattedNumber:gsub("%.0+$", ""):gsub("(%..-)0+$", "%1")

	return (isNegative and "-" or "") .. formattedNumber .. suffix
end

return NumberUtil
