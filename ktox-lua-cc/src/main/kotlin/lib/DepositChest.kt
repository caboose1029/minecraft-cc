package lib

import common.ktoxConfigDepositVaults
import lib.drainVaultInto
import lib.leastFullStorageVaultName

// Deposit chests (job.type "deposit_chest" — an ordinary vault a player
// physically loads by hand, see PLAN.md). Distinct from the turtle-only
// `deposit` CLI command (lib/Cli.kt's runDepositCommand, which sweeps a
// TURTLE's own inventory via job.aboveChest/belowChest) — this is a plain
// vault-to-vault drain, no turtle involved at all, for a build where the
// player would rather just open a chest and drop items in than stand at
// a terminal.
//
// Swept opportunistically after each head interaction (see
// HeadTerminal.kt), same cadence and same reasoning as
// topUpPassiveFeeders()/manageFarms() — a real timer risks being
// cancelled and restarted before its sleep elapses under steady CLI
// traffic, and a head sitting fully idle not draining until its next
// command is an accepted limitation, not a bug.
fun drainDepositChests() {
    val raw = ktoxConfigDepositVaults()
    if (raw == "") {
        return
    }
    val names = raw.split(",")
    var i = 1
    while (i <= names.size) {
        drainVaultInto(names[i], leastFullStorageVaultName())
        i += 1
    }
}
