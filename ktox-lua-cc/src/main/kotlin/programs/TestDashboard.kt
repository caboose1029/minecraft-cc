package programs

import lib.DashboardState
import lib.DisplaySize
import lib.Touch
import lib.detailBackRect
import lib.detailCraftButtonRect
import lib.detailFetchButtonRect
import lib.detailQtyRect
import lib.freshDashboardState
import lib.handleBrowseTouch
import lib.handleDetailTouch
import lib.handleKeypadTouch
import lib.detailFetchCheckboxRect
import lib.detailLocationRect
import lib.itemRowRect
import lib.keypadKeyRect
import lib.tabRect

// Exercises the dashboard UI's pure state-machine logic (lib/Dashboard.kt)
// against synthetic touches, entirely offline - no real display/touch
// event is ever waited on, so this can run headless via CraftOS-PC
// (scripts/validate.sh TestDashboard.lua). Confirms the render/hit-test
// coordinate math agrees with itself and that taps resolve to the
// expected state transitions and command strings. Does NOT confirm real
// monitor_touch/mouse_click events actually fire the way this assumes -
// see PLAN.md "Known open items", that part is still unverified in-game.
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

    // Keypad path: tap the qty field, tap digit "2", tap OK.
    val qtyFieldRect = detailQtyRect(size)
    val afterQtyTap = handleDetailTouch(afterRow, Touch(qtyFieldRect.x, qtyFieldRect.y), size)
    println("after qty field touch: mode=${afterQtyTap.mode}")
    if (afterQtyTap.mode != "keypad") {
        println("FAIL: qty field touch should enter keypad mode, got '${afterQtyTap.mode}'")
    }

    val digitRect = keypadKeyRect(size, 3, 2) // "2"
    val afterDigit = handleKeypadTouch(afterQtyTap, Touch(digitRect.x, digitRect.y), size)
    println("after digit '2' touch: qtyText=${afterDigit.qtyText}")
    if (afterDigit.qtyText != "12") {
        println("FAIL: expected qtyText '12' (default '1' + tapped '2'), got '${afterDigit.qtyText}'")
    }

    val okRect = keypadKeyRect(size, 4, 3) // "OK"
    val afterOk = handleKeypadTouch(afterDigit, Touch(okRect.x, okRect.y), size)
    println("after OK touch: mode=${afterOk.mode} qtyText=${afterOk.qtyText}")
    if (afterOk.mode != "detail") {
        println("FAIL: OK touch should return to detail mode, got '${afterOk.mode}'")
    }

    // The Fetch button only appears for a "stocked" item, which headless
    // CraftOS-PC can never have (no real inventory) - can't reach it via
    // a real row tap here, so construct that detail state directly to
    // confirm its hit-test/command-building path independently (it's
    // otherwise identical to Craft's, just untested in isolation).
    val stockedDetail = DashboardState("detail", "stocked", 1, "minecraft:iron_ingot", "stocked", "64", "3", true, -1, "")
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

    // Location selector cycles through named locations (config's real
    // pickup vault is named "main") and back to "(auto)".
    val locationRect = detailLocationRect(size)
    val afterLocation1 = handleDetailTouch(stockedDetail, Touch(locationRect.x, locationRect.y), size)
    println("after 1st location touch: locationIndex=${afterLocation1.locationIndex}")
    val afterFetchWithLocation = handleDetailTouch(afterLocation1, Touch(fetchRect.x, fetchRect.y), size)
    println("after fetch touch (location set): readyCommand=(${afterFetchWithLocation.readyCommand})")
    if (afterFetchWithLocation.readyCommand != "pull minecraft:iron_ingot 3 --location=main") {
        println("FAIL: expected '--location=main' appended, got '${afterFetchWithLocation.readyCommand}'")
    }

    // A touch outside every rect (the whole screen is tappable in browse
    // mode, so this needs to be off-screen entirely) should be a no-op.
    val afterMiss = handleBrowseTouch(state, Touch(999, 999), size)
    if (afterMiss.mode != state.mode || afterMiss.tab != state.tab) {
        println("FAIL: an out-of-bounds touch mutated state unexpectedly")
    }

    println("TestDashboard done.")
}
