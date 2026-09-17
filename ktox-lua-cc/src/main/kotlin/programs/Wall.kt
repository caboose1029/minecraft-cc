package programs

import common.turtleBack
import common.turtleDown
import common.turtleForward
import common.turtleGetFuelLevel
import common.turtleGetItemCount
import common.turtleGetItemName
import common.turtlePlaceDown
import common.turtleSelect
import common.turtleUp

// Simple wall builder. Usage: wall <length> <height>
//   - length: blocks along the wall's run.
//   - height: rows stacked upward.
// Put the wall material in slot 1 before running - only slots holding
// that exact same item are ever used; other items in the inventory are
// left alone (so a turtle also carrying mined loot won't accidentally
// build with it).
//
// Placement is always turtlePlaceDown(), never turtlePlace() - placing
// forward and then walking into that same cell would either block the
// turtle or (with a dig-fallback like lib/Movement.kt's forward()) mine
// the wall block right back out as it tried to advance through it. Down
// avoids that entirely: the turtle hovers one row above the course it's
// currently building and lets go beneath itself, never obstructing its
// own path. CC:Tweaked turtles aren't affected by gravity, so hovering
// with nothing solid underneath is safe - general platform behavior,
// not separately verified in-game this session.
//
// Rows are built bottom-up, alternating direction each row (forward across
// row 0, back across row 1, forward across row 2, ...) instead of turning
// around at the end of every row - since placement is straight down, the
// turtle's facing never matters, so there's nothing to gain by turning.
// Every actual movement goes through wallStepForward/Back/Up/Down below,
// which track net horizontal/vertical displacement from the start; wall
// building can stop early (out of material, or a movement unexpectedly
// blocked), and wallReturnHome() unwinds exactly whatever displacement
// was actually accumulated, so it always finds its way back regardless of
// where it stopped.

const val WALL_FUEL_SAFETY_MARGIN = 10

fun wallPrintUsage() {
    println("Usage: wall <length> <height>")
    println("  length: blocks along the wall's run")
    println("  height: rows stacked upward")
    println("Put the wall material in slot 1 before running - only slots")
    println("holding that exact same item are used; other items are left alone.")
}

// Finds a slot currently holding `materialName`, lowest slot number first
// - same pattern as ExcavatePro's findCobblestoneSlot(). -1 if none of the
// turtle's slots currently hold any more of it.
fun wallFindMaterialSlot(materialName: String): Int {
    var slot = 1
    var found = -1
    while (slot <= 16 && found == -1) {
        if (turtleGetItemCount(slot) > 0) {
            val name = turtleGetItemName(slot)
            if (name != null && name == materialName) {
                found = slot
            }
        }
        slot += 1
    }
    return found
}

// Selects a slot holding `materialName` and places it directly below the
// turtle. False (with nothing selected) if no slot holds any more of it -
// the caller decides what that means.
fun wallPlaceMaterialDown(materialName: String): Boolean {
    val slot = wallFindMaterialSlot(materialName)
    if (slot == -1) {
        return false
    }
    turtleSelect(slot)
    return turtlePlaceDown()
}

var wallHorizontalOffset = 0
var wallVerticalOffset = 0

fun wallStepForward(): Boolean {
    if (turtleForward()) {
        wallHorizontalOffset += 1
        return true
    }
    return false
}

fun wallStepBack(): Boolean {
    if (turtleBack()) {
        wallHorizontalOffset -= 1
        return true
    }
    return false
}

fun wallStepUp(): Boolean {
    if (turtleUp()) {
        wallVerticalOffset += 1
        return true
    }
    return false
}

fun wallStepDown(): Boolean {
    if (turtleDown()) {
        wallVerticalOffset -= 1
        return true
    }
    return false
}

// Unwinds whatever net displacement wallHorizontalOffset/wallVerticalOffset
// actually accumulated, so this works the same whether the build finished
// cleanly or stopped early. Prints a clear message and gives up (rather
// than looping forever) if a step back home is itself blocked - genuinely
// stuck needs a player, not a retry loop.
fun wallReturnHome() {
    while (wallVerticalOffset > 0) {
        if (!wallStepDown()) {
            println("Couldn't descend while returning home - manual recovery needed.")
            return
        }
    }
    while (wallVerticalOffset < 0) {
        if (!wallStepUp()) {
            println("Couldn't ascend while returning home - manual recovery needed.")
            return
        }
    }
    while (wallHorizontalOffset > 0) {
        if (!wallStepBack()) {
            println("Couldn't return home - manual recovery needed.")
            return
        }
    }
    while (wallHorizontalOffset < 0) {
        if (!wallStepForward()) {
            println("Couldn't return home - manual recovery needed.")
            return
        }
    }
}

fun main(args: Array<String>) {
    if (args.size < 2) {
        wallPrintUsage()
        return
    }
    if (args[1] == "-h" || args[1] == "--help") {
        wallPrintUsage()
        return
    }
    // args[1]/args[2] are the first/second real CLI args directly (ktox
    // does not offset-correct indexing - see AGENTS.md) - the args.size
    // < 2 check above already guarantees both are present.
    val length = args[1].toIntOrNull()
    val height = args[2].toIntOrNull()
    if (length == null || height == null || length < 1 || height < 1) {
        wallPrintUsage()
        return
    }

    val materialName = turtleGetItemName(1)
    if (materialName == null) {
        println("Slot 1 is empty - put the wall material there first.")
        return
    }

    val neededFuel = length * height + WALL_FUEL_SAFETY_MARGIN
    val fuel = turtleGetFuelLevel()
    if (fuel < neededFuel) {
        println("Warning: fuel may be too low (have ${fuel}, want ~${neededFuel}). Continuing anyway.")
    }

    println("Building a ${length}x${height} wall from ${materialName}...")

    // Go up once before starting: the turtle begins standing at the
    // wall's bottom row, so placeDown() would otherwise target the
    // ground it's already standing on (occupied, so it'd just fail).
    // One turtleUp() puts the base row directly beneath it instead.
    if (!wallStepUp()) {
        println("Couldn't get into position (blocked above) - aborting.")
        return
    }

    var row = 0
    var placed = 0
    var stoppedShort = false
    while (row < height && !stoppedShort) {
        var col = 0
        while (col < length && !stoppedShort) {
            if (wallPlaceMaterialDown(materialName)) {
                placed += 1
            } else {
                println("Ran out of ${materialName} after placing ${placed} block(s).")
                stoppedShort = true
            }
            if (col < length - 1 && !stoppedShort) {
                // Not `val moved = if (...) A else B` - ktox compiles that
                // single-expression form to Lua's `(cond and A or B)`
                // idiom, which silently falls through to B whenever A
                // evaluates to `false` (both branches here return
                // Boolean) - see AGENTS.md's documented ktox quirk. A
                // real if/else block avoids it.
                var moved = false
                if (row % 2 == 0) {
                    moved = wallStepForward()
                } else {
                    moved = wallStepBack()
                }
                if (!moved) {
                    println("Blocked partway along row ${row + 1} - stopping.")
                    stoppedShort = true
                }
            }
            col += 1
        }
        row += 1
    }

    wallReturnHome()

    if (stoppedShort) {
        println("Stopped early - placed ${placed} of ${length * height} block(s).")
    } else {
        println("Done - placed ${placed} block(s).")
    }
}
