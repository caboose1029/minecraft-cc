package programs

import common.ktoxRednetLastMessage
import common.ktoxRednetReceiveProtocol
import common.readInput
import common.rednetSend
import common.termWrite
import lib.VAULT_CMD_PROTOCOL
import lib.VAULT_RESULT_PROTOCOL
import lib.queryForHead

// A secondary vault terminal (see PLAN.md "Terminal roles") — a thin
// client. Forwards every local command to the head over rednet and
// prints back whatever it replies; never decides anything itself. Purely
// sequential (read -> send -> receive -> print), unlike HeadTerminal.kt,
// since a secondary only ever has one blocking operation in flight at a
// time — no parallel.waitForAny needed here.
//
// Usage: SecondaryTerminal (no args)

fun main() {
    println("Secondary terminal starting...")
    val headId = queryForHead(2.0)
    if (headId == -1) {
        println("No head terminal found on the network. Make sure exactly one head is running, then reboot this secondary.")
        return
    }

    println("Secondary terminal ready (head id ${headId}). Commands: list, pull, craft, trash.")
    while (true) {
        termWrite("> ")
        val commandLine = readInput()
        val sent = rednetSend(headId, commandLine, VAULT_CMD_PROTOCOL)
        if (!sent) {
            println("Failed to reach the head terminal.")
        } else {
            val got = ktoxRednetReceiveProtocol(VAULT_RESULT_PROTOCOL, 30.0)
            if (got) {
                println(ktoxRednetLastMessage())
            } else {
                println("No response from the head terminal (timed out).")
            }
        }
    }
}
