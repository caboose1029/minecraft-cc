-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Executor.kt", {["1-14"]=1,["15"]=24,["16"]=25,["17-18"]=26,["19-25"]=28,["26-32"]=36,["33"]=40,["34-40"]=41,["41"]=47,["42"]=48,["43"]=49,["44"]=50,["45"]=51,["46"]=52,["47"]=53,["48"]=54,["49"]=55,["50-51"]=56,["52-53"]=58,["54-58"]=60,["59"]=69,["60"]=70,["61"]=71,["62-69"]=72,["70"]=85,["71"]=86,["72"]=87,["73"]=88,["74"]=89,["75-76"]=90,["77"]=93,["78"]=94,["79"]=95,["80"]=96,["81"]=97,["82"]=98,["83"]=99,["84"]=100,["85-86"]=101,["87-95"]=103,["96"]=120,["97"]=121,["98-99"]=122,["100"]=125,["101"]=126,["102"]=127,["103"]=128,["104"]=129,["105"]=130,["106"]=131,["107"]=133,["108-109"]=134,["110"]=136,["111"]=137,["112"]=139,["113"]=140,["114"]=141,["115-116"]=142,["117"]=144,["118"]=145,["119"]=146,["120"]=147,["121"]=148,["122"]=149,["123"]=150,["124"]=151,["125"]=152,["126-127"]=153,["128-130"]=155,["131"]=158,["132-134"]=159,["135-136"]=162,["137-139"]=164}, "lib")
ktox_require("lib/Inventory")
ktox_require("lib/Redstone")

DEFAULT_JOB_TIMEOUT_SECONDS = 30

FEEDER_EMPTY_TIMEOUT_SECONDS = 30

---@param jobType string
---@return number
function jobTimeoutSeconds(jobType)
    local configured = ktoxConfigJobTimeoutSeconds(jobType)
    if configured < 0 then
        return DEFAULT_JOB_TIMEOUT_SECONDS
    end
    return configured
end

---@param numerator number
---@param denominator number
---@return number
function floorDiv(numerator, denominator)
    return (numerator - numerator % denominator) / denominator
end

---@param numerator number
---@param denominator number
---@return number
function ceilDiv(numerator, denominator)
    local padded = numerator + denominator - 1
    return floorDiv(padded, denominator)
end

---@param recipe Recipe
---@param cap number
---@return number
function maxAffordableBatches(recipe, cap)
    local minBatches = cap
    local inputCount = recipeInputCount(recipe)
    local i = 1
    while i <= inputCount do
        local itemName = recipeInputItem(recipe, i)
        local perBatch = recipeInputCountAt(recipe, i)
        local available = storagePoolCount(itemName)
        local affordable = floorDiv(available, perBatch)
        if affordable < minBatches then
            minBatches = affordable
        end
        i = ktox_plusAssign(i, 1)
    end
    return minBatches
end

---@param vaultName string
function waitForFeederEmpty(vaultName)
    local waited = 0
    while waited < FEEDER_EMPTY_TIMEOUT_SECONDS and not ktoxInventoryIsEmpty(vaultName) do
        os.sleep(1.0)
        waited = ktox_plusAssign(waited, 1)
    end
end

---@param feederVault string
---@param recipe Recipe
---@param batches number
function pushRecipeInputs(feederVault, recipe, batches)
    local inputCount = recipeInputCount(recipe)
    if inputCount <= 1 then
        local itemName = recipeInputItem(recipe, 1)
        local perBatch = recipeInputCountAt(recipe, 1)
        pullFromStoragePool(feederVault, itemName, batches * perBatch)
        return
    end
    local unit = 1
    while unit <= batches do
        local i = 1
        while i <= inputCount do
            local itemName = recipeInputItem(recipe, i)
            local perBatch = recipeInputCountAt(recipe, i)
            pullFromStoragePool(feederVault, itemName, perBatch)
            waitForFeederEmpty(feederVault)
            i = ktox_plusAssign(i, 1)
        end
        unit = ktox_plusAssign(unit, 1)
    end
end

---@param recipe Recipe
---@param desiredOutput number
---@param timeoutSeconds number
---@return number
function runDirectJob(recipe, desiredOutput, timeoutSeconds)
    local feederVault = ktoxConfigFeederForJob(recipe.jobType)
    if feederVault == "MISSING" then
        return 0
    end
    local totalProduced = 0
    local attempt = 1
    local giveUp = false
    while attempt <= 2 and totalProduced < desiredOutput and not giveUp do
        local remaining = desiredOutput - totalProduced
        local desiredBatches = ceilDiv(remaining, recipe.outputCount)
        local batches = maxAffordableBatches(recipe, desiredBatches)
        if batches <= 0 then
            giveUp = true
        else
            local expectedThisAttempt = batches * recipe.outputCount
            pushRecipeInputs(feederVault, recipe, batches)
            local startingOutput = storagePoolCount(recipe.outputName)
            local powered = setJobPower(recipe.jobType, true)
            if not powered then
                giveUp = true
            else
                local lastCount = startingOutput
                local secondsSinceProgress = 0
                local madeThisAttempt = 0
                while secondsSinceProgress < timeoutSeconds and madeThisAttempt < expectedThisAttempt do
                    os.sleep(1.0)
                    local currentCount = storagePoolCount(recipe.outputName)
                    madeThisAttempt = currentCount - startingOutput
                    if currentCount > lastCount then
                        secondsSinceProgress = 0
                        lastCount = currentCount
                    else
                        secondsSinceProgress = ktox_plusAssign(secondsSinceProgress, 1)
                    end
                end
                setJobPower(recipe.jobType, false)
                totalProduced = ktox_plusAssign(totalProduced, madeThisAttempt)
            end
        end
        attempt = ktox_plusAssign(attempt, 1)
    end
    return totalProduced
end

