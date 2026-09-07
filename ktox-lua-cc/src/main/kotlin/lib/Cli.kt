package lib

import common.ktoxConfigPickupVaultByName
import common.ktoxConfigPickupVaultDefault
import common.ktoxConfigStorageVaultNames
import common.ktoxConfigTrashVault
import common.ktoxIsConfiguredPickupLocation
import common.ktoxListCatalog
import common.ktoxSelfPeripheralName
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

// Literal square brackets in a Kotlin string transpile to invalid Lua
// (ktox emits "\[" / "\]", not valid Lua escape sequences - confirmed via
// CraftOS-PC: "invalid escape sequence near '\['"). Use parens for
// optional-arg notation instead, never brackets, anywhere in this file.
const val LIST_USAGE = "Usage: list (--stocked|--craftable|--unavailable) (item-name-filter) (-h)\n  Lists items in the storage pool. Optional status flag narrows to one status; optional trailing text filters to item names containing that substring (e.g. \"list --stocked iron\")."
const val PULL_USAGE = "Usage: pull <name> <qty> (-h)\n  Pulls <qty> of <name> from the storage pool into a pickup location - this terminal's own inventory if it's itself configured as a pickup location, otherwise whichever pickup location is marked \"default\" in config/peripherals.json."
const val CRAFT_USAGE = "Usage: craft <name> <qty> (--location=<name>) (--fetch=false) (-h)\n  Crafts <qty> of <name>, chaining through intermediate jobs as needed, then pulls the result into a pickup location. Defaults to this terminal's own inventory if it's itself configured as a pickup location, otherwise the config/peripherals.json default; pass --location=<name> to target a specific named pickup location instead. Pass --fetch=false to craft without pulling the result out at all (leaves it in the storage pool)."
const val TRASH_USAGE = "Usage: trash <name> <qty> (-h)\n  Permanently destroys <qty> of <name> from the storage pool via the trash vault (dumped into lava)."

fun isHelpFlag(parts: List<String>): Boolean {
    return parts.size >= 2 && (parts[2] == "-h" || parts[2] == "--help")
}

// Resolves which pickup-type vault to deliver results into. If
// explicitLocation is non-empty, looks it up by its peripherals.json
// "name" label ("MISSING" if no pickup vault carries that label).
// Otherwise: prefer this terminal's own inventory if it's itself
// configured as a pickup location (see PLAN.md's "Vaults" section -
// turtles can be pickup locations, including a head/secondary terminal's
// own), falling back to whichever pickup vault is marked "default" in
// peripherals.json. "MISSING" if nothing resolves either way.
fun resolvePickupLocation(explicitLocation: String): String {
    if (explicitLocation != "") {
        return ktoxConfigPickupVaultByName(explicitLocation)
    }
    val selfName = ktoxSelfPeripheralName()
    if (selfName != "MISSING" && ktoxIsConfiguredPickupLocation(selfName)) {
        return selfName
    }
    return ktoxConfigPickupVaultDefault()
}

fun runListCommand(parts: List<String>): String {
    if (isHelpFlag(parts)) {
        return LIST_USAGE
    }
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
    if (isHelpFlag(parts)) {
        return PULL_USAGE
    }
    if (parts.size < 3) {
        return PULL_USAGE
    }
    val itemName = parts[2]
    val qtyRaw = parts[3].toDoubleOrNull()
    if (qtyRaw == null) {
        return "${PULL_USAGE}\n\"${parts[3]}\" isn't a number."
    }
    val qty = qtyRaw.toInt()

    val pickupVault = resolvePickupLocation("")
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
    if (isHelpFlag(parts)) {
        return CRAFT_USAGE
    }
    if (parts.size < 3) {
        return CRAFT_USAGE
    }
    val itemName = parts[2]
    val qtyRaw = parts[3].toDoubleOrNull()
    if (qtyRaw == null) {
        return "${CRAFT_USAGE}\n\"${parts[3]}\" isn't a number."
    }
    val qty = qtyRaw.toInt()

    // Flags can appear in either order at positions 4+ (e.g. both
    // "--location=x --fetch=false" and "--fetch=false --location=x").
    // Split on "=" rather than a substring/startsWith check - ktox has
    // no established-safe prefix-check idiom in this codebase, but
    // .split() is already proven throughout this file.
    var fetch = true
    var location = ""
    var flagIndex = 4
    while (flagIndex <= parts.size) {
        val flagParts = parts[flagIndex].split("=")
        val flagName = flagParts[1]
        if (flagName == "--fetch") {
            if (flagParts.size >= 2 && flagParts[2] == "false") {
                fetch = false
            }
        } else if (flagName == "--location") {
            if (flagParts.size >= 2) {
                location = flagParts[2]
            }
        }
        flagIndex += 1
    }

    var pickupVault = ""
    if (fetch) {
        pickupVault = resolvePickupLocation(location)
        if (pickupVault == "MISSING") {
            if (location != "") {
                return "No pickup location named \"${location}\" is configured (\"name\" under a job.type \"pickup\" entry in config/peripherals.json)."
            }
            return "No pickup vault configured (job.type \"pickup\" in config/peripherals.json)."
        }
    }

    ensureStocked(itemName, qty, 0)

    if (!fetch) {
        return "Crafted ${itemName} up to ${qty} (left in the storage pool; --fetch=false)."
    }

    val pulled = pullFromStoragePool(pickupVault, itemName, qty)
    return "Pulled ${pulled} of ${itemName} (requested ${qty})."
}

// Permanently destroys items from the storage pool via the trash vault
// (job.type "trash", dumps into lava — see PLAN.md). Deliberately its
// own explicit command, never something another command routes to
// automatically.
fun runTrashCommand(parts: List<String>): String {
    if (isHelpFlag(parts)) {
        return TRASH_USAGE
    }
    if (parts.size < 3) {
        return TRASH_USAGE
    }
    val itemName = parts[2]
    val qtyRaw = parts[3].toDoubleOrNull()
    if (qtyRaw == null) {
        return "${TRASH_USAGE}\n\"${parts[3]}\" isn't a number."
    }
    val qty = qtyRaw.toInt()

    val trashVault = ktoxConfigTrashVault()
    if (trashVault == "MISSING") {
        return "No trash vault configured (job.type \"trash\" in config/peripherals.json)."
    }

    val trashed = pullFromStoragePool(trashVault, itemName, qty)
    return "Destroyed ${trashed} of ${itemName} (requested ${qty})."
}
