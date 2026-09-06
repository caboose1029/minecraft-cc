package lib

import common.ktoxConfigPickupVault
import common.ktoxConfigStorageVaultNames
import common.ktoxConfigTrashVault
import common.ktoxListCatalog
import lib.ensureStocked
import lib.pullFromStoragePool

// Shared command dispatcher for both a terminal's own local input and
// rednet-forwarded input from a secondary terminal (see PLAN.md — same
// parsing/execution either way, so the head is the only thing that ever
// decides anything). Returns the full response as one (possibly
// multi-line) string to print or send back.
fun runCliCommand(commandLine: String): String {
    if (commandLine == "") {
        return "Empty command. Try: list, pull, craft."
    }
    val parts = commandLine.split(" ")
    val verb = parts[1]
    if (verb == "list") {
        return runListCommand(parts)
    }
    if (verb == "pull") {
        return runPullCommand(parts)
    }
    if (verb == "craft") {
        return runCraftCommand(parts)
    }
    if (verb == "trash") {
        return runTrashCommand(parts)
    }
    return "Unknown command: ${verb}. Try: list, pull, craft, trash."
}

fun runListCommand(parts: List<String>): String {
    var filter = ""
    var substring = ""
    var nextIndex = 2
    if (parts.size >= 2) {
        val maybeFlag = parts[2]
        if (maybeFlag == "--stocked") {
            filter = "stocked"
            nextIndex = 3
        } else if (maybeFlag == "--craftable") {
            filter = "craftable"
            nextIndex = 3
        } else if (maybeFlag == "--unavailable") {
            filter = "unavailable"
            nextIndex = 3
        }
    }
    if (parts.size >= nextIndex) {
        substring = parts[nextIndex]
    }

    val raw = ktoxListCatalog(ktoxConfigStorageVaultNames(), filter, substring)
    if (raw == "") {
        return "No items found."
    }

    val rows = raw.split("\n")
    var output = ""
    var i = 1
    while (i <= rows.size) {
        val cols = rows[i].split(",")
        val status = cols[1]
        val name = cols[2]
        val count = cols[3]
        if (status == "stocked") {
            output = "${output}${name}: ${count} in stock\n"
        } else if (status == "craftable") {
            output = "${output}${name}: craftable\n"
        } else {
            output = "${output}${name}: unavailable\n"
        }
        i += 1
    }
    return output
}

fun runPullCommand(parts: List<String>): String {
    if (parts.size < 3) {
        return "Usage: pull <name> <qty>"
    }
    val itemName = parts[2]
    val qty = parts[3].toDouble().toInt()

    val pickupVault = ktoxConfigPickupVault()
    if (pickupVault == "MISSING") {
        return "No pickup vault configured (job.type \"pickup\" in config/peripherals.json)."
    }

    val pulled = pullFromStoragePool(pickupVault, itemName, qty)
    return "Pulled ${pulled} of ${itemName} into the pickup vault (requested ${qty})."
}

// Combined craft+pull, chained (see PLAN.md's phase-2 planner —
// lib/Planner.kt's ensureStocked recurses through as many conversion
// levels as needed, e.g. raw log -> stripped log -> casing, not just a
// single direct recipe). Pulls whatever ends up available after that,
// up to the requested quantity.
fun runCraftCommand(parts: List<String>): String {
    if (parts.size < 3) {
        return "Usage: craft <name> <qty>"
    }
    val itemName = parts[2]
    val qty = parts[3].toDouble().toInt()

    val pickupVault = ktoxConfigPickupVault()
    if (pickupVault == "MISSING") {
        return "No pickup vault configured (job.type \"pickup\" in config/peripherals.json)."
    }

    ensureStocked(itemName, qty, 0)
    val pulled = pullFromStoragePool(pickupVault, itemName, qty)
    return "Pulled ${pulled} of ${itemName} (requested ${qty})."
}

// Permanently destroys items from the storage pool via the trash vault
// (job.type "trash", dumps into lava — see PLAN.md). Deliberately its
// own explicit command, never something another command routes to
// automatically.
fun runTrashCommand(parts: List<String>): String {
    if (parts.size < 3) {
        return "Usage: trash <name> <qty>"
    }
    val itemName = parts[2]
    val qty = parts[3].toDouble().toInt()

    val trashVault = ktoxConfigTrashVault()
    if (trashVault == "MISSING") {
        return "No trash vault configured (job.type \"trash\" in config/peripherals.json)."
    }

    val trashed = pullFromStoragePool(trashVault, itemName, qty)
    return "Destroyed ${trashed} of ${itemName} (requested ${qty})."
}
