package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Bindings to CC:Tweaked's `term` API. See Turtle.kt for the binding idiom.
//
// `term.getSize`/`term.getCursorPos` return multiple values in Lua, which
// Kotlin can't express directly — left out until that's solved.

@NativeName("term.write")
fun termWrite(text: String): Unit = externalSource()

@NativeName("term.clear")
fun termClear(): Unit = externalSource()

@NativeName("term.clearLine")
fun termClearLine(): Unit = externalSource()

@NativeName("term.setCursorPos")
fun termSetCursorPos(x: Int, y: Int): Unit = externalSource()

@NativeName("term.setTextColor")
fun termSetTextColor(color: Int): Unit = externalSource()

@NativeName("term.setBackgroundColor")
fun termSetBackgroundColor(color: Int): Unit = externalSource()

@NativeName("term.scroll")
fun termScroll(lines: Int): Unit = externalSource()
