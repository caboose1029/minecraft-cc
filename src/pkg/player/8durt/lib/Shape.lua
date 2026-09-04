-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Shape.kt", {["1-16"]=1,["17"]=41,["18-19"]=42,["20"]=44,["21"]=47,["22"]=48,["23-24"]=49,["25-32"]=51,["33"]=72,["34"]=73,["35"]=74,["36"]=75,["37-38"]=76,["39-40"]=78,["41"]=80,["42"]=81,["43"]=82,["44-45"]=83,["46-47"]=85,["48"]=87,["49"]=88,["50"]=89,["51"]=90,["52-53"]=91,["54"]=93,["55-61"]=94,["62"]=102,["63"]=108,["64-65"]=109,["66"]=111,["67-68"]=112,["69-74"]=114,["75-77"]=123}, "lib")
ktox_require("lib/Span")

SHAPE_TRIANGLE = "TRIANGLE"

SHAPE_RIGHT_TRIANGLE = "RIGHT_TRIANGLE"

SHAPE_CIRCLE = "CIRCLE"

---@param shape string
---@param size number
---@return number
function shapeRowCount(shape, size)
    if shape == SHAPE_CIRCLE then
        return 2 * size + 1
    end
    if shape == SHAPE_TRIANGLE then
        local n = size - 1
        local half = (n - n % 2) / 2
        return half + 1
    end
    return size
end

---@param shape string
---@param size number
---@param row number
---@return IntSpan?
function shapeRowBounds(shape, size, row)
    if shape == SHAPE_TRIANGLE then
        local start = row
        local finish = size - 1 - row
        if start > finish then
            return nil
        end
        return IntSpan:new(start, finish)
    end
    if shape == SHAPE_RIGHT_TRIANGLE then
        local finish = size - 1 - row
        if finish < 0 then
            return nil
        end
        return IntSpan:new(0, finish)
    end
    local radius = size
    local dz = row - radius
    local remaining = radius * radius - dz * dz
    if remaining < 0 then
        return nil
    end
    local dx = sqrtFloor(remaining)
    return IntSpan:new(radius - dx, radius + dx)
end

---@param shape string
---@param size number
---@return number
function shapeSpineColumn(shape, size)
    if shape == SHAPE_TRIANGLE then
        local n = size - 1
        return (n - n % 2) / 2
    end
    if shape == SHAPE_CIRCLE then
        return size
    end
    return 0
end

---@param n number
---@return number
function sqrtFloor(n)
    return ktox_toInt(math.sqrt(ktox_toDouble(n)))
end

