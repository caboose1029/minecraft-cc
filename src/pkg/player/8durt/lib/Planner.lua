-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Planner.kt", {["1-15"]=1,["16"]=39,["17"]=40,["18-19"]=41,["20"]=43,["21-22"]=44,["23"]=47,["24"]=48,["25"]=49,["26-27"]=50,["28"]=53,["29"]=54,["30"]=55,["31"]=56,["32"]=57,["33"]=58,["34"]=63,["35-36"]=64,["37"]=67,["38"]=68,["39-40"]=69,["41-42"]=71,["43-45"]=73}, "lib")
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
    if jobKind(recipe.jobType) == "crafter" then
        runCrafterJob(recipe, shortfall, timeout)
    else
        runDirectJob(recipe, shortfall, timeout)
    end
    return storagePoolCount(itemName)
end

