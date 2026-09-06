package lib

import lib.ceilDiv
import lib.findDirectConversion
import lib.jobTimeoutSeconds
import lib.runDirectJob
import lib.storagePoolCount

// Phase 2: the recursive planner (see PLAN.md — deferred behind phase 1
// on purpose, only attempted once everything else was solid). Chains
// multiple job levels when a *direct* recipe's own input isn't stocked
// either (raw log -> stripped log -> casing), which lib/Executor.kt's
// single-hop runDirectJob deliberately does not attempt.
//
// Design note: rather than building an explicit ordered job-list data
// structure (ktox has no working MutableList/growable collection to
// hold one — see AGENTS.md), this recurses into the missing INPUT
// first, then runs the current level's job — so jobs naturally execute
// in dependency order (deepest missing ingredient first) purely via
// normal call-stack unwinding. No job-list needed at all.
//
// MAX_PLANNER_DEPTH guards against a cyclic resource-tree config (A
// converts to B, B converts to A) — refuses to recurse past a small
// fixed limit rather than looping forever on a player config mistake.
const val MAX_PLANNER_DEPTH = 5

// Recursively ensures at least `desiredCount` of `itemName` exists in
// the storage pool, running as many chained conversions as needed.
// Returns the pool's actual count of itemName after this call (may be
// less than desiredCount if the chain bottomed out at an unstocked,
// non-convertible item, or hit MAX_PLANNER_DEPTH).
fun ensureStocked(itemName: String, desiredCount: Int, depth: Int): Int {
    val currentStock = storagePoolCount(itemName)
    if (currentStock >= desiredCount) {
        return currentStock
    }
    if (depth >= MAX_PLANNER_DEPTH) {
        return currentStock
    }

    val shortfall = desiredCount - currentStock
    val conversion = findDirectConversion(itemName)
    if (conversion == null) {
        return currentStock
    }

    val batchesNeeded = ceilDiv(shortfall, conversion.outputCount)
    val inputNeeded = batchesNeeded * conversion.inputCount
    // Recurse into the input FIRST — guarantees it exists (as far as the
    // chain can produce it) before this level's own job runs, so the
    // deepest missing ingredient always gets made before anything that
    // depends on it.
    ensureStocked(conversion.inputName, inputNeeded, depth + 1)

    val timeout = jobTimeoutSeconds(conversion.jobType)
    runDirectJob(conversion, shortfall, timeout)
    return storagePoolCount(itemName)
}
