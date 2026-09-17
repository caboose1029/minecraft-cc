package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Binding to Lua's `math` global. See Turtle.kt for the binding idiom.

@NativeName("math.sqrt")
fun mathSqrt(x: Double): Double = externalSource()
