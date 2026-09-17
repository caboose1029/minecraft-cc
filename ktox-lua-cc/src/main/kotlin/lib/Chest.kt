package lib

import common.turtleDrop
import common.turtleGetFuelLevel
import common.turtleGetFuelLimit
import common.turtleGetItemCount
import common.turtleGetItemName
import common.turtleRefuel
import common.turtleSelect
import common.turtleSuck

// Shared home-chest servicing pattern: a fuel/supply chest at the
// turtle's start position, with overflow chests extending sideways from
// there for anything that doesn't fit. Used by any program with this
// setup (Digsite, ExcavatePro) so there's exactly one implementation of
// the chest-hopping and suck/sort logic to get right.

// +1 = turtle's original right is "sideways toward the overflow row".
// Flip to -1 if the chests turn out to be laid out the other way in-game.
const val CHEST_OVERFLOW_SIDE = 1

const val CHEST_MAX_OVERFLOW = 20

// Scratch slot used only transiently during restockChest() — never a
// permanent stockpile, since fuel is consumed immediately on pickup and
// anything else is moved to its real slot (or dropped back) the same
// visit. Slot 16 rather than something lower so it doesn't collide with
// small, deliberately low-numbered reserved slots a caller might use.
const val CHEST_INTAKE_SLOT = 16

// Deliberately restrictive, not exhaustive — turtle.refuel() itself
// already accepts anything CC:Tweaked considers valid fuel (any wood
// variant included) for free, via its own return value. This allowlist
// exists to burn LESS than that on purpose, so wood/planks/logs never
// get consumed as fuel even though they're technically valid, without
// having to enumerate every wood variant to exclude it. No blaze rod,
// per explicit request. Shared by every program with a fuel chest, so
// there's exactly one place these numbers live.
//
// Values are fuel level gained per single item burned. These match
// commonly-documented CC:Tweaked numbers but aren't verified against
// this pack/version — to confirm one yourself: hold one item, note
// turtleGetFuelLevel(), run turtle.refuel(1), and the difference is the
// exact value for your setup. Worth spot-checking coal_block and
// dried_kelp_block especially, since a wrong number there is exactly
// the near-cap waste this exists to prevent. Returns 0 for anything not
// on the allowlist (including every wood variant).
fun fuelValue(name: String): Int {
    if (name == "minecraft:charcoal") {
        return 80
    }
    if (name == "minecraft:coal") {
        return 80
    }
    if (name == "minecraft:coal_block") {
        return 800
    }
    if (name == "minecraft:lava_bucket") {
        return 1000
    }
    if (name == "minecraft:dried_kelp_block") {
        return 4000
    }
    return 0
}

// Chest N (N=0 is the home/supply chest itself, N>=1 are overflow
// chests) sits N blocks from the home chest, sideways along
// CHEST_OVERFLOW_SIDE, one row back from the turtle's home line. Must
// be called with m at the home position.
fun goToChest(m: Movement, n: Int) {
    val sideways = (m.homeHeading + CHEST_OVERFLOW_SIDE + 4) % 4
    val targetX = m.homeX + headingDx(sideways) * n
    val targetZ = m.homeZ + headingDz(sideways) * n
    navigateTo(m, targetX, m.homeY, targetZ)
    m.faceHeading((m.homeHeading + 2) % 4)
}

// True once every slot NOT exempted by `keepSlot` has something in it.
// Which slots are exempt (a fuel reserve, stock of some kind, step
// material, ...) is program-specific — see Digsite's/ExcavatePro's own
// keepSlot for what they protect and why.
fun cargoFull(keepSlot: (Int) -> Boolean): Boolean {
    var slot = 1
    var full = true
    while (slot <= 16) {
        if (!keepSlot(slot)) {
            if (turtleGetItemCount(slot) == 0) {
                full = false
            }
        }
        slot += 1
    }
    return full
}

// Dumps every non-exempt, non-empty slot into the home chest's overflow
// row, hopping to the next chest whenever the current one won't take
// any more. Must be called with m at (or able to path from) home.
fun dumpCargo(m: Movement, keepSlot: (Int) -> Boolean) {
    var chestIndex = 1
    goToChest(m, chestIndex)

    var slot = 1
    var giveUp = false
    while (slot <= 16 && !giveUp) {
        if (!keepSlot(slot)) {
            val count = turtleGetItemCount(slot)
            if (count > 0) {
                turtleSelect(slot)
                var dropped = turtleDrop(64)
                while (!dropped && !giveUp) {
                    chestIndex += 1
                    if (chestIndex > CHEST_MAX_OVERFLOW) {
                        println("All overflow chests full, stopping dump early.")
                        giveUp = true
                    } else {
                        goToChest(m, chestIndex)
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

// Sucks from the home chest one item at a time via CHEST_INTAKE_SLOT.
// Anything on the fuelValue() allowlist is burned as long as there's
// room under turtleGetFuelLimit() for its full value (a high-value item
// is skipped entirely rather than burned for partial value near the
// cap). Anything else is offered to `onOther(name)`, which should move
// it wherever it belongs and return true if it did.
//
// turtle.suck() always pulls whatever's in the chest's lowest-indexed
// non-empty slot — there's no way to ask for a specific item, and
// turtle.drop() puts an unwanted item right back into that same slot.
// So an item that's neither burnable nor handled by onOther gets
// dropped back, then restocking stops immediately: dropping it back
// just re-surfaces the identical stack on the very next suck(), so
// further attempts would only repeat that cycle rather than reach
// anything behind it — an unwinnable loop, not a transient hiccup.
//
// NOTE for callers writing onOther: don't write it as
// `{ name -> if (cond) { sideEffect(); true } else { false } }` — a
// multi-statement if/else branch used as an expression like that
// transpiles to invalid Lua (see AGENTS.md). Use an explicit
// `var handled = false; if (cond) { sideEffect(); handled = true };
// handled` instead.
fun restockChest(m: Movement, maxAttempts: Int, onOther: (String) -> Boolean) {
    goToChest(m, 0)
    var attempts = 0
    var chestEmpty = false
    var stuck = false
    while (attempts < maxAttempts && !chestEmpty && !stuck) {
        turtleSelect(CHEST_INTAKE_SLOT)
        val pulled = turtleSuck(64)
        if (!pulled) {
            chestEmpty = true
        } else {
            val name = turtleGetItemName(CHEST_INTAKE_SLOT)
            var handled = false
            if (name != null) {
                val value = fuelValue(name)
                if (value > 0) {
                    val headroom = turtleGetFuelLimit() - turtleGetFuelLevel()
                    if (headroom >= value) {
                        turtleSelect(CHEST_INTAKE_SLOT)
                        turtleRefuel(64)
                        handled = true
                    }
                } else if (onOther(name)) {
                    handled = true
                }
            }
            if (!handled) {
                turtleSelect(CHEST_INTAKE_SLOT)
                turtleDrop(64)
                stuck = true
                println("Chest's next item isn't usable right now (unrecognized, or would waste a high-value fuel item near the cap) - stopping restock early.")
            }
        }
        attempts += 1
    }
    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m.faceHeading(m.homeHeading)
}
