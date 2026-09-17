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

// Same GET, but returns the response body directly instead of writing
// it to disk — for a small text file whose content is needed
// immediately (GhFetch's own file manifest). "MISSING" on any failure.
@NativeName("ktoxDownloadFileText")
fun ktoxDownloadFileText(url: String): String = externalSource()
