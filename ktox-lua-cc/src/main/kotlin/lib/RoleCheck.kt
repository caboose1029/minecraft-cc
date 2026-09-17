package lib

import common.ktoxRednetLastMessage
import common.ktoxRednetLastSenderId
import common.ktoxRednetReceiveProtocol
import common.rednetBroadcast
import common.rednetOpenAny

// Rednet protocol names for the terminal role system — see PLAN.md
// ("Terminal roles"). Fixed short tags, never freeform text, so no
// delimiter-ambiguity risk in any of the shim plumbing that uses them.
const val VAULT_ROLE_QUERY_PROTOCOL = "vault-role-query"
const val VAULT_ROLE_REPLY_PROTOCOL = "vault-role-reply"
const val VAULT_CMD_PROTOCOL = "vault-cmd"
const val VAULT_RESULT_PROTOCOL = "vault-result"

// Crafter discovery/command protocols — see PLAN.md "Crafter role". The
// query's payload IS the job type (not a fixed "?" like the role query),
// since a network can have several crafters, each responsible for a
// different job type.
const val VAULT_CRAFTER_QUERY_PROTOCOL = "vault-crafter-query"
const val VAULT_CRAFTER_REPLY_PROTOCOL = "vault-crafter-reply"
// Payload packed as "<outputItemName>,<batches>" - see PLAN.md "Crafter
// role" for the chest-above/chest-below physical flow this drives. The
// crafter looks up the recipe for outputItemName itself (findRecipe,
// same shared lib/Config.kt function the head uses) rather than being
// told the ingredient/slot shape - it only needs to know WHAT to make
// and HOW MANY times.
const val VAULT_CRAFTER_CMD_PROTOCOL = "vault-crafter-cmd"

// Crafter -> head, freeform failure reason (payload IS the message, no
// packing - matches VAULT_RESULT_PROTOCOL's own freeform-string
// convention). Sent whenever a physical step doesn't work as expected
// (a suckUp/dropDown/transferTo that didn't move what was expected, no
// known recipe, leftover inventory at job start, ...) so the head can
// surface a SPECIFIC reason instead of just a generic timeout once
// nothing shows up in the drop-down chest. Fire-and-forget, no ack
// needed - see lib/Executor.kt's runCrafterJob for how the head listens
// for this alongside its normal completion polling.
const val VAULT_CRAFTER_FAILURE_PROTOCOL = "vault-crafter-failure"

// Broadcasts a role query and waits up to `listenSeconds` for a head to
// answer. Returns the head's rednet ID if one replied, -1 otherwise (no
// modem, no head present, or timeout). Shared by both the head's own
// boot-time collision check ("does a head already exist?") and a
// secondary's lookup ("who do I forward commands to?") — see PLAN.md,
// these are the same underlying question.
fun queryForHead(listenSeconds: Double): Int {
    if (!rednetOpenAny()) {
        return -1
    }
    rednetBroadcast("?", VAULT_ROLE_QUERY_PROTOCOL)
    val got = ktoxRednetReceiveProtocol(VAULT_ROLE_REPLY_PROTOCOL, listenSeconds)
    if (!got) {
        return -1
    }
    if (ktoxRednetLastMessage() != "head") {
        return -1
    }
    return ktoxRednetLastSenderId()
}

// Broadcasts a crafter query naming `jobType` and waits up to
// `listenSeconds` for the responsible crafty turtle to answer. Returns
// its rednet ID if one replied, -1 otherwise (no modem, no crafter
// configured for this job type, or timeout). Deliberately no collision
// detection here (unlike queryForHead) — multiple crafters answering the
// same job type isn't guarded against in phase 1, see PLAN.md.
fun queryForCrafter(jobType: String, listenSeconds: Double): Int {
    if (!rednetOpenAny()) {
        return -1
    }
    rednetBroadcast(jobType, VAULT_CRAFTER_QUERY_PROTOCOL)
    val got = ktoxRednetReceiveProtocol(VAULT_CRAFTER_REPLY_PROTOCOL, listenSeconds)
    if (!got) {
        return -1
    }
    if (ktoxRednetLastMessage() != jobType) {
        return -1
    }
    return ktoxRednetLastSenderId()
}
