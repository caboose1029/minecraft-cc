package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// There's no `monitor` global to bind directly — a monitor is a peripheral
// reached via peripheral.find("monitor"), and its methods (write, clear,
// getSize, ...) live on that returned handle, not a fixed global path.
// ktox's @NativeName binding idiom only targets fixed global dotted paths,
// so each of these binds to a hand-written shim in
// src/main/lua/ktox-cc-shim.lua that does the peripheral.find() + method
// call(s) in one step and returns a single, Kotlin-representable value.
// Assumes exactly one monitor on the network. See AGENTS.md.

@NativeName("ktoxMonitorClear")
fun ktoxMonitorClear(): Boolean = externalSource()

// monitor.getSize() returns 2 values in Lua; packed as a comma-joined
// string, same idiom as ktoxGpsLocateRaw (see Gps.kt).
@NativeName("ktoxMonitorGetSize")
fun ktoxMonitorGetSizeRaw(): String? = externalSource()

@NativeName("ktoxMonitorDrawButton")
fun ktoxMonitorDrawButton(x: Int, y: Int, w: Int, h: Int, text: String, bgColor: Int): Boolean = externalSource()

// os.pullEvent("monitor_touch") returns 4 values in Lua; packed as a
// comma-joined "x,y" string (the event name and monitor side are
// discarded in the shim — single-monitor rig, see ktox-cc-shim.lua).
@NativeName("ktoxWaitMonitorTouch")
fun ktoxWaitMonitorTouchRaw(): String = externalSource()
