package lib

import common.ktoxConfigPickupVaultNames
import common.ktoxConfigStorageVaultNames
import common.ktoxListCatalog
import common.readInput
import common.termClear
import common.termSetCursorPos
import common.termWrite
import lib.COLOR_BLACK
import lib.COLOR_BLUE
import lib.COLOR_GRAY
import lib.COLOR_LIME
import lib.COLOR_WHITE
import lib.DisplaySize
import lib.Touch
import lib.displayClear
import lib.displayFillRect
import lib.displayInit
import lib.displaySize
import lib.displayWaitTouch
import lib.touchInRect

// Touch-driven dashboard UI (see PLAN.md "Dashboard UI") — replaces the
// plain `read()` prompt as HeadTerminal/SecondaryTerminal's local-input
// step. Renders onto this computer's own screen (lib/Display.kt — the
// main use case is a turtle's or pocket computer's own screen, not an
// external Monitor peripheral; a monitor-driven dashboard, if built, is
// a separate program later) and resolves taps into the exact same
// command strings the CLI already accepts, feeding them through
// runCliCommand/rednet unchanged — this file only ever produces a
// String, never touches vault/job logic directly.
//
// Two screens (DashboardState.mode): "browse" (tabs + paginated item
// list) and "detail" (one selected item's actions). A third, transient
// mode ("qtyentry") isn't really a screen at all — see
// runDashboardLoop()'s handling of it and promptForQuantity() below:
// this computer's own screen DOES capture real keyboard input while its
// GUI is open (unlike a Monitor peripheral, which never does), so
// quantity entry is a normal blocking read() prompt, not a tap-driven
// keypad. Kept as an explicit state (not just an inline side effect
// inside handleDetailTouch) specifically so the pure hit-testing logic
// stays testable: handleDetailTouch itself never blocks on real
// keyboard input, only runDashboardLoop's dispatch does — see
// TestDashboard.kt, which exercises the former but can't touch the
// latter (there's no way to feed simulated keystrokes to CraftOS-PC's
// headless --script mode - see common/Term.kt's own note on this).
//
// Deliberately NOT a mutable state object — DashboardState is an
// immutable data class, always constructed fresh at every return site
// (never `.copy()`, unconfirmed whether that ktox-transpiles correctly).
// Screen contents are recomputed from (tab, page) on every render AND
// every touch check via the same helper functions, rather than cached
// anywhere, so drawing and hit-testing can never disagree about what's
// currently on screen.

data class Rect(val x: Int, val y: Int, val w: Int, val h: Int)

data class DashboardState(
    val mode: String, // "browse" | "detail" | "qtyentry"
    val tab: String, // "stocked" | "craftable" | "unavailable"
    val page: Int, // 1-indexed
    val selectedItem: String,
    val selectedStatus: String,
    val selectedCount: String, // display string: a count, or "craftable"/"unavailable"
    val qtyText: String,
    val fetchChecked: Boolean,
    val locationIndex: Int, // -1 = auto (self-then-default resolution)
    val readyCommand: String, // "" = keep looping; non-empty = return this
)

fun freshDashboardState(): DashboardState {
    return DashboardState("browse", "stocked", 1, "", "", "", "1", true, -1, "")
}

// Blocks until a Fetch/Craft action actually resolves to a command,
// exactly like read() blocks until Enter — same contract, so callers
// (HeadTerminal/SecondaryTerminal) don't need to change anything past
// this call. The "qtyentry" branch is the one place this does real
// blocking keyboard I/O (promptForQuantity) rather than tap handling —
// pulled out of handleDetailTouch precisely so that function can stay a
// pure, testable state transition (see the file header comment).
fun runDashboardLoop(): String {
    var state = freshDashboardState()
    displayInit()
    while (state.readyCommand == "") {
        if (state.mode == "qtyentry") {
            val newQty = promptForQuantity(state.qtyText)
            state = DashboardState("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, newQty, state.fetchChecked, state.locationIndex, "")
        } else {
            val size = displaySize()
            renderDashboard(state, size)
            val touch = displayWaitTouch()
            state = handleDashboardTouch(state, touch, size)
        }
    }
    return state.readyCommand
}

// Real keyboard entry (this computer's own screen, GUI open, has a real
// keyboard available — unlike a Monitor peripheral). Blank input or a
// non-positive/non-numeric value keeps whatever quantity was already
// set, rather than sending a broken command later.
fun promptForQuantity(current: String): String {
    termClear()
    termSetCursorPos(1, 1)
    termWrite("Enter quantity (currently ${current}):")
    termSetCursorPos(1, 2)
    val typed = readInput()
    if (typed == "") {
        return current
    }
    val parsed = typed.toDoubleOrNull()
    if (parsed == null || parsed <= 0.0) {
        return current
    }
    return typed
}

// Shows a Fetch/Craft result on the display and waits for a dismiss tap
// before the caller loops back to a fresh runDashboardLoop(). Assumes a
// single-line message, which every pull/craft result actually is (the
// only two commands the dashboard ever produces) - a longer message is
// just truncated by displayFillRect's own width clamp, same as an
// overlong item name in the browse list.
fun showDashboardResult(message: String) {
    displayClear()
    val size = displaySize()
    displayFillRect(1, 1, size.width, 1, COLOR_BLACK, COLOR_WHITE, message)
    displayFillRect(1, size.height, size.width, 1, COLOR_GRAY, COLOR_WHITE, "(tap to continue)")
    displayWaitTouch()
}

// ---- shared layout helpers (used by BOTH rendering and hit-testing,
// so the two can never disagree about where something is) ----

fun threeColumnRect(size: DisplaySize, columnIndex: Int, y: Int, h: Int): Rect {
    val totalW = size.width
    val remainder = totalW % 3
    val base = (totalW - remainder) / 3
    if (columnIndex == 1) {
        return Rect(1, y, base, h)
    }
    if (columnIndex == 2) {
        return Rect(1 + base, y, base, h)
    }
    return Rect(1 + base + base, y, totalW - base - base, h)
}

fun tabRect(size: DisplaySize, index: Int): Rect {
    return threeColumnRect(size, index, 1, 1)
}

fun tabLabel(index: Int): String {
    if (index == 1) {
        return "Stocked"
    }
    if (index == 2) {
        return "Craftable"
    }
    return "Uncraftable"
}

fun tabStatus(index: Int): String {
    if (index == 1) {
        return "stocked"
    }
    if (index == 2) {
        return "craftable"
    }
    return "unavailable"
}

fun tabIndexForStatus(status: String): Int {
    if (status == "stocked") {
        return 1
    }
    if (status == "craftable") {
        return 2
    }
    return 3
}

fun rowsPerPage(size: DisplaySize): Int {
    val reserved = 2 // tabs row + pagination footer row
    val available = size.height - reserved
    if (available < 1) {
        return 1
    }
    return available
}

fun itemRowRect(size: DisplaySize, rowSlot: Int): Rect {
    return Rect(1, 1 + rowSlot, size.width, 1)
}

fun paginationFooterY(size: DisplaySize): Int {
    return size.height
}

fun totalPagesFor(count: Int, perPage: Int): Int {
    if (count == 0) {
        return 1
    }
    val remainder = count % perPage
    var pages = (count - remainder) / perPage
    if (remainder > 0) {
        pages += 1
    }
    return pages
}

// Strips the "modid:" namespace prefix for display only - the full name
// (with namespace) is still what's stored in state and sent to
// runCliCommand.
fun displayItemName(fullName: String): String {
    val parts = fullName.split(":")
    if (parts.size < 2) {
        return fullName
    }
    return parts[2]
}

fun pickupLocationNames(): List<String> {
    val raw = ktoxConfigPickupVaultNames()
    if (raw == "") {
        return listOf()
    }
    return raw.split(",")
}

fun locationLabel(locationIndex: Int): String {
    if (locationIndex == -1) {
        return "(auto)"
    }
    val names = pickupLocationNames()
    if (locationIndex < 1 || locationIndex > names.size) {
        return "(auto)"
    }
    return names[locationIndex]
}

fun locationFlag(locationIndex: Int): String {
    if (locationIndex == -1) {
        return ""
    }
    val names = pickupLocationNames()
    if (locationIndex < 1 || locationIndex > names.size) {
        return ""
    }
    return " --location=${names[locationIndex]}"
}

fun nextLocationIndex(locationIndex: Int): Int {
    val names = pickupLocationNames()
    if (names.size == 0) {
        return -1
    }
    if (locationIndex < 1) {
        return 1
    }
    if (locationIndex >= names.size) {
        return -1
    }
    return locationIndex + 1
}

// ---- detail-mode rects (fixed rows - the detail screen's content is a
// fixed size regardless of display size, unlike the item list) ----

fun detailBackRect(): Rect {
    return Rect(1, 1, 8, 1)
}

fun detailQtyRect(size: DisplaySize): Rect {
    return Rect(1, 2, size.width, 1)
}

fun detailLocationRect(size: DisplaySize): Rect {
    return Rect(1, 3, size.width, 1)
}

fun detailFetchCheckboxRect(size: DisplaySize): Rect {
    return Rect(1, 4, size.width, 1)
}

fun detailFetchButtonRect(size: DisplaySize): Rect {
    return threeColumnRect(size, 1, 6, 2)
}

fun detailCraftButtonRect(size: DisplaySize): Rect {
    val fetchRect = detailFetchButtonRect(size)
    return Rect(fetchRect.x + fetchRect.w, 6, size.width - fetchRect.w, 2)
}

// ---- rendering ----

fun renderDashboard(state: DashboardState, size: DisplaySize) {
    if (state.mode == "browse") {
        renderBrowse(state, size)
        return
    }
    renderDetail(state, size)
}

fun renderBrowse(state: DashboardState, size: DisplaySize) {
    displayClear()

    var i = 1
    while (i <= 3) {
        val rect = tabRect(size, i)
        var bg = COLOR_GRAY
        if (tabStatus(i) == state.tab) {
            bg = COLOR_BLUE
        }
        displayFillRect(rect.x, rect.y, rect.w, rect.h, bg, COLOR_WHITE, tabLabel(i))
        i += 1
    }

    val raw = ktoxListCatalog(ktoxConfigStorageVaultNames(), state.tab, "")
    val rows = if (raw == "") listOf() else raw.split("\n")
    val perPage = rowsPerPage(size)
    val startIndex = 1 + (state.page - 1) * perPage

    var rowSlot = 1
    while (rowSlot <= perPage) {
        val dataIndex = startIndex + rowSlot - 1
        val rect = itemRowRect(size, rowSlot)
        if (dataIndex <= rows.size) {
            val cols = rows[dataIndex].split(",")
            val status = cols[1]
            val name = cols[2]
            val count = cols[3]
            var countText = count
            if (status == "craftable") {
                countText = "craftable"
            } else if (status == "unavailable") {
                countText = "-"
            }
            val label = "${displayItemName(name)}  ${countText}"
            displayFillRect(rect.x, rect.y, rect.w, rect.h, COLOR_BLACK, COLOR_WHITE, label)
        }
        rowSlot += 1
    }

    val totalPages = totalPagesFor(rows.size, perPage)
    val footerY = paginationFooterY(size)
    if (state.page > 1) {
        displayFillRect(1, footerY, 6, 1, COLOR_GRAY, COLOR_WHITE, "<Prev")
    }
    if (state.page < totalPages) {
        displayFillRect(size.width - 5, footerY, 6, 1, COLOR_GRAY, COLOR_WHITE, "Next>")
    }
    displayFillRect(7, footerY, size.width - 12, 1, COLOR_BLACK, COLOR_GRAY, "Page ${state.page}/${totalPages}")
}

fun renderDetail(state: DashboardState, size: DisplaySize) {
    displayClear()

    val backRect = detailBackRect()
    displayFillRect(backRect.x, backRect.y, backRect.w, backRect.h, COLOR_GRAY, COLOR_WHITE, "<Back")
    displayFillRect(
        backRect.x + backRect.w + 1, 1, size.width - backRect.w - 1, 1,
        COLOR_BLACK, COLOR_WHITE,
        "${displayItemName(state.selectedItem)} (${state.selectedCount})",
    )

    val qtyRect = detailQtyRect(size)
    displayFillRect(qtyRect.x, qtyRect.y, qtyRect.w, qtyRect.h, COLOR_BLACK, COLOR_WHITE, "Qty: ${state.qtyText} (tap to type)")

    val locationRect = detailLocationRect(size)
    displayFillRect(locationRect.x, locationRect.y, locationRect.w, locationRect.h, COLOR_BLACK, COLOR_WHITE, "Location: ${locationLabel(state.locationIndex)} (tap to cycle)")

    val checkboxRect = detailFetchCheckboxRect(size)
    // No square brackets - a literal "[" in a Kotlin string transpiles to
    // an invalid Lua escape sequence, see AGENTS.md's ktox quirks list
    // (hit this exact bug once already, in lib/Cli.kt's usage strings).
    var checkboxLabel = "(off) Fetch after craft"
    if (state.fetchChecked) {
        checkboxLabel = "(ON) Fetch after craft"
    }
    displayFillRect(checkboxRect.x, checkboxRect.y, checkboxRect.w, checkboxRect.h, COLOR_BLACK, COLOR_WHITE, checkboxLabel)

    if (state.selectedStatus == "stocked") {
        val fetchRect = detailFetchButtonRect(size)
        displayFillRect(fetchRect.x, fetchRect.y, fetchRect.w, fetchRect.h, COLOR_LIME, COLOR_BLACK, "FETCH")
    }
    val craftRect = detailCraftButtonRect(size)
    displayFillRect(craftRect.x, craftRect.y, craftRect.w, craftRect.h, COLOR_BLUE, COLOR_WHITE, "CRAFT")
}

// ---- touch handling ----
//
// Pure state transitions - no I/O, no blocking, always safe to call from
// a test. The one exception is the qty field's tap, which transitions to
// "qtyentry" rather than doing the actual keyboard read here - see the
// file header comment and runDashboardLoop.

fun handleDashboardTouch(state: DashboardState, touch: Touch, size: DisplaySize): DashboardState {
    if (state.mode == "browse") {
        return handleBrowseTouch(state, touch, size)
    }
    return handleDetailTouch(state, touch, size)
}

fun handleBrowseTouch(state: DashboardState, touch: Touch, size: DisplaySize): DashboardState {
    var i = 1
    while (i <= 3) {
        val rect = tabRect(size, i)
        if (touchInRect(touch, rect.x, rect.y, rect.w, rect.h)) {
            return DashboardState("browse", tabStatus(i), 1, "", "", "", "1", true, -1, "")
        }
        i += 1
    }

    val raw = ktoxListCatalog(ktoxConfigStorageVaultNames(), state.tab, "")
    val rows = if (raw == "") listOf() else raw.split("\n")
    val perPage = rowsPerPage(size)
    val totalPages = totalPagesFor(rows.size, perPage)
    val footerY = paginationFooterY(size)

    if (state.page > 1 && touchInRect(touch, 1, footerY, 6, 1)) {
        return DashboardState("browse", state.tab, state.page - 1, "", "", "", "1", true, -1, "")
    }
    if (state.page < totalPages && touchInRect(touch, size.width - 5, footerY, 6, 1)) {
        return DashboardState("browse", state.tab, state.page + 1, "", "", "", "1", true, -1, "")
    }

    val startIndex = 1 + (state.page - 1) * perPage
    var rowSlot = 1
    while (rowSlot <= perPage) {
        val rect = itemRowRect(size, rowSlot)
        if (touchInRect(touch, rect.x, rect.y, rect.w, rect.h)) {
            val dataIndex = startIndex + rowSlot - 1
            if (dataIndex <= rows.size) {
                val cols = rows[dataIndex].split(",")
                val status = cols[1]
                val name = cols[2]
                val count = cols[3]
                var countText = count
                if (status == "craftable") {
                    countText = "craftable"
                } else if (status == "unavailable") {
                    countText = "-"
                }
                return DashboardState("detail", state.tab, state.page, name, status, countText, "1", true, -1, "")
            }
        }
        rowSlot += 1
    }

    return state
}

fun handleDetailTouch(state: DashboardState, touch: Touch, size: DisplaySize): DashboardState {
    val backRect = detailBackRect()
    if (touchInRect(touch, backRect.x, backRect.y, backRect.w, backRect.h)) {
        return DashboardState("browse", state.tab, state.page, "", "", "", "1", true, -1, "")
    }

    val qtyRect = detailQtyRect(size)
    if (touchInRect(touch, qtyRect.x, qtyRect.y, qtyRect.w, qtyRect.h)) {
        return DashboardState("qtyentry", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, "")
    }

    val locationRect = detailLocationRect(size)
    if (touchInRect(touch, locationRect.x, locationRect.y, locationRect.w, locationRect.h)) {
        val newIndex = nextLocationIndex(state.locationIndex)
        return DashboardState("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, newIndex, "")
    }

    val checkboxRect = detailFetchCheckboxRect(size)
    if (touchInRect(touch, checkboxRect.x, checkboxRect.y, checkboxRect.w, checkboxRect.h)) {
        return DashboardState("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, !state.fetchChecked, state.locationIndex, "")
    }

    val qty = state.qtyText.toDoubleOrNull()
    if (qty != null && qty > 0.0) {
        if (state.selectedStatus == "stocked") {
            val fetchRect = detailFetchButtonRect(size)
            if (touchInRect(touch, fetchRect.x, fetchRect.y, fetchRect.w, fetchRect.h)) {
                val command = "pull ${state.selectedItem} ${state.qtyText}${locationFlag(state.locationIndex)}"
                return DashboardState("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, command)
            }
        }
        val craftRect = detailCraftButtonRect(size)
        if (touchInRect(touch, craftRect.x, craftRect.y, craftRect.w, craftRect.h)) {
            var fetchFlag = ""
            if (!state.fetchChecked) {
                fetchFlag = " --fetch=false"
            }
            val command = "craft ${state.selectedItem} ${state.qtyText}${locationFlag(state.locationIndex)}${fetchFlag}"
            return DashboardState("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, command)
        }
    }

    return state
}
