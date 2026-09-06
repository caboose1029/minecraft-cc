package lib

import lib.ceilDiv
import lib.findRecipe
import lib.jobKind
import lib.jobTimeoutSeconds
import lib.recipeInputCount
import lib.recipeInputCountAt
import lib.recipeInputItem
import lib.runCrafterJob
import lib.runDirectJob
import lib.storagePoolCount

// Phase 2: the recursive planner (see PLAN.md — deferred behind phase 1
// on purpose, only attempted once everything else was solid). Chains
// multiple job levels when a recipe's own input isn't stocked either
// (raw copper -> copper ingot -> copper sheet), and now also handles
// recipes with more than one ingredient (brass: copper AND zinc) by
// recursing into every input, not just one.
//
// Design note: rather than building an explicit ordered job-list data
// structure (ktox has no working MutableList/growable collection to
// hold one — see AGENTS.md), this recurses into each missing input
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
    val recipe = findRecipe(itemName)
    if (recipe == null) {
        return currentStock
    }

    val batchesNeeded = ceilDiv(shortfall, recipe.outputCount)
    val inputCount = recipeInputCount(recipe)
    var i = 1
    while (i <= inputCount) {
        val inputItem = recipeInputItem(recipe, i)
        val perBatch = recipeInputCountAt(recipe, i)
        // Recurse into each input FIRST — guarantees they exist (as far
        // as the chain can produce them) before this level's own job
        // runs, so the deepest missing ingredient always gets made
        // before anything that depends on it.
        ensureStocked(inputItem, batchesNeeded * perBatch, depth + 1)
        i += 1
    }

    val timeout = jobTimeoutSeconds(recipe.jobType)
    if (jobKind(recipe.jobType) == "crafter") {
        runCrafterJob(recipe, shortfall, timeout)
    } else {
        runDirectJob(recipe, shortfall, timeout)
    }
    return storagePoolCount(itemName)
}
