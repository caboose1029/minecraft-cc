package programs

import common.fsMakeDir
import common.ktoxDownloadFile
import common.ktoxDownloadFileText

// Pulls Digsite and its dependencies onto a fresh turtle/computer, straight
// from GitHub. Each entry is a path relative to the repo base and also the
// local path it's saved to, preserving directory structure — unlike
// moonman's `sync`, which flattens every file to the CC root via
// fs.getName() and would break require("lib/Movement") the moment this
// package's files land there. See AGENTS.md.
//
// The actual file list lives in FILES_MANIFEST (fetched, not hardcoded
// here) — see that constant's own comment for why, and MANIFEST.md at
// the repo root for how to maintain it. This file only knows the ONE
// thing that can't itself come from the manifest: where to find it.
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
const val FILES_MANIFEST = "files.manifest"

fun main(args: Array<String>) {
    val branch = if (args.size >= 1) args[1] else DEFAULT_BRANCH
    val repoBase = "https://raw.githubusercontent.com/caboose1029/minecraft-cc/${branch}/src/pkg/player/8durt"
    println("Fetching from branch: ${branch}")

    val manifestUrl = "${repoBase}/${FILES_MANIFEST}"
    val manifestText = ktoxDownloadFileText(manifestUrl)
    if (manifestText == "MISSING") {
        println("Could not fetch the file manifest (${FILES_MANIFEST}) - aborting.")
        return
    }
    // Also save it to disk, same as every other synced file - not
    // strictly needed for this run (already have the text above), but
    // keeps it inspectable and consistent with everything else ghfetch
    // deploys.
    ktoxDownloadFile(manifestUrl, FILES_MANIFEST)

    // One path per line. A trailing blank line (a file conventionally
    // ends with one) is skipped below, not an error.
    val files = manifestText.split("\n")

    var i = 1
    var failures = 0
    var fetched = 0
    while (i <= files.size) {
        val path = files[i]
        if (path != "") {
            // Every real path in this tree is either bare ("Foo.lua") or
            // exactly one directory deep ("lib/Foo.lua") - never nested
            // further, so the directory is just the first "/"-separated
            // part when there is one.
            val pathParts = path.split("/")
            if (pathParts.size >= 2) {
                fsMakeDir(pathParts[1])
            }
            val url = "${repoBase}/${path}"
            println("Fetching ${path}...")
            val ok = ktoxDownloadFile(url, path)
            if (ok) {
                println("  ok")
                fetched += 1
            } else {
                println("  FAILED: ${path}")
                failures += 1
            }
        }
        i += 1
    }

    if (failures > 0) {
        println("${failures} file(s) failed.")
    } else {
        println("Fetched ${fetched} file(s).")
    }
}
