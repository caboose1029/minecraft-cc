package lib

import common.ktoxConfigJobKind
import common.ktoxConfigProducesLookup

// A resource-tree.json recipe. `inputsRaw` is intentionally NOT parsed
// into a list of records here — ktox has no working MutableList/growable
// collection (see AGENTS.md) to hold a variable number of parsed inputs,
// so it stays as the packed "item,count,slot;item,count,slot" string and
// is re-split per access via the recipeInput*() helpers below. A bit
// more re-parsing than a real object list would need, but recipes have
// at most a handful of ingredients and this isn't a hot loop. Comma
// (not colon) separates the fields within one input — an item ID's own
// namespace separator IS a colon ("minecraft:copper_ingot"), which broke
// this immediately the first time it was colon-delimited (confirmed
// live via CraftOS-PC).
data class Recipe(
    val outputName: String,
    val outputCount: Int,
    val jobType: String,
    val inputsRaw: String,
)

// The single recipe that produces `outputName`, from
// config/resource-tree.json. null if none exists.
fun findRecipe(outputName: String): Recipe? {
    val raw = ktoxConfigProducesLookup(outputName)
    if (raw == "MISSING") {
        return null
    }
    // ktox does NOT offset List indexing from Kotlin's 0-based convention
    // to Lua's 1-based tables - parts[1] is the first element. See
    // AGENTS.md and lib/Position.kt for the same idiom.
    val parts = raw.split("|")
    return Recipe(
        outputName,
        parts[2].toDouble().toInt(),
        parts[1],
        parts[3],
    )
}

fun recipeInputCount(recipe: Recipe): Int {
    return recipe.inputsRaw.split(";").size
}

// 1-indexed, matching every other list access in this codebase.
fun recipeInputItem(recipe: Recipe, index: Int): String {
    val entry = recipe.inputsRaw.split(";")[index]
    return entry.split(",")[1]
}

fun recipeInputCountAt(recipe: Recipe, index: Int): Int {
    val entry = recipe.inputsRaw.split(";")[index]
    return entry.split(",")[2].toDouble().toInt()
}

// The turtle crafting-grid slot (1-9) this ingredient belongs in, for a
// crafter-kind recipe — or -1 if this recipe has no slot info (an
// ordinary machine recipe, where placement doesn't matter).
fun recipeInputSlot(recipe: Recipe, index: Int): Int {
    val entry = recipe.inputsRaw.split(";")[index]
    val slotStr = entry.split(",")[3]
    if (slotStr == "") {
        return -1
    }
    return slotStr.toDouble().toInt()
}

// "machine" (redstone relay + feeder vault) or "crafter" (turtle.craft) —
// see PLAN.md. Defaults to "machine" when config/job-types.json doesn't
// specify one.
fun jobKind(jobType: String): String {
    return ktoxConfigJobKind(jobType)
}
