package lib

// CC:Tweaked's `colors` API constants (16-color palette, power-of-2
// bitmask values) - no way to bind the `colors` global table itself
// (ktox's @NativeName only targets fixed dotted paths, not table field
// lookups), so these are just the well-known constant values, confirmed
// against this project's own earlier TestMonitor.kt (which independently
// inlined LIME=32/GREEN=8192 for the same reason - matches exactly).
const val COLOR_WHITE = 1
const val COLOR_ORANGE = 2
const val COLOR_MAGENTA = 4
const val COLOR_LIGHT_BLUE = 8
const val COLOR_YELLOW = 16
const val COLOR_LIME = 32
const val COLOR_PINK = 64
const val COLOR_GRAY = 128
const val COLOR_LIGHT_GRAY = 256
const val COLOR_CYAN = 512
const val COLOR_PURPLE = 1024
const val COLOR_BLUE = 2048
const val COLOR_BROWN = 4096
const val COLOR_GREEN = 8192
const val COLOR_RED = 16384
const val COLOR_BLACK = 32768
