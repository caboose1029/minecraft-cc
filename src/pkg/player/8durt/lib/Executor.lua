-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Executor.kt", {["1-16"]=1,["17"]=33,["18"]=34,["19-20"]=35,["21-27"]=37,["28-34"]=45,["35"]=49,["36-42"]=50,["43"]=56,["44"]=57,["45"]=58,["46"]=59,["47"]=60,["48"]=61,["49"]=62,["50"]=63,["51"]=64,["52-53"]=65,["54-55"]=67,["56-60"]=69,["61"]=78,["62"]=79,["63"]=80,["64-71"]=81,["72"]=94,["73"]=95,["74"]=96,["75"]=97,["76"]=98,["77-78"]=99,["79"]=102,["80"]=103,["81"]=104,["82"]=105,["83"]=106,["84"]=107,["85"]=108,["86"]=109,["87-88"]=110,["89-97"]=112,["98"]=129,["99"]=130,["100-101"]=131,["102"]=134,["103"]=135,["104"]=136,["105"]=137,["106"]=138,["107"]=139,["108"]=140,["109"]=142,["110-111"]=143,["112"]=145,["113"]=146,["114"]=148,["115"]=149,["116"]=150,["117-118"]=151,["119"]=153,["120"]=154,["121"]=155,["122"]=156,["123"]=157,["124"]=158,["125"]=159,["126"]=160,["127"]=161,["128-129"]=162,["130-132"]=164,["133"]=167,["134-136"]=168,["137-138"]=171,["139-146"]=173,["147"]=186,["148"]=187,["149-150"]=188,["151"]=191,["152"]=192,["153"]=193,["154"]=194,["155"]=195,["156"]=196,["157"]=197,["158"]=199,["159-160"]=200,["161"]=202,["162"]=203,["163-164"]=204,["165"]=206,["166"]=207,["167"]=208,["168"]=209,["169"]=210,["170"]=211,["171"]=212,["172"]=213,["173-174"]=214,["175"]=217,["176"]=218,["177"]=220,["178"]=221,["179"]=222,["180"]=223,["181"]=224,["182"]=225,["183"]=226,["184"]=227,["185"]=228,["186-187"]=229,["188-190"]=231,["191-193"]=234,["194-195"]=237,["196-198"]=239}, "lib")
ktox_require("lib/Inventory")
ktox_require("lib/RoleCheck")
ktox_require("lib/Config")
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

---@param recipe Recipe
---@param desiredOutput number
---@param timeoutSeconds number
---@return number
function runCrafterJob(recipe, desiredOutput, timeoutSeconds)
    local crafterName = ktoxConfigCrafterForJob(recipe.jobType)
    if crafterName == "MISSING" then
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
            local crafterId = queryForCrafter(recipe.jobType, 2.0)
            if crafterId == -1 then
                giveUp = true
            else
                local expectedThisAttempt = batches * recipe.outputCount
                local inputCount = recipeInputCount(recipe)
                local i = 1
                while i <= inputCount do
                    local itemName = recipeInputItem(recipe, i)
                    local perBatch = recipeInputCountAt(recipe, i)
                    local slot = recipeInputSlot(recipe, i)
                    pullFromStoragePoolToSlot(crafterName, slot, itemName, perBatch * batches)
                    i = ktox_plusAssign(i, 1)
                end
                local startingOutput = storagePoolCount(recipe.outputName)
                rednet.send(crafterId, tostring(batches), VAULT_CRAFTER_CMD_PROTOCOL)
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
                totalProduced = ktox_plusAssign(totalProduced, madeThisAttempt)
            end
        end
        attempt = ktox_plusAssign(attempt, 1)
    end
    return totalProduced
end

