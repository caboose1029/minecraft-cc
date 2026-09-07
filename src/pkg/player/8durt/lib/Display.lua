-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Display.kt", {["1-73"]=1,["74"]=17,["75-79"]=18,["80"]=22,["81"]=26,["82-85"]=27,["86-96"]=31,["97-101"]=37,["102"]=42,["103"]=43,["104-113"]=44,["114-116"]=50}, "lib")

---@class DisplaySize
---@field width number
---@field height number
DisplaySize = {}
DisplaySize.__index = DisplaySize

function DisplaySize:new(width, height)
    local self = setmetatable({}, DisplaySize)
    self.width = width
    self.height = height
    return self
end

function DisplaySize:equals(other)
    return self.width == other.width and self.height == other.height
end
DisplaySize.__eq = function(a, b) return a:equals(b) end
function DisplaySize:toString()
    return "DisplaySize(" .. "width=" .. tostring(self.width) .. ", " .. "height=" .. tostring(self.height) .. ")"
end
DisplaySize.__tostring = function(a) return a:toString() end
function DisplaySize:copy(width, height)
    if width == nil then width = self.width end
    if height == nil then height = self.height end
    return DisplaySize:new(width, height)
end
function DisplaySize:component1()
    return self.width
end
function DisplaySize:component2()
    return self.height
end

---@class Touch
---@field x number
---@field y number
Touch = {}
Touch.__index = Touch

function Touch:new(x, y)
    local self = setmetatable({}, Touch)
    self.x = x
    self.y = y
    return self
end

function Touch:equals(other)
    return self.x == other.x and self.y == other.y
end
Touch.__eq = function(a, b) return a:equals(b) end
function Touch:toString()
    return "Touch(" .. "x=" .. tostring(self.x) .. ", " .. "y=" .. tostring(self.y) .. ")"
end
Touch.__tostring = function(a) return a:toString() end
function Touch:copy(x, y)
    if x == nil then x = self.x end
    if y == nil then y = self.y end
    return Touch:new(x, y)
end
function Touch:component1()
    return self.x
end
function Touch:component2()
    return self.y
end

---@return DisplaySize
function displayInit()
    ktoxDisplayInit()
    return displaySize()
end

---@return DisplaySize
function displaySize()
    local raw = ktoxDisplayGetSize()
    local parts = ktox_split(raw, ",")
    return DisplaySize:new(ktox_toInt(ktox_toDouble(parts[1])), ktox_toInt(ktox_toDouble(parts[2])))
end

function displayClear()
    ktoxDisplayClear()
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param bgColor number
---@param textColor number
---@param text string
function displayFillRect(x, y, w, h, bgColor, textColor, text)
    ktoxDisplayFillRect(x, y, w, h, bgColor, textColor, text)
end

---@return Touch
function displayWaitTouch()
    local raw = ktoxDisplayWaitTouch()
    local parts = ktox_split(raw, ",")
    return Touch:new(ktox_toInt(ktox_toDouble(parts[1])), ktox_toInt(ktox_toDouble(parts[2])))
end

---@param t Touch
---@param x number
---@param y number
---@param w number
---@param h number
---@return boolean
function touchInRect(t, x, y, w, h)
    return t.x >= x and t.x < x + w and t.y >= y and t.y < y + h
end

