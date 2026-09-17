package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Binding to CC:Tweaked's `parallel` API — the standard idiom for
// multiplexing a blocking local read() against a blocking rednet.receive
// (see PLAN.md's head terminal design: it must react to whichever of
// local keyboard input or a secondary's forwarded command arrives
// first). runs both, returns once either one finishes (the other is
// terminated).
//
// UNVERIFIED: function-type (lambda) parameters are confirmed working
// elsewhere in this codebase (see AGENTS.md), but always for
// hand-written Kotlin functions — this is the first time a lambda
// parameter is passed to an `externalSource()`-bodied native binding.
// Call-site codegen for arguments should be identical either way (the
// callee's own body has no bearing on how its arguments are
// transpiled), but this specific combination hasn't been exercised via
// CraftOS-PC. Verify in-game before relying on it.
@NativeName("parallel.waitForAny")
fun parallelWaitForAny(first: () -> Unit, second: () -> Unit): Unit = externalSource()
