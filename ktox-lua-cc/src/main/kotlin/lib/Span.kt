package lib

// An inclusive [start, finish] integer range that preserves direction —
// unlike a sorted min:max pair, start > finish is a valid descending span.
// Shared by any program that sweeps a bounded x/y/z footprint (Digsite,
// ExcavatePro).
data class IntSpan(val start: Int, val finish: Int)

fun stepFor(span: IntSpan): Int {
    return if (span.start <= span.finish) 1 else -1
}

// True once `current` has moved past `limit` while stepping by `step`
// (whose sign gives the direction of travel).
//
// Written as an if/else block, NOT `return if (cond) A else B` — ktox
// compiles that single-expression form to Lua's `(cond and A or B)`
// idiom, which is broken here: A (`current > limit`) is itself a
// boolean, and whenever it's false, `cond and false` is false, so Lua
// falls through to B regardless of cond. See AGENTS.md.
fun pastEnd(current: Int, limit: Int, step: Int): Boolean {
    if (step > 0) {
        return current > limit
    }
    return current < limit
}
