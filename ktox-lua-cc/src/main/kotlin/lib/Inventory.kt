package lib

import common.ktoxConfigCrafterChests
import common.ktoxConfigStorageVaultNames
import common.ktoxInventoryCountNamed
import common.ktoxInventoryDrainAll
import common.ktoxInventoryListPooled
import common.ktoxInventoryPullNamedFromPool
import common.ktoxInventoryPushNamedFromPool

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

// Same as pullFromStoragePool, but SOURCE-initiated (a storage vault
// calls pushItems into `toName`) instead of destination-initiated (the
// pull* functions above, where `toName` calls pullItems on itself).
// Needed when `toName` is a turtle: wrapping a turtle as a peripheral
// only exposes generic remote-control methods (confirmed live - no
// pullItems at all), so a turtle can never do the pulling itself. This
// has the SOURCE vault push instead, hoping the turtle is still a valid
// routing target by name even though it can't act as one - STILL
// UNVERIFIED, and the equivalent hypothesis for crafter ingredient
// delivery (pushToStoragePoolTargetSlot, since removed) did NOT pan out
// in practice - runCrafterJob now uses a physical turtle.suckUp()
// instead (see lib/Executor.kt / programs/Crafter.kt). This function
// (used only by lib/Cli.kt's deliverToPickupLocation, for a turtle-based
// pickup location like turtle_0 receiving its own results) has NOT been
// switched to that same physical pattern yet - flagged in PLAN.md's
// Known Open Items as very likely broken for the same reason, not yet
// confirmed or fixed.
fun pushToStoragePoolTarget(toName: String, itemName: String, desired: Int): Int {
    val vaultNames = ktoxConfigStorageVaultNames()
    if (vaultNames == "") {
        return 0
    }
    return ktoxInventoryPushNamedFromPool(vaultNames, toName, itemName, desired)
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

data class CrafterChests(val above: String, val below: String)

// The chest-above/chest-below peripheral names dedicated to `crafterName`
// (see PLAN.md "Crafter role" - a physical chest-in-chest-out flow, not
// a network push into the turtle, which is confirmed not to work). null
// if either isn't configured on that crafter's own peripherals.json
// entry (job.aboveChest / job.belowChest).
fun crafterChestsFor(crafterName: String): CrafterChests? {
    val raw = ktoxConfigCrafterChests(crafterName)
    if (raw == "MISSING") {
        return null
    }
    val parts = raw.split(",")
    return CrafterChests(parts[1], parts[2])
}

// Moves everything out of `fromName` into `toName`, regardless of item
// identity - for proactively draining a crafter's staging/output chest
// before a new job (clearing stale leftovers) or collecting a finished
// craft result. Both ends are ordinary vault peripherals here, never a
// turtle.
fun drainVaultInto(fromName: String, toName: String): Int {
    return ktoxInventoryDrainAll(fromName, toName)
}
