-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Movement.kt", {["1-39"]=1,["40"]=51,["41-44"]=52,["45"]=56,["46-49"]=57,["50"]=61,["51-55"]=62,["56"]=67,["57"]=68,["58-59"]=69,["60"]=71,["61"]=72,["62"]=73,["63-69"]=74,["70"]=82,["71"]=83,["72-73"]=84,["74"]=86,["75"]=87,["76"]=88,["77-78"]=89,["79-83"]=91,["84"]=95,["85"]=96,["86-87"]=97,["88-92"]=99,["93"]=103,["94"]=104,["95-96"]=105,["97"]=107,["98"]=108,["99"]=109,["100-101"]=110,["102-106"]=112,["107"]=116,["108"]=117,["109-110"]=118,["111"]=120,["112"]=121,["113"]=122,["114-115"]=123,["116-120"]=125,["121"]=129,["122"]=130,["123-124"]=131,["125-126"]=132,["127-128"]=133,["129-134"]=134,["135"]=142,["136"]=143,["137"]=144,["138"]=145,["139"]=146,["140"]=147,["141-150"]=148,["151"]=161,["152"]=162,["153-154"]=163,["155"]=165,["156"]=166,["157"]=167,["158-160"]=168,["161"]=171,["162"]=172,["163-164"]=176,["165"]=178,["166-172"]=179,["173-188"]=183,["189-194"]=194,["195-203"]=204,["204"]=226,["205"]=227,["206-208"]=228,["209"]=231,["210"]=232,["211-213"]=233,["214"]=236,["215"]=237,["216"]=238,["217"]=239,["218"]=240,["219-222"]=241,["223"]=245,["224"]=246,["225"]=247,["226"]=248,["227"]=249,["228-231"]=250,["232-234"]=254}, "lib")

---@alias MoveSign "FORWARD" | "BACKWARD"
local MoveSign = {}

MoveSign.FORWARD = "FORWARD"
MoveSign.BACKWARD = "BACKWARD"

---@class Movement
---@field homeX number
---@field homeY number
---@field homeZ number
---@field homeHeading number
---@field gpsEnabled boolean
---@field x number
---@field y number
---@field z number
---@field heading number
Movement = {}
Movement.__index = Movement

function Movement:new(startX, startY, startZ, startHeading, homeX, homeY, homeZ, homeHeading, gpsEnabled)
    local self = setmetatable({}, Movement)
    self.homeX = homeX
    self.homeY = homeY
    self.homeZ = homeZ
    self.homeHeading = homeHeading
    self.gpsEnabled = gpsEnabled
    self.x = startX
    self.y = startY
    self.z = startZ
    self.heading = startHeading
    return self
end

function Movement:turnLeft()
    turtle.turnLeft()
    self.heading = (self.heading + 3) % 4
end

function Movement:turnRight()
    turtle.turnRight()
    self.heading = (self.heading + 1) % 4
end

function Movement:turnAround()
    self:turnRight()
    self:turnRight()
end

---@param target number
function Movement:faceHeading(target)
    local diff = (target - self.heading + 4) % 4
    if diff == 3 then
        self:turnLeft()
    else
        local turned = 0
        while turned < diff do
            self:turnRight()
            turned = ktox_plusAssign(turned, 1)
        end
    end
end

---@return boolean
function Movement:forward()
    if turtle.forward() then
        self:applyDelta(MoveSign.FORWARD)
        return true
    end
    turtle.dig()
    if turtle.forward() then
        self:applyDelta(MoveSign.FORWARD)
        return true
    end
    return false
end

---@return boolean
function Movement:back()
    if turtle.back() then
        self:applyDelta(MoveSign.BACKWARD)
        return true
    end
    return false
end

---@return boolean
function Movement:up()
    if turtle.up() then
        self.y = ktox_plusAssign(self.y, 1)
        return true
    end
    turtle.digUp()
    if turtle.up() then
        self.y = ktox_plusAssign(self.y, 1)
        return true
    end
    return false
end

---@return boolean
function Movement:down()
    if turtle.down() then
        self.y = ktox_minusAssign(self.y, 1)
        return true
    end
    turtle.digDown()
    if turtle.down() then
        self.y = ktox_minusAssign(self.y, 1)
        return true
    end
    return false
end

---@param sign MoveSign
function Movement:applyDelta(sign)
    local delta = (sign == MoveSign.FORWARD and 1 or -1)
    if self.heading == 0 then
        self.z = ktox_minusAssign(self.z, delta)
    elseif self.heading == 1 then
        self.x = ktox_plusAssign(self.x, delta)
    elseif self.heading == 2 then
        self.z = ktox_plusAssign(self.z, delta)
    else
        self.x = ktox_minusAssign(self.x, delta)
    end
end

---@return number
function Movement:distanceHome()
    local dx = self.x - self.homeX
    local dz = self.z - self.homeZ
    local dy = self.y - self.homeY
    local adx = (dx < 0 and -dx or dx)
    local ady = (dy < 0 and -dy or dy)
    local adz = (dz < 0 and -dz or dz)
    return adx + ady + adz
end

function Movement:toString()
    return "lib.Movement"
end
Movement.__tostring = function(a) return a:toString() end

---@return Movement
function calibrateMovement()
    local start = gpsLocate()
    if start == nil then
        return Movement:new(0, 0, 0, 0, 0, 0, 0, 0, false)
    end
    if not turtle.forward() then
        turtle.dig()
        if not turtle.forward() then
            return Movement:new(0, 0, 0, 0, 0, 0, 0, 0, false)
        end
    end
    local after = gpsLocate()
    if after == nil then
        return Movement:new(0, 0, 0, 0, 0, 0, 0, 0, false)
    end
    local heading = headingFromDelta(after.x - start.x, after.z - start.z)
    return Movement:new(after.x, after.y, after.z, heading, start.x, start.y, start.z, heading, true)
end

---@param dx number
---@param dz number
---@return number
function headingFromDelta(dx, dz)
    return (function()
        if dz < 0 then
            return 0
        elseif dx > 0 then
            return 1
        elseif dz > 0 then
            return 2
        else
            return 3
        end
    end)()
end

---@param h number
---@return number
function headingDx(h)
    return (h == 1 and 1 or (h == 3 and -1 or 0))
end

---@param h number
---@return number
function headingDz(h)
    return (h == 2 and 1 or (h == 0 and -1 or 0))
end

---@param m Movement
---@param targetX number
---@param targetY number
---@param targetZ number
---@return boolean
function navigateTo(m, targetX, targetY, targetZ)
    while m.y < targetY do
        if not m:up() then
            return false
        end
    end
    while m.y > targetY do
        if not m:down() then
            return false
        end
    end
    if m.x ~= targetX then
        local toward = (targetX > m.x and 1 or 3)
        m:faceHeading(toward)
        while m.x ~= targetX do
            if not m:forward() then
                return false
            end
        end
    end
    if m.z ~= targetZ then
        local toward = (targetZ > m.z and 2 or 0)
        m:faceHeading(toward)
        while m.z ~= targetZ do
            if not m:forward() then
                return false
            end
        end
    end
    return true
end

