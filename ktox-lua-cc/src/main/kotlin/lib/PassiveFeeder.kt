package lib

import common.ktoxConfigPassiveFeeders
import common.ktoxInventoryCountNamed
import lib.pullFromStoragePool

// Passive feeders (job.type "passive" — a vault sitting above a
// deployer, trying to always hold a full stack of one item, see
// PLAN.md). Unlike a job-input feeder, nothing triggers this — it's
// topped up opportunistically by the head after handling each local or
// remote command (see Head.kt), not on an independent timer: a genuine
// background timer would need a third parallel.waitForAny branch whose
// sleep gets cancelled and restarted every time a command arrives before
// it elapses, which could starve it indefinitely under steady CLI
// traffic — checking after every interaction instead is simpler, safer,
// and good enough given the head is only useful while being interacted
// with anyway. A head that sits fully idle won't top up passive feeders
// until the next command — an accepted, disclosed limitation, not
// something worth a timer's complexity for phase 1.
fun topUpPassiveFeeders() {
    val raw = ktoxConfigPassiveFeeders()
    if (raw == "") {
        return
    }
    val rows = raw.split("\n")
    var i = 1
    while (i <= rows.size) {
        val cols = rows[i].split(",")
        val vaultName = cols[1]
        val itemName = cols[2]
        val low = cols[3].toDouble().toInt()
        val high = cols[4].toDouble().toInt()
        val current = ktoxInventoryCountNamed(vaultName, itemName)
        if (current < low) {
            pullFromStoragePool(vaultName, itemName, high - current)
        }
        i += 1
    }
}
