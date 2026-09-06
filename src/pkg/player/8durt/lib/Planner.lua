-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Planner.kt", {["1-15"]=1,["16"]=37,["17"]=38,["18-19"]=39,["20"]=41,["21-22"]=42,["23"]=45,["24"]=46,["25"]=47,["26-27"]=48,["28"]=51,["29"]=52,["30"]=53,["31"]=54,["32"]=55,["33"]=56,["34"]=61,["35-36"]=62,["37"]=65,["38"]=66,["39-41"]=67}, "lib")
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
    local recipe = findRecipe(itemName)
    if recipe == nil then
        return currentStock
    end
    local batchesNeeded = ceilDiv(shortfall, recipe.outputCount)
    local inputCount = recipeInputCount(recipe)
    local i = 1
    while i <= inputCount do
        local inputItem = recipeInputItem(recipe, i)
        local perBatch = recipeInputCountAt(recipe, i)
        ensureStocked(inputItem, batchesNeeded * perBatch, depth + 1)
        i = ktox_plusAssign(i, 1)
    end
    local timeout = jobTimeoutSeconds(recipe.jobType)
    runDirectJob(recipe, shortfall, timeout)
    return storagePoolCount(itemName)
end

