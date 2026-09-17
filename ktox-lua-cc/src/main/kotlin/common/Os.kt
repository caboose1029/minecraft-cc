package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Bindings to CC:Tweaked's `os` API. See Turtle.kt for the binding idiom.
//
// `os.pullEvent` genuinely returns a variable-length Lua tuple (event name
// plus event-specific args); Kotlin can't express that, so only the event
// name is modeled here. Event-specific payloads aren't accessible through
// this binding yet.

@NativeName("os.pullEvent")
fun osPullEvent(): String = externalSource()

@NativeName("os.pullEvent")
fun osPullEvent(filter: String): String = externalSource()

@NativeName("os.queueEvent")
fun osQueueEvent(event: String): Unit = externalSource()

@NativeName("os.sleep")
fun osSleep(seconds: Double): Unit = externalSource()

@NativeName("os.startTimer")
fun osStartTimer(seconds: Double): Int = externalSource()

@NativeName("os.cancelTimer")
fun osCancelTimer(id: Int): Unit = externalSource()

@NativeName("os.getComputerID")
fun osGetComputerID(): Int = externalSource()

@NativeName("os.getComputerLabel")
fun osGetComputerLabel(): String = externalSource()

@NativeName("os.setComputerLabel")
fun osSetComputerLabel(label: String): Unit = externalSource()

@NativeName("os.time")
fun osTime(): Double = externalSource()

@NativeName("os.day")
fun osDay(): Int = externalSource()

@NativeName("os.epoch")
fun osEpoch(): Double = externalSource()

@NativeName("os.shutdown")
fun osShutdown(): Unit = externalSource()

@NativeName("os.reboot")
fun osReboot(): Unit = externalSource()
