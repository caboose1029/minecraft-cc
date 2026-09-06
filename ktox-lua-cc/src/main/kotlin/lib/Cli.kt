package lib

import common.ktoxConfigPickupVault
import common.ktoxConfigStorageVaultNames
import common.ktoxListCatalog
import lib.findDirectConversion
import lib.jobTimeoutSeconds
import lib.pullFromStoragePool
import lib.runDirectJob

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
    return "Unknown command: ${verb}. Try: list, pull, craft."
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

// Combined craft+pull, single-hop only — see PLAN.md. Pulls whatever's
// already stocked first, then for any shortfall, runs the one direct
// conversion that produces it (if any). Multi-hop chains (need sheets,
// only raw ore exists) are phase 2's planner, not this command — this
// just reports "not directly craftable" for those.
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

    val pulledFromStock = pullFromStoragePool(pickupVault, itemName, qty)
    val stillNeeded = qty - pulledFromStock
    if (stillNeeded <= 0) {
        return "Pulled ${pulledFromStock} of ${itemName} from stock (requested ${qty})."
    }

    val conversion = findDirectConversion(itemName)
    if (conversion == null) {
        return "Pulled ${pulledFromStock} of ${itemName} from stock; ${stillNeeded} more not directly craftable (requested ${qty})."
    }

    val timeout = jobTimeoutSeconds(conversion.jobType)
    val produced = runDirectJob(conversion, stillNeeded, timeout)
    if (produced <= 0) {
        return "Pulled ${pulledFromStock} of ${itemName} from stock; craft job produced none of the remaining ${stillNeeded} (requested ${qty})."
    }

    val pulledAfterCraft = pullFromStoragePool(pickupVault, itemName, produced)
    val totalPulled = pulledFromStock + pulledAfterCraft
    return "Pulled ${totalPulled} of ${itemName} total (${pulledFromStock} from stock, ${pulledAfterCraft} freshly crafted) - requested ${qty}."
}
