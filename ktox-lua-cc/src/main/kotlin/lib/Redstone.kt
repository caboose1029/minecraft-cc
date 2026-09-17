package lib

import common.ktoxConfigRelayForJob
import common.ktoxPeripheralCallRaw

// Toggles the redstone relay (see PLAN.md — a real CC:Tweaked peripheral
// mirroring the `redstone` global API, reachable remotely over the wired
// network) that controls the given job/machine type, per
// config/peripherals.json. Returns false if no relay is configured for
// this job type, or the relay peripheral isn't reachable.
fun setJobPower(jobType: String, on: Boolean): Boolean {
    val relaySide = ktoxConfigRelayForJob(jobType)
    if (relaySide == "MISSING") {
        return false
    }
    // ktox does NOT offset List indexing from Kotlin's 0-based convention
    // to Lua's 1-based tables - parts[1] is the first element. See
    // AGENTS.md and lib/Position.kt for the same idiom.
    val parts = relaySide.split(",")
    val relayName = parts[1]
    val side = parts[2]
    val result = ktoxPeripheralCallRaw(relayName, "setOutput", "S:${side}|B:${on}")
    return result != "MISSING"
}
