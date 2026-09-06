-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Executor.kt", {["1-12"]=1,["13"]=17,["14"]=18,["15-16"]=19,["17-23"]=21,["24-30"]=29,["31"]=33,["32-39"]=34,["40"]=49,["41"]=50,["42-43"]=51,["44"]=54,["45"]=55,["46"]=56,["47"]=57,["48"]=58,["49"]=59,["50"]=60,["51"]=61,["52"]=62,["53"]=64,["54-55"]=65,["56"]=67,["57"]=68,["58"]=69,["59"]=71,["60"]=72,["61"]=73,["62-63"]=74,["64"]=76,["65"]=77,["66"]=78,["67"]=79,["68"]=80,["69"]=81,["70"]=82,["71"]=83,["72"]=84,["73-74"]=85,["75-77"]=87,["78"]=90,["79-81"]=91,["82-83"]=94,["84-86"]=96}, "lib")
ktox_require("lib/Inventory")
ktox_require("lib/Redstone")

DEFAULT_JOB_TIMEOUT_SECONDS = 30

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

---@param conversion DirectConversion
---@param desiredOutput number
---@param timeoutSeconds number
---@return number
function runDirectJob(conversion, desiredOutput, timeoutSeconds)
    local feederVault = ktoxConfigFeederForJob(conversion.jobType)
    if feederVault == "MISSING" then
        return 0
    end
    local totalProduced = 0
    local attempt = 1
    local giveUp = false
    while attempt <= 2 and totalProduced < desiredOutput and not giveUp do
        local remaining = desiredOutput - totalProduced
        local availableInput = storagePoolCount(conversion.inputName)
        local desiredBatches = ceilDiv(remaining, conversion.outputCount)
        local affordableBatches = floorDiv(availableInput, conversion.inputCount)
        local batches = (desiredBatches < affordableBatches and desiredBatches or affordableBatches)
        if batches <= 0 then
            giveUp = true
        else
            local inputToPush = batches * conversion.inputCount
            local expectedThisAttempt = batches * conversion.outputCount
            pullFromStoragePool(feederVault, conversion.inputName, inputToPush)
            local startingOutput = storagePoolCount(conversion.outputName)
            local powered = setJobPower(conversion.jobType, true)
            if not powered then
                giveUp = true
            else
                local lastCount = startingOutput
                local secondsSinceProgress = 0
                local madeThisAttempt = 0
                while secondsSinceProgress < timeoutSeconds and madeThisAttempt < expectedThisAttempt do
                    os.sleep(1.0)
                    local currentCount = storagePoolCount(conversion.outputName)
                    madeThisAttempt = currentCount - startingOutput
                    if currentCount > lastCount then
                        secondsSinceProgress = 0
                        lastCount = currentCount
                    else
                        secondsSinceProgress = ktox_plusAssign(secondsSinceProgress, 1)
                    end
                end
                setJobPower(conversion.jobType, false)
                totalProduced = ktox_plusAssign(totalProduced, madeThisAttempt)
            end
        end
        attempt = ktox_plusAssign(attempt, 1)
    end
    return totalProduced
end

