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
// SecondaryTerminal.kt, just a different kind of thin client — the head is
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
    // Long finite timeout rather than "forever" - see HeadTerminal.kt's identical
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
        // turtle.craft() matches whatever's PHYSICALLY in the grid right
        // now - it has no notion of "the recipe the head intended".
        // Confirmed live: leftover ingredients from an earlier successful
        // craft (brass ingots forming brass_block's exact 9-slot shape)
        // sat through dumpAllForward() below never actually clearing them
        // (most likely turtleDrop() silently failing - nothing valid in
        // front to receive them, or that vault was full) and got
        // re-crafted into brass_block on every subsequent, unrelated
        // craft request (raw_zinc_block, minecraft:chest) regardless of
        // what ingredients the head had actually tried to deliver.
        // Clearing FIRST and refusing to craft unless that verifiably
        // succeeded turns a silent wrong-item craft (real materials
        // wasted) into a safe no-op (0 produced, matching every other
        // "couldn't do this" case already in this codebase) - it can't
        // fix WHY the drop isn't landing (a real-world check: is there a
        // non-full storage vault directly in front of this turtle?), but
        // it stops the turtle from ever crafting from stale contents.
        dumpAllForward()
        if (isInventoryEmpty()) {
            turtleCraft(quantity)
            dumpAllForward()
        }
    }
}

fun isInventoryEmpty(): Boolean {
    var slot = 1
    while (slot <= 16) {
        if (turtleGetItemCount(slot) > 0) {
            return false
        }
        slot += 1
    }
    return true
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
