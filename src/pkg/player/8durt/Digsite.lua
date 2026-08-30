-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Digsite.kt", {["1-43"]=1,["44"]=38,["45"]=39,["46"]=40,["47-57"]=41,["58"]=52,["59"]=53,["60-61"]=54,["62"]=57,["63"]=58,["64"]=59,["65"]=61,["66"]=62,["67"]=63,["68"]=64,["69-70"]=65,["71"]=67,["72"]=69,["73"]=70,["74-75"]=71,["76-77"]=73,["78-83"]=76,["84-89"]=82,["90-97"]=92,["98"]=104,["99-100"]=105,["101"]=107,["102-103"]=108,["104"]=110,["105"]=111,["106"]=112,["107"]=113,["108-110"]=114,["111"]=117,["112"]=118,["113"]=119,["114"]=120,["115-122"]=121,["123"]=129,["124"]=130,["125"]=131,["126-127"]=132,["128-132"]=134,["133"]=138,["134"]=139,["135"]=140,["136"]=141,["137-138"]=142,["139-140"]=144,["141-145"]=146,["146"]=150,["147-152"]=151,["153"]=156,["154"]=157,["155"]=158,["156"]=159,["157"]=161,["158"]=162,["159"]=164,["160"]=165,["161"]=167,["162"]=170,["163"]=171,["164"]=172,["165"]=173,["166-167"]=174,["168-173"]=176,["174"]=183,["175"]=184,["176"]=185,["177"]=186,["178-182"]=187,["183"]=191,["184"]=192,["185"]=194,["186"]=195,["187"]=196,["188"]=197,["189"]=198,["190"]=199,["191"]=200,["192"]=201,["193"]=202,["194"]=203,["195"]=204,["196-197"]=205,["198"]=207,["199-202"]=208,["203-204"]=212,["205"]=215,["206-210"]=216,["211"]=220,["212"]=221,["213"]=222,["214"]=223,["215"]=224,["216"]=225,["217"]=226,["218"]=227,["219-220"]=228,["221-223"]=230,["224-231"]=233,["232"]=239,["233"]=240,["234"]=241,["235-243"]=242,["244"]=247,["245"]=248,["246"]=249,["247"]=250,["248"]=251,["249"]=252,["250"]=253,["251"]=254,["252-254"]=255,["255"]=258,["256"]=259,["257"]=260,["258"]=261,["259-261"]=262,["262"]=265,["263-270"]=266,["271"]=273,["272"]=274,["273"]=275,["274"]=276,["275"]=277,["276"]=278,["277"]=279,["278"]=280,["279"]=281,["280-282"]=282,["283"]=285,["284"]=286,["285"]=287,["286"]=288,["287-289"]=289,["290"]=292,["291-299"]=293,["300"]=298,["301"]=299,["302"]=300,["303"]=301,["304"]=302,["305-306"]=303,["307-311"]=305}, "programs")
ktox_require("lib/Movement")
ktox_require("lib/Position")

---@class IntSpan
---@field lo number
---@field hi number
IntSpan = {}
IntSpan.__index = IntSpan

function IntSpan:new(lo, hi)
    local self = setmetatable({}, IntSpan)
    self.lo = lo
    self.hi = hi
    return self
end

function IntSpan:equals(other)
    return self.lo == other.lo and self.hi == other.hi
end
IntSpan.__eq = function(a, b) return a:equals(b) end
function IntSpan:toString()
    return "IntSpan(" .. "lo=" .. tostring(self.lo) .. ", " .. "hi=" .. tostring(self.hi) .. ")"
end
IntSpan.__tostring = function(a) return a:toString() end
function IntSpan:copy(lo, hi)
    if lo == nil then lo = self.lo end
    if hi == nil then hi = self.hi end
    return IntSpan:new(lo, hi)
end
function IntSpan:component1()
    return self.lo
end
function IntSpan:component2()
    return self.hi
end

---@param raw string
---@return IntSpan
function parseSpan(raw)
    local parts = ktox_split(raw, ":")
    local a = ktox_toInt(parts[1])
    local b = ktox_toInt(parts[2])
    return (a <= b and IntSpan:new(a, b) or IntSpan:new(b, a))
end

OVERFLOW_SIDE = 1

FUEL_SAFETY_MARGIN = 20

MAX_OVERFLOW_CHESTS = 20

---@param args table
function main(args)
    if #(args) < 2 then
        println("Usage: digsite x1:x2 z1:z2 (y1:y2 optional)")
        return
    end
    local xSpan = parseSpan(args[1])
    local zSpan = parseSpan(args[2])
    local hasYSpan = #(args) >= 3
    println("Calibrating position via GPS...")
    local movement = calibrateMovement()
    if movement == nil then
        println("GPS calibration failed - check the wireless/ender modem and GPS host coverage.")
        return
    end
    println("Home at x=" .. tostring(movement.homeX) .. " y=" .. tostring(movement.homeY) .. " z=" .. tostring(movement.homeZ))
    if hasYSpan then
        local ySpan = parseSpan(args[3])
        digsiteRoom(movement, xSpan, ySpan, zSpan)
    else
        clearCut(movement, xSpan, zSpan)
    end
    println("Excavation complete.")
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

---@param m Movement
---@return boolean
function needsService(m)
    local fuel = turtle.getFuelLevel()
    local distance = m:distanceHome()
    if fuel < distance + FUEL_SAFETY_MARGIN then
        return true
    end
    return inventoryFull()
end

---@return boolean
function inventoryFull()
    local slot = 1
    local full = true
    while slot <= 16 do
        if turtle.getItemCount(slot) == 0 then
            full = false
        end
        slot = ktox_plusAssign(slot, 1)
    end
    return full
end

---@param m Movement
function ensureFuelAndSpace(m)
    if needsService(m) then
        serviceAtBase(m)
    end
end

---@param m Movement
function serviceAtBase(m)
    println("Returning to base to refuel/dump inventory...")
    local returnX = m.x
    local returnY = m.y
    local returnZ = m.z
    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m:faceHeading(m.homeHeading)
    dumpInventoryAtBase(m)
    refuelAtBase(m)
    navigateTo(m, returnX, returnY, returnZ)
    local checked = gpsLocate()
    if checked ~= nil then
        m.x = checked.x
        m.y = checked.y
        m.z = checked.z
    end
    println("Resuming excavation.")
end

---@param m Movement
---@param n number
function goToChest(m, n)
    local sideways = (m.homeHeading + OVERFLOW_SIDE + 4) % 4
    local targetX = m.homeX + headingDx(sideways) * n
    local targetZ = m.homeZ + headingDz(sideways) * n
    navigateTo(m, targetX, m.homeY, targetZ)
    m:faceHeading((m.homeHeading + 2) % 4)
end

---@param m Movement
function dumpInventoryAtBase(m)
    local chestIndex = 1
    goToChest(m, chestIndex)
    local slot = 1
    local giveUp = false
    while slot <= 16 and not giveUp do
        local count = turtle.getItemCount(slot)
        if count > 0 then
            turtle.select(slot)
            local dropped = turtle.drop(64)
            while not dropped and not giveUp do
                chestIndex = ktox_plusAssign(chestIndex, 1)
                if chestIndex > MAX_OVERFLOW_CHESTS then
                    println("All overflow chests full, stopping dump early.")
                    giveUp = true
                else
                    goToChest(m, chestIndex)
                    dropped = turtle.drop(64)
                end
            end
        end
        slot = ktox_plusAssign(slot, 1)
    end
    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m:faceHeading(m.homeHeading)
end

---@param m Movement
function refuelAtBase(m)
    m:faceHeading((m.homeHeading + 2) % 4)
    local attempts = 0
    local chestEmpty = false
    while attempts < 16 and not chestEmpty do
        turtle.select(1)
        local pulled = turtle.suck(64)
        if pulled then
            turtle.refuel(64)
            attempts = ktox_plusAssign(attempts, 1)
        else
            chestEmpty = true
        end
    end
    m:faceHeading(m.homeHeading)
end

---@param m Movement
---@param xSpan IntSpan
---@param ySpan IntSpan
---@param zSpan IntSpan
function digsiteRoom(m, xSpan, ySpan, zSpan)
    local y = ySpan.lo
    while y <= ySpan.hi do
        digsiteLayer(m, xSpan, zSpan, y)
        y = ktox_plusAssign(y, 1)
    end
end

---@param m Movement
---@param xSpan IntSpan
---@param zSpan IntSpan
---@param y number
function digsiteLayer(m, xSpan, zSpan, y)
    local x = xSpan.lo
    local forwardZ = true
    while x <= xSpan.hi do
        if forwardZ then
            local z = zSpan.lo
            while z <= zSpan.hi do
                ensureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z = ktox_plusAssign(z, 1)
            end
        else
            local z = zSpan.hi
            while z >= zSpan.lo do
                ensureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z = ktox_minusAssign(z, 1)
            end
        end
        forwardZ = not forwardZ
        x = ktox_plusAssign(x, 1)
    end
end

---@param m Movement
---@param xSpan IntSpan
---@param zSpan IntSpan
function clearCut(m, xSpan, zSpan)
    local floorY = m.homeY
    local x = xSpan.lo
    local forwardZ = true
    while x <= xSpan.hi do
        if forwardZ then
            local z = zSpan.lo
            while z <= zSpan.hi do
                ensureFuelAndSpace(m)
                clearColumn(m, x, floorY, z)
                z = ktox_plusAssign(z, 1)
            end
        else
            local z = zSpan.hi
            while z >= zSpan.lo do
                ensureFuelAndSpace(m)
                clearColumn(m, x, floorY, z)
                z = ktox_minusAssign(z, 1)
            end
        end
        forwardZ = not forwardZ
        x = ktox_plusAssign(x, 1)
    end
end

---@param m Movement
---@param x number
---@param floorY number
---@param z number
function clearColumn(m, x, floorY, z)
    navigateTo(m, x, floorY, z)
    local clearing = true
    while clearing do
        local above = ktoxInspectUpName()
        if above == nil then
            clearing = false
        else
            m:up()
        end
    end
end


main({...})
