package programs

import common.turtleGetFuelLevel
import lib.CHEST_INTAKE_SLOT
import lib.IntSpan
import lib.Movement
import lib.calibrateMovement
import lib.cargoFull
import lib.dumpCargo
import lib.gpsLocate
import lib.headingDx
import lib.headingDz
import lib.navigateTo
import lib.pastEnd
import lib.restockChest
import lib.stepFor

// Footprint-driven excavator. Named "digsite" (not "excavate") to avoid
// clashing with CC:Tweaked's built-in turtle/excavate.lua program.
//
// Usage: digsite <width> (<length>) (<height>)
//   - width: footprint size along the turtle's right-hand side at start.
//   - length (optional, defaults to width — square footprint): footprint
//     size along the turtle's forward direction at start.
//   - height (optional, signed — positive climbs, negative descends): if
//     given, "room" mode — hollows out that exact bounded x/y/z volume
//     (homeY to homeY+height), one full horizontal layer at a time. If
//     omitted, "clear cut" mode — the turtle's own starting Y is the
//     FLOOR (never dug below); it sweeps full layers upward from there
//     through CLEAR_CUT_HEIGHT blocks. Full-layer sweeps (not per-column
//     "dig until first gap") so overhangs/floating terrain get cleared
//     too.
//   All three are relative to home (the turtle's start position/heading),
//   like ExcavatePro's width/length/depth, rather than absolute world
//   coordinates — so this works identically with or without GPS (see
//   calibrateMovement() in lib/Movement.kt). Replaces an earlier
//   x1:x2/z1:z2 absolute-world-coordinate interface that broke (silently
//   pointed at meaningless/wrong ground) the moment GPS was unavailable.
//   Positional convention: arg COUNT decides meaning (1 = width only,
//   2 = width+length, 3 = width+length+height), matching ExcavatePro,
//   since there's no way to tell a bare length from a bare height apart
//   otherwise.
//
// Fueling/storage: assumes a fuel chest directly behind the turtle's start
// position, with overflow chests extending from there. ASSUMPTION (easy to
// flip if wrong — see CHEST_OVERFLOW_SIDE in lib/Chest.kt): overflow chests
// extend toward the turtle's original right-hand side. Chest logic itself
// (dumping, restocking, the fuel allowlist) is shared with ExcavatePro via
// lib/Chest.kt — this file only decides which slot(s) to keep off-limits.

const val FUEL_SAFETY_MARGIN = 20

// Blocks swept upward from the floor in clear-cut mode. Raise this if your
// terrain runs taller than this above the turtle's starting position.
const val CLEAR_CUT_HEIGHT = 32

fun main(args: Array<String>) {
    if (args.size < 1) {
        println("Usage: digsite <width> (<length>) (<height>)")
        return
    }

    val width = args[1].toInt()
    val length = if (args.size >= 2) args[2].toInt() else width
    val hasHeight = args.size >= 3
    val height = if (hasHeight) args[3].toInt() else 0

    println("Calibrating position via GPS...")
    val movement = calibrateMovement()
    if (movement.gpsEnabled) {
        println("Home at x=${movement.homeX} y=${movement.homeY} z=${movement.homeZ}")
    } else {
        println("No GPS available - running on dead reckoning only (no drift checks).")
    }

    val fwdDx = headingDx(movement.homeHeading)
    val fwdDz = headingDz(movement.homeHeading)
    val rightHeading = (movement.homeHeading + 1) % 4
    val rgtDx = headingDx(rightHeading)
    val rgtDz = headingDz(rightHeading)

    val xOther = movement.homeX + rgtDx * (width - 1) + fwdDx * (length - 1)
    val zOther = movement.homeZ + rgtDz * (width - 1) + fwdDz * (length - 1)
    val xSpan = IntSpan(movement.homeX, xOther)
    val zSpan = IntSpan(movement.homeZ, zOther)

    if (hasHeight) {
        val yOther = movement.homeY + height
        val ySpan = IntSpan(movement.homeY, yOther)
        digsiteRoom(movement, xSpan, ySpan, zSpan)
    } else {
        clearCut(movement, xSpan, zSpan)
    }

    println("Excavation complete. Returning home...")
    navigateTo(movement, movement.homeX, movement.homeY, movement.homeZ)
    movement.faceHeading(movement.homeHeading)
    println("Home.")
}

// -- Base servicing (fuel + item disposal) --

// Only the shared restock scratch slot needs protecting — unlike
// ExcavatePro, there's no stock (torches, step material) to reserve a
// slot for, since fuel is consumed immediately by restockChest() rather
// than stockpiled.
fun keepSlot(slot: Int): Boolean {
    return slot == CHEST_INTAKE_SLOT
}

fun needsService(m: Movement): Boolean {
    val fuel = turtleGetFuelLevel()
    val distance = m.distanceHome()
    if (fuel < distance + FUEL_SAFETY_MARGIN) {
        return true
    }
    return cargoFull { slot -> keepSlot(slot) }
}

fun ensureFuelAndSpace(m: Movement) {
    if (needsService(m)) {
        serviceAtBase(m)
    }
}

fun serviceAtBase(m: Movement) {
    println("Returning to base to refuel/dump inventory...")
    val returnX = m.x
    val returnY = m.y
    val returnZ = m.z

    dumpCargo(m) { slot -> keepSlot(slot) }
    // Nothing else to sort here (no torches/stairs like ExcavatePro) —
    // any non-fuel item just means the chest doesn't hold what this
    // program expects, and restockChest will stop on it rather than spin.
    restockChest(m, 16) { name -> false }

    navigateTo(m, returnX, returnY, returnZ)

    // Drift safety check after the round trip — only meaningful when GPS
    // was available at calibration; otherwise there's no ground truth to
    // check against.
    if (m.gpsEnabled) {
        val checked = gpsLocate()
        if (checked != null) {
            m.x = checked.x
            m.y = checked.y
            m.z = checked.z
        }
    }
    println("Resuming excavation.")
}

// -- Room mode: bounded x/y/z box excavation, one full layer at a time --

fun digsiteRoom(m: Movement, xSpan: IntSpan, ySpan: IntSpan, zSpan: IntSpan) {
    val yStep = stepFor(ySpan)
    var y = ySpan.start
    while (!pastEnd(y, ySpan.finish, yStep)) {
        digsiteLayer(m, xSpan, zSpan, y)
        y += yStep
    }
}

fun digsiteLayer(m: Movement, xSpan: IntSpan, zSpan: IntSpan, y: Int) {
    val xStep = stepFor(xSpan)
    val zStep = stepFor(zSpan)
    var x = xSpan.start
    var forwardZ = true
    while (!pastEnd(x, xSpan.finish, xStep)) {
        if (forwardZ) {
            var z = zSpan.start
            while (!pastEnd(z, zSpan.finish, zStep)) {
                ensureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z += zStep
            }
        } else {
            var z = zSpan.finish
            while (!pastEnd(z, zSpan.start, -zStep)) {
                ensureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z -= zStep
            }
        }
        forwardZ = !forwardZ
        x += xStep
    }
}

// -- Clear-cut mode: x/z footprint, floor = home Y, full layers upward --
//
// Just digsiteRoom with an auto-computed y-range: home Y as the floor,
// CLEAR_CUT_HEIGHT blocks of full-layer sweeps above it. Sweeping every
// layer in full (rather than following each column up until the first
// gap) is what actually clears overhangs/floating terrain — a gap below
// a column no longer stops that column's higher blocks from being dug,
// since every other column at that same height gets visited regardless.

fun clearCut(m: Movement, xSpan: IntSpan, zSpan: IntSpan) {
    val floorY = m.homeY
    val ySpan = IntSpan(floorY, floorY + CLEAR_CUT_HEIGHT)
    digsiteRoom(m, xSpan, ySpan, zSpan)
}
