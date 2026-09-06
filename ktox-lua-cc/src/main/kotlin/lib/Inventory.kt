package lib

import common.ktoxConfigStorageVaultNames
import common.ktoxInventoryCountNamed
import common.ktoxInventoryListPooled
import common.ktoxInventoryPullNamedFromPool

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
