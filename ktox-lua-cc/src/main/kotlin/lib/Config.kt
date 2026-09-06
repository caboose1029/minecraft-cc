package lib

import common.ktoxConfigProducesLookup

data class DirectConversion(
    val inputName: String,
    val jobType: String,
    val inputCount: Int,
    val outputCount: Int,
)

// The single direct (one-hop) recipe that produces `outputName`, from
// config/resource-tree.json. null if none exists — multi-hop chains
// (needing an intermediate that's itself not stocked) are phase 2's
// planner, not this lookup. See PLAN.md.
fun findDirectConversion(outputName: String): DirectConversion? {
    val raw = ktoxConfigProducesLookup(outputName)
    if (raw == "MISSING") {
        return null
    }
    // ktox does NOT offset List indexing from Kotlin's 0-based convention
    // to Lua's 1-based tables - parts[1] is the first element. See
    // AGENTS.md and lib/Position.kt for the same idiom.
    val parts = raw.split(",")
    return DirectConversion(
        parts[1],
        parts[2],
        parts[3].toDouble().toInt(),
        parts[4].toDouble().toInt(),
    )
}
