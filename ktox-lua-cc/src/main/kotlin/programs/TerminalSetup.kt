package programs

import common.ktoxWriteRoleFile
import lib.queryForHead

// Provisions this computer/turtle as a head, secondary, or crafter vault
// terminal (see PLAN.md "Terminal roles"). Writes role.txt, which
// startup.lua reads on every future boot to auto-launch Head/Secondary/
// Crafter — run ghfetch first so those programs (and startup.lua's
// dispatch logic) are actually present before setting a role that
// depends on them.
//
// Usage: terminalsetup <head|secondary|crafter> [jobType]
//   jobType is required for, and only meaningful with, "crafter" — the
//   job type (from config/job-types.json) this crafty turtle handles.

fun main(args: Array<String>) {
    if (args.size < 1) {
        println("Usage: terminalsetup <head|secondary|crafter> (jobType)")
        return
    }
    val role = args[1]
    if (role != "head" && role != "secondary" && role != "crafter") {
        println("Unknown role \"${role}\" - expected \"head\", \"secondary\", or \"crafter\".")
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

    if (role == "crafter") {
        if (args.size < 2) {
            println("Usage: terminalsetup crafter <jobType>")
            return
        }
        val jobType = args[2]
        val wrote = ktoxWriteRoleFile("crafter:${jobType}")
        if (!wrote) {
            println("Failed to write role.txt.")
            return
        }
        println("Configured as crafter for job \"${jobType}\". Reboot to start automatically, or run 'crafter ${jobType}' directly now.")
        return
    }

    val wrote = ktoxWriteRoleFile(role)
    if (!wrote) {
        println("Failed to write role.txt.")
        return
    }

    println("Configured as ${role}. Reboot to start automatically, or run the ${role} program directly now.")
}
