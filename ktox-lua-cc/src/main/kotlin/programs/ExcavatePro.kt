package programs

import common.turtleGetItemName
import common.turtleDigUp
import common.turtleDrop
import common.turtleGetFuelLevel
import common.turtleGetFuelLimit
import common.turtleGetItemCount
import common.turtlePlaceUp
import common.turtleRefuel
import common.turtleSelect
import common.turtleSuck
import common.turtleTransferTo
import lib.IntSpan
import lib.Movement
import lib.calibrateMovement
import lib.gpsLocate
import lib.headingDx
import lib.headingDz
import lib.navigateTo
import lib.pastEnd
import lib.stepFor

// Straight-down excavator (like CC's built-in excavate) that also lines
// the shaft with a spiral staircase and torches as it descends.
//
// Usage: excavatepro <width> [<length>] [<yTarget>]
//   - width: footprint size along the turtle's right-hand side at start.
//   - length (optional, defaults to width — square footprint): footprint
//     size along the turtle's forward direction at start.
//   - yTarget (optional, can be negative): absolute world Y to stop at.
//     Omit to dig until bedrock (a fresh digDown() attempt fails).
//   Positional convention: arg COUNT decides meaning (1 = width only,
//   2 = width+length, 3 = width+length+yTarget) since there's no way to
//   tell a bare length from a bare yTarget apart otherwise. To request a
//   square hole to a specific depth, pass width twice: "5 5 -50".
//
// Geometry: one step (cobblestone — see below) or, every TORCH_INTERVAL
// levels, one torch instead, is placed each Y-level at a position that
// walks around the footprint's perimeter, so the full descent traces one
// connected spiral (wrapping around for as many laps as the depth
// needs). It's placed into the CEILING of the layer just finished — i.e.
// the floor of the layer above, which was already fully cleared on the
// previous iteration — via turtlePlaceUp(), not down into ground the
// turtle is about to descend through. That means no bookkeeping is
// needed to protect it from the next layer's sweep: the layer it's
// placed into has already been swept and is never revisited, so there's
// nothing left to accidentally re-dig it. This whole placement scheme is
// the least-tested part of this program (no way to exercise real turtle
// placement outside a live world).
//
// Steps are plain cobblestone, not actual stair blocks: mining through
// stone always produces it, so it's entirely self-sustaining (no chest
// trip needed), and unlike a real stair block it has no facing to get
// placed wrong. It won't look like a proper sloped staircase, just
// ascending platforms, but it's a reliable climbable path.
//
// Supply: a chest at the turtle's start position holds charcoal and
// torches ("minecraft:torch") mixed together — sucked one item at a
// time into INTAKE_SLOT and sorted by name. TORCH_SLOT holds torch
// stock; cobblestone is never dumped as cargo (kept for steps, see
// shouldKeepSlot); everything else is general cargo, dumped to overflow
// chests exactly like Digsite.

// +1 = turtle's original right is "sideways toward the overflow row".
// Flip to -1 if the chests turn out to be laid out the other way in-game.
const val EP_OVERFLOW_SIDE = 1

const val EP_FUEL_SAFETY_MARGIN = 20
const val EP_MAX_OVERFLOW_CHESTS = 20
const val TORCH_INTERVAL = 6
const val TORCH_SLOT = 3
const val INTAKE_SLOT = 16
const val RESTOCK_ATTEMPTS = 32

fun main(args: Array<String>) {
    if (args.size < 1) {
        println("Usage: excavatepro <width> (<length>) (<yTarget>)")
        return
    }

    val width = args[1].toInt()
    val length = if (args.size >= 2) args[2].toInt() else width
    val hasYTarget = args.size >= 3
    var yTarget = 0
    if (hasYTarget) {
        yTarget = args[3].toInt()
    }

    println("Calibrating position via GPS...")
    val movement = calibrateMovement()
    if (movement == null) {
        println("GPS calibration failed - check the wireless/ender modem and GPS host coverage.")
        return
    }
    println("Home at x=${movement.homeX} y=${movement.homeY} z=${movement.homeZ}")

    val fwdDx = headingDx(movement.homeHeading)
    val fwdDz = headingDz(movement.homeHeading)
    val rightHeading = (movement.homeHeading + 1) % 4
    val rgtDx = headingDx(rightHeading)
    val rgtDz = headingDz(rightHeading)

    val xOther = movement.homeX + rgtDx * (width - 1) + fwdDx * (length - 1)
    val zOther = movement.homeZ + rgtDz * (width - 1) + fwdDz * (length - 1)
    val xSpan = IntSpan(movement.homeX, xOther)
    val zSpan = IntSpan(movement.homeZ, zOther)

    val hasStaircase = width >= 2 && length >= 2

    var y = movement.homeY
    var step = 0
    var levelsSinceTorch = 0
    var isFirstLayer = true
    var digging = true

    while (digging) {
        epEnsureFuelAndSpace(movement)
        digLayer(movement, xSpan, zSpan, y)

        // Nothing to attach a step to above the very first (topmost) layer.
        if (hasStaircase && !isFirstLayer) {
            val cell = perimeterCell(step, width, length)
            // cell.dx/dz are offsets along the right/forward axes (the same
            // basis used to build xSpan/zSpan above) — NOT along x/z
            // directly. Which world axis "right" and "forward" map to
            // depends on the turtle's starting heading (north/south: right
            // is x, forward is z; east/west: the other way around), so
            // reusing xSpan/zSpan's step values here would silently swap
            // width and length whenever the turtle started facing east or
            // west. rgtDx/rgtDz/fwdDx/fwdDz already encode that mapping
            // correctly — reuse them instead.
            val cellX = movement.homeX + rgtDx * cell.dx + fwdDx * cell.dz
            val cellZ = movement.homeZ + rgtDz * cell.dx + fwdDz * cell.dz
            navigateTo(movement, cellX, y, cellZ)

            levelsSinceTorch += 1
            if (levelsSinceTorch >= TORCH_INTERVAL) {
                ensureTorchSupply(movement)
                turtleDigUp()
                turtleSelect(TORCH_SLOT)
                turtlePlaceUp()
                levelsSinceTorch = 0
            } else {
                val stepSlot = findCobblestoneSlot()
                if (stepSlot == -1) {
                    println("No cobblestone on hand for a step at y=${y} - skipping this one.")
                } else {
                    turtleDigUp()
                    turtleSelect(stepSlot)
                    turtlePlaceUp()
                }
            }

            step += 1
        }
        isFirstLayer = false

        if (hasYTarget && y <= yTarget) {
            digging = false
        } else {
            val moved = movement.down()
            y = movement.y
            if (!moved) {
                println("Hit bedrock (or an undiggable block) at y=${y}.")
                digging = false
            }
        }
    }

    println("Excavation complete. Returning home...")
    navigateTo(movement, movement.homeX, movement.homeY, movement.homeZ)
    movement.faceHeading(movement.homeHeading)
    println("Home.")
}

// -- Perimeter walk --
//
// Cell(0,0) is the turtle's starting corner. Walks clockwise: along the
// "width" edge, then the "length" edge, back along "width", back along
// "length" — wrapping via modulo for however many laps the depth needs.
// Only valid for width >= 2 and length >= 2 (checked by the caller).

data class Cell(val dx: Int, val dz: Int)

fun perimeterLength(width: Int, length: Int): Int {
    return 2 * width + 2 * length - 4
}

fun perimeterCell(step: Int, width: Int, length: Int): Cell {
    val p = perimeterLength(width, length)
    var i = step % p
    if (i < width) {
        return Cell(i, 0)
    }
    i -= width
    if (i < length - 1) {
        return Cell(width - 1, i + 1)
    }
    i -= (length - 1)
    if (i < width - 1) {
        return Cell(width - 2 - i, length - 1)
    }
    i -= (width - 1)
    return Cell(0, length - 2 - i)
}

// -- Full-layer excavation --

fun digLayer(m: Movement, xSpan: IntSpan, zSpan: IntSpan, y: Int) {
    val xStep = stepFor(xSpan)
    val zStep = stepFor(zSpan)
    var x = xSpan.start
    var forwardZ = true
    while (!pastEnd(x, xSpan.finish, xStep)) {
        if (forwardZ) {
            var z = zSpan.start
            while (!pastEnd(z, zSpan.finish, zStep)) {
                epEnsureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z += zStep
            }
        } else {
            var z = zSpan.finish
            while (!pastEnd(z, zSpan.start, -zStep)) {
                epEnsureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z -= zStep
            }
        }
        forwardZ = !forwardZ
        x += xStep
    }
}

// -- Base servicing (fuel + item disposal + torch restock) --

fun isTorchItem(name: String): Boolean {
    return name == "minecraft:torch"
}

// A slot's current content is worth keeping — never dumped as cargo —
// when: it's the transient intake slot and happens to be empty right
// now; it's the torch slot and actually holds a torch; or it holds
// cobblestone, kept around as step material regardless of which slot it
// landed in (mining always produces some, so there's no dedicated slot
// to protect — see findCobblestoneSlot()). Checking by content rather
// than just slot number matters: a slot ktoxGetItemName doesn't
// recognize as its intended item (e.g. TORCH_SLOT holding ordinary
// mined cobblestone, because it happened to be the first empty slot the
// very first time the turtle mined something, before any chest visit
// ever occurred) is NOT protected — it's ordinary cargo that needs to
// get dumped so the slot is actually empty for the real item next visit.
fun shouldKeepSlot(slot: Int): Boolean {
    if (slot == INTAKE_SLOT) {
        return turtleGetItemCount(slot) == 0
    }
    val name = turtleGetItemName(slot)
    if (name == null) {
        return slot == TORCH_SLOT
    }
    if (slot == TORCH_SLOT && isTorchItem(name)) {
        return true
    }
    return name == "minecraft:cobblestone"
}

fun epNeedsService(m: Movement): Boolean {
    val fuel = turtleGetFuelLevel()
    val distance = m.distanceHome()
    if (fuel < distance + EP_FUEL_SAFETY_MARGIN) {
        return true
    }
    return epInventoryFull()
}

fun epInventoryFull(): Boolean {
    var slot = 1
    var full = true
    while (slot <= 16) {
        if (!shouldKeepSlot(slot)) {
            if (turtleGetItemCount(slot) == 0) {
                full = false
            }
        }
        slot += 1
    }
    return full
}

fun epEnsureFuelAndSpace(m: Movement) {
    if (epNeedsService(m)) {
        epServiceAtBase(m)
    }
}

fun ensureTorchSupply(m: Movement) {
    val name = turtleGetItemName(TORCH_SLOT)
    val hasTorch = name != null && isTorchItem(name)
    if (!hasTorch) {
        epServiceAtBase(m)
    }
}

// Searches inventory for a slot already holding cobblestone (from mining
// through stone) to use as step material. Returns -1 if the turtle
// genuinely has none right now — rare, but possible early in a dig or in
// a stone-poor area.
fun findCobblestoneSlot(): Int {
    var slot = 1
    var found = -1
    while (slot <= 16 && found == -1) {
        if (turtleGetItemCount(slot) > 0) {
            val name = turtleGetItemName(slot)
            if (name != null && name == "minecraft:cobblestone") {
                found = slot
            }
        }
        slot += 1
    }
    return found
}

fun epServiceAtBase(m: Movement) {
    println("Returning to base to refuel/dump inventory/restock supplies...")
    val returnX = m.x
    val returnY = m.y
    val returnZ = m.z

    epDumpInventoryAtBase(m)
    restockAtChest(m)

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

// Chest N (N=0 is the fuel/supply chest itself, N>=1 are overflow chests)
// sits N blocks from the supply chest, sideways along EP_OVERFLOW_SIDE, one
// row back from the turtle's home line. Must be called with m at home.
fun epGoToChest(m: Movement, n: Int) {
    val sideways = (m.homeHeading + EP_OVERFLOW_SIDE + 4) % 4
    val targetX = m.homeX + headingDx(sideways) * n
    val targetZ = m.homeZ + headingDz(sideways) * n
    navigateTo(m, targetX, m.homeY, targetZ)
    m.faceHeading((m.homeHeading + 2) % 4)
}

// See shouldKeepSlot() — torch stock, cobblestone (step material), and
// the empty intake slot are never dumped as cargo.
fun epDumpInventoryAtBase(m: Movement) {
    var chestIndex = 1
    epGoToChest(m, chestIndex)

    var slot = 1
    var giveUp = false
    while (slot <= 16 && !giveUp) {
        if (!shouldKeepSlot(slot)) {
            val count = turtleGetItemCount(slot)
            if (count > 0) {
                turtleSelect(slot)
                var dropped = turtleDrop(64)
                while (!dropped && !giveUp) {
                    chestIndex += 1
                    if (chestIndex > EP_MAX_OVERFLOW_CHESTS) {
                        println("All overflow chests full, stopping dump early.")
                        giveUp = true
                    } else {
                        epGoToChest(m, chestIndex)
                        dropped = turtleDrop(64)
                    }
                }
            }
        }
        slot += 1
    }

    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m.faceHeading(m.homeHeading)
}

// Sucks from the mixed supply chest one item at a time, sorting by name:
// charcoal (or any valid furnace fuel) is burned immediately, torches go
// to TORCH_SLOT, anything else gets put back.
//
// turtle.suck() always pulls whatever's in the chest's lowest-indexed
// non-empty slot — there's no way to ask for a specific item, and
// turtle.drop() puts an unwanted item right back into that same slot.
// So if the chest's front item can't be used *right now* (most likely:
// charcoal, but the tank's already topped off) and isn't a torch either,
// dropping it back just re-surfaces the identical stack on the next
// suck() — an unwinnable loop, not a transient hiccup. Detect that and
// stop this visit early rather than burning the whole attempt budget
// spinning on one stuck stack.
fun restockAtChest(m: Movement) {
    epGoToChest(m, 0)
    var attempts = 0
    var chestEmpty = false
    var stuck = false
    while (attempts < RESTOCK_ATTEMPTS && !chestEmpty && !stuck) {
        turtleSelect(INTAKE_SLOT)
        val pulled = turtleSuck(64)
        if (!pulled) {
            chestEmpty = true
        } else {
            turtleSelect(INTAKE_SLOT)
            if (turtleGetFuelLevel() < turtleGetFuelLimit()) {
                turtleRefuel(64)
            }
            val name = turtleGetItemName(INTAKE_SLOT)
            if (name == null) {
                // fully consumed as fuel - nothing left to sort
            } else if (isTorchItem(name)) {
                turtleSelect(INTAKE_SLOT)
                turtleTransferTo(TORCH_SLOT, 64)
            } else {
                turtleSelect(INTAKE_SLOT)
                turtleDrop(64)
                stuck = true
                println("Chest's next item isn't usable right now (fuel topped off?) and torches may be stuck behind it - stopping restock early.")
            }
        }
        attempts += 1
    }
    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m.faceHeading(m.homeHeading)
}
