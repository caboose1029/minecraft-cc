package lib

import common.ktoxConfigCrafterForJob
import common.ktoxConfigFeederForJob
import common.ktoxConfigJobTimeoutSecondsRaw
import common.ktoxConfigRelayForJob
import common.ktoxInventoryCountNamed
import common.ktoxInventoryIsEmpty
import common.ktoxRednetLastMessage
import common.ktoxRednetReceiveProtocol
import common.ktoxSetLastCrafterFailure
import common.osSleep
import common.rednetSend
import lib.chestsFor
import lib.drainVaultInto
import lib.leastFullStorageVaultName
import lib.isFirstInputOccurrence
import lib.pullFromStoragePool
import lib.queryForCrafter
import lib.recipeInputCount
import lib.recipeInputCountAt
import lib.recipeInputItem
import lib.setJobPower
import lib.storagePoolCount
import lib.totalNeededForItem
import lib.VAULT_CRAFTER_CMD_PROTOCOL
import lib.VAULT_CRAFTER_FAILURE_PROTOCOL

const val DEFAULT_JOB_TIMEOUT_SECONDS = 30

// How long to wait for a feeder vault to actually drain before pushing
// the next ingredient in a multi-ingredient job's interleaved push (see
// pushRecipeInputs). Separate from the job's own output timeout — this
// is about the funnel/chute clearing, not the machine finishing.
const val FEEDER_EMPTY_TIMEOUT_SECONDS = 30

// The configured per-job timeout, falling back to a sensible default
// when config/job-types.lua doesn't specify one — different machines
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
//
// A redstone relay is OPTIONAL, not required — confirmed via research
// that plenty of real Create machines (a Deployer applying an ingredient
// to a passing item, a Mixer basin fed by an always-lit Blaze Burner)
// run continuously with no redstone control at all; the player only
// wires a relay to a job type if they actually want on/off control. No
// relay configured is NOT treated as failure here — only a relay that's
// configured but unreachable in-world is.
fun runDirectJob(recipe: Recipe, desiredOutput: Int, timeoutSeconds: Int): Int {
    val feederVault = ktoxConfigFeederForJob(recipe.jobType)
    if (feederVault == "MISSING") {
        return 0
    }
    val relayConfigured = ktoxConfigRelayForJob(recipe.jobType) != "MISSING"

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
            val powered = if (relayConfigured) setJobPower(recipe.jobType, true) else true
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
                if (relayConfigured) {
                    setJobPower(recipe.jobType, false)
                }
                totalProduced += madeThisAttempt
            }
        }
        attempt += 1
    }
    return totalProduced
}

// Stages every distinct ingredient `recipe` needs (summed across however
// many grid slots it fills, times `batches`) into `aboveChest`, then
// verifies the full amount actually landed there before returning true -
// a silent short-delivery (the established failure shape for every
// pull/push helper in this codebase) would otherwise only surface later
// as a confusing crafter-side failure, not here where the real cause is
// obvious. Sets ktoxSetLastCrafterFailure with a specific reason and
// returns false on the first shortfall.
fun stageIngredients(recipe: Recipe, aboveChest: String, batches: Int): Boolean {
    val inputCount = recipeInputCount(recipe)
    var i = 1
    while (i <= inputCount) {
        if (isFirstInputOccurrence(recipe, i)) {
            val itemName = recipeInputItem(recipe, i)
            val needed = totalNeededForItem(recipe, itemName, batches)
            pullFromStoragePool(aboveChest, itemName, needed)
            val actual = ktoxInventoryCountNamed(aboveChest, itemName)
            if (actual < needed) {
                ktoxSetLastCrafterFailure("Couldn't stage ${needed} of ${itemName} into ${aboveChest} for the crafter (only got ${actual}).")
                return false
            }
        }
        i += 1
    }
    return true
}

// Runs one crafter-kind job (a crafty turtle running turtle.craft() —
// see PLAN.md "Crafter role") to produce up to `desiredOutput` more of
// the recipe's output. Same batching/timeout shape as runDirectJob, but
// the physical flow is chest-above -> turtle -> chest-below, top to
// bottom, matching Create's own machine convention (see PLAN.md): stage
// every distinct ingredient into a dedicated chest above the crafter
// (chestsFor - a physically dedicated pair of chests declared on
// the crafter's OWN peripherals.json entry, not pooled/shared vaults),
// tell the crafter what to make and how many times
// ("<outputItemName>,<batches>" - it looks up the recipe/slot shape
// itself, same shared lib/Config.kt functions the head uses here), then
// watch the chest below for the result while also listening for an
// explicit failure report (VAULT_CRAFTER_FAILURE_PROTOCOL) so a genuine
// problem surfaces as a specific reason, not just a generic timeout.
// Both chests are drained back into storage proactively before every
// attempt, not just once — stale contents from an earlier attempt/job
// should never be able to linger and contaminate the next one (this is
// the THIRD ingredient-delivery design tried this session; the first two
// - a network push into the turtle's grid slots, then a network-signaled
// per-slot turtle.suckUp() - are both gone, see PLAN.md's "Known open
// items" for why neither held up).
fun runCrafterJob(recipe: Recipe, desiredOutput: Int, timeoutSeconds: Int): Int {
    val crafterName = ktoxConfigCrafterForJob(recipe.jobType)
    if (crafterName == "MISSING") {
        ktoxSetLastCrafterFailure("No crafter turtle configured for job type \"${recipe.jobType}\".")
        return 0
    }
    val chests = chestsFor(crafterName)
    if (chests == null) {
        ktoxSetLastCrafterFailure("Crafter \"${crafterName}\" has no aboveChest/belowChest configured in peripherals.json.")
        return 0
    }
    if (leastFullStorageVaultName() == "MISSING") {
        ktoxSetLastCrafterFailure("No storage vault configured to move crafted items into.")
        return 0
    }

    var totalProduced = 0
    var attempt = 1
    var giveUp = false
    while (attempt <= 2 && totalProduced < desiredOutput && !giveUp) {
        // Proactively drain both chests before every attempt - stale
        // leftovers from an earlier attempt/job should never linger.
        // Picked fresh each time (not cached from outside the loop) since
        // load balancing should reflect whichever vault is emptiest RIGHT
        // NOW, which can change between attempts.
        drainVaultInto(chests.above, leastFullStorageVaultName())
        drainVaultInto(chests.below, leastFullStorageVaultName())

        val remaining = desiredOutput - totalProduced
        val desiredBatches = ceilDiv(remaining, recipe.outputCount)
        val batches = maxAffordableBatches(recipe, desiredBatches)

        if (batches <= 0) {
            giveUp = true
        } else {
            val crafterId = queryForCrafter(recipe.jobType, 2.0)
            if (crafterId == -1) {
                ktoxSetLastCrafterFailure("Crafter turtle for job type \"${recipe.jobType}\" didn't answer.")
                giveUp = true
            } else if (!stageIngredients(recipe, chests.above, batches)) {
                giveUp = true
            } else {
                val expectedThisAttempt = batches * recipe.outputCount
                rednetSend(crafterId, "${recipe.outputName},${batches}", VAULT_CRAFTER_CMD_PROTOCOL)

                var lastCount = 0
                var secondsSinceProgress = 0
                var madeThisAttempt = 0
                var crafterFailure = ""
                while (secondsSinceProgress < timeoutSeconds && madeThisAttempt < expectedThisAttempt && crafterFailure == "") {
                    osSleep(1.0)
                    // Non-blocking (0s timeout) check for an explicit
                    // failure report, interleaved with the normal
                    // completion poll below.
                    val gotFailure = ktoxRednetReceiveProtocol(VAULT_CRAFTER_FAILURE_PROTOCOL, 0.0)
                    if (gotFailure) {
                        crafterFailure = ktoxRednetLastMessage()
                    } else {
                        val currentCount = ktoxInventoryCountNamed(chests.below, recipe.outputName)
                        madeThisAttempt = currentCount
                        if (currentCount > lastCount) {
                            secondsSinceProgress = 0
                            lastCount = currentCount
                        } else {
                            secondsSinceProgress += 1
                        }
                    }
                }

                if (crafterFailure != "") {
                    ktoxSetLastCrafterFailure(crafterFailure)
                } else if (madeThisAttempt < expectedThisAttempt) {
                    ktoxSetLastCrafterFailure("Crafter timed out - expected ${expectedThisAttempt}x ${recipe.outputName} in the chest below, only saw ${madeThisAttempt}.")
                }

                drainVaultInto(chests.below, leastFullStorageVaultName())
                totalProduced += madeThisAttempt
            }
        }
        attempt += 1
    }
    return totalProduced
}
