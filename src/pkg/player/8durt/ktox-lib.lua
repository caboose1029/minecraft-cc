-- ktox-lib.lua
-- Runtime support library for Kotlin-to-Lua transpiled code.
-- Provides Lua equivalents of Kotlin standard-library scope functions and
-- iterable/collection functions.
--
-- Performance notes: all collection helpers use numeric-for loops
-- (faster than ipairs — no iterator closure), cache #t in a local when
-- used more than once, and build result tables with index assignment +
-- counter rather than table.insert (avoids the function-call overhead).

-- -------------------------------------------------------------------------
-- Module guard – prevent re-executing on repeated require() calls.
-- Lua's require() caches via package.loaded, but this guard also protects
-- against dofile() or manual re-loading in embedded environments.
-- -------------------------------------------------------------------------

if _G.ktox_lib_loaded then return end
_G.ktox_lib_loaded = true

-- -------------------------------------------------------------------------
-- Require deduplication
-- -------------------------------------------------------------------------

-- ktox_require: deduplicated require. Calls require() at most once per path.
local _ktox_required = {}
function ktox_require(path)
    if _ktox_required[path] then return end
    _ktox_required[path] = true
    return require(path)
end

-- -------------------------------------------------------------------------
-- Source-map traceback
-- -------------------------------------------------------------------------

-- ktox_sourcemap_traceback: register a Lua→Kotlin source map for fileName
-- and install a debug.traceback wrapper that rewrites ".lua:N" references
-- in tracebacks to "<kotlinFile>:M" using the registered maps.
--
-- fileName:    the Lua file name (from debug.getinfo(1).short_src).
-- kotlinFile:  the full Kotlin source file path (e.g. "features/Foo.kt").
-- sourceMap:   range-keyed table {["N"]=K, ["N-M"]=K, ...} where N/M are Lua
--              line numbers and K is the corresponding Kotlin line number.
-- Called once per module, at module load time.
function ktox_sourcemap_traceback(fileName, kotlinFile, sourceMap, kotlinPkg)
    _G.ktox_sourcemap = _G.ktox_sourcemap or {}
    _G.ktox_sourcemap[fileName] = {ktFile = kotlinFile, map = sourceMap, ktPkg = kotlinPkg}
    if _G.ktox_originalTraceback == nil then
        if not (debug and debug.traceback) then
            print("WARNING: debug.traceback is not defined in this environment. Source traceback will not function.")
            return nil
        end
        _G.ktox_originalTraceback = debug.traceback
        debug.traceback = function(...)
            local tb = _G.ktox_originalTraceback(...)
            if type(tb) ~= "string" then return tb end

            -- Rewrite error message: @FileName.lua:Line ... -> @ktox.lua(FileName.lua:Line) ...
            -- The goal is to keep @FileName.lua at the start so that the IDE can link to it.
            tb = tb:gsub("^(@%S+%.lua):(%d+)", function(fileAt, line)
                local fileNameWithAt = tostring(fileAt)
                local file = fileNameWithAt:sub(2)
                return "@ktox.lua(" .. file .. ":" .. line .. ")"
            end)

            -- Rewrite stack trace lines: FileName.lua:Line: in ... -> pkg(FileName.kt:Line): in ...
            return (tb:gsub("(%S+)%.lua:(%d+)", function(file, line)
                local entry = _G.ktox_sourcemap[tostring(file) .. ".lua"]
                if entry then
                    local n = tonumber(line)
                    for key, val in pairs(entry.map) do
                        local rangeStart, rangeEnd = key:match("^(%d+)-(%d+)$")
                        if rangeStart then
                            if n >= tonumber(rangeStart) and n <= tonumber(rangeEnd) then
                                local ktFileName = entry.ktFile:match("([^/%\\]+)$") or entry.ktFile
                                local prefix = entry.ktPkg or ktFileName
                                if entry.ktPkg and entry.ktPkg ~= "" then
                                    return prefix .. "(" .. ktFileName .. ":" .. tostring(val) .. ")"
                                else
                                    return ktFileName .. ":" .. tostring(val)
                                end
                            end
                        else
                            if tonumber(key) == n then
                                local ktFileName = entry.ktFile:match("([^/%\\]+)$") or entry.ktFile
                                local prefix = entry.ktPkg or ktFileName
                                if entry.ktPkg and entry.ktPkg ~= "" then
                                    return prefix .. "(" .. ktFileName .. ":" .. tostring(val) .. ")"
                                else
                                    return ktFileName .. ":" .. tostring(val)
                                end
                            end
                        end
                    end
                end
                return file .. ".lua:" .. line
            end))
        end
    end
end


-- -------------------------------------------------------------------------
-- Standard functions
-- -------------------------------------------------------------------------

local original_print = print

-- println: standard print with newline.
function println(...)
    original_print(...)
end

if io and io.write then
    -- print without newline
    function print(...)
        local args = {...}
        for i, v in ipairs(args) do
            io.write(tostring(v))
            if i < #args then
                io.write("\t")
            end
        end
    end
else
    -- fallback: use original print (always newline, sorry)
    function print(...)
        original_print(...)
    end
end

-- Kotlin `also`: calls fn(obj), then returns obj.
function ktox_also(obj, fn)
    fn(obj)
    return obj
end

-- Kotlin `let`: calls fn(obj), returns fn's result.
function ktox_let(obj, fn)
    return fn(obj)
end

-- Kotlin `takeIf`: returns obj when fn(obj) is truthy, otherwise nil.
function ktox_takeIf(obj, fn)
    if fn(obj) then return obj end
    return nil
end

-- Kotlin `apply`: calls fn(obj) with obj as the receiver (`self`), then returns obj.
function ktox_apply(obj, fn)
    fn(obj)
    return obj
end

-- Null-safe call for statement use: calls fn(obj) only when obj is not nil.
-- Used by Kotlin `?.let`, `?.also`, `?.run`, `?.apply`, `?.takeIf` etc. when
-- the result is discarded, ensuring the receiver is evaluated exactly once.
function ktox_safe_call(obj, fn)
    if obj ~= nil then fn(obj) end
end

-- Kotlin elvis `?:` operator: returns `a` when a ~= nil, otherwise `b`.
-- This avoids the `a and a or b` pitfall where `false` is treated as nil.
function ktox_elvis(a, b)
    if a ~= nil then return a else return b end
end

-- Kotlin `is` check for user-defined class types.
-- Walks the metatable chain of `obj` to determine if it is an instance of `cls`
-- or any of its parent classes (i.e. supports inheritance).
-- Returns true if `obj` was constructed from `cls` or a subclass of `cls`.
-- For primitive types (string, number, boolean) use Lua's type() directly.
--
-- Class metatable chain (as emitted by ktox-lua):
--   instance         → getmetatable → DogClass
--   DogClass         = setmetatable({}, {__index = AnimalClass})
--                       getmetatable → {__index = AnimalClass}
--   AnimalClass      = setmetatable({}, …) or plain {}
--                       getmetatable → {__index = …} or nil (no further parent)
function ktox_isinstance(obj, cls)
    if obj == nil then return false end
    local mt = getmetatable(obj)
    while mt ~= nil do
        if mt == cls then return true end
        -- Each class table's metatable is an anonymous proxy {__index = ParentClass}.
        -- Walk through it to reach the parent class table.
        local proxy = getmetatable(mt)
        if proxy == nil then break end
        local parent = proxy.__index
        if parent == nil or parent == mt then break end
        mt = parent
    end
    return false
end

-- -------------------------------------------------------------------------
-- Range constructors
-- -------------------------------------------------------------------------

-- ktox_rangeUntil: builds an array of integers [start, stop) (exclusive upper bound).
-- Equivalent to Kotlin's `start until stop`.
function ktox_rangeUntil(start, stop)
    local t, n = {}, 0
    for i = start, stop - 1 do n = n + 1; t[n] = i end
    return t
end

-- ktox_rangeDownTo: builds an array of integers [start, stop] in descending order.
-- Equivalent to Kotlin's `start downTo stop`.
function ktox_rangeDownTo(start, stop)
    local t, n = {}, 0
    for i = start, stop, -1 do n = n + 1; t[n] = i end
    return t
end

-- -------------------------------------------------------------------------
-- Iteration / side-effects
-- -------------------------------------------------------------------------

-- forEach: calls fn(value) for each element.
function ktox_forEach(t, fn)
    for i = 1, #t do fn(t[i]) end
end

-- forEachIndexed: calls fn(index, value) for each element.
function ktox_forEachIndexed(t, fn)
    for i = 1, #t do fn(i, t[i]) end
end

-- -------------------------------------------------------------------------
-- Transformation
-- -------------------------------------------------------------------------

-- map: returns a new table with fn(value) applied to each element.
function ktox_map(t, fn)
    local n = #t
    local r = {}
    for i = 1, n do r[i] = fn(t[i]) end
    return r
end

-- mapIndexed: like map but fn receives (index, value).
function ktox_mapIndexed(t, fn)
    local n = #t
    local r = {}
    for i = 1, n do r[i] = fn(i, t[i]) end
    return r
end

-- filter: returns a new table containing elements where fn(value) is truthy.
function ktox_filter(t, fn)
    local r, n = {}, 0
    for i = 1, #t do
        local v = t[i]
        if fn(v) then n = n + 1; r[n] = v end
    end
    return r
end

-- filterIndexed: like filter but fn receives (index, value).
function ktox_filterIndexed(t, fn)
    local r, n = {}, 0
    for i = 1, #t do
        local v = t[i]
        if fn(i, v) then n = n + 1; r[n] = v end
    end
    return r
end

-- filterNotNull: returns a new table with all nil values removed.
function ktox_filterNotNull(t)
    local r, n = {}, 0
    for i = 1, #t do
        local v = t[i]
        if v ~= nil then n = n + 1; r[n] = v end
    end
    return r
end

-- mapNotNull: maps each element with fn and returns a new table with nil results removed.
function ktox_mapNotNull(t, fn)
    local r, n = {}, 0
    for i = 1, #t do
        local v = fn(t[i])
        if v ~= nil then n = n + 1; r[n] = v end
    end
    return r
end

-- flatMap: maps each element to a table with fn, then flattens one level.
function ktox_flatMap(t, fn)
    local r, n = {}, 0
    for i = 1, #t do
        local inner = fn(t[i])
        for j = 1, #inner do n = n + 1; r[n] = inner[j] end
    end
    return r
end

-- flatten: flattens one level of nested tables.
function ktox_flatten(t)
    local r, n = {}, 0
    for i = 1, #t do
        local inner = t[i]
        for j = 1, #inner do n = n + 1; r[n] = inner[j] end
    end
    return r
end

-- -------------------------------------------------------------------------
-- Aggregation / folding
-- -------------------------------------------------------------------------

-- fold: reduces the table with an initial accumulator value.
-- fn receives (accumulator, value).
function ktox_fold(t, init, fn)
    local acc = init
    for i = 1, #t do acc = fn(acc, t[i]) end
    return acc
end

-- reduce: folds using the first element as the initial accumulator.
-- fn receives (accumulator, value).
function ktox_reduce(t, fn)
    local acc = t[1]
    for i = 2, #t do acc = fn(acc, t[i]) end
    return acc
end

-- sum: sum of a numeric sequence.
function ktox_sum(t)
    local s = 0
    for i = 1, #t do s = s + t[i] end
    return s
end

-- sumOf: sum of fn(element) over the sequence.
function ktox_sumOf(t, fn)
    local s = 0
    for i = 1, #t do s = s + fn(t[i]) end
    return s
end

-- -------------------------------------------------------------------------
-- Predicates
-- -------------------------------------------------------------------------

-- any: true if fn(value) is truthy for at least one element.
function ktox_any(t, fn)
    for i = 1, #t do if fn(t[i]) then return true end end
    return false
end

-- all: true if fn(value) is truthy for every element.
function ktox_all(t, fn)
    for i = 1, #t do if not fn(t[i]) then return false end end
    return true
end

-- none: true if fn(value) is falsy for every element.
function ktox_none(t, fn)
    for i = 1, #t do if fn(t[i]) then return false end end
    return true
end

-- count: number of elements, or number matching fn when provided.
-- For strings, returns the length (#s).
function ktox_count(t, fn)
    if type(t) == "string" then return #t end
    if fn == nil then
        local n = #t
        if n > 0 then return n end
        -- t may be a string-keyed map; pairs() is safe for both cases.
        for _ in pairs(t) do n = n + 1 end
        return n
    end
    local n = 0
    for i = 1, #t do if fn(t[i]) then n = n + 1 end end
    return n
end

-- contains: true if value is present in the sequence, is a key in a map, or is
-- a substring of a string.
function ktox_contains(t, value)
    if type(t) == "string" then
        return t:find(value, 1, true) ~= nil
    end
    local n = #t
    if n > 0 then
        for i = 1, n do if t[i] == value then return true end end
        return false
    end
    -- Empty table → false; non-empty string-keyed map → key existence check.
    if next(t) == nil then return false end
    return t[value] ~= nil
end

-- -------------------------------------------------------------------------
-- Element access
-- -------------------------------------------------------------------------

-- find / firstOrNull: returns the first element where fn(value) is truthy, or nil.
function ktox_find(t, fn)
    for i = 1, #t do
        local v = t[i]
        if fn(v) then return v end
    end
    return nil
end
ktox_firstOrNull = ktox_find

-- first: returns t[1], or the first element matching fn, errors if not found.
function ktox_first(t, fn)
    if fn == nil then return t[1] end
    for i = 1, #t do
        local v = t[i]
        if fn(v) then return v end
    end
    error("ktox_first: no matching element", 2)
end

-- last: returns t[#t], or the last element matching fn, errors if not found.
function ktox_last(t, fn)
    local n = #t
    if fn == nil then return t[n] end
    for i = n, 1, -1 do
        local v = t[i]
        if fn(v) then return v end
    end
    error("ktox_last: no matching element", 2)
end

-- lastOrNull: last element matching fn, or nil.
function ktox_lastOrNull(t, fn)
    local n = #t
    if fn == nil then return t[n] end
    for i = n, 1, -1 do
        local v = t[i]
        if fn(v) then return v end
    end
    return nil
end

-- minOrNull: smallest element in a numeric sequence, or nil when empty.
function ktox_minOrNull(t)
    local n = #t
    if n == 0 then return nil end
    local m = t[1]
    for i = 2, n do if t[i] < m then m = t[i] end end
    return m
end

-- maxOrNull: largest element in a numeric sequence, or nil when empty.
function ktox_maxOrNull(t)
    local n = #t
    if n == 0 then return nil end
    local m = t[1]
    for i = 2, n do if t[i] > m then m = t[i] end end
    return m
end

-- minByOrNull: element with the smallest fn(element) key, or nil when empty.
function ktox_minByOrNull(t, fn)
    local n = #t
    if n == 0 then return nil end
    local best, bestKey = t[1], fn(t[1])
    for i = 2, n do
        local v = t[i]; local k = fn(v)
        if k < bestKey then best = v; bestKey = k end
    end
    return best
end

-- maxByOrNull: element with the largest fn(element) key, or nil when empty.
function ktox_maxByOrNull(t, fn)
    local n = #t
    if n == 0 then return nil end
    local best, bestKey = t[1], fn(t[1])
    for i = 2, n do
        local v = t[i]; local k = fn(v)
        if k > bestKey then best = v; bestKey = k end
    end
    return best
end

-- -------------------------------------------------------------------------
-- Ordering / deduplication
-- -------------------------------------------------------------------------

-- distinct: returns a copy with duplicate values removed (first occurrence wins).
function ktox_distinct(t)
    local r, n, seen = {}, 0, {}
    for i = 1, #t do
        local v = t[i]
        if not seen[v] then seen[v] = true; n = n + 1; r[n] = v end
    end
    return r
end

-- reversed: returns a new table with elements in reverse order, or a reversed string.
function ktox_reversed(t)
    if type(t) == "string" then return t:reverse() end
    local n = #t
    local r = {}
    for i = 1, n do r[i] = t[n - i + 1] end
    return r
end

-- sortedBy: returns a sorted copy keyed by fn(element) ascending.
function ktox_sortedBy(t, fn)
    local n = #t
    local r = {}
    for i = 1, n do r[i] = t[i] end
    table.sort(r, function(a, b) return fn(a) < fn(b) end)
    return r
end

-- sortedByDescending: returns a sorted copy keyed by fn(element) descending.
function ktox_sortedByDescending(t, fn)
    local n = #t
    local r = {}
    for i = 1, n do r[i] = t[i] end
    table.sort(r, function(a, b) return fn(a) > fn(b) end)
    return r
end

-- -------------------------------------------------------------------------
-- Grouping / association
-- -------------------------------------------------------------------------

-- groupBy: groups elements into a table of lists keyed by fn(element).
function ktox_groupBy(t, fn)
    local r = {}
    for i = 1, #t do
        local v = t[i]; local k = fn(v)
        local g = r[k]
        if g == nil then g = {}; r[k] = g end
        g[#g + 1] = v
    end
    return r
end

-- associateBy: creates a table mapping fn(element) → element.
function ktox_associateBy(t, fn)
    local r = {}
    for i = 1, #t do local v = t[i]; r[fn(v)] = v end
    return r
end

-- zip: pairs elements from two sequences up to the shorter length.
-- Optional fn(a, b) transforms each pair; otherwise returns {a, b} tables.
function ktox_zip(t1, t2, fn)
    local n = math.min(#t1, #t2)
    local r = {}
    if fn == nil then
        for i = 1, n do r[i] = {t1[i], t2[i]} end
    else
        for i = 1, n do r[i] = fn(t1[i], t2[i]) end
    end
    return r
end

-- -------------------------------------------------------------------------
-- Slicing / building
-- -------------------------------------------------------------------------

-- toList: returns a shallow copy of the sequence.
function ktox_toList(t)
    local n = #t
    local r = {}
    for i = 1, n do r[i] = t[i] end
    return r
end

-- plus: concatenates two sequences, appends a scalar to a list, or merges maps.
-- • list + list   → concatenated list
-- • list + scalar → list with scalar appended
-- • map  + map    → merged map (right-hand entries win)
-- • map  + pair   → map with the pair {key, value} inserted
function ktox_plus(t1, t2)
    if type(t2) ~= "table" then
        -- List + scalar: append element.
        local n = #t1
        local r = {}
        for i = 1, n do r[i] = t1[i] end
        r[n + 1] = t2
        return r
    end
    local t1_is_map = #t1 == 0 and next(t1) ~= nil
    local t2_is_map = #t2 == 0 and next(t2) ~= nil
    if t1_is_map or t2_is_map then
        -- At least one operand is a string-keyed map: perform map merge.
        -- This also covers the edge case of an empty map + a map (e.g. {} + mapOf("a" to 1)).
        local r = {}
        for k, v in pairs(t1) do r[k] = v end
        if #t2 > 0 then
            -- t2 is a Pair represented as {key, value}.
            r[t2[1]] = t2[2]
        else
            for k, v in pairs(t2) do r[k] = v end
        end
        return r
    end
    -- List + List (default).
    local n1 = #t1
    local r = {}
    for i = 1, n1 do r[i] = t1[i] end
    for i = 1, #t2 do r[n1 + i] = t2[i] end
    return r
end

-- mapPlus: explicitly map + pair/map operation.
-- Use this (emitted by the transpiler) when the left-hand side is known to be
-- a map at compile time, including the empty-map case that ktox_plus cannot
-- distinguish from an empty list.
-- • map + pair  → new map with the pair {key, value} inserted
-- • map + map   → new map merged (right-hand entries win)
function ktox_mapPlus(m1, m2)
    local r = {}
    for k, v in pairs(m1) do r[k] = v end
    if #m2 > 0 then
        -- m2 is a Pair represented as {key, value}.
        r[m2[1]] = m2[2]
    else
        -- m2 is another map.
        for k, v in pairs(m2) do r[k] = v end
    end
    return r
end

-- minus: removes an element from a list or a key from a map.
-- • list - scalar → new list with all occurrences of scalar removed
-- • map  - key    → new map without the given key
function ktox_minus(t, elem)
    if #t == 0 then
        -- Map: remove key.
        local r = {}
        for k, v in pairs(t) do
            if k ~= elem then r[k] = v end
        end
        return r
    end
    -- List: remove all occurrences of elem.
    local r, n = {}, 0
    for i = 1, #t do
        local v = t[i]
        if v ~= elem then n = n + 1; r[n] = v end
    end
    return r
end

-- plusAssign: implements Kotlin's `+=` operator for both numeric, string, and collection types.
-- • number += number → arithmetic addition
-- • string += string → concatenation
-- • list   += element → new list with element appended  (rebinds the variable)
-- • list   += list    → concatenated list               (rebinds the variable)
-- • map    += pair    → new map with the pair inserted  (rebinds the variable)
-- • map    += map     → merged map                      (rebinds the variable)
-- Intended usage: `left = ktox_plusAssign(left, right)`
function ktox_plusAssign(left, right)
    if type(left) == "string" or type(right) == "string" then
        return tostring(left) .. tostring(right)
    end
    if type(left) ~= "table" then
        return left + right
    end
    -- left is a table (list or map). Determine table kind using # and next().
    if #left > 0 then
        -- Non-empty sequence: list += element or list += list
        return ktox_plus(left, right)
    end
    if next(left) ~= nil then
        -- Non-empty string-keyed map: map += pair or map += map
        return ktox_mapPlus(left, right)
    end
    -- Empty table: infer intended operation from the right-hand side.
    if type(right) == "table" then
        if #right == 0 and next(right) ~= nil then
            -- right is a non-empty string-keyed map → treat as map merge
            return ktox_mapPlus(left, right)
        end
    end
    -- Default: treat as list += element / list += list
    return ktox_plus(left, right)
end

-- minusAssign: implements Kotlin's `-=` operator for both numeric and collection types.
-- • number -= number → arithmetic subtraction
-- • list   -= element → new list with all occurrences of element removed (rebinds)
-- • map    -= key     → new map without the given key                    (rebinds)
-- Intended usage: `left = ktox_minusAssign(left, right)`
function ktox_minusAssign(left, right)
    if type(left) ~= "table" then
        return left - right
    end
    return ktox_minus(left, right)
end

-- take: returns the first n elements.
function ktox_take(t, n)
    local len = math.min(n, #t)
    local r = {}
    for i = 1, len do r[i] = t[i] end
    return r
end

-- drop: returns all elements after the first n.
function ktox_drop(t, n)
    local r, j = {}, 0
    for i = n + 1, #t do j = j + 1; r[j] = t[i] end
    return r
end

-- joinToString: joins elements to a string with optional separator and transform.
function ktox_joinToString(t, separator, fn)
    if separator == nil then separator = ", " end
    local n = #t
    local parts = {}
    if fn == nil then
        for i = 1, n do parts[i] = tostring(t[i]) end
    else
        for i = 1, n do parts[i] = tostring(fn(t[i])) end
    end
    return table.concat(parts, separator)
end

-- joinTo: appends joined elements to a buffer (list of strings) and returns it.
function ktox_joinTo(t, buffer, separator, fn)
    if separator == nil then separator = ", " end
    local n = #t
    for i = 1, n do
        local s = fn and tostring(fn(t[i])) or tostring(t[i])
        buffer[#buffer + 1] = s
        if i < n then buffer[#buffer + 1] = separator end
    end
    return buffer
end

-- -------------------------------------------------------------------------
-- Additional element access
-- -------------------------------------------------------------------------

-- findLast: returns the last element where fn(value) is truthy, or nil.
function ktox_findLast(t, fn)
    for i = #t, 1, -1 do
        if fn(t[i]) then return t[i] end
    end
    return nil
end

-- firstNotNullOf: returns fn(element) for the first element where the result is not nil.
-- Throws an error if no such element exists.
function ktox_firstNotNullOf(t, fn)
    for i = 1, #t do
        local v = fn(t[i])
        if v ~= nil then return v end
    end
    error("ktox_firstNotNullOf: no element produced a non-null value", 2)
end

-- firstNotNullOfOrNull: like firstNotNullOf but returns nil instead of throwing.
function ktox_firstNotNullOfOrNull(t, fn)
    for i = 1, #t do
        local v = fn(t[i])
        if v ~= nil then return v end
    end
    return nil
end

-- single: returns the single element (or single element matching fn), throws if not exactly one.
function ktox_single(t, fn)
    if fn then
        local found = nil
        for i = 1, #t do
            if fn(t[i]) then
                if found ~= nil then error("ktox_single: more than one matching element", 2) end
                found = t[i]
            end
        end
        if found == nil then error("ktox_single: no matching element", 2) end
        return found
    else
        if #t ~= 1 then error("ktox_single: expected exactly one element, got " .. #t, 2) end
        return t[1]
    end
end

-- singleOrNull: like single but returns nil instead of throwing.
function ktox_singleOrNull(t, fn)
    if fn then
        local found = nil
        for i = 1, #t do
            if fn(t[i]) then
                if found ~= nil then return nil end
                found = t[i]
            end
        end
        return found
    else
        if #t ~= 1 then return nil end
        return t[1]
    end
end

-- elementAt: returns the element at the given 0-based index (Kotlin-style).
function ktox_elementAt(t, index)
    local v = t[index + 1]
    if v == nil then error("ktox_elementAt: index out of bounds: " .. index, 2) end
    return v
end

-- elementAtOrElse: returns the element at 0-based index, or defaultFn(index) if out of bounds.
function ktox_elementAtOrElse(t, index, defaultFn)
    local v = t[index + 1]
    if v == nil then return defaultFn(index) end
    return v
end

-- elementAtOrNull: returns the element at 0-based index, or nil if out of bounds.
function ktox_elementAtOrNull(t, index)
    return t[index + 1]
end

-- indexOfFirst: returns the 0-based index of the first element matching fn, or -1.
function ktox_indexOfFirst(t, fn)
    for i = 1, #t do
        if fn(t[i]) then return i - 1 end
    end
    return -1
end

-- indexOfLast: returns the 0-based index of the last element matching fn, or -1.
function ktox_indexOfLast(t, fn)
    for i = #t, 1, -1 do
        if fn(t[i]) then return i - 1 end
    end
    return -1
end

-- -------------------------------------------------------------------------
-- Additional filtering
-- -------------------------------------------------------------------------

-- filterNot: returns elements where fn(value) is falsy.
function ktox_filterNot(t, fn)
    local r, n = {}, 0
    for i = 1, #t do
        if not fn(t[i]) then n = n + 1; r[n] = t[i] end
    end
    return r
end

-- filterIsInstance: returns elements that are instances of cls (uses ktox_isinstance).
-- When cls is nil, returns a copy of all elements.
function ktox_filterIsInstance(t, cls)
    if cls == nil then return ktox_toList(t) end
    local r, n = {}, 0
    for i = 1, #t do
        if ktox_isinstance(t[i], cls) then n = n + 1; r[n] = t[i] end
    end
    return r
end

-- filterTo: appends elements matching fn to dst and returns dst.
function ktox_filterTo(t, dst, fn)
    local n = #dst
    for i = 1, #t do
        if fn(t[i]) then n = n + 1; dst[n] = t[i] end
    end
    return dst
end

-- filterNotTo: appends elements not matching fn to dst and returns dst.
function ktox_filterNotTo(t, dst, fn)
    local n = #dst
    for i = 1, #t do
        if not fn(t[i]) then n = n + 1; dst[n] = t[i] end
    end
    return dst
end

-- filterNotNullTo: appends non-nil elements to dst and returns dst.
function ktox_filterNotNullTo(t, dst)
    local n = #dst
    for i = 1, #t do
        if t[i] ~= nil then n = n + 1; dst[n] = t[i] end
    end
    return dst
end

-- filterIndexedTo: appends elements matching fn(index, value) to dst and returns dst.
function ktox_filterIndexedTo(t, dst, fn)
    local n = #dst
    for i = 1, #t do
        if fn(i, t[i]) then n = n + 1; dst[n] = t[i] end
    end
    return dst
end

-- filterIsInstanceTo: appends elements that are instances of cls to dst and returns dst.
function ktox_filterIsInstanceTo(t, dst, cls)
    local n = #dst
    if cls == nil then
        for i = 1, #t do n = n + 1; dst[n] = t[i] end
        return dst
    end
    for i = 1, #t do
        if ktox_isinstance(t[i], cls) then n = n + 1; dst[n] = t[i] end
    end
    return dst
end

-- -------------------------------------------------------------------------
-- Additional transformations
-- -------------------------------------------------------------------------

-- mapTo: applies fn to each element, appending results to dst, and returns dst.
function ktox_mapTo(t, dst, fn)
    local n = #dst
    for i = 1, #t do n = n + 1; dst[n] = fn(t[i]) end
    return dst
end

-- mapIndexedTo: like mapIndexed, appending results to dst, and returns dst.
function ktox_mapIndexedTo(t, dst, fn)
    local n = #dst
    for i = 1, #t do n = n + 1; dst[n] = fn(i, t[i]) end
    return dst
end

-- mapNotNullTo: like mapNotNull, appending non-nil results to dst, and returns dst.
function ktox_mapNotNullTo(t, dst, fn)
    local n = #dst
    for i = 1, #t do
        local v = fn(t[i])
        if v ~= nil then n = n + 1; dst[n] = v end
    end
    return dst
end

-- mapIndexedNotNull: maps with index and removes nil results.
function ktox_mapIndexedNotNull(t, fn)
    local r, n = {}, 0
    for i = 1, #t do
        local v = fn(i, t[i])
        if v ~= nil then n = n + 1; r[n] = v end
    end
    return r
end

-- mapIndexedNotNullTo: like mapIndexedNotNull, appending to dst, and returns dst.
function ktox_mapIndexedNotNullTo(t, dst, fn)
    local n = #dst
    for i = 1, #t do
        local v = fn(i, t[i])
        if v ~= nil then n = n + 1; dst[n] = v end
    end
    return dst
end

-- flatMapTo: appends flatMapped elements to dst and returns dst.
function ktox_flatMapTo(t, dst, fn)
    local n = #dst
    for i = 1, #t do
        local sub = fn(t[i])
        for j = 1, #sub do n = n + 1; dst[n] = sub[j] end
    end
    return dst
end

-- flatMapIndexed: flatMap with 1-based index argument.
function ktox_flatMapIndexed(t, fn)
    local r, n = {}, 0
    for i = 1, #t do
        local sub = fn(i, t[i])
        for j = 1, #sub do n = n + 1; r[n] = sub[j] end
    end
    return r
end

-- flatMapIndexedTo: appends flatMapIndexed elements to dst and returns dst.
function ktox_flatMapIndexedTo(t, dst, fn)
    local n = #dst
    for i = 1, #t do
        local sub = fn(i, t[i])
        for j = 1, #sub do n = n + 1; dst[n] = sub[j] end
    end
    return dst
end

-- -------------------------------------------------------------------------
-- Additional folding / scanning
-- -------------------------------------------------------------------------

-- foldIndexed: fold with 1-based index passed as first lambda argument.
function ktox_foldIndexed(t, init, fn)
    local acc = init
    for i = 1, #t do acc = fn(i, acc, t[i]) end
    return acc
end

-- reduceOrNull: like reduce but returns nil for an empty collection.
function ktox_reduceOrNull(t, fn)
    if #t == 0 then return nil end
    local acc = t[1]
    for i = 2, #t do acc = fn(acc, t[i]) end
    return acc
end

-- reduceIndexed: reduce with 1-based index passed as first lambda argument.
function ktox_reduceIndexed(t, fn)
    local n = #t
    if n == 0 then error("ktox_reduceIndexed: empty collection cannot be reduced", 2) end
    local acc = t[1]
    for i = 2, n do acc = fn(i, acc, t[i]) end
    return acc
end

-- reduceIndexedOrNull: like reduceIndexed but returns nil for an empty collection.
function ktox_reduceIndexedOrNull(t, fn)
    if #t == 0 then return nil end
    local acc = t[1]
    for i = 2, #t do acc = fn(i, acc, t[i]) end
    return acc
end

-- runningFold: returns a list of all intermediate accumulator values, starting with init.
function ktox_runningFold(t, init, fn)
    local r = {init}
    local acc = init
    for i = 1, #t do acc = fn(acc, t[i]); r[i + 1] = acc end
    return r
end

-- runningFoldIndexed: runningFold with 1-based index passed as first lambda argument.
function ktox_runningFoldIndexed(t, init, fn)
    local r = {init}
    local acc = init
    for i = 1, #t do acc = fn(i, acc, t[i]); r[i + 1] = acc end
    return r
end

-- runningReduce: like runningFold but uses the first element as the initial value.
function ktox_runningReduce(t, fn)
    if #t == 0 then return {} end
    local r = {t[1]}
    local acc = t[1]
    for i = 2, #t do acc = fn(acc, t[i]); r[i] = acc end
    return r
end

-- runningReduceIndexed: runningReduce with 1-based index passed as first lambda argument.
function ktox_runningReduceIndexed(t, fn)
    if #t == 0 then return {} end
    local r = {t[1]}
    local acc = t[1]
    for i = 2, #t do acc = fn(i, acc, t[i]); r[i] = acc end
    return r
end

-- scan: alias for runningFold (Kotlin 1.4+).
ktox_scan = ktox_runningFold

-- scanIndexed: alias for runningFoldIndexed (Kotlin 1.4+).
ktox_scanIndexed = ktox_runningFoldIndexed

-- -------------------------------------------------------------------------
-- Aggregation
-- -------------------------------------------------------------------------

-- average: returns the arithmetic mean of a numeric sequence, or nil if empty.
function ktox_average(t)
    local n = #t
    if n == 0 then return nil end
    local s = 0
    for i = 1, n do s = s + t[i] end
    return s / n
end

-- sumBy: sum of Integer-valued fn(element) (deprecated in Kotlin, equivalent to sumOf).
function ktox_sumBy(t, fn)
    local s = 0
    for i = 1, #t do s = s + fn(t[i]) end
    return s
end

-- sumByDouble: sum of Double-valued fn(element) (deprecated in Kotlin, equivalent to sumOf).
function ktox_sumByDouble(t, fn)
    local s = 0.0
    for i = 1, #t do s = s + fn(t[i]) end
    return s
end

-- max: returns the maximum element (natural ordering), or nil if empty.
-- Deprecated in Kotlin in favour of maxOrNull.
function ktox_max(t)
    return ktox_maxOrNull(t)
end

-- min: returns the minimum element (natural ordering), or nil if empty.
-- Deprecated in Kotlin in favour of minOrNull.
function ktox_min(t)
    return ktox_minOrNull(t)
end

-- maxBy: returns the element with the largest fn(element) key, or nil if empty.
-- Deprecated in Kotlin in favour of maxByOrNull.
function ktox_maxBy(t, fn)
    return ktox_maxByOrNull(t, fn)
end

-- minBy: returns the element with the smallest fn(element) key, or nil if empty.
-- Deprecated in Kotlin in favour of minByOrNull.
function ktox_minBy(t, fn)
    return ktox_minByOrNull(t, fn)
end

-- maxOf: returns the maximum value of fn(element), throws if empty.
function ktox_maxOf(t, fn)
    local n = #t
    if n == 0 then error("ktox_maxOf: empty collection", 2) end
    local m = fn(t[1])
    for i = 2, n do local v = fn(t[i]); if v > m then m = v end end
    return m
end

-- maxOfOrNull: returns the maximum value of fn(element), or nil if empty.
function ktox_maxOfOrNull(t, fn)
    local n = #t
    if n == 0 then return nil end
    local m = fn(t[1])
    for i = 2, n do local v = fn(t[i]); if v > m then m = v end end
    return m
end

-- minOf: returns the minimum value of fn(element), throws if empty.
function ktox_minOf(t, fn)
    local n = #t
    if n == 0 then error("ktox_minOf: empty collection", 2) end
    local m = fn(t[1])
    for i = 2, n do local v = fn(t[i]); if v < m then m = v end end
    return m
end

-- minOfOrNull: returns the minimum value of fn(element), or nil if empty.
function ktox_minOfOrNull(t, fn)
    local n = #t
    if n == 0 then return nil end
    local m = fn(t[1])
    for i = 2, n do local v = fn(t[i]); if v < m then m = v end end
    return m
end

-- maxWith: returns the element with the largest value according to comparator cmp, throws if empty.
-- cmp(a, b) returns negative when a < b, 0 when equal, positive when a > b.
function ktox_maxWith(t, cmp)
    local n = #t
    if n == 0 then error("ktox_maxWith: empty collection", 2) end
    local m = t[1]
    for i = 2, n do if cmp(m, t[i]) < 0 then m = t[i] end end
    return m
end

-- maxWithOrNull: like maxWith but returns nil if empty.
function ktox_maxWithOrNull(t, cmp)
    local n = #t
    if n == 0 then return nil end
    local m = t[1]
    for i = 2, n do if cmp(m, t[i]) < 0 then m = t[i] end end
    return m
end

-- minWith: returns the element with the smallest value according to comparator cmp, throws if empty.
function ktox_minWith(t, cmp)
    local n = #t
    if n == 0 then error("ktox_minWith: empty collection", 2) end
    local m = t[1]
    for i = 2, n do if cmp(m, t[i]) > 0 then m = t[i] end end
    return m
end

-- minWithOrNull: like minWith but returns nil if empty.
function ktox_minWithOrNull(t, cmp)
    local n = #t
    if n == 0 then return nil end
    local m = t[1]
    for i = 2, n do if cmp(m, t[i]) > 0 then m = t[i] end end
    return m
end

-- maxOfWith: returns the maximum value of fn(element) using comparator cmp, throws if empty.
function ktox_maxOfWith(t, cmp, fn)
    local n = #t
    if n == 0 then error("ktox_maxOfWith: empty collection", 2) end
    local m = fn(t[1])
    for i = 2, n do local v = fn(t[i]); if cmp(m, v) < 0 then m = v end end
    return m
end

-- maxOfWithOrNull: like maxOfWith but returns nil if empty.
function ktox_maxOfWithOrNull(t, cmp, fn)
    local n = #t
    if n == 0 then return nil end
    local m = fn(t[1])
    for i = 2, n do local v = fn(t[i]); if cmp(m, v) < 0 then m = v end end
    return m
end

-- minOfWith: returns the minimum value of fn(element) using comparator cmp, throws if empty.
function ktox_minOfWith(t, cmp, fn)
    local n = #t
    if n == 0 then error("ktox_minOfWith: empty collection", 2) end
    local m = fn(t[1])
    for i = 2, n do local v = fn(t[i]); if cmp(m, v) > 0 then m = v end end
    return m
end

-- minOfWithOrNull: like minOfWith but returns nil if empty.
function ktox_minOfWithOrNull(t, cmp, fn)
    local n = #t
    if n == 0 then return nil end
    local m = fn(t[1])
    for i = 2, n do local v = fn(t[i]); if cmp(m, v) > 0 then m = v end end
    return m
end

-- -------------------------------------------------------------------------
-- Additional ordering / deduplication
-- -------------------------------------------------------------------------

-- sorted: returns a sorted copy of the sequence using natural (ascending) ordering.
function ktox_sorted(t)
    local n = #t
    local r = {}
    for i = 1, n do r[i] = t[i] end
    table.sort(r)
    return r
end

-- sortedDescending: returns a sorted copy in descending natural ordering.
function ktox_sortedDescending(t)
    local n = #t
    local r = {}
    for i = 1, n do r[i] = t[i] end
    table.sort(r, function(a, b) return a > b end)
    return r
end

-- sortedWith: returns a sorted copy using the given comparator.
-- cmp(a, b) returns negative when a < b, 0 when equal, positive when a > b.
function ktox_sortedWith(t, cmp)
    local n = #t
    local r = {}
    for i = 1, n do r[i] = t[i] end
    table.sort(r, function(a, b) return cmp(a, b) < 0 end)
    return r
end

-- distinctBy: returns a list containing only elements with distinct keys (fn(element)).
function ktox_distinctBy(t, fn)
    local seen, r, n = {}, {}, 0
    for i = 1, #t do
        local k = fn(t[i])
        if not seen[k] then seen[k] = true; n = n + 1; r[n] = t[i] end
    end
    return r
end

-- -------------------------------------------------------------------------
-- Additional grouping / association
-- -------------------------------------------------------------------------

-- associate: creates a map from pairs returned by fn(element) → {key, value}.
function ktox_associate(t, fn)
    local m = {}
    for i = 1, #t do
        local pair = fn(t[i])
        m[pair[1]] = pair[2]
    end
    return m
end

-- associateWith: creates a map from each element to fn(element).
function ktox_associateWith(t, fn)
    local m = {}
    for i = 1, #t do m[t[i]] = fn(t[i]) end
    return m
end

-- associateTo: like associate but puts results into an existing map dst.
function ktox_associateTo(t, dst, fn)
    for i = 1, #t do
        local pair = fn(t[i])
        dst[pair[1]] = pair[2]
    end
    return dst
end

-- associateByTo: like associateBy but puts results into an existing map dst.
-- Optional valueFn transforms the value; defaults to the element itself.
function ktox_associateByTo(t, dst, keyFn, valueFn)
    for i = 1, #t do
        local key = keyFn(t[i])
        dst[key] = valueFn and valueFn(t[i]) or t[i]
    end
    return dst
end

-- associateWithTo: like associateWith but puts results into an existing map dst.
function ktox_associateWithTo(t, dst, fn)
    for i = 1, #t do dst[t[i]] = fn(t[i]) end
    return dst
end

-- groupByTo: like groupBy but puts results into an existing map dst.
function ktox_groupByTo(t, dst, fn)
    for i = 1, #t do
        local k = fn(t[i])
        if dst[k] == nil then dst[k] = {} end
        local g = dst[k]; g[#g + 1] = t[i]
    end
    return dst
end

-- groupingBy: groups elements by key and returns an aggregate map {key → count}.
-- In Kotlin this returns a Grouping object; here it eagerly counts occurrences.
function ktox_groupingBy(t, fn)
    local m = {}
    for i = 1, #t do
        local k = fn(t[i])
        m[k] = (m[k] or 0) + 1
    end
    return m
end

-- -------------------------------------------------------------------------
-- Additional slicing / building
-- -------------------------------------------------------------------------

-- takeWhile: takes elements while fn(element) is truthy.
function ktox_takeWhile(t, fn)
    local r, n = {}, 0
    for i = 1, #t do
        if not fn(t[i]) then break end
        n = n + 1; r[n] = t[i]
    end
    return r
end

-- dropWhile: drops elements while fn(element) is truthy, then returns the rest.
function ktox_dropWhile(t, fn)
    local i, len = 1, #t
    while i <= len and fn(t[i]) do i = i + 1 end
    local r, n = {}, 0
    for j = i, len do n = n + 1; r[n] = t[j] end
    return r
end

-- chunked: splits the sequence into non-overlapping chunks of the given size.
function ktox_chunked(t, size)
    local r, n, len = {}, 0, #t
    local i = 1
    while i <= len do
        n = n + 1
        local chunk = {}
        local cn = 0
        for j = i, math.min(i + size - 1, len) do cn = cn + 1; chunk[cn] = t[j] end
        r[n] = chunk
        i = i + size
    end
    return r
end

-- windowed: returns all windows of the given size with optional step and partial-window control.
function ktox_windowed(t, size, step, partialWindows)
    if step == nil then step = 1 end
    local r, rn, len = {}, 0, #t
    local i = 1
    while i <= len do
        local window, wn = {}, 0
        for j = i, math.min(i + size - 1, len) do wn = wn + 1; window[wn] = t[j] end
        if wn == size or partialWindows then rn = rn + 1; r[rn] = window end
        i = i + step
    end
    return r
end

-- zipWithNext: zips each element with the next one.
-- Optional fn(a, b) transforms each pair; otherwise returns {a, b} tables.
function ktox_zipWithNext(t, fn)
    local r, n, len = {}, 0, #t
    for i = 1, len - 1 do
        n = n + 1
        r[n] = fn and fn(t[i], t[i + 1]) or {t[i], t[i + 1]}
    end
    return r
end

-- withIndex: returns a list of {index, value} pairs (0-based index, Kotlin-style).
function ktox_withIndex(t)
    local r, n = {}, #t
    for i = 1, n do r[i] = {i - 1, t[i]} end
    return r
end

-- unzip: splits a list of {first, second} pairs into two separate lists.
function ktox_unzip(t)
    local first, second, n = {}, {}, #t
    for i = 1, n do first[i] = t[i][1]; second[i] = t[i][2] end
    return {first, second}
end

-- shuffled: returns a randomly shuffled copy of the sequence.
function ktox_shuffled(t)
    local r, n = {}, #t
    for i = 1, n do r[i] = t[i] end
    for i = n, 2, -1 do
        local j = math.random(1, i)
        r[i], r[j] = r[j], r[i]
    end
    return r
end

-- partition: splits elements into two lists: {matching, not-matching}.
function ktox_partition(t, fn)
    local yes, no = {}, {}
    local yn, nn = 0, 0
    for i = 1, #t do
        if fn(t[i]) then yn = yn + 1; yes[yn] = t[i]
        else nn = nn + 1; no[nn] = t[i] end
    end
    return {yes, no}
end

-- onEach: calls fn(element) for each element and returns the original collection.
function ktox_onEach(t, fn)
    for i = 1, #t do fn(t[i]) end
    return t
end

-- onEachIndexed: calls fn(index, element) for each element and returns the original collection.
function ktox_onEachIndexed(t, fn)
    for i = 1, #t do fn(i, t[i]) end
    return t
end

-- plusElement: returns a new list with the single element appended.
function ktox_plusElement(t, elem)
    local n = #t
    local r = {}
    for i = 1, n do r[i] = t[i] end
    r[n + 1] = elem
    return r
end

-- minusElement: returns a new list with the first occurrence of elem removed.
function ktox_minusElement(t, elem)
    local r, n, removed = {}, 0, false
    for i = 1, #t do
        if not removed and t[i] == elem then removed = true
        else n = n + 1; r[n] = t[i] end
    end
    return r
end

-- toCollection: appends all elements to dst and returns dst.
function ktox_toCollection(t, dst)
    local n = #dst
    for i = 1, #t do n = n + 1; dst[n] = t[i] end
    return dst
end

-- toSet: returns an array-table of distinct elements (set semantics).
function ktox_toSet(t)
    return ktox_distinct(t)
end

-- toHashSet: returns a set (same as toSet in Lua).
function ktox_toHashSet(t)
    return ktox_distinct(t)
end

-- toMutableList: returns a mutable copy (same as toList in Lua).
function ktox_toMutableList(t)
    return ktox_toList(t)
end

-- toMutableSet: returns a mutable set (same as toSet in Lua).
function ktox_toMutableSet(t)
    return ktox_distinct(t)
end

-- toSortedSet: returns a sorted array of distinct elements.
function ktox_toSortedSet(t)
    return ktox_sorted(ktox_distinct(t))
end

-- requireNoNulls: asserts that no element is nil and returns the collection unchanged.
function ktox_requireNoNulls(t)
    for i = 1, #t do
        if t[i] == nil then error("ktox_requireNoNulls: null element at index " .. i, 2) end
    end
    return t
end

-- ifEmpty: returns the collection if non-empty; otherwise calls and returns defaultFn().
function ktox_ifEmpty(t, defaultFn)
    if #t == 0 then return defaultFn() end
    return t
end

-- orEmpty: returns the collection, or an empty table if it is nil.
function ktox_orEmpty(t)
    if t == nil then return {} end
    return t
end

-- asSequence: creates a KtoxSequence wrapper for lazy chaining.
-- Loads ktox_sequence on first call if available; otherwise returns the table unchanged.
function ktox_asSequence(t)
    if not _G.ktox_sequence_loaded then
        local ok = pcall(require, "ktox_sequence")
        if not ok then return t end
    end
    return KtoxSequence.of(t or {})
end

-- generateSequence: creates an infinite (or finite) lazy KtoxSequence.
-- Supports both Kotlin overloads:
--   generateSequence(seed, nextFn)        -- seed is a value; stop when nextFn returns nil
--   generateSequence(seedFn, nextFn)      -- seedFn() supplies the first element
-- Loads ktox_sequence on first call.
function ktox_generateSequence(seedOrFn, nextFn)
    if not _G.ktox_sequence_loaded then
        local ok = pcall(require, "ktox_sequence")
        if not ok then return {} end
    end
    return KtoxSequence.generate(seedOrFn, nextFn)
end

-- asIterable: returns the collection as-is (already iterable in Lua).
function ktox_asIterable(t)
    return t
end

-- constrainOnce: in Kotlin sequences, constrains to a single iteration; no-op here.
function ktox_constrainOnce(t)
    return t
end

-- -------------------------------------------------------------------------
-- Map / table-as-dictionary
-- -------------------------------------------------------------------------

-- containsKey: true if the map has a non-nil value for key.
function ktox_containsKey(m, key)
    return m[key] ~= nil
end

-- containsValue: true if any value in the map equals value.
function ktox_containsValue(m, value)
    for _, v in pairs(m) do
        if v == value then return true end
    end
    return false
end

-- getOrDefault: returns m[key] when present, otherwise default.
function ktox_getOrDefault(m, key, default)
    local v = m[key]
    if v ~= nil then return v end
    return default
end

-- getOrElse: returns m[key] when present, otherwise the result of fn().
function ktox_getOrElse(m, key, fn)
    local v = m[key]
    if v ~= nil then return v end
    return fn()
end

-- mapValues: creates a new map with the same keys but fn(key, value) as values.
function ktox_mapValues(m, fn)
    local r = {}
    for k, v in pairs(m) do r[k] = fn(k, v) end
    return r
end

-- mapKeys: creates a new map with fn(key, value) as keys and the same values.
function ktox_mapKeys(m, fn)
    local r = {}
    for k, v in pairs(m) do r[fn(k, v)] = v end
    return r
end

-- filterKeys: keeps only entries where fn(key) is truthy.
function ktox_filterKeys(m, fn)
    local r = {}
    for k, v in pairs(m) do
        if fn(k) then r[k] = v end
    end
    return r
end

-- filterValues: keeps only entries where fn(value) is truthy.
function ktox_filterValues(m, fn)
    local r = {}
    for k, v in pairs(m) do
        if fn(v) then r[k] = v end
    end
    return r
end

-- toMap: returns a shallow copy of the map table.
function ktox_toMap(m)
    local r = {}
    for k, v in pairs(m) do r[k] = v end
    return r
end

-- keys: returns an array of the map's keys.
function ktox_keys(m)
    local r, n = {}, 0
    for k in pairs(m) do n = n + 1; r[n] = k end
    return r
end

-- values: returns an array of the map's values.
function ktox_values(m)
    local r, n = {}, 0
    for _, v in pairs(m) do n = n + 1; r[n] = v end
    return r
end

-- entries: returns an array of {key, value} pairs.
function ktox_entries(m)
    local r, n = {}, 0
    for k, v in pairs(m) do n = n + 1; r[n] = {k, v} end
    return r
end

-- -------------------------------------------------------------------------
-- Map / table-as-dictionary – functional programming
-- -------------------------------------------------------------------------

-- mapForEach: calls fn(key, value) for each map entry.
function ktox_mapForEach(m, fn)
    for k, v in pairs(m) do fn(k, v) end
end

-- mapFilter: returns a new map keeping entries where fn(key, value) is truthy.
function ktox_mapFilter(m, fn)
    local r = {}
    for k, v in pairs(m) do
        if fn(k, v) then r[k] = v end
    end
    return r
end

-- mapTransform: collects fn(key, value) results into a list.
function ktox_mapTransform(m, fn)
    local r, n = {}, 0
    for k, v in pairs(m) do n = n + 1; r[n] = fn(k, v) end
    return r
end

-- mapFlatMap: flat-maps fn(key, value) → list into a single list.
function ktox_mapFlatMap(m, fn)
    local r, n = {}, 0
    for k, v in pairs(m) do
        local inner = fn(k, v)
        for i = 1, #inner do n = n + 1; r[n] = inner[i] end
    end
    return r
end

-- mapAny: true if fn(key, value) is truthy for at least one entry.
function ktox_mapAny(m, fn)
    for k, v in pairs(m) do if fn(k, v) then return true end end
    return false
end

-- mapAll: true if fn(key, value) is truthy for every entry.
function ktox_mapAll(m, fn)
    for k, v in pairs(m) do if not fn(k, v) then return false end end
    return true
end

-- mapNone: true if fn(key, value) is falsy for every entry.
function ktox_mapNone(m, fn)
    for k, v in pairs(m) do if fn(k, v) then return false end end
    return true
end

-- mapCount: number of entries, or number where fn(key, value) is truthy.
function ktox_mapCount(m, fn)
    local n = 0
    if fn == nil then
        for _ in pairs(m) do n = n + 1 end
    else
        for k, v in pairs(m) do if fn(k, v) then n = n + 1 end end
    end
    return n
end

-- isEmpty: true when the map has no entries or the string is empty.
function ktox_isEmpty(m)
    if type(m) == "string" then return #m == 0 end
    return next(m) == nil
end

-- isNotEmpty: true when the map has at least one entry or the string is non-empty.
function ktox_isNotEmpty(m)
    if type(m) == "string" then return #m > 0 end
    return next(m) ~= nil
end

-- isNullOrEmpty: true when t is nil, empty string, or has no elements / entries.
-- Works for strings, sequences (lists) and string-keyed maps.
function ktox_isNullOrEmpty(t)
    if t == nil then return true end
    if type(t) == "string" then return #t == 0 end
    return next(t) == nil
end

-- putAll: copies all entries from other into m (mutating).
function ktox_putAll(m, other)
    for k, v in pairs(other) do m[k] = v end
end

-- getOrPut: returns m[key] when present; otherwise calls fn(), stores the
-- result under key, and returns it.
function ktox_getOrPut(m, key, fn)
    local v = m[key]
    if v ~= nil then return v end
    v = fn()
    m[key] = v
    return v
end

-- -------------------------------------------------------------------------
-- String functions
-- -------------------------------------------------------------------------

-- matches: returns true if the entire string s matches the Lua pattern p.
-- Corresponds to Kotlin's String.matches(Regex) / infix `matches`.
function ktox_matches(s, p)
    return string.match(s, "^" .. p .. "$") ~= nil
end

-- uppercase / toUpperCase: returns the string in upper case.
function ktox_uppercase(s)
    return string.upper(s)
end
ktox_toUpperCase = ktox_uppercase

-- lowercase / toLowerCase: returns the string in lower case.
function ktox_lowercase(s)
    return string.lower(s)
end
ktox_toLowerCase = ktox_lowercase

-- trim: removes leading and trailing whitespace.
function ktox_trim(s)
    return (s:match("^%s*(.-)%s*$"))
end

-- trimStart: removes leading whitespace.
function ktox_trimStart(s)
    return (s:match("^%s*(.*)$"))
end

-- trimEnd: removes trailing whitespace.
function ktox_trimEnd(s)
    return (s:match("^(.-)%s*$"))
end

-- trimIndent: removes common leading whitespace from all non-blank lines,
-- and strips leading/trailing blank lines.
-- Corresponds to Kotlin's String.trimIndent().
function ktox_trimIndent(s)
    local raw_lines = {}
    for line in (s .. "\n"):gmatch("([^\n]*)\n") do
        raw_lines[#raw_lines + 1] = line
    end
    -- Find the minimum indentation among non-blank lines.
    local min_indent = math.huge
    for _, line in ipairs(raw_lines) do
        if line:match("%S") then
            local indent = #(line:match("^(%s*)"))
            if indent < min_indent then min_indent = indent end
        end
    end
    if min_indent == math.huge then min_indent = 0 end
    -- Strip leading blank lines.
    local start_i = 1
    while start_i <= #raw_lines and not raw_lines[start_i]:match("%S") do
        start_i = start_i + 1
    end
    -- Strip trailing blank lines.
    local end_i = #raw_lines
    while end_i >= 1 and not raw_lines[end_i]:match("%S") do
        end_i = end_i - 1
    end
    local result = {}
    for i = start_i, end_i do
        result[#result + 1] = raw_lines[i]:sub(min_indent + 1)
    end
    return table.concat(result, "\n")
end

-- trimMargin: removes leading whitespace up to and including a margin prefix
-- from each line, and strips leading/trailing blank lines.
-- Corresponds to Kotlin's String.trimMargin(marginPrefix = "|").
function ktox_trimMargin(s, marginPrefix)
    if marginPrefix == nil then marginPrefix = "|" end
    local raw_lines = {}
    for line in (s .. "\n"):gmatch("([^\n]*)\n") do
        raw_lines[#raw_lines + 1] = line
    end
    local result_lines = {}
    for _, line in ipairs(raw_lines) do
        local pos = line:find(marginPrefix, 1, true)
        if pos then
            result_lines[#result_lines + 1] = line:sub(pos + #marginPrefix)
        else
            result_lines[#result_lines + 1] = line
        end
    end
    -- Strip leading blank lines.
    local start_i = 1
    while start_i <= #result_lines and not result_lines[start_i]:match("%S") do
        start_i = start_i + 1
    end
    -- Strip trailing blank lines.
    local end_i = #result_lines
    while end_i >= 1 and not result_lines[end_i]:match("%S") do
        end_i = end_i - 1
    end
    local result = {}
    for i = start_i, end_i do
        result[#result + 1] = result_lines[i]
    end
    return table.concat(result, "\n")
end

-- substring: returns a substring using 0-based start (inclusive) and optional
-- end (exclusive) indices, matching Kotlin's String.substring().
function ktox_substring(s, startIndex, endIndex)
    local lua_start = startIndex + 1
    local lua_end = endIndex  -- Kotlin endIndex exclusive = Lua end inclusive
    return s:sub(lua_start, lua_end)
end

-- indexOf: for strings, returns the 0-based index of the first occurrence of sub,
-- starting at optional startIndex (0-based). For lists, returns the 0-based index
-- of the first occurrence of sub (element equality). Returns -1 if not found.
function ktox_indexOf(s, sub, startIndex)
    if type(s) == "table" then
        for i = 1, #s do if s[i] == sub then return i - 1 end end
        return -1
    end
    local lua_start = startIndex and (startIndex + 1) or 1
    local pos = s:find(sub, lua_start, true)
    if pos == nil then return -1 end
    return pos - 1
end

-- lastIndexOf: for strings, returns the 0-based index of the last occurrence of sub.
-- For lists, returns the 0-based index of the last occurrence of sub (element equality).
-- Returns -1 if not found.
function ktox_lastIndexOf(s, sub)
    if type(s) == "table" then
        for i = #s, 1, -1 do if s[i] == sub then return i - 1 end end
        return -1
    end
    local result = -1
    local pos = 1
    while true do
        local found = s:find(sub, pos, true)
        if found == nil then break end
        result = found - 1
        pos = found + 1
    end
    return result
end

-- startsWith: returns true if s starts with the given prefix.
function ktox_startsWith(s, prefix)
    return s:sub(1, #prefix) == prefix
end

-- endsWith: returns true if s ends with the given suffix.
function ktox_endsWith(s, suffix)
    if #suffix == 0 then return true end
    return s:sub(-#suffix) == suffix
end

-- replace: replaces all plain-text occurrences of old with new in s.
-- Corresponds to Kotlin's String.replace(old: String, new: String).
function ktox_replace(s, old, new_val)
    if #old == 0 then return s end
    local escaped_old = old:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    local escaped_new = new_val:gsub("%%", "%%%%")
    return (s:gsub(escaped_old, escaped_new))
end

-- replaceRegex: replaces all pattern matches of pattern with replacement in s.
-- Corresponds to Kotlin's String.replace(regex: Regex, replacement: String).
function ktox_replaceRegex(s, pattern, replacement)
    local escaped_repl = replacement:gsub("%%", "%%%%")
    return (s:gsub(pattern, escaped_repl))
end

-- replaceFirst: replaces the first plain-text occurrence of old with new in s.
-- Corresponds to Kotlin's String.replaceFirst(old: String, new: String).
function ktox_replaceFirst(s, old, new_val)
    if #old == 0 then return s end
    local escaped_old = old:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    local escaped_new = new_val:gsub("%%", "%%%%")
    return (s:gsub(escaped_old, escaped_new, 1))
end

-- split: splits s by the given delimiter string, returning a list.
-- Corresponds to Kotlin's String.split(delimiter: String).
function ktox_split(s, delimiter)
    if delimiter == nil then delimiter = " " end
    local r, n = {}, 0
    if #delimiter == 0 then
        for i = 1, #s do n = n + 1; r[n] = s:sub(i, i) end
        return r
    end
    local escaped = delimiter:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    local search_pos = 1
    while true do
        local found_start, found_end = s:find(escaped, search_pos)
        if not found_start then
            n = n + 1; r[n] = s:sub(search_pos)
            break
        end
        n = n + 1; r[n] = s:sub(search_pos, found_start - 1)
        search_pos = found_end + 1
    end
    return r
end

-- lines: splits s into a list of lines (splitting on \n).
-- Corresponds to Kotlin's String.lines().
function ktox_lines(s)
    local r, n = {}, 0
    for line in (s .. "\n"):gmatch("([^\n]*)\n") do
        n = n + 1; r[n] = line
    end
    -- Remove the trailing empty entry added by our sentinel "\n" if the
    -- original string already ended with a newline.
    if n > 0 and r[n] == "" then r[n] = nil end
    return r
end

-- repeat: repeats the string n times.
-- Corresponds to Kotlin's String.repeat(n: Int).
function ktox_repeat(s, n)
    return string.rep(s, n)
end

-- padStart: pads s on the left with padChar (default ' ') to reach the given length.
function ktox_padStart(s, length, padChar)
    if padChar == nil then padChar = " " end
    local pad = length - #s
    if pad <= 0 then return s end
    return string.rep(padChar, pad) .. s
end

-- padEnd: pads s on the right with padChar (default ' ') to reach the given length.
function ktox_padEnd(s, length, padChar)
    if padChar == nil then padChar = " " end
    local pad = length - #s
    if pad <= 0 then return s end
    return s .. string.rep(padChar, pad)
end

-- removePrefix: removes prefix from the start of s if present.
function ktox_removePrefix(s, prefix)
    if s:sub(1, #prefix) == prefix then
        return s:sub(#prefix + 1)
    end
    return s
end

-- removeSuffix: removes suffix from the end of s if present.
function ktox_removeSuffix(s, suffix)
    if #suffix == 0 then return s end
    if s:sub(-#suffix) == suffix then
        return s:sub(1, -#suffix - 1)
    end
    return s
end

-- toInt / toLong: converts the string to an integer; errors if not convertible.
function ktox_toInt(s)
    local n = tonumber(s)
    if n == nil then error("NumberFormatException: For input string: \"" .. tostring(s) .. "\"") end
    return math.floor(n)
end
ktox_toLong = ktox_toInt

-- toIntOrNull / toLongOrNull: converts the string to an integer, or nil.
function ktox_toIntOrNull(s)
    local n = tonumber(s)
    if n == nil then return nil end
    return math.floor(n)
end
ktox_toLongOrNull = ktox_toIntOrNull

-- toDouble / toFloat: converts the string to a number; errors if not convertible.
function ktox_toDouble(s)
    local n = tonumber(s)
    if n == nil then error("NumberFormatException: For input string: \"" .. tostring(s) .. "\"") end
    return n
end
ktox_toFloat = ktox_toDouble

-- toDoubleOrNull / toFloatOrNull: converts the string to a number, or nil.
function ktox_toDoubleOrNull(s)
    return tonumber(s)
end
ktox_toFloatOrNull = ktox_toDoubleOrNull

-- isBlank: returns true if s is empty or contains only whitespace.
function ktox_isBlank(s)
    return s:match("^%s*$") ~= nil
end

-- isNotBlank: returns true if s contains at least one non-whitespace character.
function ktox_isNotBlank(s)
    return s:match("^%s*$") == nil
end

-- isNullOrBlank: returns true if s is nil, empty, or contains only whitespace.
function ktox_isNullOrBlank(s)
    if s == nil then return true end
    return s:match("^%s*$") ~= nil
end

-- format: formats the string as a printf-style format string.
-- Corresponds to Kotlin's String.format(vararg args).
function ktox_format(fmt, ...)
    return string.format(fmt, ...)
end

