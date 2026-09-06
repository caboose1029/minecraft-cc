package programs

import common.ktoxConfigFeederForJob
import common.ktoxConfigRelayForJob
import common.ktoxConfigStorageVaultNames
import lib.findDirectConversion
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

    val conversion = findDirectConversion("create:copper_sheet")
    if (conversion == null) {
        println("Direct conversion for create:copper_sheet: none configured")
    } else {
        println("Direct conversion for create:copper_sheet: ${conversion.inputCount}x ${conversion.inputName} via ${conversion.jobType} -> ${conversion.outputCount}x output")
    }

    println("Storage pool count of minecraft:copper_ingot: ${storagePoolCount("minecraft:copper_ingot")}")

    val powered = setJobPower("smelter", true)
    println("setJobPower(smelter, true) reached a relay: ${powered}")
}
