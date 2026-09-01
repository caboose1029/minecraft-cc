package programs

import common.turtleGetItemName
import common.turtleDigUp
import common.turtleGetFuelLevel
import common.turtleGetItemCount
import common.turtlePlaceUp
import common.turtleSelect
import common.turtleTransferTo
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

// Straight-down excavator (like CC's built-in excavate) that also lines
// the shaft with a spiral staircase and torches as it descends.
//
// Usage: excavatepro <width> [<length>] [<depth>]
//   - width: footprint size along the turtle's right-hand side at start.
//   - length (optional, defaults to width — square footprint): footprint
//     size along the turtle's forward direction at start.
//   - depth (optional, blocks below home's Y — always positive): stop
//     once this many levels below the start have been dug. Omit to dig
//     until bedrock (a fresh digDown() attempt fails). Relative to home
//     rather than an absolute world Y, so this works identically with or
//     without GPS (see calibrateMovement() in lib/Movement.kt).
//   Positional convention: arg COUNT decides meaning (1 = width only,
//   2 = width+length, 3 = width+length+depth) since there's no way to
//   tell a bare length from a bare depth apart otherwise. To request a
//   square hole to a specific depth, pass width twice: "5 5 50".
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
// time into CHEST_INTAKE_SLOT and sorted by name. TORCH_SLOT holds torch
// stock; cobblestone is never dumped as cargo (kept for steps, see
// shouldKeepSlot); everything else is general cargo, dumped to overflow
// chests. Chest logic itself (dumping, restocking, the fuel allowlist)
// is shared with Digsite via lib/Chest.kt — this file only decides
// which slots to keep off-limits and what to do with a non-fuel item.

const val EP_FUEL_SAFETY_MARGIN = 20
const val TORCH_INTERVAL = 6
const val TORCH_SLOT = 3
const val RESTOCK_ATTEMPTS = 32
const val COBBLESTONE_RESERVE = 64

fun main(args: Array<String>) {
    if (args.size < 1) {
        println("Usage: excavatepro <width> (<length>) (<depth>)")
        return
    }

    val width = args[1].toInt()
    val length = if (args.size >= 2) args[2].toInt() else width
    val hasDepth = args.size >= 3
    val depth = if (hasDepth) args[3].toInt() else 0

    println("Calibrating position via GPS...")
    val movement = calibrateMovement()
    if (movement.gpsEnabled) {
        println("Home at x=${movement.homeX} y=${movement.homeY} z=${movement.homeZ}")
    } else {
        println("No GPS available - running on dead reckoning only (no drift checks).")
    }

    // Relative to homeY rather than an absolute world Y, so this stop
    // condition means the same thing regardless of GPS availability.
    val yTarget = movement.homeY - depth

    val fwdDx = headingDx(movement.homeHeading)
    val fwdDz = headingDz(movement.homeHeading)
    val rightHeading = (movement.homeHeading + 1) % 4
    val rgtDx = headingDx(rightHeading)
    val rgtDz = headingDz(rightHeading)

    val xOther = movement.homeX + rgtDx * (width - 1) + fwdDx * (length - 1)
    val zOther = movement.homeZ + rgtDz * (width - 1) + fwdDz * (length - 1)
    val xSpan = IntSpan(movement.homeX, xOther)
    val zSpan = IntSpan(movement.homeZ, zOther)

    // Used only as a return-path waypoint (see navigateWithRecovery) —
    // every layer's digLayer sweep clears it along with everything else,
    // so it's guaranteed open at every height above wherever the turtle
    // currently is, unlike a direct path to home which could run into
    // this layer's own placed step/torch or, at the very bottom, bedrock
    // on multiple sides at once.
    val centerX = movement.homeX + rgtDx * (width / 2) + fwdDx * (length / 2)
    val centerZ = movement.homeZ + rgtDz * (width / 2) + fwdDz * (length / 2)

    val hasStaircase = width >= 2 && length >= 2

    var y = movement.homeY
    var step = 0
    var levelsSinceTorch = 0
    var digging = true

    while (digging) {
        epEnsureFuelAndSpace(movement, centerX, centerZ)
        var blocked = false
        if (!digLayer(movement, xSpan, zSpan, y, centerX, centerZ)) {
            blocked = true
        }

        // Nothing is placed at or above homeY: the topmost layer has
        // nothing pre-cleared above it to place into (there was no
        // previous iteration), and more importantly homeY is the fuel
        // chest's level — every overflow chest sits along exactly the
        // same right-hand line (dz=0) that segment 1 of the perimeter
        // walk below would otherwise place its first few steps/torches
        // into, burying the chest row (or home itself, at cell (0,0))
        // under a placed block. The first real step goes in once
        // excavation reaches the layer strictly below homeY.
        if (!blocked && hasStaircase && y + 1 < movement.homeY) {
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
            if (!navigateTo(movement, cellX, y, cellZ)) {
                blocked = true
            } else {
                // The step is placed on every transition, unconditionally
                // - it's the only thing making that transition climbable.
                // A torch used to be placed here INSTEAD of the step every
                // TORCH_INTERVAL layers, which left a gap in the staircase
                // at every one of those transitions (a torch isn't
                // something you can stand on). Torches are now a bonus,
                // placed at a separate cell below instead of competing
                // for this one.
                val stepSlot = findCobblestoneSlot()
                if (stepSlot == -1) {
                    println("No cobblestone on hand for a step at y=${y} - skipping this one.")
                } else {
                    turtleDigUp()
                    turtleSelect(stepSlot)
                    turtlePlaceUp()
                }

                levelsSinceTorch += 1
                if (levelsSinceTorch >= TORCH_INTERVAL) {
                    // Next perimeter cell over — not due for its own
                    // (real) step until the following, one-lower
                    // iteration, so there's no Y-level collision with it,
                    // and it's right next to the step just placed.
                    val torchCell = perimeterCell(step + 1, width, length)
                    val torchX = movement.homeX + rgtDx * torchCell.dx + fwdDx * torchCell.dz
                    val torchZ = movement.homeZ + rgtDz * torchCell.dx + fwdDz * torchCell.dz
                    if (!navigateTo(movement, torchX, y, torchZ)) {
                        println("Couldn't reach a torch position at y=${y} - skipping this one.")
                    } else {
                        ensureTorchSupply(movement, centerX, centerZ)
                        turtleDigUp()
                        turtleSelect(TORCH_SLOT)
                        turtlePlaceUp()
                    }
                    levelsSinceTorch = 0
                }
                step += 1
            }
        }

        if (blocked) {
            // Movement genuinely can't proceed — most likely bedrock (dig
            // succeeds into a pocket between two bedrock blocks, but the
            // move into the next one still fails). Stop and fall through
            // to the return-home below rather than retrying a move that
            // will just fail again.
            println("Movement blocked at y=${y} (bedrock or another undiggable obstruction) - stopping.")
            digging = false
        } else if (hasDepth && y <= yTarget) {
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
    if (!navigateWithRecovery(movement, centerX, centerZ)) {
        println("Could not reach the center column even after climbing - staying put.")
    } else {
        // From the center column, everything above was already fully
        // cleared by earlier digLayer calls, so a plain climb-then-walk
        // is safe the rest of the way.
        navigateTo(movement, centerX, movement.homeY, centerZ)
        navigateTo(movement, movement.homeX, movement.homeY, movement.homeZ)
        movement.faceHeading(movement.homeHeading)
        println("Home.")
    }
}

const val MAX_RECOVERY_ASCENTS = 32

// Tries to reach (targetX, targetZ) at the turtle's current height. If
// blocked — most likely wedged in a bedrock pocket, possibly boxed in on
// more than one side — climbs one block (retracing already-dug
// territory, since everything above the current layer was already fully
// swept) and retries at the new height, repeating until it succeeds or
// MAX_RECOVERY_ASCENTS is hit. Gives up (returns false) immediately if
// even climbing fails — that would mean something is blocking upward
// too, which shouldn't happen given every layer above is already clear,
// but there's no sense retrying a move that can't work.
fun navigateWithRecovery(m: Movement, targetX: Int, targetZ: Int): Boolean {
    if (navigateTo(m, targetX, m.y, targetZ)) {
        return true
    }
    var attempts = 0
    var reached = false
    while (!reached && attempts < MAX_RECOVERY_ASCENTS) {
        if (!m.up()) {
            return false
        }
        reached = navigateTo(m, targetX, m.y, targetZ)
        attempts += 1
    }
    return reached
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

// Returns false the moment any move is genuinely blocked (see
// navigateTo) — the layer may be left partially swept when that happens;
// the caller decides how to react (main() stops and returns home).
fun digLayer(m: Movement, xSpan: IntSpan, zSpan: IntSpan, y: Int, centerX: Int, centerZ: Int): Boolean {
    val xStep = stepFor(xSpan)
    val zStep = stepFor(zSpan)
    var x = xSpan.start
    var forwardZ = true
    var ok = true
    while (ok && !pastEnd(x, xSpan.finish, xStep)) {
        if (forwardZ) {
            var z = zSpan.start
            while (ok && !pastEnd(z, zSpan.finish, zStep)) {
                epEnsureFuelAndSpace(m, centerX, centerZ)
                if (!navigateTo(m, x, y, z)) {
                    ok = false
                }
                z += zStep
            }
        } else {
            var z = zSpan.finish
            while (ok && !pastEnd(z, zSpan.start, -zStep)) {
                epEnsureFuelAndSpace(m, centerX, centerZ)
                if (!navigateTo(m, x, y, z)) {
                    ok = false
                }
                z -= zStep
            }
        }
        forwardZ = !forwardZ
        x += xStep
    }
    return ok
}

// -- Base servicing (fuel + item disposal + torch restock) --

fun isTorchItem(name: String): Boolean {
    return name == "minecraft:torch"
}

// True if this slot's cobblestone falls within the first
// COBBLESTONE_RESERVE items counted across cobblestone-holding slots in
// order from slot 1 - roughly "the first stack". Mining constantly
// produces more cobblestone than a staircase actually needs, and it used
// to be kept in EVERY slot that held any, uncapped - cargo filled with
// cobblestone alone, triggering base trips (see epServiceAtBase) far
// more often than necessary. Recomputed fresh each call (a plain O(slot)
// scan) rather than tracked as running state, since shouldKeepSlot is
// called independently per slot by the shared cargoFull/dumpCargo loops
// in lib/Chest.kt with no state passed between calls.
fun withinCobblestoneReserve(slot: Int): Boolean {
    var s = 1
    var totalBefore = 0
    while (s < slot) {
        val name = turtleGetItemName(s)
        if (name != null && name == "minecraft:cobblestone") {
            totalBefore += turtleGetItemCount(s)
        }
        s += 1
    }
    return totalBefore < COBBLESTONE_RESERVE
}

// A slot's current content is worth keeping — never dumped as cargo —
// when: it's the transient intake slot and happens to be empty right
// now; it's the torch slot and actually holds a torch; or it holds
// cobblestone within the reserve (see withinCobblestoneReserve) — cargo
// beyond that reserve is treated as ordinary cargo like anything else.
// Checking by content rather than just slot number matters: a slot that
// doesn't hold its intended item (e.g. TORCH_SLOT holding ordinary mined
// cobblestone, because it happened to be the first empty slot the very
// first time the turtle mined something, before any chest visit ever
// occurred) is NOT protected — it's ordinary cargo that needs to get
// dumped so the slot is actually empty for the real item next visit.
fun shouldKeepSlot(slot: Int): Boolean {
    if (slot == CHEST_INTAKE_SLOT) {
        return turtleGetItemCount(slot) == 0
    }
    val name = turtleGetItemName(slot)
    if (name == null) {
        return slot == TORCH_SLOT
    }
    if (slot == TORCH_SLOT) {
        return isTorchItem(name)
    }
    if (name == "minecraft:cobblestone") {
        return withinCobblestoneReserve(slot)
    }
    return false
}

fun epNeedsService(m: Movement): Boolean {
    val fuel = turtleGetFuelLevel()
    val distance = m.distanceHome()
    if (fuel < distance + EP_FUEL_SAFETY_MARGIN) {
        return true
    }
    return cargoFull { slot -> shouldKeepSlot(slot) }
}

fun epEnsureFuelAndSpace(m: Movement, centerX: Int, centerZ: Int) {
    if (epNeedsService(m)) {
        epServiceAtBase(m, centerX, centerZ)
    }
}

fun ensureTorchSupply(m: Movement, centerX: Int, centerZ: Int) {
    val name = turtleGetItemName(TORCH_SLOT)
    val hasTorch = name != null && isTorchItem(name)
    if (!hasTorch) {
        epServiceAtBase(m, centerX, centerZ)
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

fun epServiceAtBase(m: Movement, centerX: Int, centerZ: Int) {
    println("Returning to base to refuel/dump inventory/restock supplies...")
    val returnX = m.x
    val returnY = m.y
    val returnZ = m.z

    // Route vertical travel through the center column - guaranteed clear
    // of placed steps at every height (see centerX/centerZ in main()) -
    // rather than climbing/descending straight from wherever the turtle
    // happens to be, which could dig straight through (destroy) a step
    // placed on an earlier, higher layer.
    navigateTo(m, centerX, m.y, centerZ)
    navigateTo(m, centerX, m.homeY, centerZ)

    dumpCargo(m) { slot -> shouldKeepSlot(slot) }
    restockAtChest(m)

    navigateTo(m, centerX, m.homeY, centerZ)
    navigateTo(m, centerX, returnY, centerZ)
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

// Anything restockChest's fuel allowlist doesn't already claim — a
// torch goes to TORCH_SLOT; anything else is left for restockChest to
// drop back and stop on. Written with an explicit `handled` local, not
// as an if/else expression — see AGENTS.md on why a multi-statement
// if/else branch used as a lambda's implicit return can transpile to
// invalid Lua.
fun restockAtChest(m: Movement) {
    restockChest(m, RESTOCK_ATTEMPTS) { name ->
        var handled = false
        if (isTorchItem(name)) {
            turtleSelect(CHEST_INTAKE_SLOT)
            // Checked, not assumed: turtleTransferTo() returns false (and
            // moves nothing) if TORCH_SLOT is occupied by something that
            // can't stack with a torch. Reporting handled=true anyway
            // would silently strand the torch in CHEST_INTAKE_SLOT, where
            // it'd eventually get swept up and dumped as ordinary cargo
            // on the next base trip instead of ever reaching TORCH_SLOT.
            handled = turtleTransferTo(TORCH_SLOT, 64)
        }
        handled
    }
}
