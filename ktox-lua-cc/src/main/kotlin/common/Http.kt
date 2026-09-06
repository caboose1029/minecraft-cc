package common

import com.isycat.ktox.annotations.NativeName
import com.isycat.ktox.annotations.externalSource

// Downloads `url` and writes the raw response body to `path`, overwriting
// any existing file. http.get()'s response handle and fs.open()'s write
// handle are both Lua objects with methods — ktox can't model those as
// Kotlin types yet — so the actual GET + write happens in the shim
// (src/main/lua/ktox-cc-shim.lua). This does NOT create parent
// directories; call fsMakeDir first for any path with a folder in it.

@NativeName("ktoxDownloadFile")
fun ktoxDownloadFile(url: String, path: String): Boolean = externalSource()
