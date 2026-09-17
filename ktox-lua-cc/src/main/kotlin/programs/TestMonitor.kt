package programs

import common.ktoxMonitorClear
import common.ktoxMonitorDrawButton
import common.ktoxMonitorGetSizeRaw
import common.ktoxWaitMonitorTouchRaw

// Smoke test for a monitor peripheral + touch input: draws one button,
// waits for it to be touched, redraws it to confirm the touch landed.
// Assumes exactly one monitor peripheral on the network. See
// common/Monitor.kt / ktox-cc-shim.lua for the binding this relies on.

// CC:Tweaked color constants (colors.lime / colors.green) - no Colors.kt
// header exists yet, so inlined as raw ints for this one-off test rather
// than adding shared top-level consts that could collide with a future
// program's own color constants (see AGENTS.md on package-wide name
// collisions).
const val TEST_MONITOR_LIME = 32
const val TEST_MONITOR_GREEN = 8192

fun main() {
    val cleared = ktoxMonitorClear()
    if (!cleared) {
        println("No monitor peripheral found - attach one and try again.")
        return
    }

    val sizeRaw = ktoxMonitorGetSizeRaw()
    if (sizeRaw == null) {
        println("Monitor disappeared before size could be read.")
        return
    }
    // ktox does NOT offset List indexing from Kotlin's 0-based convention
    // to Lua's 1-based tables - parts[1] is the first element. See
    // AGENTS.md and lib/Position.kt for the same idiom.
    val sizeParts = sizeRaw.split(",")
    val monitorW = sizeParts[1].toDouble().toInt()
    val monitorH = sizeParts[2].toDouble().toInt()

    val buttonW = 11
    val buttonH = 3
    // Never divide two Kotlin Ints directly when the result feeds a
    // coordinate - ktox's `/` transpiles to Lua's always-float division,
    // so an odd (monitorW - buttonW) would produce a `.5` cursor position.
    // Subtract off the remainder first to guarantee a true whole number.
    val diffX = monitorW - buttonW
    val diffY = monitorH - buttonH
    val buttonX = 1 + (diffX - diffX % 2) / 2
    val buttonY = 1 + (diffY - diffY % 2) / 2

    ktoxMonitorDrawButton(buttonX, buttonY, buttonW, buttonH, "PRESS ME", TEST_MONITOR_LIME)
    println("Button drawn. Waiting for a monitor touch...")

    var pressed = false
    while (!pressed) {
        val touchRaw = ktoxWaitMonitorTouchRaw()
        val touchParts = touchRaw.split(",")
        val touchX = touchParts[1].toDouble().toInt()
        val touchY = touchParts[2].toDouble().toInt()
        if (touchX >= buttonX && touchX < buttonX + buttonW && touchY >= buttonY && touchY < buttonY + buttonH) {
            ktoxMonitorDrawButton(buttonX, buttonY, buttonW, buttonH, "PRESSED!", TEST_MONITOR_GREEN)
            println("Button pressed at (${touchX}, ${touchY}).")
            pressed = true
        }
    }
}
