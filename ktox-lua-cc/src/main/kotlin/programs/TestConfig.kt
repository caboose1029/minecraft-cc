package programs

import common.ktoxConfigFeederForJob
import common.ktoxConfigRelayForJob
import common.ktoxConfigStorageVaultNames
import lib.findRecipe
import lib.jobKind
import lib.manageFarms
import lib.topUpPassiveFeeders
import lib.recipeInputCount
import lib.recipeInputCountAt
import lib.recipeInputItem
import lib.recipeInputSlot
import lib.runCliCommand
import lib.setJobPower
import lib.storagePoolCount

// Diagnostic for config/peripherals.json and config/resource-tree.json —
// prints what the loaders actually found, so a player authoring those
// files by hand can confirm they parsed correctly without needing the
// full CLI built yet. See PLAN.md for the schemas.
//
// Usage: testconfig (no args)

fun main() {
    println("Storage vault names: ${ktoxConfigStorageVaultNames()}")

    val feeder = ktoxConfigFeederForJob("mechanical_press_depot")
    if (feeder == "MISSING") {
        println("Feeder for mechanical_press_depot: none configured")
    } else {
        println("Feeder for mechanical_press_depot: ${feeder}")
    }

    val relay = ktoxConfigRelayForJob("smelter")
    if (relay == "MISSING") {
        println("Relay for smelter: none configured")
    } else {
        println("Relay for smelter: ${relay}")
    }

    val recipe = findRecipe("create:copper_sheet")
    if (recipe == null) {
        println("Recipe for create:copper_sheet: none configured")
    } else {
        val count = recipeInputCount(recipe)
        println("Recipe for create:copper_sheet: ${count} input(s) via ${recipe.jobType} -> ${recipe.outputCount}x output")
        var i = 1
        while (i <= count) {
            println("  input ${i}: ${recipeInputCountAt(recipe, i)}x ${recipeInputItem(recipe, i)} (slot ${recipeInputSlot(recipe, i)})")
            i += 1
        }
    }

    val brass = findRecipe("create:brass_ingot")
    if (brass == null) {
        println("Recipe for create:brass_ingot: none configured")
    } else {
        val count = recipeInputCount(brass)
        println("Recipe for create:brass_ingot: ${count} input(s) via ${brass.jobType} -> ${brass.outputCount}x output")
        var i = 1
        while (i <= count) {
            println("  input ${i}: ${recipeInputCountAt(brass, i)}x ${recipeInputItem(brass, i)}")
            i += 1
        }
    }

    println("Storage pool count of minecraft:copper_ingot: ${storagePoolCount("minecraft:copper_ingot")}")

    val powered = setJobPower("smelter", true)
    println("setJobPower(smelter, true) reached a relay: ${powered}")

    println("--- list ---")
    println(runCliCommand("list"))
    println("--- list --unavailable ---")
    println(runCliCommand("list --unavailable"))
    println("--- pull with no pickup vault configured ---")
    println(runCliCommand("pull minecraft:copper_ingot 5"))
    println("--- craft (no stock, no input available - should not hang) ---")
    println(runCliCommand("craft create:copper_sheet 5"))
    println("--- craft brass (2-ingredient recipe, no stock - should not hang) ---")
    println(runCliCommand("craft create:brass_ingot 5"))
    println("--- trash ---")
    println(runCliCommand("trash minecraft:cobblestone 64"))

    val chestRecipe = findRecipe("minecraft:chest")
    if (chestRecipe == null) {
        println("Recipe for minecraft:chest: none configured")
    } else {
        val count = recipeInputCount(chestRecipe)
        println("Recipe for minecraft:chest: ${count} input(s) via ${chestRecipe.jobType}")
        if (chestRecipe.jobType != "chest_crafter") {
            println("MISMATCH: expected job \"chest_crafter\", got \"${chestRecipe.jobType}\" - this recipe won't find its crafter turtle!")
        }
        var i = 1
        while (i <= count) {
            println("  input ${i}: ${recipeInputCountAt(chestRecipe, i)}x ${recipeInputItem(chestRecipe, i)} -> slot ${recipeInputSlot(chestRecipe, i)}")
            i += 1
        }
    }
    println("Job kind for chest_crafter: ${jobKind("chest_crafter")}")
    println("Job kind for smelter: ${jobKind("smelter")}")
    println("--- craft chest (crafter-kind job, no modem - should not hang) ---")
    println(runCliCommand("craft minecraft:chest 1"))

    println("--- topUpPassiveFeeders (no real peripherals - should not crash) ---")
    topUpPassiveFeeders()
    println("done")

    println("--- manageFarms (no real peripherals - should not crash) ---")
    manageFarms()
    println("done")

    println("--- craft dried kelp block (9:1 compacting chain, no stock - should not hang) ---")
    println(runCliCommand("craft minecraft:dried_kelp_block 1"))
    println("--- craft lava bucket (fluid-adjacent, no stock - should not hang) ---")
    println(runCliCommand("craft minecraft:lava_bucket 1"))
}
