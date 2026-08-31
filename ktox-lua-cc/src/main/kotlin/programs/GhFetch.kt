package programs

import common.fsMakeDir
import common.ktoxDownloadFile

// Pulls Digsite and its dependencies onto a fresh turtle/computer, straight
// from GitHub. Each entry is a path relative to REPO_BASE and also the
// local path it's saved to, preserving directory structure — unlike
// moonman's `sync`, which flattens every file to the CC root via
// fs.getName() and would break require("lib/Movement") the moment this
// package's files land there. See AGENTS.md.
//
// REPO_BASE points at the feat/add-ktox-lua-cc branch since main doesn't
// have src/pkg/player/8durt yet — move it to refs/heads/main (matching
// moonman's manifest convention) once that branch merges.
//
// Usage: ghfetch (no args)

const val REPO_BASE = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/feat/add-ktox-lua-cc/src/pkg/player/8durt"

fun main() {
    val dirs = arrayOf("lib")
    var d = 1
    while (d <= dirs.size) {
        fsMakeDir(dirs[d])
        d += 1
    }

    val files = arrayOf(
        "ktox-lib.lua",
        "ktox-cc-shim.lua",
        "startup.lua",
        "lib/Movement.lua",
        "lib/Position.lua",
        "lib/Span.lua",
        "Digsite.lua",
        "ExcavatePro.lua",
        "GhFetch.lua",
    )

    var i = 1
    var failures = 0
    while (i <= files.size) {
        val path = files[i]
        val url = "${REPO_BASE}/${path}"
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
