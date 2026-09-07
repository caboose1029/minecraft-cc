package programs

import common.ktoxRednetLastMessage
import common.ktoxRednetLastProtocol
import common.ktoxRednetLastSenderId
import common.ktoxRednetReceiveAny
import common.parallelWaitForAny
import common.readInput
import common.rednetOpenAny
import common.rednetSend
import common.termWrite
import lib.VAULT_CMD_PROTOCOL
import lib.VAULT_ROLE_QUERY_PROTOCOL
import lib.VAULT_ROLE_REPLY_PROTOCOL
import lib.VAULT_RESULT_PROTOCOL
import lib.manageFarms
import lib.queryForHead
import lib.runCliCommand
import lib.topUpPassiveFeeders

// The head vault terminal (see PLAN.md "Terminal roles") — the sole
// decision-maker. Runs the shared CLI dispatcher (lib/Cli.kt) against
// both its own local read() prompt and commands forwarded over rednet
// from secondary terminals, multiplexed via parallel.waitForAny (see
// common/Parallel.kt — UNVERIFIED, this whole rednet+parallel path has
// not been exercised in a real game; validate with two real computers
// before relying on it).
//
// Usage: HeadTerminal (no args)

fun main() {
    println("Head terminal starting...")
    val hasModem = rednetOpenAny()
    if (!hasModem) {
        println("No modem found - attach one and reboot. A head terminal needs one to detect other heads and talk to secondaries.")
        return
    }

    val existingHead = queryForHead(2.0)
    if (existingHead != -1) {
        println("Another head is already running (id ${existingHead}) - refusing to start. Only one head terminal is allowed on the network.")
        return
    }

    println("Head terminal ready. Commands: list, pull, craft, trash.")
    while (true) {
        parallelWaitForAny(
            { handleLocalInput() },
            { handleRemoteMessage() },
        )
        // Opportunistic, not on an independent timer — see
        // lib/PassiveFeeder.kt for why.
        topUpPassiveFeeders()
        manageFarms()
    }
}

fun handleLocalInput() {
    termWrite("> ")
    val commandLine = readInput()
    println(runCliCommand(commandLine))
}

fun handleRemoteMessage() {
    // Long finite timeout rather than "forever" - no evidence either way
    // on whether ktox correctly transpiles a sentinel for "no timeout"
    // through this native binding, so a large number sidesteps the
    // question entirely (worst case: re-loops once an hour for nothing).
    val got = ktoxRednetReceiveAny(3600.0)
    if (!got) {
        return
    }
    val senderId = ktoxRednetLastSenderId()
    val protocol = ktoxRednetLastProtocol()
    if (protocol == VAULT_ROLE_QUERY_PROTOCOL) {
        rednetSend(senderId, "head", VAULT_ROLE_REPLY_PROTOCOL)
    } else if (protocol == VAULT_CMD_PROTOCOL) {
        val commandLine = ktoxRednetLastMessage()
        val result = runCliCommand(commandLine)
        rednetSend(senderId, result, VAULT_RESULT_PROTOCOL)
    }
}
