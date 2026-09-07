package programs

import common.fsMakeDir
import common.ktoxDownloadFile

// Pulls Digsite and its dependencies onto a fresh turtle/computer, straight
// from GitHub. Each entry is a path relative to the repo base and also the
// local path it's saved to, preserving directory structure — unlike
// moonman's `sync`, which flattens every file to the CC root via
// fs.getName() and would break require("lib/Movement") the moment this
// package's files land there. See AGENTS.md.
//
// DEFAULT_BRANCH tracks whichever branch is under active iteration —
// currently feat/ktox-lua-storage. main doesn't have
// src/pkg/player/8durt yet, so this can't point there — move it to
// "main" (matching moonman's manifest convention) once that merges.
//
// Usage: ghfetch [branch]
//   - branch (optional): git ref to fetch from, e.g. a feature branch
//     you're iterating on. Defaults to DEFAULT_BRANCH when omitted.

const val DEFAULT_BRANCH = "feat/ktox-lua-storage"

fun main(args: Array<String>) {
    val branch = if (args.size >= 1) args[1] else DEFAULT_BRANCH
    val repoBase = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/${branch}/src/pkg/player/8durt"
    println("Fetching from branch: ${branch}")

    val dirs = arrayOf("lib", "common", "config")
    var d = 1
    while (d <= dirs.size) {
        fsMakeDir(dirs[d])
        d += 1
    }

    // NOTE: this list isn't derived from anything — every new program/lib
    // file has to be added here by hand or it silently won't reach fresh
    // turtles via ghfetch. Do this proactively for every new feature file
    // until moonman's sync (see AGENTS.md) is fixed by caboose1029 and we
    // can drop this manifest in favor of his.
    val files = arrayOf(
        "ktox-lib.lua",
        "ktox-cc-shim.lua",
        "startup.lua",
        "lib/Movement.lua",
        "lib/Position.lua",
        "lib/Span.lua",
        "lib/Chest.lua",
        "lib/Shape.lua",
        "lib/Redstone.lua",
        "lib/Inventory.lua",
        "lib/Config.lua",
        "lib/Executor.lua",
        "lib/RoleCheck.lua",
        "lib/Planner.lua",
        "lib/PassiveFeeder.lua",
        "lib/Farm.lua",
        "lib/Cli.lua",
        "lib/Colors.lua",
        "lib/Display.lua",
        "lib/Dashboard.lua",
        "common/Monitor.lua",
        "common/Display.lua",
        "common/Str.lua",
        "common/Peripheral.lua",
        "common/Rednet.lua",
        "common/Parallel.lua",
        "common/Role.lua",
        "config/peripherals.example.json",
        "config/job-types.lua",
        "config/resource-tree.lua",
        "Digsite.lua",
        "ExcavatePro.lua",
        "DiamondFinder.lua",
        "TestMonitor.lua",
        "TestConfig.lua",
        "TestDashboard.lua",
        "HeadTerminal.lua",
        "SecondaryTerminal.lua",
        "Crafter.lua",
        "TerminalSetup.lua",
        "GhFetch.lua",
    )

    var i = 1
    var failures = 0
    while (i <= files.size) {
        val path = files[i]
        val url = "${repoBase}/${path}"
        println("Fetching ${path}...")
        val ok = ktoxDownloadFile(url, path)
        if (ok) {
            println("  ok")
        } else {
            println("  FAILED: ${path}")
            failures += 1
        }
        i += 1
    }

    if (failures > 0) {
        println("${failures} file(s) failed.")
    } else {
        println("Fetched ${files.size} file(s).")
    }
}
