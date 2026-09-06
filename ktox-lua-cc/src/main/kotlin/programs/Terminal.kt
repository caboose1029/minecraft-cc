package programs

import common.readInput
import common.termWrite
import lib.runCliCommand

// The vault terminal CLI (see PLAN.md) — list/pull/craft, run locally at
// this computer's own read() prompt. Head/secondary rednet forwarding
// (so the same commands work from a secondary terminal too) isn't wired
// up yet; this is the single-terminal case, run directly on whichever
// computer/turtle is configured as the head. Loops forever — Ctrl+T to
// stop, matching normal CC program conventions.
//
// Usage: terminal (no args)

fun main() {
    println("Vault terminal ready. Commands: list, pull, craft.")
    while (true) {
        termWrite("> ")
        val commandLine = readInput()
        println(runCliCommand(commandLine))
    }
}
