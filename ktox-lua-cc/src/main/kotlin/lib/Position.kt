package lib

import common.ktoxGpsLocateRaw

data class Position(
    val x: Int,
    val y: Int,
    val z: Int,
)

// gps.locate() itself returns 3 values or nil — Kotlin can't express that,
// so the native call is bound (common/Gps.kt) to a shim that packs the
// result into a comma-joined string or nil. This parses that back into a
// real value. See src/main/lua/ktox-cc-shim.lua for the Lua side.
fun gpsLocate(timeout: Double = 2.0): Position? {
    val raw = ktoxGpsLocateRaw(timeout)
    if (raw == null) {
        return null
    }
    // ktox does NOT offset List indexing from Kotlin's 0-based convention
    // to Lua's 1-based tables — `parts[0]` transpiles to the literal (and
    // always-nil) Lua index `parts[0]`. Indices below are 1-based on
    // purpose to match what ktox_split actually produces. See AGENTS.md.
    val parts = raw.split(",")
    return Position(
        parts[1].toDouble().toInt(),
        parts[2].toDouble().toInt(),
        parts[3].toDouble().toInt(),
    )
}
