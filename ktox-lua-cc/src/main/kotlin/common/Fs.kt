package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Bindings to CC:Tweaked's `fs` API. See Turtle.kt for the binding idiom.
//
// `fs.open` (file handles) and `fs.list` (returns a Lua table of names)
// aren't modeled yet — file handles are Lua tables with their own methods,
// which needs a proper Kotlin type, and that's follow-up work, not core
// essentials.

@NativeName("fs.exists")
fun fsExists(path: String): Boolean = externalSource()

@NativeName("fs.isDir")
fun fsIsDir(path: String): Boolean = externalSource()

@NativeName("fs.isReadOnly")
fun fsIsReadOnly(path: String): Boolean = externalSource()

@NativeName("fs.makeDir")
fun fsMakeDir(path: String): Unit = externalSource()

@NativeName("fs.delete")
fun fsDelete(path: String): Unit = externalSource()

@NativeName("fs.combine")
fun fsCombine(basePath: String, localPath: String): String = externalSource()

@NativeName("fs.getSize")
fun fsGetSize(path: String): Int = externalSource()

@NativeName("fs.getFreeSpace")
fun fsGetFreeSpace(path: String): Int = externalSource()
