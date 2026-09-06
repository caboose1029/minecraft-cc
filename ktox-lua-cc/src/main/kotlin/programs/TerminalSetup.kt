package programs

import common.ktoxWriteRoleFile
import lib.queryForHead

// Provisions this computer/turtle as a head or secondary vault terminal
// (see PLAN.md "Terminal roles"). Writes role.txt, which startup.lua
// reads on every future boot to auto-launch Head or Secondary — run
// ghfetch first so those programs (and startup.lua's dispatch logic)
// are actually present before setting a role that depends on them.
//
// Usage: terminalsetup <head|secondary>

fun main(args: Array<String>) {
    if (args.size < 1) {
        println("Usage: terminalsetup <head|secondary>")
        return
    }
    val role = args[1]
    if (role != "head" && role != "secondary") {
        println("Unknown role \"${role}\" - expected \"head\" or \"secondary\".")
        return
    }

    if (role == "head") {
        println("Checking for an existing head on the network...")
        val existingHead = queryForHead(2.0)
        if (existingHead != -1) {
            println("Another head is already running (id ${existingHead}) - refusing to configure this machine as a second head. Only one head terminal is allowed on the network.")
            return
        }
    }

    val wrote = ktoxWriteRoleFile(role)
    if (!wrote) {
        println("Failed to write role.txt.")
        return
    }

    println("Configured as ${role}. Reboot to start automatically, or run the ${role} program directly now.")
}
