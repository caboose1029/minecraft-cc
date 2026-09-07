package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Generic string helpers with no existing ktox runtime support (unlike
// .split()/.toDoubleOrNull(), which ktox's own bundled ktox-lib.lua
// backs already) - hand-written shims in ktox-cc-shim.lua instead of
// assuming Kotlin's stdlib method transpiles. See AGENTS.md.

@NativeName("ktoxDropLastChar")
fun ktoxDropLastChar(s: String): String = externalSource()
