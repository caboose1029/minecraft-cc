-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Position.kt", {["1-48"]=1,["49"]=16,["50"]=17,["51-52"]=18,["53"]=24,["54-56"]=25}, "lib")

---@class Position
---@field x number
---@field y number
---@field z number
Position = {}
Position.__index = Position

function Position:new(x, y, z)
    local self = setmetatable({}, Position)
    self.x = x
    self.y = y
    self.z = z
    return self
end

function Position:equals(other)
    return self.x == other.x and self.y == other.y and self.z == other.z
end
Position.__eq = function(a, b) return a:equals(b) end
function Position:toString()
    return "Position(" .. "x=" .. tostring(self.x) .. ", " .. "y=" .. tostring(self.y) .. ", " .. "z=" .. tostring(self.z) .. ")"
end
Position.__tostring = function(a) return a:toString() end
function Position:copy(x, y, z)
    if x == nil then x = self.x end
    if y == nil then y = self.y end
    if z == nil then z = self.z end
    return Position:new(x, y, z)
end
function Position:component1()
    return self.x
end
function Position:component2()
    return self.y
end
function Position:component3()
    return self.z
end

---@param timeout number
---@return Position?
function gpsLocate(timeout)
    if timeout == nil then timeout = 2.0 end
    local raw = ktoxGpsLocate(timeout)
    if raw == nil then
        return nil
    end
    local parts = ktox_split(raw, ",")
    return Position:new(ktox_toInt(ktox_toDouble(parts[1])), ktox_toInt(ktox_toDouble(parts[2])), ktox_toInt(ktox_toDouble(parts[3])))
end

