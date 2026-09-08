-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Executor.kt", {["1-16"]=1,["17"]=42,["18"]=43,["19-20"]=44,["21-27"]=46,["28-34"]=54,["35"]=58,["36-42"]=59,["43"]=65,["44"]=66,["45"]=67,["46"]=68,["47"]=69,["48"]=70,["49"]=71,["50"]=72,["51"]=73,["52-53"]=74,["54-55"]=76,["56-60"]=78,["61"]=87,["62"]=88,["63"]=89,["64-71"]=90,["72"]=103,["73"]=104,["74"]=105,["75"]=106,["76"]=107,["77-78"]=108,["79"]=111,["80"]=112,["81"]=113,["82"]=114,["83"]=115,["84"]=116,["85"]=117,["86"]=118,["87-88"]=119,["89-97"]=121,["98"]=146,["99"]=147,["100-101"]=148,["102"]=150,["103"]=152,["104"]=153,["105"]=154,["106"]=155,["107"]=156,["108"]=157,["109"]=158,["110"]=160,["111-112"]=161,["113"]=163,["114"]=164,["115"]=166,["116"]=167,["117"]=168,["118-119"]=169,["120"]=171,["121"]=172,["122"]=173,["123"]=174,["124"]=175,["125"]=176,["126"]=177,["127"]=178,["128"]=179,["129-130"]=180,["131-133"]=182,["134"]=185,["135-136"]=186,["137-139"]=188,["140-141"]=191,["142-149"]=193,["150"]=205,["151"]=206,["152"]=207,["153"]=208,["154"]=209,["155"]=210,["156"]=211,["157"]=212,["158"]=213,["159"]=214,["160-162"]=215,["163-164"]=218,["165-172"]=220,["173"]=245,["174"]=246,["175"]=247,["176-177"]=248,["178"]=250,["179"]=251,["180"]=252,["181-182"]=253,["183"]=255,["184"]=256,["185"]=257,["186-187"]=258,["188"]=261,["189"]=262,["190"]=263,["191"]=264,["192"]=267,["193"]=268,["194"]=270,["195"]=271,["196"]=272,["197"]=274,["198-199"]=275,["200"]=277,["201"]=278,["202"]=279,["203-204"]=280,["205-206"]=282,["207"]=284,["208"]=285,["209"]=287,["210"]=288,["211"]=289,["212"]=290,["213"]=291,["214"]=292,["215"]=296,["216"]=297,["217-218"]=298,["219"]=300,["220"]=301,["221"]=302,["222"]=303,["223-224"]=304,["225-228"]=306,["229"]=311,["230-231"]=312,["232-233"]=314,["234"]=317,["235-237"]=318,["238-239"]=321,["240-242"]=323}, "lib")
ktox_require("lib/Inventory")
ktox_require("lib/Config")
ktox_require("lib/RoleCheck")
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
---@param aboveChest string
---@param batches number
---@return boolean
function stageIngredients(recipe, aboveChest, batches)
    local inputCount = recipeInputCount(recipe)
    local i = 1
    while i <= inputCount do
        if isFirstInputOccurrence(recipe, i) then
            local itemName = recipeInputItem(recipe, i)
            local needed = totalNeededForItem(recipe, itemName, batches)
            pullFromStoragePool(aboveChest, itemName, needed)
            local actual = ktoxInventoryCountNamed(aboveChest, itemName)
            if actual < needed then
                ktoxSetLastCrafterFailure("Couldn\'t stage " .. tostring(needed) .. " of " .. tostring(itemName) .. " into " .. tostring(aboveChest) .. " for the crafter (only got " .. tostring(actual) .. ").")
                return false
            end
        end
        i = ktox_plusAssign(i, 1)
    end
    return true
end

---@param recipe Recipe
---@param desiredOutput number
---@param timeoutSeconds number
---@return number
function runCrafterJob(recipe, desiredOutput, timeoutSeconds)
    local crafterName = ktoxConfigCrafterForJob(recipe.jobType)
    if crafterName == "MISSING" then
        ktoxSetLastCrafterFailure("No crafter turtle configured for job type " .. "\"" .. tostring(recipe.jobType) .. "\"" .. ".")
        return 0
    end
    local chests = chestsFor(crafterName)
    if chests == nil then
        ktoxSetLastCrafterFailure("Crafter " .. "\"" .. tostring(crafterName) .. "\"" .. " has no aboveChest/belowChest configured in peripherals.json.")
        return 0
    end
    local storageVault = firstStorageVaultName()
    if storageVault == "MISSING" then
        ktoxSetLastCrafterFailure("No storage vault configured to move crafted items into.")
        return 0
    end
    local totalProduced = 0
    local attempt = 1
    local giveUp = false
    while attempt <= 2 and totalProduced < desiredOutput and not giveUp do
        drainVaultInto(chests.above, storageVault)
        drainVaultInto(chests.below, storageVault)
        local remaining = desiredOutput - totalProduced
        local desiredBatches = ceilDiv(remaining, recipe.outputCount)
        local batches = maxAffordableBatches(recipe, desiredBatches)
        if batches <= 0 then
            giveUp = true
        else
            local crafterId = queryForCrafter(recipe.jobType, 2.0)
            if crafterId == -1 then
                ktoxSetLastCrafterFailure("Crafter turtle for job type " .. "\"" .. tostring(recipe.jobType) .. "\"" .. " didn\'t answer.")
                giveUp = true
            elseif not stageIngredients(recipe, chests.above, batches) then
                giveUp = true
            else
                local expectedThisAttempt = batches * recipe.outputCount
                rednet.send(crafterId, tostring(recipe.outputName) .. "," .. tostring(batches), VAULT_CRAFTER_CMD_PROTOCOL)
                local lastCount = 0
                local secondsSinceProgress = 0
                local madeThisAttempt = 0
                local crafterFailure = ""
                while secondsSinceProgress < timeoutSeconds and madeThisAttempt < expectedThisAttempt and crafterFailure == "" do
                    os.sleep(1.0)
                    local gotFailure = ktoxRednetReceiveProtocol(VAULT_CRAFTER_FAILURE_PROTOCOL, 0.0)
                    if gotFailure then
                        crafterFailure = ktoxRednetLastMessage()
                    else
                        local currentCount = ktoxInventoryCountNamed(chests.below, recipe.outputName)
                        madeThisAttempt = currentCount
                        if currentCount > lastCount then
                            secondsSinceProgress = 0
                            lastCount = currentCount
                        else
                            secondsSinceProgress = ktox_plusAssign(secondsSinceProgress, 1)
                        end
                    end
                end
                if crafterFailure ~= "" then
                    ktoxSetLastCrafterFailure(crafterFailure)
                elseif madeThisAttempt < expectedThisAttempt then
                    ktoxSetLastCrafterFailure("Crafter timed out - expected " .. tostring(expectedThisAttempt) .. "x " .. tostring(recipe.outputName) .. " in the chest below, only saw " .. tostring(madeThisAttempt) .. ".")
                end
                drainVaultInto(chests.below, storageVault)
                totalProduced = ktox_plusAssign(totalProduced, madeThisAttempt)
            end
        end
        attempt = ktox_plusAssign(attempt, 1)
    end
    return totalProduced
end

