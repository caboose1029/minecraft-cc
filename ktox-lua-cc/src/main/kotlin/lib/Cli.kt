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
const val PULL_USAGE = "Usage: pull <name> <qty> (--location=<name>) (-h)\n  Pulls <qty> of <name> from the storage pool into a pickup location. --location=<name> targets a specific named one; without it, this terminal's own inventory if it's itself configured as a pickup location, otherwise whichever pickup location is marked \"default\" in config/peripherals.json."
const val CRAFT_USAGE = "Usage: craft <name> <qty> (--location=<name>) (--fetch=false) (-h)\n  Crafts <qty> of <name>, chaining through intermediate jobs as needed, then pulls the result into a pickup location. Defaults to this terminal's own inventory if it's itself configured as a pickup location, otherwise the config/peripherals.json default; pass --location=<name> to target a specific named pickup location instead. Pass --fetch=false to craft without pulling the result out at all (leaves it in the storage pool)."
const val TRASH_USAGE = "Usage: trash <name> <qty> (-h)\n  Permanently destroys <qty> of <name> from the storage pool via the trash vault (dumped into lava)."

// The CC terminal has no scrollback a player can page through, so `list`
// caps its output rather than dumping the whole pool - see runListCommand.
const val LIST_DISPLAY_LIMIT = 6

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

// Shared trailing-flag parsing for pull/craft, scanning parts[startIndex..]
// for "--location=<name>"/"--fetch=false". Split on "=" rather than a
// substring/startsWith check - ktox has no established-safe prefix-check
// idiom in this codebase, but .split() is already proven throughout this
// file. Flags can appear in either order, or not at all.
fun parseLocationFlag(parts: List<String>, startIndex: Int): String {
    var idx = startIndex
    while (idx <= parts.size) {
        val flagParts = parts[idx].split("=")
        if (flagParts[1] == "--location" && flagParts.size >= 2) {
            return flagParts[2]
        }
        idx += 1
    }
    return ""
}

fun parseFetchFlag(parts: List<String>, startIndex: Int): Boolean {
    var idx = startIndex
    while (idx <= parts.size) {
        val flagParts = parts[idx].split("=")
        if (flagParts[1] == "--fetch" && flagParts.size >= 2 && flagParts[2] == "false") {
            return false
        }
        idx += 1
    }
    return true
}

// "No pickup vault"/"no location named X" - the shared failure message
// for pull/craft when resolvePickupLocation comes back "MISSING".
fun noPickupLocationMessage(explicitLocation: String): String {
    if (explicitLocation != "") {
        return "No pickup location named \"${explicitLocation}\" is configured (\"name\" under a job.type \"pickup\" entry in config/peripherals.json)."
    }
    return "No pickup vault configured (job.type \"pickup\" in config/peripherals.json)."
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

    // The CC terminal screen isn't scrollable, so a long unfiltered list
    // just runs off the top with no way back - only the tail end is ever
    // actually readable anyway. Show that tail deterministically instead
    // of whatever happens to survive terminal scroll, and say how much
    // got cut so it's not mistaken for the whole pool.
    val rows = raw.split("\n")
    var startIndex = 1
    if (rows.size > LIST_DISPLAY_LIMIT) {
        startIndex = rows.size - LIST_DISPLAY_LIMIT + 1
    }
    var output = ""
    if (startIndex > 1) {
        output = "(showing last ${LIST_DISPLAY_LIMIT} of ${rows.size} - narrow with a status flag or item-name filter)\n"
    }
    var i = startIndex
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

    val location = parseLocationFlag(parts, 4)
    val pickupVault = resolvePickupLocation(location)
    if (pickupVault == "MISSING") {
        return noPickupLocationMessage(location)
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

    val fetch = parseFetchFlag(parts, 4)
    val location = parseLocationFlag(parts, 4)

    var pickupVault = ""
    if (fetch) {
        pickupVault = resolvePickupLocation(location)
        if (pickupVault == "MISSING") {
            return noPickupLocationMessage(location)
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
