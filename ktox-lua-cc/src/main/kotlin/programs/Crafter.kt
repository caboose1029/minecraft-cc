package programs

import common.ktoxRednetLastMessage
import common.ktoxRednetLastProtocol
import common.ktoxRednetLastSenderId
import common.ktoxRednetReceiveAny
import common.rednetOpenAny
import common.rednetSend
import common.turtleCraft
import common.turtleDrop
import common.turtleGetItemCount
import common.turtleSelect
import lib.VAULT_CRAFTER_CMD_PROTOCOL
import lib.VAULT_CRAFTER_QUERY_PROTOCOL
import lib.VAULT_CRAFTER_REPLY_PROTOCOL

// A crafty turtle (see PLAN.md "Crafter role") — a third terminal role
// alongside head/secondary, but not a CLI: it never talks to a player
// directly, just sits waiting for the head to push ingredients into its
// crafting-grid slots (1, 2, 3, 5, 6, 7, 9, 10, 11) and send a craft
// command. Runs turtle.craft(), then drops everything it's holding
// toward whatever it's physically facing — expected to be an ordinary
// storage vault (see PLAN.md for why this is a physical drop, not a
// network push). Never decides anything itself, same principle as
// Secondary.kt, just a different kind of thin client — the head is
// still the only thing that knows what to craft, how much, or why.
//
// Usage: crafter <jobType> (normally auto-launched by startup.lua via
// role.txt, not run by hand — see TerminalSetup.kt)

fun main(args: Array<String>) {
    if (args.size < 1) {
        println("Usage: crafter <jobType>")
        return
    }
    val jobType = args[1]

    println("Crafter starting (job: ${jobType})...")
    val hasModem = rednetOpenAny()
    if (!hasModem) {
        println("No modem found - attach one and reboot.")
        return
    }

    println("Crafter ready, waiting for commands.")
    while (true) {
        handleOneMessage(jobType)
    }
}

fun handleOneMessage(jobType: String) {
    // Long finite timeout rather than "forever" - see Head.kt's identical
    // choice and reasoning (no evidence either way on a native timeout
    // sentinel transpiling correctly through this binding).
    val got = ktoxRednetReceiveAny(3600.0)
    if (!got) {
        return
    }
    val senderId = ktoxRednetLastSenderId()
    val protocol = ktoxRednetLastProtocol()
    if (protocol == VAULT_CRAFTER_QUERY_PROTOCOL && ktoxRednetLastMessage() == jobType) {
        rednetSend(senderId, jobType, VAULT_CRAFTER_REPLY_PROTOCOL)
    } else if (protocol == VAULT_CRAFTER_CMD_PROTOCOL) {
        val quantity = ktoxRednetLastMessage().toDouble().toInt()
        turtleCraft(quantity)
        dumpAllForward()
    }
}

// Drops everything the turtle is holding toward whatever it's facing —
// deliberately doesn't try to track which specific slot turtle.craft()'s
// result landed in (unverified/unconfirmed exact behavior), just clears
// the whole inventory after every craft. Safe as long as this turtle
// only ever holds craft-relevant items, which it should as a dedicated
// crafter with nothing else pushed into it.
fun dumpAllForward() {
    var slot = 1
    while (slot <= 16) {
        turtleSelect(slot)
        if (turtleGetItemCount(slot) > 0) {
            turtleDrop(64)
        }
        slot += 1
    }
}
