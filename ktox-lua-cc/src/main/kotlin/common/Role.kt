package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Per-machine terminal role persistence (see TerminalSetup.kt / PLAN.md).
// A plain text file (role.txt) rather than the `settings` API — see
// ktox-cc-shim.lua for why.

@NativeName("ktoxReadRoleFile")
fun ktoxReadRoleFile(): String = externalSource()

@NativeName("ktoxWriteRoleFile")
fun ktoxWriteRoleFile(role: String): Boolean = externalSource()
