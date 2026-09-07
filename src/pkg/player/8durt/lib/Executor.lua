-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Executor.kt", {["1-16"]=1,["17"]=34,["18"]=35,["19-20"]=36,["21-27"]=38,["28-34"]=46,["35"]=50,["36-42"]=51,["43"]=57,["44"]=58,["45"]=59,["46"]=60,["47"]=61,["48"]=62,["49"]=63,["50"]=64,["51"]=65,["52-53"]=66,["54-55"]=68,["56-60"]=70,["61"]=79,["62"]=80,["63"]=81,["64-71"]=82,["72"]=95,["73"]=96,["74"]=97,["75"]=98,["76"]=99,["77-78"]=100,["79"]=103,["80"]=104,["81"]=105,["82"]=106,["83"]=107,["84"]=108,["85"]=109,["86"]=110,["87-88"]=111,["89-97"]=113,["98"]=138,["99"]=139,["100-101"]=140,["102"]=142,["103"]=144,["104"]=145,["105"]=146,["106"]=147,["107"]=148,["108"]=149,["109"]=150,["110"]=152,["111-112"]=153,["113"]=155,["114"]=156,["115"]=158,["116"]=159,["117"]=160,["118-119"]=161,["120"]=163,["121"]=164,["122"]=165,["123"]=166,["124"]=167,["125"]=168,["126"]=169,["127"]=170,["128"]=171,["129-130"]=172,["131-133"]=174,["134"]=177,["135-136"]=178,["137-139"]=180,["140-141"]=183,["142-149"]=185,["150"]=198,["151"]=199,["152-153"]=200,["154"]=203,["155"]=204,["156"]=205,["157"]=206,["158"]=207,["159"]=208,["160"]=209,["161"]=211,["162-163"]=212,["164"]=214,["165"]=215,["166-167"]=216,["168"]=218,["169"]=219,["170"]=220,["171"]=221,["172"]=222,["173"]=223,["174"]=224,["175"]=225,["176-177"]=226,["178"]=229,["179"]=230,["180"]=232,["181"]=233,["182"]=234,["183"]=235,["184"]=236,["185"]=237,["186"]=238,["187"]=239,["188"]=240,["189-190"]=241,["191-193"]=243,["194-196"]=246,["197-198"]=249,["199-201"]=251}, "lib")
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
    local relayConfigured = ktoxConfigRelayForJob(recipe.jobType) ~= "MISSING"
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
            local powered = (relayConfigured and setJobPower(recipe.jobType, true) or true)
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
                if relayConfigured then
                    setJobPower(recipe.jobType, false)
                end
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
                    pushToStoragePoolTargetSlot(crafterName, slot, itemName, perBatch * batches)
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

