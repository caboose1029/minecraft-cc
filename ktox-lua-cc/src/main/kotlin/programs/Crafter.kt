package programs

import common.ktoxRednetLastMessage
import common.ktoxRednetLastProtocol
import common.ktoxRednetLastSenderId
import common.ktoxRednetReceiveAny
import common.rednetOpenAny
import common.rednetSend
import common.turtleCraft
import common.turtleDropDown
import common.turtleGetItemCount
import common.turtleSelect
import common.turtleSuckUp
import common.turtleTransferTo
import lib.Recipe
import lib.VAULT_CRAFTER_CMD_PROTOCOL
import lib.VAULT_CRAFTER_FAILURE_PROTOCOL
import lib.VAULT_CRAFTER_QUERY_PROTOCOL
import lib.VAULT_CRAFTER_REPLY_PROTOCOL
import lib.findRecipe
import lib.isFirstInputOccurrence
import lib.recipeInputCount
import lib.recipeInputCountAt
import lib.recipeInputItem
import lib.recipeInputSlot

// A crafty turtle (see PLAN.md "Crafter role") — a third terminal role
// alongside head/secondary, but not a CLI: it never talks to a player
// directly, just sits waiting for the head to tell it what to craft.
// Physical flow is top to bottom, matching Create's own machine
// convention: a chest sits directly ABOVE (ingredient staging, the head
// fills it) and a chest directly BELOW (finished output, the head
// empties it) — turtle.suckUp() pulls ingredients in, turtle.dropDown()
// pushes results out. Both are PHYSICAL turtle.* operations, never a
// network push/pull targeting this turtle's own inventory — confirmed
// live that a turtle exposed as a peripheral has no inventory methods at
// all, and a network-push workaround tried after that didn't hold up
// either. See PLAN.md's "Crafter role" for the two failed network-based
// designs before this one.
//
// The head only ever sends "<outputItemName>,<batches>" - it does NOT
// dictate ingredient/slot placement. This turtle looks the recipe up
// itself (findRecipe, the same shared lib/Config.kt function the head
// uses) and works out which of its own currently-held items go in which
// crafting-grid slot (1, 2, 3, 5, 6, 7, 9, 10, 11) - "plan the grid
// arrangement" is now crafter-side logic, deliberately, even though the
// head still decides WHAT to craft and HOW MANY. Any physical step that
// doesn't behave as expected (a suckUp/transferTo/craft call that
// returns false, or fewer items than expected) reports a SPECIFIC reason
// back to the head (VAULT_CRAFTER_FAILURE_PROTOCOL) rather than failing
// silently - see runCraftTask.
//
// Usage: crafter <jobType> (normally auto-launched by startup.lua via
// role.txt, not run by hand — see TerminalSetup.kt)

// Non-grid slots (outside the 3x3 pattern at 1,2,3,5,6,7,9,10,11) -
// each distinct ingredient the recipe needs gets its OWN staging slot
// from this list for the duration of gathering+placing it, so several
// different item types never get combined in one slot by accident.
fun stagingSlotAt(index: Int): Int {
    if (index == 1) {
        return 4
    }
    if (index == 2) {
        return 8
    }
    if (index == 3) {
        return 12
    }
    if (index == 4) {
        return 13
    }
    if (index == 5) {
        return 14
    }
    if (index == 6) {
        return 15
    }
    return 16
}

fun main(args: Array<String>) {
    if (args.size < 1) {
        println("Usage: crafter <jobType>")
        return
    }
    val jobType = args[1]

    println("Crafter starting (job: ${jobType})...")
    val hasModem = rednetOpenAny()
    if (!hasModem) {
        println("No modem found - attach one and reboot.")
        return
    }

    println("Crafter ready, waiting for commands.")
    while (true) {
        handleOneMessage(jobType)
    }
}

fun handleOneMessage(jobType: String) {
    // Long finite timeout rather than "forever" - see HeadTerminal.kt's identical
    // choice and reasoning (no evidence either way on a native timeout
    // sentinel transpiling correctly through this binding).
    val got = ktoxRednetReceiveAny(3600.0)
    if (!got) {
        return
    }
    val senderId = ktoxRednetLastSenderId()
    val protocol = ktoxRednetLastProtocol()
    if (protocol == VAULT_CRAFTER_QUERY_PROTOCOL && ktoxRednetLastMessage() == jobType) {
        rednetSend(senderId, jobType, VAULT_CRAFTER_REPLY_PROTOCOL)
    } else if (protocol == VAULT_CRAFTER_CMD_PROTOCOL) {
        val parts = ktoxRednetLastMessage().split(",")
        val outputItemName = parts[1]
        val batches = parts[2].toDouble().toInt()
        runCraftTask(senderId, outputItemName, batches)
    }
}

// Loud, informative failure reporting - printed locally (in case anyone
// is actually looking at this turtle's own screen) AND sent back to the
// head, so it can surface the SPECIFIC reason in its own result instead
// of a generic timeout once nothing shows up in the chest below.
fun reportFailure(headId: Int, reason: String) {
    println("FAILURE: ${reason}")
    rednetSend(headId, reason, VAULT_CRAFTER_FAILURE_PROTOCOL)
}

fun runCraftTask(headId: Int, outputItemName: String, batches: Int) {
    dumpAllDown()
    if (!isInventoryEmpty()) {
        reportFailure(headId, "Crafter's inventory wasn't empty at the start of a job (dropDown didn't clear it) - check the chest below isn't full or missing.")
        return
    }

    val recipe = findRecipe(outputItemName)
    if (recipe == null) {
        reportFailure(headId, "Crafter has no known recipe for ${outputItemName}.")
        return
    }

    val inputCount = recipeInputCount(recipe)
    var stagingIndex = 0
    var i = 1
    while (i <= inputCount) {
        if (isFirstInputOccurrence(recipe, i)) {
            stagingIndex += 1
            val itemName = recipeInputItem(recipe, i)
            val stagingSlot = stagingSlotAt(stagingIndex)
            val ok = stageAndDistribute(headId, recipe, itemName, stagingSlot, batches, inputCount)
            if (!ok) {
                dumpAllDown()
                return
            }
        }
        i += 1
    }

    val crafted = turtleCraft(batches)
    if (!crafted) {
        reportFailure(headId, "turtle.craft() failed for ${outputItemName} - ingredients may not have matched the expected shape.")
        dumpAllDown()
        return
    }

    dumpAllDown()
}

// Sucks `itemName` from the chest above into `stagingSlot`, distributing
// it into every grid slot the recipe needs it in, ONE target slot at a
// time - never accumulating more than one target slot's worth in the
// staging slot at once, so a large total (spread across several grid
// slots) can't overflow a single slot's stack limit even when the total
// needed across every slot combined would exceed it.
fun stageAndDistribute(headId: Int, recipe: Recipe, itemName: String, stagingSlot: Int, batches: Int, inputCount: Int): Boolean {
    var j = 1
    while (j <= inputCount) {
        if (recipeInputItem(recipe, j) == itemName) {
            val targetSlot = recipeInputSlot(recipe, j)
            val needed = recipeInputCountAt(recipe, j) * batches
            val gathered = gatherInto(stagingSlot, needed)
            if (gathered < needed) {
                reportFailure(headId, "suckUp only retrieved ${gathered} of ${needed} needed ${itemName} from the chest above.")
                return false
            }
            turtleSelect(stagingSlot)
            val moved = turtleTransferTo(targetSlot, needed)
            if (!moved) {
                reportFailure(headId, "Couldn't move ${itemName} from the staging slot into crafting-grid slot ${targetSlot}.")
                return false
            }
        }
        j += 1
    }
    return true
}

// Sucks up to `needed` of whatever's directly above into `stagingSlot`,
// looping (the chest above can split one item across several of its own
// slots) until either `needed` is reached or suckUp stops making
// progress (nothing left up there).
fun gatherInto(stagingSlot: Int, needed: Int): Int {
    turtleSelect(stagingSlot)
    var gathered = turtleGetItemCount(stagingSlot)
    while (gathered < needed) {
        val before = gathered
        turtleSuckUp(needed - gathered)
        gathered = turtleGetItemCount(stagingSlot)
        if (gathered <= before) {
            return gathered
        }
    }
    return gathered
}

fun isInventoryEmpty(): Boolean {
    var slot = 1
    while (slot <= 16) {
        if (turtleGetItemCount(slot) > 0) {
            return false
        }
        slot += 1
    }
    return true
}

// Drops everything the turtle is holding straight down into the chest
// below — both for delivering a finished craft result and for clearing
// stale contents before starting a new job (see runCraftTask).
fun dumpAllDown() {
    var slot = 1
    while (slot <= 16) {
        turtleSelect(slot)
        if (turtleGetItemCount(slot) > 0) {
            turtleDropDown(64)
        }
        slot += 1
    }
}
