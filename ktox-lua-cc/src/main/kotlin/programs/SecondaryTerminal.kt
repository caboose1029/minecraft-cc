package programs

import common.ktoxRednetLastMessage
import common.ktoxRednetReceiveProtocol
import common.rednetSend
import lib.VAULT_CMD_PROTOCOL
import lib.VAULT_RESULT_PROTOCOL
import lib.queryForHead
import lib.runDashboardLoop
import lib.showDashboardBusy
import lib.showDashboardResult

// The head's own craft path can block for real time (polling once a
// second, up to a configured timeout, twice PER planner level - see
// lib/Executor.kt/lib/Planner.kt) - the old fixed 30s reply wait here
// could easily be shorter than the head is legitimately still working,
// reporting "timed out" for a command that then succeeds moments later
// on the head's side. Not a real ceiling on how long a craft can
// actually take (a deep planner chain could still exceed even this),
// just far more generous than the original 30s.
const val CRAFTER_RESULT_TIMEOUT_SECONDS = 300.0

// A secondary vault terminal (see PLAN.md "Terminal roles") — a thin
// client. Forwards every local command to the head over rednet and
// shows back whatever it replies; never decides anything itself. Purely
// sequential (dashboard -> send -> receive -> show), unlike
// HeadTerminal.kt, since a secondary only ever has one blocking
// operation in flight at a time — no parallel.waitForAny needed here.
// Local input comes from the touch dashboard (lib/Dashboard.kt) instead
// of a plain read() prompt this used to have — same as HeadTerminal, and
// the only way this can work at all on a pocket computer (see PLAN.md).
//
// Usage: SecondaryTerminal (no args)

fun main() {
    println("Secondary terminal starting...")
    val headId = queryForHead(2.0)
    if (headId == -1) {
        println("No head terminal found on the network. Make sure exactly one head is running, then reboot this secondary.")
        return
    }

    println("Secondary terminal ready (head id ${headId}). Use the touch dashboard.")
    while (true) {
        val commandLine = runDashboardLoop()
        val sent = rednetSend(headId, commandLine, VAULT_CMD_PROTOCOL)
        if (!sent) {
            val message = "Failed to reach the head terminal."
            println(message)
            showDashboardResult(message)
        } else {
            showDashboardBusy("Working...")
            val got = ktoxRednetReceiveProtocol(VAULT_RESULT_PROTOCOL, CRAFTER_RESULT_TIMEOUT_SECONDS)
            if (got) {
                val message = ktoxRednetLastMessage()
                println(message)
                showDashboardResult(message)
            } else {
                val message = "No response from the head terminal (timed out)."
                println(message)
                showDashboardResult(message)
            }
        }
    }
}
