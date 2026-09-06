-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Movement.kt", {["1-41"]=1,["42"]=59,["43-46"]=60,["47"]=64,["48-51"]=65,["52"]=69,["53-57"]=70,["58"]=75,["59"]=76,["60-61"]=77,["62"]=79,["63"]=80,["64"]=81,["65-71"]=82,["72"]=90,["73"]=91,["74-75"]=92,["76"]=94,["77-78"]=95,["79"]=97,["80"]=98,["81-82"]=99,["83-87"]=101,["88"]=105,["89"]=106,["90-91"]=107,["92-96"]=109,["97"]=113,["98"]=114,["99-100"]=115,["101"]=117,["102-103"]=118,["104"]=120,["105"]=121,["106-107"]=122,["108-112"]=124,["113"]=128,["114"]=129,["115-116"]=130,["117"]=132,["118-119"]=133,["120"]=135,["121"]=136,["122-123"]=137,["124-128"]=139,["129"]=143,["130"]=144,["131-132"]=145,["133-134"]=146,["135-136"]=147,["137-142"]=148,["143"]=156,["144"]=157,["145"]=158,["146"]=159,["147"]=160,["148"]=161,["149-158"]=162,["159"]=175,["160"]=176,["161-162"]=177,["163"]=179,["164"]=180,["165"]=181,["166-168"]=182,["169"]=185,["170"]=186,["171-172"]=190,["173"]=192,["174-180"]=193,["181-196"]=197,["197-202"]=208,["203-211"]=218,["212"]=240,["213"]=241,["214-216"]=242,["217"]=245,["218"]=246,["219-221"]=247,["222"]=250,["223"]=251,["224"]=252,["225"]=253,["226"]=254,["227-230"]=255,["231"]=259,["232"]=260,["233"]=261,["234"]=262,["235"]=263,["236-239"]=264,["240-242"]=268}, "lib")

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
---@field blocksDug number
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
    self.blocksDug = 0
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
    if turtle.dig() then
        self.blocksDug = ktox_plusAssign(self.blocksDug, 1)
    end
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
    if turtle.digUp() then
        self.blocksDug = ktox_plusAssign(self.blocksDug, 1)
    end
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
    if turtle.digDown() then
        self.blocksDug = ktox_plusAssign(self.blocksDug, 1)
    end
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

