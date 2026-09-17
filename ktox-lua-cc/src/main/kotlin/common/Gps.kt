package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// gps.locate() returns 3 values (x, y, z) or nil — Kotlin can't express
// that directly, so this binds to ktoxGpsLocate (src/main/lua/ktox-cc-shim.lua),
// which packs the result into a single comma-joined string or nil.
// See lib/Position.kt for the parsed, idiomatic version of this.

@NativeName("ktoxGpsLocate")
fun ktoxGpsLocateRaw(timeout: Double): String? = externalSource()
