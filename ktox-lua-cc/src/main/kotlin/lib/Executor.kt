package lib

import common.ktoxConfigFeederForJob
import common.ktoxConfigJobTimeoutSecondsRaw
import common.ktoxInventoryIsEmpty
import common.osSleep
import lib.pullFromStoragePool
import lib.setJobPower
import lib.storagePoolCount

const val DEFAULT_JOB_TIMEOUT_SECONDS = 30

// How long to wait for a feeder vault to actually drain before pushing
// the next ingredient in a multi-ingredient job's interleaved push (see
// pushRecipeInputs). Separate from the job's own output timeout — this
// is about the funnel/chute clearing, not the machine finishing.
const val FEEDER_EMPTY_TIMEOUT_SECONDS = 30

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

// The most whole batches of `recipe` affordable (bounded by `cap`),
// bottlenecked by whichever ingredient runs out first.
fun maxAffordableBatches(recipe: Recipe, cap: Int): Int {
    var minBatches = cap
    val inputCount = recipeInputCount(recipe)
    var i = 1
    while (i <= inputCount) {
        val itemName = recipeInputItem(recipe, i)
        val perBatch = recipeInputCountAt(recipe, i)
        val available = storagePoolCount(itemName)
        val affordable = floorDiv(available, perBatch)
        if (affordable < minBatches) {
            minBatches = affordable
        }
        i += 1
    }
    return minBatches
}

// Waits (polling once a second) for `vaultName` to be completely empty,
// giving up after FEEDER_EMPTY_TIMEOUT_SECONDS either way — a feeder
// that never drains shouldn't hang a job forever, just proceed best
// effort (matches the "double-feeding is acceptable" risk tolerance
// already established for the retry path).
fun waitForFeederEmpty(vaultName: String) {
    var waited = 0
    while (waited < FEEDER_EMPTY_TIMEOUT_SECONDS && !ktoxInventoryIsEmpty(vaultName)) {
        osSleep(1.0)
        waited += 1
    }
}

// Pushes `batches` worth of every ingredient in `recipe` into
// `feederVault`. A single-ingredient recipe pushes its whole quantity in
// one go (existing, fast behavior). A multi-ingredient recipe (brass:
// copper + zinc) interleaves instead — one unit of each ingredient at a
// time, waiting for the feeder to fully drain between each push — since
// dumping a full batch of one ingredient before the other arrives can
// clog the funnel/basin downstream and starve the recipe of its other
// half (observed in-game, see PLAN.md).
fun pushRecipeInputs(feederVault: String, recipe: Recipe, batches: Int) {
    val inputCount = recipeInputCount(recipe)
    if (inputCount <= 1) {
        val itemName = recipeInputItem(recipe, 1)
        val perBatch = recipeInputCountAt(recipe, 1)
        pullFromStoragePool(feederVault, itemName, batches * perBatch)
        return
    }

    var unit = 1
    while (unit <= batches) {
        var i = 1
        while (i <= inputCount) {
            val itemName = recipeInputItem(recipe, i)
            val perBatch = recipeInputCountAt(recipe, i)
            pullFromStoragePool(feederVault, itemName, perBatch)
            waitForFeederEmpty(feederVault)
            i += 1
        }
        unit += 1
    }
}

// Runs one direct (single-hop) job to produce up to `desiredOutput` more
// of the recipe's output — see PLAN.md ("craft" CLI command) for the
// full semantics this implements: push input into the job's feeder
// vault (interleaved for multi-ingredient recipes, see
// pushRecipeInputs), power the machine on, poll the storage pool for
// progress, timeout resets on any increase, one retry (which re-pushes
// input for whatever's still missing — double-feeding a partially-run
// machine is accepted, not guarded against) before giving up. Always
// powers the machine back off at the end of an attempt, success or not —
// never leaves a machine running unattended. Returns how many were
// actually produced in total (may be less than desiredOutput if input
// ran out or both attempts timed out).
fun runDirectJob(recipe: Recipe, desiredOutput: Int, timeoutSeconds: Int): Int {
    val feederVault = ktoxConfigFeederForJob(recipe.jobType)
    if (feederVault == "MISSING") {
        return 0
    }

    var totalProduced = 0
    var attempt = 1
    var giveUp = false
    while (attempt <= 2 && totalProduced < desiredOutput && !giveUp) {
        val remaining = desiredOutput - totalProduced
        val desiredBatches = ceilDiv(remaining, recipe.outputCount)
        val batches = maxAffordableBatches(recipe, desiredBatches)

        if (batches <= 0) {
            giveUp = true
        } else {
            val expectedThisAttempt = batches * recipe.outputCount
            pushRecipeInputs(feederVault, recipe, batches)

            val startingOutput = storagePoolCount(recipe.outputName)
            val powered = setJobPower(recipe.jobType, true)
            if (!powered) {
                giveUp = true
            } else {
                var lastCount = startingOutput
                var secondsSinceProgress = 0
                var madeThisAttempt = 0
                while (secondsSinceProgress < timeoutSeconds && madeThisAttempt < expectedThisAttempt) {
                    osSleep(1.0)
                    val currentCount = storagePoolCount(recipe.outputName)
                    madeThisAttempt = currentCount - startingOutput
                    if (currentCount > lastCount) {
                        secondsSinceProgress = 0
                        lastCount = currentCount
                    } else {
                        secondsSinceProgress += 1
                    }
                }
                setJobPower(recipe.jobType, false)
                totalProduced += madeThisAttempt
            }
        }
        attempt += 1
    }
    return totalProduced
}
