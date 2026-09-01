package programs

import common.readInput
import common.turtleGetFuelLevel
import common.turtleInspectDownName
import common.turtleInspectName
import common.turtleInspectUpName
import lib.CHEST_INTAKE_SLOT
import lib.Movement
import lib.calibrateMovement
import lib.cargoFull
import lib.dumpCargo
import lib.gpsLocate
import lib.headingDx
import lib.headingDz
import lib.navigateTo
import lib.restockChest

// Branch-mining ore finder: bores parallel 1-wide, 1-tall tunnels at two
// fixed depths favorable for diamonds, and chases any valuable ore
// (diamond, redstone, gold, and other metals — see isValuableOre) found
// along the way to clear out its whole vein before resuming.
//
// Usage: diamondfinder <branchLength> <branchCount> (<spacing>)
//   - branchLength: how many blocks long each borehole tunnel is.
//   - branchCount: how many parallel boreholes to bore per tier.
//   - spacing (optional, default 3): blocks of unmined stone left
//     between adjacent boreholes within a tier. Small enough that ore
//     roughly in the middle of the gap is still within inspection range
//     (up/down/left/right, 1 block) of at least one borehole wall.
//
// Depth: two fixed tiers, Y = -56 and -59, clustered near -59 — the
// sharp density peak for diamond generation in modern (1.18+) world
// gen — rather than spread toward the surface (an earlier version went
// up to -51 to dodge a lava-heavy layer around -54, but turtles don't
// care about lava, so there was nothing to actually dodge, just fewer
// diamonds per block dug the further from -59 it went). A 3-block gap
// between the two tiers is deliberate, not just "close together": the
// 2 blocks strictly between them (-57, -58) are each directly reached
// by one tier's up/down inspection (-56's down-check hits -57; -59's
// up-check hits -58) — full coverage, no blind spot. A 4-block gap
// (e.g. -55/-59) leaves the single middle block uninspected, relying on
// a vein spanning multiple Y levels to still get caught by an adjacent
// tier; 3 blocks avoids needing that assumption at all, for one less
// block of total vertical range. Not currently configurable — see
// tierY() to adjust.
//
// GPS: these tier depths are real absolute world Y, not relative offsets
// like Digsite/ExcavatePro's spans — dead reckoning alone can't tell you
// how deep -59 is from an unknown start. If GPS calibration fails, this
// program prompts for the turtle's actual Y via read() and aborts on
// invalid/missing input rather than digging to a meaningless depth.
//
// Each borehole is bored one block at a time; at every position, the
// turtle checks up, down, left, and right (never behind — that's
// already-mined air) for valuable ore, and follows any found vein via
// recursive backtracking (see followVein) before resuming the bore.
// Fuel/cargo servicing reuses the same lib/Chest.kt machinery as
// Digsite/ExcavatePro — this file only supplies its own keep/onOther
// policy (charcoal only, no torches/stairs/step-material concept here)
// and its own thin df-prefixed wrapper (named distinctly from Digsite's
// existing needsService/ensureFuelAndSpace/serviceAtBase — same package,
// see AGENTS.md on why that collision would be a real compile error).
//
// Return trip: like ExcavatePro, the direct path home could be blocked
// by a local bedrock pocket (most likely on the return from deep inside
// a vein chase near the lowest tier). Unlike ExcavatePro there's no
// always-open "center column" to retreat to — each borehole is its own
// isolated 1-wide tunnel — so recovery just climbs straight up and
// retries toward home directly; ordinary stone digs through fine via
// Movement's own auto-dig, so climbing only matters for escaping an
// actual bedrock formation, which is typically a small local pocket, not
// a full impassable layer.

// Substring match rather than an exhaustive equality list: every ore here
// follows Minecraft's "minecraft:[deepslate_]<ore>_ore" naming, so this
// catches deepslate/stone variants (and any future variant) alike without
// needing both spelled out - a gap that would otherwise silently miss
// real ore (see AGENTS.md-adjacent history: deepslate_gold_ore was
// already listed explicitly, but this makes that kind of gap impossible
// instead of just checking it off one variant at a time).
fun isValuableOre(name: String): Boolean {
    if (name.contains("diamond")) {
        return true
    }
    if (name.contains("redstone")) {
        return true
    }
    if (name.contains("gold")) {
        return true
    }
    if (name.contains("iron")) {
        return true
    }
    if (name.contains("copper")) {
        return true
    }
    if (name.contains("lapis")) {
        return true
    }
    if (name.contains("emerald")) {
        return true
    }
    return false
}

const val DF_FUEL_SAFETY_MARGIN = 20
const val DF_RESTOCK_ATTEMPTS = 16
const val MAX_VEIN_DEPTH = 24
const val MAX_RETURN_ASCENTS = 32

fun main(args: Array<String>) {
    if (args.size < 2) {
        println("Usage: diamondfinder <branchLength> <branchCount> (<spacing>)")
        return
    }

    val branchLength = args[1].toInt()
    val branchCount = args[2].toInt()
    val spacing = if (args.size >= 3) args[3].toInt() else 3

    println("Calibrating position via GPS...")
    var movement = calibrateMovement()
    if (movement.gpsEnabled) {
        println("Home at x=${movement.homeX} y=${movement.homeY} z=${movement.homeZ}")
    } else {
        // Unlike Digsite/ExcavatePro, the tier depths below (tierY()) are
        // fixed absolute world Y values chosen for real diamond generation
        // - there's no relative substitute for "how deep is Y=-59 from
        // here" without knowing the turtle's actual world Y. Ask for it
        // rather than digging to a meaningless (or bedrock-piercing)
        // depth.
        println("No GPS available - DiamondFinder targets real diamond-rich depths (y=-56/-59) and needs the turtle's actual world Y to do that.")
        println("Enter the turtle's current Y coordinate:")
        val input = readInput()
        val manualY = input.toIntOrNull()
        if (manualY == null) {
            println("Invalid Y value entered - aborting.")
            return
        }
        movement = Movement(0, manualY, 0, 0, 0, manualY, 0, 0, false)
        println("Using manual y=${manualY} as home.")
    }

    val fwdDx = headingDx(movement.homeHeading)
    val fwdDz = headingDz(movement.homeHeading)
    val rightHeading = (movement.homeHeading + 1) % 4
    val rgtDx = headingDx(rightHeading)
    val rgtDz = headingDz(rightHeading)

    var tierIndex = 1
    while (tierIndex <= 2) {
        val tierY = tierY(tierIndex)
        println("Moving to tier ${tierIndex} (y=${tierY})...")
        navigateTo(movement, movement.homeX, tierY, movement.homeZ)

        var branch = 0
        while (branch < branchCount) {
            val lateralOffset = branch * (spacing + 1)
            val startX = movement.homeX + rgtDx * lateralOffset
            val startZ = movement.homeZ + rgtDz * lateralOffset
            dfEnsureFuelAndSpace(movement)
            navigateTo(movement, startX, tierY, startZ)
            movement.faceHeading(movement.homeHeading)
            boreBranch(movement, branchLength)
            branch += 1
        }

        tierIndex += 1
    }

    println("Diamond survey complete. Returning home...")
    if (!returnHomeWithRecovery(movement)) {
        println("Could not fully reach home - staying put.")
    } else {
        movement.faceHeading(movement.homeHeading)
        println("Home.")
    }
}

fun tierY(tierIndex: Int): Int {
    if (tierIndex == 1) {
        return -56
    }
    return -59
}

// -- Boring + vein-following --

fun boreBranch(m: Movement, length: Int) {
    var i = 0
    var blocked = false
    while (i < length && !blocked) {
        dfEnsureFuelAndSpace(m)
        if (!m.forward()) {
            println("Blocked while boring at x=${m.x} y=${m.y} z=${m.z} - stopping this branch.")
            blocked = true
        } else {
            followVein(m, 0)
            i += 1
        }
    }
}

// Checks up/down/left/right/forward from the turtle's current position
// and chases any valuable ore found (digs in, recurses one level
// deeper, then backs out the same way) before returning — so by the
// time this returns, the turtle is back exactly where this call found
// it, regardless of how far the vein wandered. Bounded by
// MAX_VEIN_DEPTH so an unusually large vein (or, in principle, a loop of
// ore doubling back on itself) can't wander indefinitely and burn
// through fuel chasing it.
//
// Called with depth=0 after every step of the main bore (checking
// "forward" there just means the next not-yet-dug tunnel block — a
// harmless early check, since the bore loop was about to dig it anyway).
fun followVein(m: Movement, depth: Int) {
    if (depth >= MAX_VEIN_DEPTH) {
        return
    }
    dfEnsureFuelAndSpace(m)

    val upName = turtleInspectUpName()
    if (upName != null && isValuableOre(upName)) {
        if (m.up()) {
            followVein(m, depth + 1)
            m.down()
        }
    }

    val downName = turtleInspectDownName()
    if (downName != null && isValuableOre(downName)) {
        if (m.down()) {
            followVein(m, depth + 1)
            m.up()
        }
    }

    m.turnLeft()
    val leftName = turtleInspectName()
    if (leftName != null && isValuableOre(leftName)) {
        if (m.forward()) {
            followVein(m, depth + 1)
            m.back()
        }
    }
    m.turnRight()

    m.turnRight()
    val rightName = turtleInspectName()
    if (rightName != null && isValuableOre(rightName)) {
        if (m.forward()) {
            followVein(m, depth + 1)
            m.back()
        }
    }
    m.turnLeft()

    val fwdName = turtleInspectName()
    if (fwdName != null && isValuableOre(fwdName)) {
        if (m.forward()) {
            followVein(m, depth + 1)
            m.back()
        }
    }
}

// Tries the direct path home; if blocked (most likely a local bedrock
// pocket), climbs one block — ordinary stone digs through fine via
// Movement's own auto-dig, so this only matters for actually escaping a
// bedrock formation — and retries, repeating (bounded by
// MAX_RETURN_ASCENTS) until it clears whatever's blocking it.
fun returnHomeWithRecovery(m: Movement): Boolean {
    if (navigateTo(m, m.homeX, m.homeY, m.homeZ)) {
        return true
    }
    var attempts = 0
    var reached = false
    while (!reached && attempts < MAX_RETURN_ASCENTS) {
        if (!m.up()) {
            return false
        }
        reached = navigateTo(m, m.homeX, m.homeY, m.homeZ)
        attempts += 1
    }
    return reached
}

// -- Base servicing (fuel + cargo disposal; charcoal-only chest) --

fun dfKeepSlot(slot: Int): Boolean {
    return slot == CHEST_INTAKE_SLOT
}

fun dfEnsureFuelAndSpace(m: Movement) {
    val fuel = turtleGetFuelLevel()
    val distance = m.distanceHome()
    var needsService = fuel < distance + DF_FUEL_SAFETY_MARGIN
    if (!needsService) {
        needsService = cargoFull { slot -> dfKeepSlot(slot) }
    }
    if (needsService) {
        println("Returning to base to refuel/dump inventory...")
        val returnX = m.x
        val returnY = m.y
        val returnZ = m.z

        dumpCargo(m) { slot -> dfKeepSlot(slot) }
        restockChest(m, DF_RESTOCK_ATTEMPTS) { name -> false }

        navigateTo(m, returnX, returnY, returnZ)

        // Drift safety check after the round trip — only meaningful when
        // GPS was available at calibration; otherwise there's no ground
        // truth to check against.
        if (m.gpsEnabled) {
            val checked = gpsLocate()
            if (checked != null) {
                m.x = checked.x
                m.y = checked.y
                m.z = checked.z
            }
        }
        println("Resuming.")
    }
}
