package lib

import common.ktoxConfigChestsFor
import common.ktoxConfigStorageVaultNames
import common.ktoxInventoryCountNamed
import common.ktoxInventoryDrainAll
import common.ktoxInventoryListPooled
import common.ktoxInventoryPullNamedFromPool
import common.turtleDropDown
import common.turtleGetItemCount
import common.turtleSelect
import common.turtleSuckUp

// Storage is treated as one logical resource pool spread across every
// vault whose config/peripherals.json job.type is "storage" — see
// PLAN.md. These wrappers hide the peripheral-name plumbing from
// callers, which only ever need to think in terms of item names/counts.

// How much of `itemName` currently exists across every storage vault.
fun storagePoolCount(itemName: String): Int {
    val vaultNames = ktoxConfigStorageVaultNames()
    if (vaultNames == "") {
        return 0
    }
    return ktoxInventoryCountNamed(vaultNames, itemName)
}

// Pulls up to `desired` of `itemName` out of the storage pool into
// `toName` (typically the terminal's own inventory). Returns how many
// were actually pulled - may be less than desired if the pool doesn't
// have enough.
fun pullFromStoragePool(toName: String, itemName: String, desired: Int): Int {
    val vaultNames = ktoxConfigStorageVaultNames()
    if (vaultNames == "") {
        return 0
    }
    return ktoxInventoryPullNamedFromPool(toName, vaultNames, itemName, desired)
}

// Raw "name,count" lines (one per distinct item across the whole pool,
// see ktoxInventoryListPooled), still unparsed - the `list` CLI command
// splits each line itself. Not modeled as a richer Kotlin collection of
// records here: ktox's MutableList has no real runtime backing (see
// AGENTS.md), so a plain List<String> from split(), indexed manually, is
// the idiomatic way to walk a variable number of results in this
// codebase (same pattern as lib/Position.kt's gpsLocate parsing).
//
// Note: an empty pool comes back as a one-element list containing a
// single empty string (split("\n") on "" yields [""], not []) - callers
// must skip a blank line rather than assume a non-empty result means a
// real item.
fun listStoragePoolLines(): List<String> {
    val raw = ktoxInventoryListPooled(ktoxConfigStorageVaultNames())
    return raw.split("\n")
}

// The peripheral name of the first configured storage vault - used as
// "some real vault in the pool" when a caller needs a concrete
// destination (draining a crafter's chests back into the pool) rather
// than a name filter across all of them. Which ONE doesn't matter, since
// every storage vault is treated as the same logical pool. "MISSING" if
// none are configured.
fun firstStorageVaultName(): String {
    val vaultNames = ktoxConfigStorageVaultNames()
    if (vaultNames == "") {
        return "MISSING"
    }
    return vaultNames.split(",")[1]
}

data class Chests(val above: String, val below: String)

// The chest-above/chest-below peripheral names dedicated to
// `peripheralName` (see PLAN.md "Crafter role" - a physical
// chest-in-chest-out flow, not a network push into the turtle, which is
// confirmed not to work). Shared by the crafter and by a turtle-based
// pickup terminal's self-suckUp/self-deposit path below - same schema
// either way. null if either isn't configured on that entry's own
// peripherals.json entry (job.aboveChest / job.belowChest).
fun chestsFor(peripheralName: String): Chests? {
    val raw = ktoxConfigChestsFor(peripheralName)
    if (raw == "MISSING") {
        return null
    }
    val parts = raw.split(",")
    return Chests(parts[1], parts[2])
}

// Moves everything out of `fromName` into `toName`, regardless of item
// identity - for proactively draining a crafter's staging/output chest
// before a new job (clearing stale leftovers) or collecting a finished
// craft result. Both ends are ordinary vault peripherals here, never a
// turtle.
fun drainVaultInto(fromName: String, toName: String): Int {
    return ktoxInventoryDrainAll(fromName, toName)
}

// Delivers up to `desired` of `itemName` into THIS terminal's own
// inventory via physical turtle.suckUp() calls - the self-pickup
// counterpart to the crafter's physical ingredient delivery (see
// programs/Crafter.kt's gatherInto/dumpAllDown), for a turtle-based
// pickup terminal (e.g. turtle_0) receiving its own `pull`/`craft`
// results. Never a network pullItems/pushItems call targeting the
// turtle itself - confirmed live that doesn't work in either direction
// (see PLAN.md's "Turtle-as-network-inventory-peripheral"). `aboveChest`
// is staged with the exact needed amount first via an ordinary
// vault-to-vault pull (safe - never targets the turtle over the
// network), then sucked up one turtle inventory slot at a time (a
// single slot caps at that item's stack size, so a large `desired`
// needs several). Returns how many actually ended up in the turtle's
// own inventory - may be less than `desired` if the pool came up short
// or suckUp stops making progress.
fun deliverViaSelfSuckUp(aboveChest: String, itemName: String, desired: Int): Int {
    val staged = pullFromStoragePool(aboveChest, itemName, desired)
    if (staged <= 0) {
        return 0
    }
    var remaining = staged
    var slot = 1
    while (slot <= 16 && remaining > 0) {
        if (turtleGetItemCount(slot) == 0) {
            turtleSelect(slot)
            turtleSuckUp(remaining)
            val gathered = turtleGetItemCount(slot)
            remaining -= gathered
            if (gathered == 0) {
                return staged - remaining
            }
        }
        slot += 1
    }
    return staged - remaining
}

// Drops everything currently in THIS terminal's own inventory into
// `belowChest` (turtle.dropDown(), one slot at a time - the deposit
// counterpart to deliverViaSelfSuckUp, and physically identical to the
// crafter's dumpAllDown), then drains that chest into the storage pool
// via an ordinary vault-to-vault transfer. Never drained BEFORE
// dropping - any stray items left over from an earlier partial deposit
// get swept up along with this one, which is a feature, not a bug.
// Returns how many total items ended up back in the pool (this
// deposit's items plus any recovered strays). 0 if no storage vault is
// configured at all.
fun depositSelfInventory(belowChest: String): Int {
    var slot = 1
    while (slot <= 16) {
        turtleSelect(slot)
        if (turtleGetItemCount(slot) > 0) {
            turtleDropDown(64)
        }
        slot += 1
    }
    val storageVault = firstStorageVaultName()
    if (storageVault == "MISSING") {
        return 0
    }
    return drainVaultInto(belowChest, storageVault)
}
