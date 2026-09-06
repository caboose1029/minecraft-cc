package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Generic peripheral dispatch — see ktox-cc-shim.lua's ktoxPeripheralCall
// and PLAN.md ("Generic peripheral-call shim") for why this exists.
// argsPacked is "<tag>:<value>" pairs joined by "|" (tag: S/B/N for
// string/boolean/number — e.g. "S:right|B:true"), pass "" for no
// arguments. NOT JSON array syntax: a Kotlin string literal containing
// `[`/`]` transpiles to invalid Lua (confirmed ktox bug, see AGENTS.md),
// so call sites must never build "[...]" text. The result is JSON-
// encoded, or the sentinel "MISSING" (peripheral/method not found) or
// "null" (call returned nothing).
//
// These sentinels are compared against as literal Kotlin strings at each
// call site ("MISSING"/"null"), not shared `const val`s — a top-level
// const defined in a `common/` file is never a real Lua global unless
// that file is `dofile`'d, which common/*.lua files aren't (by design,
// see AGENTS.md: they're native-binding declarations that normally
// generate no code at all). Confirmed live: with a shared const here, a
// missing-peripheral comparison silently compared against Lua `nil`
// instead of the string "MISSING" and reported success for a peripheral
// that was never found.

@NativeName("ktoxPeripheralCall")
fun ktoxPeripheralCallRaw(peripheralName: String, methodName: String, argsPacked: String): String = externalSource()

// Config loaders (ktox-cc-shim.lua) — see PLAN.md for the config schemas.
// These return the sentinel above when nothing matches, since ktox
// natives can't express a nullable String round-trip reliably untested;
// see lib/Config.kt for the idiomatic wrapper.

@NativeName("ktoxConfigStorageVaultNames")
fun ktoxConfigStorageVaultNames(): String = externalSource()

@NativeName("ktoxConfigFeederForJob")
fun ktoxConfigFeederForJob(jobType: String): String = externalSource()

@NativeName("ktoxConfigRelayForJob")
fun ktoxConfigRelayForJob(jobType: String): String = externalSource()

@NativeName("ktoxConfigProducesLookup")
fun ktoxConfigProducesLookup(outputName: String): String = externalSource()

@NativeName("ktoxConfigPickupVault")
fun ktoxConfigPickupVault(): String = externalSource()

@NativeName("ktoxConfigTrashVault")
fun ktoxConfigTrashVault(): String = externalSource()

@NativeName("ktoxListCatalog")
fun ktoxListCatalog(sourceNamesCsv: String, filter: String, substring: String): String = externalSource()

@NativeName("ktoxConfigJobTimeoutSeconds")
fun ktoxConfigJobTimeoutSecondsRaw(jobType: String): Int = externalSource()

@NativeName("ktoxConfigJobKind")
fun ktoxConfigJobKind(jobType: String): String = externalSource()

@NativeName("ktoxInventoryIsEmpty")
fun ktoxInventoryIsEmpty(vaultName: String): Boolean = externalSource()

// Inventory helpers (ktox-cc-shim.lua) — see lib/Inventory.kt for the
// idiomatic wrapper.

@NativeName("ktoxInventoryCountNamed")
fun ktoxInventoryCountNamed(sourceNamesCsv: String, itemName: String): Int = externalSource()

@NativeName("ktoxInventoryPullNamedFromPool")
fun ktoxInventoryPullNamedFromPool(toName: String, sourceNamesCsv: String, itemName: String, desired: Int): Int =
    externalSource()

@NativeName("ktoxInventoryListPooled")
fun ktoxInventoryListPooled(sourceNamesCsv: String): String = externalSource()
