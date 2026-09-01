package lib

import common.turtleBack
import common.turtleDig
import common.turtleDigDown
import common.turtleDigUp
import common.turtleDown
import common.turtleForward
import common.turtleTurnLeft
import common.turtleTurnRight
import common.turtleUp

// Tracks the turtle's position/heading, kept in sync purely by dead
// reckoning (counting moves) — GPS is never required for this to work,
// only optionally used to anchor it to real world coordinates and, when
// available, to sanity-check for drift. Home is a fixed reference: the
// exact block the turtle was standing on when the program started, i.e.
// where the fuel/overflow chests are relative to. See calibrateMovement()
// below: with a working wireless/ender modem + GPS host, home/heading are
// real world coordinates and callers should periodically re-sync via a
// fresh gpsLocate() call as a drift safety check (gated on `gpsEnabled`);
// without one, home is just local (0,0,0) with heading 0 — an arbitrary
// but internally consistent origin, since nothing in this file or
// lib/Chest.kt ever needs home to align with true world coordinates, only
// with itself.
//
// Heading: 0 = north (-z), 1 = east (+x), 2 = south (+z), 3 = west (-x)
// when GPS-anchored; an arbitrary but self-consistent label otherwise.
// `homeHeading` is the direction the turtle originally faced (away from
// the fuel chest) — turning to this heading and then turnAround() faces
// the fuel chest.
enum class MoveSign { FORWARD, BACKWARD }

class Movement(
    startX: Int,
    startY: Int,
    startZ: Int,
    startHeading: Int,
    val homeX: Int,
    val homeY: Int,
    val homeZ: Int,
    val homeHeading: Int,
    val gpsEnabled: Boolean,
) {
    var x: Int = startX
    var y: Int = startY
    var z: Int = startZ
    var heading: Int = startHeading

    fun turnLeft() {
        turtleTurnLeft()
        heading = (heading + 3) % 4
    }

    fun turnRight() {
        turtleTurnRight()
        heading = (heading + 1) % 4
    }

    fun turnAround() {
        this.turnRight()
        this.turnRight()
    }

    // Turns (whichever way is shorter) to face the given absolute heading.
    fun faceHeading(target: Int) {
        val diff = (target - heading + 4) % 4
        if (diff == 3) {
            this.turnLeft()
        } else {
            var turned = 0
            while (turned < diff) {
                this.turnRight()
                turned += 1
            }
        }
    }

    // Digs through an obstruction (once) if the first attempt is blocked.
    // Returns false if still blocked afterward (e.g. bedrock).
    fun forward(): Boolean {
        if (turtleForward()) {
            this.applyDelta(MoveSign.FORWARD)
            return true
        }
        turtleDig()
        if (turtleForward()) {
            this.applyDelta(MoveSign.FORWARD)
            return true
        }
        return false
    }

    fun back(): Boolean {
        if (turtleBack()) {
            this.applyDelta(MoveSign.BACKWARD)
            return true
        }
        return false
    }

    fun up(): Boolean {
        if (turtleUp()) {
            y += 1
            return true
        }
        turtleDigUp()
        if (turtleUp()) {
            y += 1
            return true
        }
        return false
    }

    fun down(): Boolean {
        if (turtleDown()) {
            y -= 1
            return true
        }
        turtleDigDown()
        if (turtleDown()) {
            y -= 1
            return true
        }
        return false
    }

    private fun applyDelta(sign: MoveSign) {
        val delta = if (sign == MoveSign.FORWARD) 1 else -1
        when (heading) {
            0 -> z -= delta
            1 -> x += delta
            2 -> z += delta
            else -> x -= delta
        }
    }

    // Manhattan distance back to home (the turtle's actual starting block,
    // not necessarily (0,0,0)) — used as a fuel safety margin before
    // committing to another move.
    fun distanceHome(): Int {
        val dx = x - homeX
        val dz = z - homeZ
        val dy = y - homeY
        val adx = if (dx < 0) -dx else dx
        val ady = if (dy < 0) -dy else dy
        val adz = if (dz < 0) -dz else dz
        return adx + ady + adz
    }
}

// Attempts one-time GPS calibration: reads world position (this becomes
// "home"), moves forward one block (digging through if blocked) to derive
// heading from the resulting position delta, then reads position again.
// GPS is optional — this never fails the caller. If no modem/GPS host is
// available (or the forced calibration move is blocked, e.g. bedrock on
// every side), it falls back to a local (0,0,0) origin with heading 0 and
// gpsEnabled=false, and the turtle stays exactly where it started (no
// forced move attempted unless the first gpsLocate() already succeeded).
fun calibrateMovement(): Movement {
    val start = gpsLocate()
    if (start == null) {
        return Movement(0, 0, 0, 0, 0, 0, 0, 0, false)
    }
    if (!turtleForward()) {
        turtleDig()
        if (!turtleForward()) {
            return Movement(0, 0, 0, 0, 0, 0, 0, 0, false)
        }
    }
    val after = gpsLocate()
    if (after == null) {
        // Already moved one block by this point with no second reading to
        // derive heading from — treat wherever the turtle now stands as
        // the dead-reckoning origin rather than aborting.
        return Movement(0, 0, 0, 0, 0, 0, 0, 0, false)
    }
    val heading = headingFromDelta(after.x - start.x, after.z - start.z)
    return Movement(after.x, after.y, after.z, heading, start.x, start.y, start.z, heading, true)
}

private fun headingFromDelta(dx: Int, dz: Int): Int {
    return when {
        dz < 0 -> 0
        dx > 0 -> 1
        dz > 0 -> 2
        else -> 3
    }
}

// Heading: 0 = north (-z), 1 = east (+x), 2 = south (+z), 3 = west (-x) —
// see Movement's own doc comment above.
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
// then Z. Digs through anything in the way (via Movement's forward/up/down)
// — but forward()/up()/down() themselves return false when genuinely
// blocked (e.g. bedrock: dig succeeds on a pocket between two bedrock
// blocks, but the move into the next one still fails). Every step here
// checks that and bails out immediately instead of re-attempting the same
// blocked move in an infinite loop with the target never getting closer.
//
// Returns true if the target was fully reached, false if it stopped
// early — callers that care why (bedrock vs. something else) can inspect
// m.x/m.y/m.z afterward; callers that don't care can ignore the result,
// same as before this returned Unit.
fun navigateTo(m: Movement, targetX: Int, targetY: Int, targetZ: Int): Boolean {
    while (m.y < targetY) {
        if (!m.up()) {
            return false
        }
    }
    while (m.y > targetY) {
        if (!m.down()) {
            return false
        }
    }
    if (m.x != targetX) {
        val toward = if (targetX > m.x) 1 else 3
        m.faceHeading(toward)
        while (m.x != targetX) {
            if (!m.forward()) {
                return false
            }
        }
    }
    if (m.z != targetZ) {
        val toward = if (targetZ > m.z) 2 else 0
        m.faceHeading(toward)
        while (m.z != targetZ) {
            if (!m.forward()) {
                return false
            }
        }
    }
    return true
}
