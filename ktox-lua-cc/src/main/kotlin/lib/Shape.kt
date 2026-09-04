package lib

import common.mathSqrt

// Explicit same-package import, not strictly needed for Kotlin itself,
// but required for correct Lua output: ktox only emits a
// ktox_require(...) for an explicitly imported symbol, even within the
// same Kotlin package - confirmed via CraftOS-PC that without this,
// Shape.lua's use of IntSpan:new(...) fails with "attempt to index
// global 'IntSpan' (a nil value)" unless some OTHER already-loaded file
// happened to require lib/Span first. See AGENTS.md.
import lib.IntSpan

// Non-rectangular footprint shapes for Digsite. A shape is defined purely
// in terms of local, 0-based (row, column) coordinates — row steps along
// the turtle's forward axis starting at the home row (row 0), column
// steps along its right-hand axis starting at the home column (column
// 0) — the same right/forward basis Digsite already builds from
// homeHeading. Callers translate (row, column) into world x/z themselves.
//
// Plain top-level String constants, NOT `enum class` — confirmed via
// CraftOS-PC that ktox compiles an enum class to a Lua table declared
// `local` (e.g. `local ShapeKind = {}`), which only works when every use
// stays inside the same generated file (like MoveSign in Movement.kt).
// Referenced from a different file (here, Digsite.kt via
// ktox_require("lib/Shape")), that local is invisible and every access
// fails with "attempt to index global 'ShapeKind' (a nil value)". A
// top-level `const val` has no such problem (see FUEL_SAFETY_MARGIN in
// Digsite.kt) - it transpiles to a genuine global. See AGENTS.md.
const val SHAPE_TRIANGLE = "TRIANGLE"
const val SHAPE_RIGHT_TRIANGLE = "RIGHT_TRIANGLE"
const val SHAPE_CIRCLE = "CIRCLE"

// How many rows a shape spans for a given size (side length for the
// triangles, radius for the circle). For TRIANGLE this is its actual
// height in rows (about half its base width, since it narrows by 2 per
// row), NOT `size` itself — shapeRowBounds already returns null past
// that point, but stopping the loop there avoids pointlessly iterating
// over rows that can never have any content.
fun shapeRowCount(shape: String, size: Int): Int {
    if (shape == SHAPE_CIRCLE) {
        return 2 * size + 1
    }
    if (shape == SHAPE_TRIANGLE) {
        // floor((size - 1) / 2) + 1, division-safe per AGENTS.md (see
        // shapeSpineColumn below for the same trick).
        val n = size - 1
        val half = (n - n % 2) / 2
        return half + 1
    }
    return size
}

// The inclusive [start, finish] column range included in the given row,
// or null once the shape has narrowed to nothing (past the triangle's
// apex / the circle's cap) — callers should stop there rather than call
// this for a row beyond shapeRowCount.
//
// TRIANGLE: an isoceles triangle, base (full `size` width) on row 0,
// narrowing symmetrically by 1 column on each side per row - width goes
// size, size-2, size-4, ... until it would go non-positive.
//
// RIGHT_TRIANGLE: a right isoceles triangle (both legs = `size`) with its
// right-angle vertex at (row 0, column 0) - narrows by 1 column per row,
// but only from the far edge (column 0 stays included on every row),
// unlike TRIANGLE's symmetric narrowing.
//
// CIRCLE: a filled disk of the given radius, centered on row `size`
// (i.e. `size` rows above and below the middle row) - each row's width is
// the circle's chord at that height, via floor(sqrt(r^2 - dz^2)).
fun shapeRowBounds(shape: String, size: Int, row: Int): IntSpan? {
    if (shape == SHAPE_TRIANGLE) {
        val start = row
        val finish = size - 1 - row
        if (start > finish) {
            return null
        }
        return IntSpan(start, finish)
    }
    if (shape == SHAPE_RIGHT_TRIANGLE) {
        val finish = size - 1 - row
        if (finish < 0) {
            return null
        }
        return IntSpan(0, finish)
    }
    val radius = size
    val dz = row - radius
    val remaining = radius * radius - dz * dz
    if (remaining < 0) {
        return null
    }
    val dx = sqrtFloor(remaining)
    return IntSpan(radius - dx, radius + dx)
}

// The column that stays inside every row of the shape (see
// shapeRowBounds) - safe to use as a transit path between rows, since
// every cell along it is guaranteed part of the shape and never needs
// digging around.
fun shapeSpineColumn(shape: String, size: Int): Int {
    if (shape == SHAPE_TRIANGLE) {
        // (size - 1) / 2, but subtracting the remainder before dividing -
        // ktox transpiles `/` to Lua's always-floating-point division, so
        // a plain `(size - 1) / 2` would produce a `.5` column for even
        // `size` that no integer column index can ever equal. See
        // AGENTS.md and ExcavatePro's halfWidth/halfLength.
        val n = size - 1
        return (n - n % 2) / 2
    }
    if (shape == SHAPE_CIRCLE) {
        return size
    }
    return 0
}

// floor(sqrt(n)) for n >= 0, via the Lua math.sqrt binding (see
// common/Math.kt). Truncation toward zero and floor agree here since
// sqrt(n) for a non-negative n is always >= 0 - confirmed empirically via
// CraftOS-PC (math.sqrt + Int/Double conversions all behave as expected,
// unlike some other numeric ktox quirks documented in AGENTS.md).
fun sqrtFloor(n: Int): Int {
    return mathSqrt(n.toDouble()).toInt()
}
