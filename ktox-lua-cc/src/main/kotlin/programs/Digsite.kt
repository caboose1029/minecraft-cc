package programs

import common.turtleDrop
import common.turtleGetFuelLevel
import common.turtleGetItemCount
import common.turtleRefuel
import common.turtleSelect
import common.turtleSuck
import lib.Movement
import lib.calibrateMovement
import lib.gpsLocate

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
// flip if wrong — see OVERFLOW_SIDE below): overflow chests extend toward
// the turtle's original right-hand side.

data class IntSpan(val start: Int, val finish: Int)

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

fun stepFor(span: IntSpan): Int {
    return if (span.start <= span.finish) 1 else -1
}

// True once `current` has moved past `limit` while stepping by `step`
// (whose sign gives the direction of travel).
//
// Written as an if/else block, NOT `return if (cond) A else B` — ktox
// compiles that single-expression form to Lua's `(cond and A or B)`
// idiom, which is broken here: A (`current > limit`) is itself a
// boolean, and whenever it's false, `cond and false` is false, so Lua
// falls through to B regardless of cond. That made every ascending span
// (step > 0) report "past end" on almost every call, terminating
// digsiteRoom/digsiteLayer after ~0 iterations. See AGENTS.md.
fun pastEnd(current: Int, limit: Int, step: Int): Boolean {
    if (step > 0) {
        return current > limit
    }
    return current < limit
}

// +1 = turtle's original right is "sideways toward the overflow row".
// Flip to -1 if the chests turn out to be laid out the other way in-game.
const val OVERFLOW_SIDE = 1

const val FUEL_SAFETY_MARGIN = 20
const val MAX_OVERFLOW_CHESTS = 20

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

// -- Movement helpers --

fun headingDx(h: Int): Int {
    return if (h == 1) {
        1
    } else if (h == 3) {
        -1
    } else {
        0
    }
}

fun headingDz(h: Int): Int {
    return if (h == 2) {
        1
    } else if (h == 0) {
        -1
    } else {
        0
    }
}

// Axis-aligned navigation to an absolute world position: Y first, then X,
// then Z. Digs through anything in the way (via Movement's forward/up/down).
fun navigateTo(m: Movement, targetX: Int, targetY: Int, targetZ: Int) {
    while (m.y < targetY) {
        m.up()
    }
    while (m.y > targetY) {
        m.down()
    }
    if (m.x != targetX) {
        val toward = if (targetX > m.x) 1 else 3
        m.faceHeading(toward)
        while (m.x != targetX) {
            m.forward()
        }
    }
    if (m.z != targetZ) {
        val toward = if (targetZ > m.z) 2 else 0
        m.faceHeading(toward)
        while (m.z != targetZ) {
            m.forward()
        }
    }
}

// -- Base servicing (fuel + item disposal) --

fun needsService(m: Movement): Boolean {
    val fuel = turtleGetFuelLevel()
    val distance = m.distanceHome()
    if (fuel < distance + FUEL_SAFETY_MARGIN) {
        return true
    }
    return inventoryFull()
}

fun inventoryFull(): Boolean {
    var slot = 1
    var full = true
    while (slot <= 16) {
        if (turtleGetItemCount(slot) == 0) {
            full = false
        }
        slot += 1
    }
    return full
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

    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m.faceHeading(m.homeHeading)

    dumpInventoryAtBase(m)
    refuelAtBase(m)

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

// Chest N (N=0 is the fuel chest itself, N>=1 are overflow chests) sits
// N blocks from the fuel chest, sideways along OVERFLOW_SIDE, one row back
// from the turtle's home line. Must be called with m at the home position.
fun goToChest(m: Movement, n: Int) {
    val sideways = (m.homeHeading + OVERFLOW_SIDE + 4) % 4
    val targetX = m.homeX + headingDx(sideways) * n
    val targetZ = m.homeZ + headingDz(sideways) * n
    navigateTo(m, targetX, m.homeY, targetZ)
    m.faceHeading((m.homeHeading + 2) % 4)
}

// Slot 1 is reserved for fuel (see refuelAtBase) — skipped here so leftover
// unburned charcoal (turtle.refuel() only consumes enough to top off the
// tank, and leaves the rest sitting in the slot) doesn't get hauled off to
// the overflow chest as if it were loot.
fun dumpInventoryAtBase(m: Movement) {
    var chestIndex = 1
    goToChest(m, chestIndex)

    var slot = 2
    var giveUp = false
    while (slot <= 16 && !giveUp) {
        val count = turtleGetItemCount(slot)
        if (count > 0) {
            turtleSelect(slot)
            var dropped = turtleDrop(64)
            while (!dropped && !giveUp) {
                chestIndex += 1
                if (chestIndex > MAX_OVERFLOW_CHESTS) {
                    println("All overflow chests full, stopping dump early.")
                    giveUp = true
                } else {
                    goToChest(m, chestIndex)
                    dropped = turtleDrop(64)
                }
            }
        }
        slot += 1
    }

    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m.faceHeading(m.homeHeading)
}

fun refuelAtBase(m: Movement) {
    m.faceHeading((m.homeHeading + 2) % 4)
    var attempts = 0
    var chestEmpty = false
    while (attempts < 16 && !chestEmpty) {
        turtleSelect(1)
        val pulled = turtleSuck(64)
        if (pulled) {
            turtleRefuel(64)
            attempts += 1
        } else {
            chestEmpty = true
        }
    }
    m.faceHeading(m.homeHeading)
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
