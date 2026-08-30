package programs

import common.turtleDrop
import common.turtleGetFuelLevel
import common.turtleGetItemCount
import common.turtleInspectUpName
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
//     the horizontal footprint.
//   - If a y-range is given: "room" mode — hollows out that exact bounded
//     x/y/z volume.
//   - If no y-range is given: "clear cut" mode — the turtle's own starting
//     Y is the FLOOR (never dug below); each column is cleared upward
//     until there's no block above (natural terrain top for that column,
//     following only what's attached to the ground — floating structures
//     above open air are left untouched).
//
// Fueling/storage: assumes a fuel chest directly behind the turtle's start
// position, with overflow chests extending from there. ASSUMPTION (easy to
// flip if wrong — see OVERFLOW_SIDE below): overflow chests extend toward
// the turtle's original right-hand side.

data class IntSpan(val lo: Int, val hi: Int)

// ktox does not offset List/Array [] indexing — indices below are 1-based
// on purpose. See AGENTS.md.
fun parseSpan(raw: String): IntSpan {
    val parts = raw.split(":")
    val a = parts[1].toInt()
    val b = parts[2].toInt()
    return if (a <= b) IntSpan(a, b) else IntSpan(b, a)
}

// +1 = turtle's original right is "sideways toward the overflow row".
// Flip to -1 if the chests turn out to be laid out the other way in-game.
const val OVERFLOW_SIDE = 1

const val FUEL_SAFETY_MARGIN = 20
const val MAX_OVERFLOW_CHESTS = 20

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

    println("Excavation complete.")
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

fun dumpInventoryAtBase(m: Movement) {
    var chestIndex = 1
    goToChest(m, chestIndex)

    var slot = 1
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

// -- Room mode: bounded x/y/z box excavation --

fun digsiteRoom(m: Movement, xSpan: IntSpan, ySpan: IntSpan, zSpan: IntSpan) {
    var y = ySpan.lo
    while (y <= ySpan.hi) {
        digsiteLayer(m, xSpan, zSpan, y)
        y += 1
    }
}

fun digsiteLayer(m: Movement, xSpan: IntSpan, zSpan: IntSpan, y: Int) {
    var x = xSpan.lo
    var forwardZ = true
    while (x <= xSpan.hi) {
        if (forwardZ) {
            var z = zSpan.lo
            while (z <= zSpan.hi) {
                ensureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z += 1
            }
        } else {
            var z = zSpan.hi
            while (z >= zSpan.lo) {
                ensureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z -= 1
            }
        }
        forwardZ = !forwardZ
        x += 1
    }
}

// -- Clear-cut mode: x/z footprint, floor = home Y, terrain-following --

fun clearCut(m: Movement, xSpan: IntSpan, zSpan: IntSpan) {
    val floorY = m.homeY
    var x = xSpan.lo
    var forwardZ = true
    while (x <= xSpan.hi) {
        if (forwardZ) {
            var z = zSpan.lo
            while (z <= zSpan.hi) {
                ensureFuelAndSpace(m)
                clearColumn(m, x, floorY, z)
                z += 1
            }
        } else {
            var z = zSpan.hi
            while (z >= zSpan.lo) {
                ensureFuelAndSpace(m)
                clearColumn(m, x, floorY, z)
                z -= 1
            }
        }
        forwardZ = !forwardZ
        x += 1
    }
}

fun clearColumn(m: Movement, x: Int, floorY: Int, z: Int) {
    navigateTo(m, x, floorY, z)
    var clearing = true
    while (clearing) {
        val above = turtleInspectUpName()
        if (above == null) {
            clearing = false
        } else {
            m.up()
        }
    }
}
