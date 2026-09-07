package lib

import common.ktoxDisplayClear
import common.ktoxDisplayFillRect
import common.ktoxDisplayGetSizeRaw
import common.ktoxDisplayInit
import common.ktoxDisplayWaitTouchRaw

data class DisplaySize(val width: Int, val height: Int)
data class Touch(val x: Int, val y: Int)

// Initializes the display backend (Monitor peripheral if attached,
// otherwise this computer's own term - see common/Display.kt /
// ktox-cc-shim.lua) and returns its size. Always succeeds - term always
// exists as a fallback.
fun displayInit(): DisplaySize {
    ktoxDisplayInit()
    return displaySize()
}

fun displaySize(): DisplaySize {
    val raw = ktoxDisplayGetSizeRaw()
    // ktox does NOT offset List indexing from Kotlin's 0-based convention
    // to Lua's 1-based tables - indices below are 1-based on purpose to
    // match what ktox_split actually produces. See AGENTS.md.
    val parts = raw.split(",")
    return DisplaySize(parts[1].toDouble().toInt(), parts[2].toDouble().toInt())
}

fun displayClear() {
    ktoxDisplayClear()
}

// The one drawing primitive the dashboard uses for every visual element.
// Pass "" for text to draw a plain filled rectangle with no label.
fun displayFillRect(x: Int, y: Int, w: Int, h: Int, bgColor: Int, textColor: Int, text: String) {
    ktoxDisplayFillRect(x, y, w, h, bgColor, textColor, text)
}

// Blocks until the display is touched.
fun displayWaitTouch(): Touch {
    val raw = ktoxDisplayWaitTouchRaw()
    val parts = raw.split(",")
    return Touch(parts[1].toDouble().toInt(), parts[2].toDouble().toInt())
}

// Whether `t` landed inside the (x, y, w, h) rectangle - shared hit-test
// used for every tappable region in the dashboard.
fun touchInRect(t: Touch, x: Int, y: Int, w: Int, h: Int): Boolean {
    return t.x >= x && t.x < x + w && t.y >= y && t.y < y + h
}
