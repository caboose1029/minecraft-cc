package programs

import common.turtleGetFuelLevel
import lib.CHEST_INTAKE_SLOT
import lib.IntSpan
import lib.Movement
import lib.calibrateMovement
import lib.cargoFull
import lib.dumpCargo
import lib.gpsLocate
import lib.navigateTo
import lib.pastEnd
import lib.restockChest
import lib.stepFor

// Coordinate-driven excavator. Named "digsite" (not "excavate") to avoid
// clashing with CC:Tweaked's built-in turtle/excavate.lua program.
//
// Usage: digsite x1:x2 z1:z2 (y1:y2 optional)
//   - x/z ranges are absolute world (GPS) coordinates for two corners of
//     the horizontal footprint. Each pair is a literal start:end, not a
//     sorted min:max — the turtle sweeps from the first value to the
//     second, so "100:150" climbs and "150:100" descends, on both x and z.
//   - If a y-range is given: "room" mode — hollows out that exact bounded
//     x/y/z volume, one full horizontal layer at a time.
//   - If no y-range is given: "clear cut" mode — the turtle's own starting
//     Y is the FLOOR (never dug below); it sweeps full layers upward from
//     there through CLEAR_CUT_HEIGHT blocks. Full-layer sweeps (not
//     per-column "dig until first gap") so overhangs/floating terrain get
//     cleared too — GPS keeps positioning reliable enough that clearing a
//     generous fixed height is cheap insurance rather than a real cost.
//
// Fueling/storage: assumes a fuel chest directly behind the turtle's start
// position, with overflow chests extending from there. ASSUMPTION (easy to
// flip if wrong — see CHEST_OVERFLOW_SIDE in lib/Chest.kt): overflow chests
// extend toward the turtle's original right-hand side. Chest logic itself
// (dumping, restocking, the fuel allowlist) is shared with ExcavatePro via
// lib/Chest.kt — this file only decides which slot(s) to keep off-limits.

// ktox does not offset List/Array [] indexing — indices below are 1-based
// on purpose. See AGENTS.md.
//
// Order is preserved as given (no min/max sorting) — the two values define
// a literal start->end sweep direction, not just a bounding pair.
fun parseSpan(raw: String): IntSpan {
    val parts = raw.split(":")
    val a = parts[1].toInt()
    val b = parts[2].toInt()
    return IntSpan(a, b)
}

const val FUEL_SAFETY_MARGIN = 20

// Blocks swept upward from the floor in clear-cut mode. Raise this if your
// terrain runs taller than this above the turtle's starting position.
const val CLEAR_CUT_HEIGHT = 32

fun main(args: Array<String>) {
    if (args.size < 2) {
        println("Usage: digsite x1:x2 z1:z2 (y1:y2 optional)")
        return
    }

    val xSpan = parseSpan(args[1])
    val zSpan = parseSpan(args[2])
    val hasYSpan = args.size >= 3

    println("Calibrating position via GPS...")
    val movement = calibrateMovement()
    if (movement == null) {
        println("GPS calibration failed - check the wireless/ender modem and GPS host coverage.")
        return
    }
    println("Home at x=${movement.homeX} y=${movement.homeY} z=${movement.homeZ}")

    if (hasYSpan) {
        val ySpan = parseSpan(args[3])
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

    // Drift safety check after the round trip.
    val checked = gpsLocate()
    if (checked != null) {
        m.x = checked.x
        m.y = checked.y
        m.z = checked.z
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
