-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Planner.kt", {["1-15"]=1,["16"]=33,["17"]=34,["18-19"]=35,["20"]=37,["21-22"]=38,["23"]=41,["24"]=42,["25"]=43,["26-27"]=44,["28"]=47,["29"]=48,["30"]=53,["31"]=55,["32"]=56,["33-35"]=57}, "lib")
ktox_require("lib/Executor")
ktox_require("lib/Config")
ktox_require("lib/Inventory")

MAX_PLANNER_DEPTH = 5

---@param itemName string
---@param desiredCount number
---@param depth number
---@return number
function ensureStocked(itemName, desiredCount, depth)
    local currentStock = storagePoolCount(itemName)
    if currentStock >= desiredCount then
        return currentStock
    end
    if depth >= MAX_PLANNER_DEPTH then
        return currentStock
    end
    local shortfall = desiredCount - currentStock
    local conversion = findDirectConversion(itemName)
    if conversion == nil then
        return currentStock
    end
    local batchesNeeded = ceilDiv(shortfall, conversion.outputCount)
    local inputNeeded = batchesNeeded * conversion.inputCount
    ensureStocked(conversion.inputName, inputNeeded, depth + 1)
    local timeout = jobTimeoutSeconds(conversion.jobType)
    runDirectJob(conversion, shortfall, timeout)
    return storagePoolCount(itemName)
end

