package lib

import common.ktoxConfigStorageVaultNames
import common.ktoxInventoryCountNamed
import common.ktoxInventoryListPooled
import common.ktoxInventoryPullNamedFromPool
import common.ktoxInventoryPullNamedToSlotFromPool
import common.ktoxInventoryPushNamedFromPool
import common.ktoxInventoryPushNamedToSlotFromPool

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

// Same as pullFromStoragePool, but lands the items in a specific slot of
// `toName` — needed for a crafter turtle's crafting grid, where
// placement matters (see PLAN.md "Crafter role").
fun pullFromStoragePoolToSlot(toName: String, toSlot: Int, itemName: String, desired: Int): Int {
    val vaultNames = ktoxConfigStorageVaultNames()
    if (vaultNames == "") {
        return 0
    }
    return ktoxInventoryPullNamedToSlotFromPool(toName, toSlot, vaultNames, itemName, desired)
}

// Same as pullFromStoragePool, but SOURCE-initiated (a storage vault
// calls pushItems into `toName`) instead of destination-initiated (the
// pull* functions above, where `toName` calls pullItems on itself).
// Needed when `toName` is a turtle: wrapping a turtle as a peripheral
// only exposes generic remote-control methods (confirmed live - no
// pullItems at all), so a turtle can never do the pulling itself, but
// should still be a valid routing target for an ordinary vault's own
// push. UNVERIFIED - working hypothesis, not yet confirmed against a
// real turtle. See PLAN.md's "Known open items".
fun pushToStoragePoolTarget(toName: String, itemName: String, desired: Int): Int {
    val vaultNames = ktoxConfigStorageVaultNames()
    if (vaultNames == "") {
        return 0
    }
    return ktoxInventoryPushNamedFromPool(vaultNames, toName, itemName, desired)
}

// Same as pushToStoragePoolTarget, but lands the items in a specific
// slot of `toName` — needed for a crafter turtle's crafting grid.
fun pushToStoragePoolTargetSlot(toName: String, toSlot: Int, itemName: String, desired: Int): Int {
    val vaultNames = ktoxConfigStorageVaultNames()
    if (vaultNames == "") {
        return 0
    }
    return ktoxInventoryPushNamedToSlotFromPool(vaultNames, toName, toSlot, itemName, desired)
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
