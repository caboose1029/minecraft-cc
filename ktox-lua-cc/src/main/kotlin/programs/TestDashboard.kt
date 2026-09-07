package programs

import lib.DashboardState
import lib.DisplaySize
import lib.Touch
import lib.detailBackRect
import lib.detailCraftButtonRect
import lib.detailFetchButtonRect
import lib.detailQtyDownRect
import lib.detailQtyRect
import lib.detailQtyUpRect
import lib.freshDashboardState
import lib.handleBrowseTouch
import lib.handleDetailTouch
import lib.detailFetchCheckboxRect
import lib.detailLocationRect
import lib.itemRowRect
import lib.searchButtonRect
import lib.tabRect

// Exercises the dashboard UI's pure state-machine logic (lib/Dashboard.kt)
// against synthetic touches, entirely offline - no real display/touch
// event is ever waited on, so this can run headless via CraftOS-PC
// (scripts/validate.sh TestDashboard.lua). Confirms the render/hit-test
// coordinate math agrees with itself and that taps resolve to the
// expected state transitions and command strings. Does NOT confirm real
// mouse_click events actually fire the way this assumes, or exercise
// promptForQuantity's real keyboard read at all (CraftOS-PC's headless
// --script mode can't feed simulated keystrokes - see common/Term.kt's
// own note on this) - see PLAN.md "Known open items", both still
// unverified in-game.
//
// Usage: TestDashboard (no args)

fun main() {
    val size = DisplaySize(30, 13)
    println("size=${size.width}x${size.height}")

    val state = freshDashboardState()
    println("initial: mode=${state.mode} tab=${state.tab} page=${state.page}")

    // Tab 3 = "Uncraftable" ("unavailable") - guaranteed non-empty even
    // with zero real peripherals attached, since ktoxListCatalog seeds it
    // from the resource-tree recipe list too, not just physical
    // inventory contents (unlike "stocked", which needs a real vault).
    val tab3Rect = tabRect(size, 3)
    val afterTab = handleBrowseTouch(state, Touch(tab3Rect.x, tab3Rect.y), size)
    println("after tab3 touch: mode=${afterTab.mode} tab=${afterTab.tab} page=${afterTab.page}")
    if (afterTab.tab != "unavailable") {
        println("FAIL: tab3 touch should select 'unavailable', got '${afterTab.tab}'")
    }

    val row1Rect = itemRowRect(size, 1)
    val afterRow = handleBrowseTouch(afterTab, Touch(row1Rect.x, row1Rect.y), size)
    println("after row1 touch: mode=${afterRow.mode} item=${afterRow.selectedItem} status=${afterRow.selectedStatus} qty=${afterRow.qtyText}")
    if (afterRow.mode != "detail") {
        println("FAIL: row1 touch should enter detail mode, got '${afterRow.mode}'")
    }
    if (afterRow.selectedItem == "") {
        println("FAIL: row1 touch should select an item, got empty string")
    }

    val craftRect = detailCraftButtonRect(size)
    val afterCraft = handleDetailTouch(afterRow, Touch(craftRect.x, craftRect.y), size)
    println("after craft touch: readyCommand=(${afterCraft.readyCommand})")
    val expectedCraftPrefix = "craft ${afterRow.selectedItem} 1"
    if (afterCraft.readyCommand != expectedCraftPrefix) {
        println("FAIL: expected readyCommand '${expectedCraftPrefix}', got '${afterCraft.readyCommand}'")
    }

    val backRect = detailBackRect()
    val afterBack = handleDetailTouch(afterRow, Touch(backRect.x, backRect.y), size)
    println("after back touch: mode=${afterBack.mode} tab=${afterBack.tab}")
    if (afterBack.mode != "browse") {
        println("FAIL: back touch should return to browse mode, got '${afterBack.mode}'")
    }

    // Qty field tap is a pure transition to "qtyentry" - runDashboardLoop
    // is what actually calls the blocking promptForQuantity() for that
    // mode, not handleDetailTouch, precisely so this stays testable here
    // without ever touching real keyboard I/O.
    val qtyFieldRect = detailQtyRect(size)
    val afterQtyTap = handleDetailTouch(afterRow, Touch(qtyFieldRect.x, qtyFieldRect.y), size)
    println("after qty field touch: mode=${afterQtyTap.mode}")
    if (afterQtyTap.mode != "qtyentry") {
        println("FAIL: qty field touch should enter qtyentry mode, got '${afterQtyTap.mode}'")
    }

    // The Fetch button only appears for a "stocked" item, which headless
    // CraftOS-PC can never have (no real inventory) - can't reach it via
    // a real row tap here, so construct that detail state directly to
    // confirm its hit-test/command-building path independently (it's
    // otherwise identical to Craft's, just untested in isolation).
    val stockedDetail = DashboardState("detail", "stocked", 1, "minecraft:iron_ingot", "stocked", "64", "3", true, -1, "", "")
    val fetchRect = detailFetchButtonRect(size)
    val afterFetch = handleDetailTouch(stockedDetail, Touch(fetchRect.x, fetchRect.y), size)
    println("after fetch touch: readyCommand=(${afterFetch.readyCommand})")
    if (afterFetch.readyCommand != "pull minecraft:iron_ingot 3") {
        println("FAIL: expected readyCommand 'pull minecraft:iron_ingot 3', got '${afterFetch.readyCommand}'")
    }

    // Fetch checkbox toggles, and feeds the craft command's --fetch=false
    // flag only when unchecked.
    val checkboxRect = detailFetchCheckboxRect(size)
    val afterUncheck = handleDetailTouch(stockedDetail, Touch(checkboxRect.x, checkboxRect.y), size)
    println("after checkbox touch: fetchChecked=${afterUncheck.fetchChecked}")
    if (afterUncheck.fetchChecked) {
        println("FAIL: checkbox touch should have unchecked fetchChecked")
    }
    val craftRect2 = detailCraftButtonRect(size)
    val afterCraftUnchecked = handleDetailTouch(afterUncheck, Touch(craftRect2.x, craftRect2.y), size)
    println("after craft touch (fetch unchecked): readyCommand=(${afterCraftUnchecked.readyCommand})")
    if (afterCraftUnchecked.readyCommand != "craft minecraft:iron_ingot 3 --fetch=false") {
        println("FAIL: expected '--fetch=false' appended, got '${afterCraftUnchecked.readyCommand}'")
    }

    // Stack up/down buttons add/subtract one full stack - a plain item
    // (default 64) and one of config/stack-sizes.lua's overrides
    // (ender pearls, 16) should step by different amounts.
    val qtyUpRect = detailQtyUpRect(size)
    val afterStackUp = handleDetailTouch(stockedDetail, Touch(qtyUpRect.x, qtyUpRect.y), size)
    println("after stack-up touch (default 64): qtyText=${afterStackUp.qtyText}")
    if (afterStackUp.qtyText != "67") {
        println("FAIL: expected qtyText '67' (starting qty 3 + 64), got '${afterStackUp.qtyText}'")
    }
    val qtyDownRect = detailQtyDownRect(size)
    val afterStackDown = handleDetailTouch(afterStackUp, Touch(qtyDownRect.x, qtyDownRect.y), size)
    println("after stack-down touch: qtyText=${afterStackDown.qtyText}")
    if (afterStackDown.qtyText != "3") {
        println("FAIL: expected qtyText '3' (back down one stack), got '${afterStackDown.qtyText}'")
    }
    val pearlDetail = DashboardState("detail", "stocked", 1, "minecraft:ender_pearl", "stocked", "5", "1", true, -1, "", "")
    val afterPearlUp = handleDetailTouch(pearlDetail, Touch(qtyUpRect.x, qtyUpRect.y), size)
    println("after stack-up touch (ender_pearl, stack 16): qtyText=${afterPearlUp.qtyText}")
    if (afterPearlUp.qtyText != "17") {
        println("FAIL: expected qtyText '17' (starting qty 1 + 16), got '${afterPearlUp.qtyText}'")
    }
    val afterPearlDownBelowZero = handleDetailTouch(pearlDetail, Touch(qtyDownRect.x, qtyDownRect.y), size)
    println("after stack-down touch clamping at 0: qtyText=${afterPearlDownBelowZero.qtyText}")
    if (afterPearlDownBelowZero.qtyText != "0") {
        println("FAIL: expected qtyText '0' (clamped, not negative), got '${afterPearlDownBelowZero.qtyText}'")
    }

    // Location selector cycles through named locations and back to
    // "(auto)". Config now has more than one named pickup vault ("main",
    // "head"), and Lua's pairs() iteration order isn't stable, so this
    // deliberately does NOT assert which name comes first - only that
    // cycling once lands on SOME real named location, not "(auto)".
    val locationRect = detailLocationRect(size)
    val afterLocation1 = handleDetailTouch(stockedDetail, Touch(locationRect.x, locationRect.y), size)
    println("after 1st location touch: locationIndex=${afterLocation1.locationIndex}")
    if (afterLocation1.locationIndex < 1) {
        println("FAIL: expected locationIndex to advance to a real location, stayed at ${afterLocation1.locationIndex}")
    }
    val afterFetchWithLocation = handleDetailTouch(afterLocation1, Touch(fetchRect.x, fetchRect.y), size)
    println("after fetch touch (location set): readyCommand=(${afterFetchWithLocation.readyCommand})")
    val locationParts = afterFetchWithLocation.readyCommand.split("--location=")
    if (locationParts.size < 2 || locationParts[2] == "") {
        println("FAIL: expected '--location=<name>' appended, got '${afterFetchWithLocation.readyCommand}'")
    }

    // Search button tap is a pure transition to "searchentry" - same
    // reasoning as the qty field's "qtyentry" transition: the actual
    // blocking read() prompt lives only in runDashboardLoop.
    val searchRect = searchButtonRect(size)
    val afterSearchTap = handleBrowseTouch(afterTab, Touch(searchRect.x, searchRect.y), size)
    println("after search button touch: mode=${afterSearchTap.mode}")
    if (afterSearchTap.mode != "searchentry") {
        println("FAIL: search button touch should enter searchentry mode, got '${afterSearchTap.mode}'")
    }

    // An active search filters the row list ktoxListCatalog returns -
    // confirmed indirectly: tab3 with no search (afterTab, above) selects
    // a real item via row1; the same tab with a search string that can't
    // possibly match anything should leave row1 empty, so tapping it is
    // a no-op (stays in browse mode) rather than entering detail.
    val impossibleSearch = DashboardState("browse", "unavailable", 1, "", "", "", "1", true, -1, "", "zzz_no_such_item_zzz")
    val afterImpossibleRowTap = handleBrowseTouch(impossibleSearch, Touch(row1Rect.x, row1Rect.y), size)
    println("after row1 touch under an unmatchable search: mode=${afterImpossibleRowTap.mode}")
    if (afterImpossibleRowTap.mode != "browse") {
        println("FAIL: row1 touch under a search matching nothing should stay in browse mode, got '${afterImpossibleRowTap.mode}'")
    }

    // A touch outside every rect (the whole screen is tappable in browse
    // mode, so this needs to be off-screen entirely) should be a no-op.
    val afterMiss = handleBrowseTouch(state, Touch(999, 999), size)
    if (afterMiss.mode != state.mode || afterMiss.tab != state.tab) {
        println("FAIL: an out-of-bounds touch mutated state unexpectedly")
    }

    println("TestDashboard done.")
}
