package lib

import common.ktoxConfigFeederForJob
import common.ktoxConfigJobTimeoutSecondsRaw
import common.osSleep
import lib.pullFromStoragePool
import lib.setJobPower
import lib.storagePoolCount

const val DEFAULT_JOB_TIMEOUT_SECONDS = 30

// The configured per-job timeout, falling back to a sensible default
// when config/job-types.json doesn't specify one — different machines
// have very different throughput, so this is meant to actually be tuned
// per job type once real timing is known from in-game testing.
fun jobTimeoutSeconds(jobType: String): Int {
    val configured = ktoxConfigJobTimeoutSecondsRaw(jobType)
    if (configured < 0) {
        return DEFAULT_JOB_TIMEOUT_SECONDS
    }
    return configured
}

// Integer division helpers, safe under ktox's quirk where Int/Int always
// stays float in the transpiled Lua (see AGENTS.md) — both subtract off
// the remainder first, matching Kotlin's own truncating semantics while
// producing an exact whole number under Lua's float division.
fun floorDiv(numerator: Int, denominator: Int): Int {
    return (numerator - numerator % denominator) / denominator
}

fun ceilDiv(numerator: Int, denominator: Int): Int {
    val padded = numerator + denominator - 1
    return floorDiv(padded, denominator)
}

// Runs one direct (single-hop) job to produce up to `desiredOutput` more
// of the conversion's output — see PLAN.md ("craft" CLI command) for the
// full semantics this implements: push input into the job's feeder
// vault, power the machine on, poll the storage pool for progress,
// timeout resets on any increase, one retry (which re-pushes input for
// whatever's still missing — double-feeding a partially-run machine is
// accepted, not guarded against) before giving up. Always powers the
// machine back off at the end of an attempt, success or not — never
// leaves a machine running unattended. Returns how many were actually
// produced in total (may be less than desiredOutput if input ran out or
// both attempts timed out).
fun runDirectJob(conversion: DirectConversion, desiredOutput: Int, timeoutSeconds: Int): Int {
    val feederVault = ktoxConfigFeederForJob(conversion.jobType)
    if (feederVault == "MISSING") {
        return 0
    }

    var totalProduced = 0
    var attempt = 1
    var giveUp = false
    while (attempt <= 2 && totalProduced < desiredOutput && !giveUp) {
        val remaining = desiredOutput - totalProduced
        val availableInput = storagePoolCount(conversion.inputName)
        val desiredBatches = ceilDiv(remaining, conversion.outputCount)
        val affordableBatches = floorDiv(availableInput, conversion.inputCount)
        val batches = if (desiredBatches < affordableBatches) desiredBatches else affordableBatches

        if (batches <= 0) {
            giveUp = true
        } else {
            val inputToPush = batches * conversion.inputCount
            val expectedThisAttempt = batches * conversion.outputCount
            pullFromStoragePool(feederVault, conversion.inputName, inputToPush)

            val startingOutput = storagePoolCount(conversion.outputName)
            val powered = setJobPower(conversion.jobType, true)
            if (!powered) {
                giveUp = true
            } else {
                var lastCount = startingOutput
                var secondsSinceProgress = 0
                var madeThisAttempt = 0
                while (secondsSinceProgress < timeoutSeconds && madeThisAttempt < expectedThisAttempt) {
                    osSleep(1.0)
                    val currentCount = storagePoolCount(conversion.outputName)
                    madeThisAttempt = currentCount - startingOutput
                    if (currentCount > lastCount) {
                        secondsSinceProgress = 0
                        lastCount = currentCount
                    } else {
                        secondsSinceProgress += 1
                    }
                }
                setJobPower(conversion.jobType, false)
                totalProduced += madeThisAttempt
            }
        }
        attempt += 1
    }
    return totalProduced
}
