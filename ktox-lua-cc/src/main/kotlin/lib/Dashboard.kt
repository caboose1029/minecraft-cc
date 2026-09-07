package lib

import common.ktoxConfigPickupVaultNames
import common.ktoxConfigStorageVaultNames
import common.ktoxDropLastChar
import common.ktoxListCatalog
import lib.COLOR_BLACK
import lib.COLOR_BLUE
import lib.COLOR_GRAY
import lib.COLOR_GREEN
import lib.COLOR_LIGHT_GRAY
import lib.COLOR_LIME
import lib.COLOR_RED
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
// step. Renders onto whatever lib/Display.kt picked (a Monitor
// peripheral, or this computer's own term) and resolves taps into the
// exact same command strings the CLI already accepts, feeding them
// through runCliCommand/rednet unchanged — this file only ever produces
// a String, never touches vault/job logic directly.
//
// Three screens (DashboardState.mode): "browse" (tabs + paginated item
// list), "detail" (one selected item's actions), "keypad" (on-screen
// numeric entry — a Monitor block can't capture keyboard focus like an
// opened Computer/Turtle/Pocket screen can, so quantity entry has to be
// tap-driven to work identically on both display backends).
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
    val mode: String, // "browse" | "detail" | "keypad"
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
// this call.
fun runDashboardLoop(): String {
    var state = freshDashboardState()
    displayInit()
    while (state.readyCommand == "") {
        val size = displaySize()
        renderDashboard(state, size)
        val touch = displayWaitTouch()
        state = handleDashboardTouch(state, touch, size)
    }
    return state.readyCommand
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

// ---- keypad-mode rects (3x4 digit grid + backspace/OK) ----

fun keypadRowY(row: Int): Int {
    return 2 + row
}

fun keypadKeyRect(size: DisplaySize, row: Int, col: Int): Rect {
    return threeColumnRect(size, col, keypadRowY(row), 1)
}

fun keypadKeyLabel(row: Int, col: Int): String {
    if (row == 1) {
        if (col == 1) {
            return "7"
        }
        if (col == 2) {
            return "8"
        }
        return "9"
    }
    if (row == 2) {
        if (col == 1) {
            return "4"
        }
        if (col == 2) {
            return "5"
        }
        return "6"
    }
    if (row == 3) {
        if (col == 1) {
            return "1"
        }
        if (col == 2) {
            return "2"
        }
        return "3"
    }
    if (col == 1) {
        return "<-"
    }
    if (col == 2) {
        return "0"
    }
    return "OK"
}

// ---- rendering ----

fun renderDashboard(state: DashboardState, size: DisplaySize) {
    if (state.mode == "browse") {
        renderBrowse(state, size)
        return
    }
    if (state.mode == "detail") {
        renderDetail(state, size)
        return
    }
    renderKeypad(state, size)
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
    displayFillRect(7, footerY, size.width - 12, 1, COLOR_BLACK, COLOR_LIGHT_GRAY, "Page ${state.page}/${totalPages}")
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
    displayFillRect(qtyRect.x, qtyRect.y, qtyRect.w, qtyRect.h, COLOR_BLACK, COLOR_WHITE, "Qty: ${state.qtyText} (tap to edit)")

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

fun renderKeypad(state: DashboardState, size: DisplaySize) {
    displayClear()
    displayFillRect(1, 1, size.width, 1, COLOR_BLACK, COLOR_WHITE, "Enter quantity: ${state.qtyText}")

    var row = 1
    while (row <= 4) {
        var col = 1
        while (col <= 3) {
            val rect = keypadKeyRect(size, row, col)
            var bg = COLOR_LIGHT_GRAY
            var fg = COLOR_BLACK
            val label = keypadKeyLabel(row, col)
            if (label == "OK") {
                bg = COLOR_GREEN
                fg = COLOR_BLACK
            } else if (label == "<-") {
                bg = COLOR_RED
                fg = COLOR_WHITE
            }
            displayFillRect(rect.x, rect.y, rect.w, rect.h, bg, fg, label)
            col += 1
        }
        row += 1
    }
}

// ---- touch handling ----

fun handleDashboardTouch(state: DashboardState, touch: Touch, size: DisplaySize): DashboardState {
    if (state.mode == "browse") {
        return handleBrowseTouch(state, touch, size)
    }
    if (state.mode == "detail") {
        return handleDetailTouch(state, touch, size)
    }
    return handleKeypadTouch(state, touch, size)
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
        return DashboardState("keypad", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, state.qtyText, state.fetchChecked, state.locationIndex, "")
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

fun handleKeypadTouch(state: DashboardState, touch: Touch, size: DisplaySize): DashboardState {
    var row = 1
    while (row <= 4) {
        var col = 1
        while (col <= 3) {
            val rect = keypadKeyRect(size, row, col)
            if (touchInRect(touch, rect.x, rect.y, rect.w, rect.h)) {
                val label = keypadKeyLabel(row, col)
                if (label == "OK") {
                    var qty = state.qtyText
                    if (qty == "") {
                        qty = "1"
                    }
                    return DashboardState("detail", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, qty, state.fetchChecked, state.locationIndex, "")
                }
                if (label == "<-") {
                    var qty = state.qtyText
                    if (qty != "") {
                        qty = ktoxDropLastChar(qty)
                    }
                    if (qty == "") {
                        qty = "0"
                    }
                    return DashboardState("keypad", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, qty, state.fetchChecked, state.locationIndex, "")
                }
                var qty = state.qtyText
                if (qty == "0") {
                    qty = label
                } else {
                    qty = "${qty}${label}"
                }
                return DashboardState("keypad", state.tab, state.page, state.selectedItem, state.selectedStatus, state.selectedCount, qty, state.fetchChecked, state.locationIndex, "")
            }
            col += 1
        }
        row += 1
    }
    return state
}
