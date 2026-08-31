-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Movement.kt", {["1-37"]=1,["38"]=44,["39-42"]=45,["43"]=49,["44-47"]=50,["48"]=54,["49-53"]=55,["54"]=60,["55"]=61,["56-57"]=62,["58"]=64,["59"]=65,["60"]=66,["61-67"]=67,["68"]=75,["69"]=76,["70-71"]=77,["72"]=79,["73"]=80,["74"]=81,["75-76"]=82,["77-81"]=84,["82"]=88,["83"]=89,["84-85"]=90,["86-90"]=92,["91"]=96,["92"]=97,["93-94"]=98,["95"]=100,["96"]=101,["97"]=102,["98-99"]=103,["100-104"]=105,["105"]=109,["106"]=110,["107-108"]=111,["109"]=113,["110"]=114,["111"]=115,["112-113"]=116,["114-118"]=118,["119"]=122,["120"]=123,["121-122"]=124,["123-124"]=125,["125-126"]=126,["127-132"]=127,["133"]=135,["134"]=136,["135"]=137,["136"]=138,["137"]=139,["138"]=140,["139-148"]=141,["149"]=151,["150"]=152,["151-152"]=153,["153"]=155,["154"]=156,["155"]=157,["156-158"]=158,["159"]=161,["160"]=162,["161-162"]=163,["163"]=165,["164-170"]=166,["171-186"]=170,["187-192"]=181,["193-200"]=191,["201"]=203,["202-203"]=204,["204"]=206,["205-206"]=207,["207"]=209,["208"]=210,["209"]=211,["210"]=212,["211-213"]=213,["214"]=216,["215"]=217,["216"]=218,["217"]=219,["218-222"]=220}, "lib")

---@alias MoveSign "FORWARD" | "BACKWARD"
local MoveSign = {}

MoveSign.FORWARD = "FORWARD"
MoveSign.BACKWARD = "BACKWARD"

---@class Movement
---@field homeX number
---@field homeY number
---@field homeZ number
---@field homeHeading number
---@field x number
---@field y number
---@field z number
---@field heading number
Movement = {}
Movement.__index = Movement

function Movement:new(startX, startY, startZ, startHeading, homeX, homeY, homeZ, homeHeading)
    local self = setmetatable({}, Movement)
    self.homeX = homeX
    self.homeY = homeY
    self.homeZ = homeZ
    self.homeHeading = homeHeading
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

---@return Movement?
function calibrateMovement()
    local start = gpsLocate()
    if start == nil then
        return nil
    end
    if not turtle.forward() then
        turtle.dig()
        if not turtle.forward() then
            return nil
        end
    end
    local after = gpsLocate()
    if after == nil then
        return nil
    end
    local heading = headingFromDelta(after.x - start.x, after.z - start.z)
    return Movement:new(after.x, after.y, after.z, heading, start.x, start.y, start.z, heading)
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
function navigateTo(m, targetX, targetY, targetZ)
    while m.y < targetY do
        m:up()
    end
    while m.y > targetY do
        m:down()
    end
    if m.x ~= targetX then
        local toward = (targetX > m.x and 1 or 3)
        m:faceHeading(toward)
        while m.x ~= targetX do
            m:forward()
        end
    end
    if m.z ~= targetZ then
        local toward = (targetZ > m.z and 2 or 0)
        m:faceHeading(toward)
        while m.z ~= targetZ do
            m:forward()
        end
    end
end

