package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// A display backend abstraction over either a Monitor peripheral (if one
// is attached to the network) or this computer's own term - see
// ktox-cc-shim.lua's ktoxDisplay* functions for why one code path
// covers both (CC:Tweaked keeps a monitor API-compatible with term) and
// PLAN.md's "Dashboard UI" section for the design this backs.
// UNVERIFIED IN-GAME: never confirmed on a real turtle/pocket computer/
// monitor - see PLAN.md "Known open items".

@NativeName("ktoxDisplayInit")
fun ktoxDisplayInit(): Boolean = externalSource()

@NativeName("ktoxDisplayGetSize")
fun ktoxDisplayGetSizeRaw(): String = externalSource()

@NativeName("ktoxDisplayClear")
fun ktoxDisplayClear(): Boolean = externalSource()

// The one drawing primitive the dashboard uses for every visual element
// (tabs, rows, buttons, checkbox, keypad keys) - pass "" for `text` to
// draw a plain filled rectangle with no label.
@NativeName("ktoxDisplayFillRect")
fun ktoxDisplayFillRect(x: Int, y: Int, w: Int, h: Int, bgColor: Int, textColor: Int, text: String): Boolean =
    externalSource()

@NativeName("ktoxDisplayWaitTouch")
fun ktoxDisplayWaitTouchRaw(): String = externalSource()
