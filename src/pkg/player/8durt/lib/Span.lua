-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Span.kt", {["1-41"]=1,["42-49"]=10,["50"]=22,["51-52"]=23,["53-55"]=25}, "lib")

---@class IntSpan
---@field start number
---@field finish number
IntSpan = {}
IntSpan.__index = IntSpan

function IntSpan:new(start, finish)
    local self = setmetatable({}, IntSpan)
    self.start = start
    self.finish = finish
    return self
end

function IntSpan:equals(other)
    return self.start == other.start and self.finish == other.finish
end
IntSpan.__eq = function(a, b) return a:equals(b) end
function IntSpan:toString()
    return "IntSpan(" .. "start=" .. tostring(self.start) .. ", " .. "finish=" .. tostring(self.finish) .. ")"
end
IntSpan.__tostring = function(a) return a:toString() end
function IntSpan:copy(start, finish)
    if start == nil then start = self.start end
    if finish == nil then finish = self.finish end
    return IntSpan:new(start, finish)
end
function IntSpan:component1()
    return self.start
end
function IntSpan:component2()
    return self.finish
end

---@param span IntSpan
---@return number
function stepFor(span)
    return (span.start <= span.finish and 1 or -1)
end

---@param current number
---@param limit number
---@param step number
---@return boolean
function pastEnd(current, limit, step)
    if step > 0 then
        return current > limit
    end
    return current < limit
end

