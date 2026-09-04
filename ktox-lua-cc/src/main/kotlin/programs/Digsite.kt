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
import lib.SHAPE_CIRCLE
import lib.SHAPE_RIGHT_TRIANGLE
import lib.SHAPE_TRIANGLE
import lib.shapeRowBounds
import lib.shapeRowCount
import lib.shapeSpineColumn
import lib.stepFor

// Footprint-driven excavator. Named "digsite" (not "excavate") to avoid
// clashing with CC:Tweaked's built-in turtle/excavate.lua program.
//
// Usage: digsite <width> (<length>) (<height>)
//        digsite -t <side> (<height>)
//        digsite -rt <side> (<height>)
//        digsite -c <radius> (<height>)
//        digsite -h
//   - width: footprint size along the turtle's right-hand side at start.
//   - length (optional, defaults to width — square footprint): footprint
//     size along the turtle's forward direction at start.
//   - height (optional, signed — positive climbs, negative descends): if
//     given, "room" mode — hollows out that exact bounded x/y/z volume
//     (homeY to homeY+height), one full horizontal layer at a time. If
//     omitted, "clear cut" mode — the turtle's own starting Y is the
//     FLOOR (never dug below); it sweeps full layers upward from there
//     through CLEAR_CUT_HEIGHT blocks (stopping early once a whole layer
//     digs nothing — see clearCut() below). Full-layer sweeps (not
//     per-column "dig until first gap") so overhangs/floating terrain get
//     cleared too.
//   All of width/length/height/side/radius are relative to home (the
//   turtle's start position/heading), like ExcavatePro's
//   width/length/depth, rather than absolute world coordinates — so this
//   works identically with or without GPS (see calibrateMovement() in
//   lib/Movement.kt). Replaces an earlier x1:x2/z1:z2
//   absolute-world-coordinate interface that broke (silently pointed at
//   meaningless/wrong ground) the moment GPS was unavailable.
//   Positional convention for the plain rectangle form: arg COUNT decides
//   meaning (1 = width only, 2 = width+length, 3 = width+length+height),
//   matching ExcavatePro, since there's no way to tell a bare length from
//   a bare height apart otherwise. -t/-rt/-c instead take a single
//   side/radius value in that slot (no separate "length" — see
//   lib/Shape.kt for what each shape looks like):
//     -t   isoceles triangle, base = <side>, apex pointing away from home.
//     -rt  right isoceles triangle (both legs = <side>), right-angle
//          vertex at home.
//     -c   filled circle of the given <radius>, centered <radius> blocks
//          right and forward of home.
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

fun printUsage() {
    println("Usage: digsite <width> (<length>) (<height>)")
    println("       digsite -t <side> (<height>)   isoceles triangle")
    println("       digsite -rt <side> (<height>)  right triangle (equal legs)")
    println("       digsite -c <radius> (<height>) circle")
    println("       digsite -h                     show this help")
    println("height omitted: clear-cut mode, sweeps up from home Y until a")
    println("layer digs nothing. height given: room mode, exact bounded box.")
}

fun main(args: Array<String>) {
    if (args.size < 1) {
        printUsage()
        return
    }

    val flag = args[1]
    if (flag == "-h" || flag == "--help") {
        printUsage()
        return
    }

    val isShape = flag == "-t" || flag == "-rt" || flag == "-c"
    if (isShape && args.size < 2) {
        printUsage()
        return
    }

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

    if (isShape) {
        val shape = shapeForFlag(flag)
        val size = args[2].toInt()
        val hasHeight = args.size >= 3
        val height = if (hasHeight) args[3].toInt() else 0

        val layerFn = { mv: Movement, y: Int ->
            digsiteLayerShaped(mv, movement.homeX, movement.homeZ, rgtDx, rgtDz, fwdDx, fwdDz, shape, size, y)
        }

        if (hasHeight) {
            val ySpan = IntSpan(movement.homeY, movement.homeY + height)
            digsiteRoom(movement, ySpan, layerFn)
        } else {
            clearCut(movement, layerFn)
        }
    } else {
        val width = args[1].toInt()
        val length = if (args.size >= 2) args[2].toInt() else width
        val hasHeight = args.size >= 3
        val height = if (hasHeight) args[3].toInt() else 0

        val xOther = movement.homeX + rgtDx * (width - 1) + fwdDx * (length - 1)
        val zOther = movement.homeZ + rgtDz * (width - 1) + fwdDz * (length - 1)
        val xSpan = IntSpan(movement.homeX, xOther)
        val zSpan = IntSpan(movement.homeZ, zOther)

        val layerFn = { mv: Movement, y: Int -> digsiteLayer(mv, xSpan, zSpan, y) }

        if (hasHeight) {
            val ySpan = IntSpan(movement.homeY, movement.homeY + height)
            digsiteRoom(movement, ySpan, layerFn)
        } else {
            clearCut(movement, layerFn)
        }
    }

    println("Excavation complete. Returning home...")
    navigateTo(movement, movement.homeX, movement.homeY, movement.homeZ)
    movement.faceHeading(movement.homeHeading)
    println("Home.")
}

fun shapeForFlag(flag: String): String {
    if (flag == "-t") {
        return SHAPE_TRIANGLE
    }
    if (flag == "-rt") {
        return SHAPE_RIGHT_TRIANGLE
    }
    return SHAPE_CIRCLE
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

// -- Room mode: bounded y-range excavation, one full layer at a time --
//
// The footprint itself (rectangle vs. a lib/Shape.kt shape) is entirely
// the caller's concern, via layerFn — this only walks the y-range and
// invokes it once per layer.

fun digsiteRoom(m: Movement, ySpan: IntSpan, layerFn: (Movement, Int) -> Unit) {
    val yStep = stepFor(ySpan)
    var y = ySpan.start
    while (!pastEnd(y, ySpan.finish, yStep)) {
        layerFn(m, y)
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

// -- Clear-cut mode: footprint (rectangle or shaped), floor = home Y,
// full layers upward --
//
// Sweeps full layers upward from home Y (the floor), one layerFn call per
// layer like digsiteRoom would over a fixed y-range, but bails out early
// once a whole layer dug nothing — that means the turtle has climbed
// above the terrain (open air/sky on every column), so grinding through
// the remaining CLEAR_CUT_HEIGHT layers just to confirm it's still empty
// wastes fuel/time for no benefit. Sweeping every layer in full (rather
// than following each column up until the first gap) is what actually
// clears overhangs/floating terrain — a gap below a column doesn't stop
// that column's higher blocks from being dug, since every other column
// at that same height gets visited regardless — the per-layer dug-count
// check preserves that: a layer only counts as "empty" when NONE of its
// columns dug anything.
//
// The floor layer itself is never skipped by this check even if it happens
// to dig nothing (e.g. the turtle started standing on bedrock/already-clear
// ground) — the loop always completes at least one full layer before the
// empty check can trigger a stop.

fun clearCut(m: Movement, layerFn: (Movement, Int) -> Unit) {
    val floorY = m.homeY
    val yStep = stepFor(IntSpan(floorY, floorY + CLEAR_CUT_HEIGHT))
    var y = floorY
    while (!pastEnd(y, floorY + CLEAR_CUT_HEIGHT, yStep)) {
        val dugBefore = m.blocksDug
        layerFn(m, y)
        if (m.blocksDug == dugBefore) {
            println("Layer at y=${y} dug nothing - assuming clear of terrain, stopping.")
            return
        }
        y += yStep
    }
}

// -- Shaped footprints (triangle/right-triangle/circle) --
//
// Sweeps one layer of a lib/Shape.kt footprint at the given world y. Each
// row (stepping along the forward axis from home) has its own included
// column range (shapeRowBounds) — the turtle transits between rows via
// the shape's spine column (shapeSpineColumn), which is guaranteed part
// of every row, then sweeps outward from the spine to each edge of the
// row's range and back. Never crosses a cell outside the shape, unlike a
// naive full-bounding-box sweep would.

fun digsiteLayerShaped(
    m: Movement,
    homeX: Int,
    homeZ: Int,
    rgtDx: Int,
    rgtDz: Int,
    fwdDx: Int,
    fwdDz: Int,
    shape: String,
    size: Int,
    y: Int,
) {
    val spine = shapeSpineColumn(shape, size)
    val rows = shapeRowCount(shape, size)
    var row = 0
    while (row < rows) {
        val bounds = shapeRowBounds(shape, size, row)
        if (bounds != null) {
            val spineX = homeX + rgtDx * spine + fwdDx * row
            val spineZ = homeZ + rgtDz * spine + fwdDz * row
            ensureFuelAndSpace(m)
            navigateTo(m, spineX, y, spineZ)

            var col = spine
            while (col > bounds.start) {
                col -= 1
                ensureFuelAndSpace(m)
                navigateTo(m, homeX + rgtDx * col + fwdDx * row, y, homeZ + rgtDz * col + fwdDz * row)
            }
            ensureFuelAndSpace(m)
            navigateTo(m, spineX, y, spineZ)

            col = spine
            while (col < bounds.finish) {
                col += 1
                ensureFuelAndSpace(m)
                navigateTo(m, homeX + rgtDx * col + fwdDx * row, y, homeZ + rgtDz * col + fwdDz * row)
            }
            ensureFuelAndSpace(m)
            navigateTo(m, spineX, y, spineZ)
        }
        row += 1
    }
}
