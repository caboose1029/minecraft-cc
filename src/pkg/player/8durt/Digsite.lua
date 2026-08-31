-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Digsite.kt", {["1-43"]=1,["44"]=43,["45"]=44,["46"]=45,["47-52"]=46,["53-60"]=50,["61-73"]=56,["74"]=71,["75"]=72,["76-77"]=73,["78"]=76,["79"]=77,["80"]=78,["81"]=80,["82"]=81,["83"]=82,["84"]=83,["85-86"]=84,["87"]=86,["88"]=88,["89"]=89,["90-91"]=90,["92-93"]=92,["94"]=95,["95"]=96,["96"]=97,["97-102"]=98,["103-108"]=104,["109-116"]=114,["117"]=126,["118-119"]=127,["120"]=129,["121-122"]=130,["123"]=132,["124"]=133,["125"]=134,["126"]=135,["127-129"]=136,["130"]=139,["131"]=140,["132"]=141,["133"]=142,["134-141"]=143,["142"]=151,["143"]=152,["144"]=153,["145-146"]=154,["147-151"]=156,["152"]=160,["153"]=161,["154"]=162,["155"]=163,["156-157"]=164,["158-159"]=166,["160-164"]=168,["165"]=172,["166-171"]=173,["172"]=178,["173"]=179,["174"]=180,["175"]=181,["176"]=183,["177"]=184,["178"]=186,["179"]=187,["180"]=189,["181"]=192,["182"]=193,["183"]=194,["184"]=195,["185-186"]=196,["187-192"]=198,["193"]=205,["194"]=206,["195"]=207,["196"]=208,["197-201"]=209,["202"]=213,["203"]=214,["204"]=216,["205"]=217,["206"]=218,["207"]=219,["208"]=220,["209"]=221,["210"]=222,["211"]=223,["212"]=224,["213"]=225,["214"]=226,["215-216"]=227,["217"]=229,["218-221"]=230,["222-223"]=234,["224"]=237,["225-229"]=238,["230"]=242,["231"]=243,["232"]=244,["233"]=245,["234"]=246,["235"]=247,["236"]=248,["237"]=249,["238-239"]=250,["240-242"]=252,["243-250"]=255,["251"]=261,["252"]=262,["253"]=263,["254"]=264,["255-263"]=265,["264"]=270,["265"]=271,["266"]=272,["267"]=273,["268"]=274,["269"]=275,["270"]=276,["271"]=277,["272"]=278,["273"]=279,["274-276"]=280,["277"]=283,["278"]=284,["279"]=285,["280"]=286,["281-283"]=287,["284"]=290,["285-292"]=291,["293"]=305,["294"]=306,["295-297"]=307}, "programs")
ktox_require("lib/Movement")
ktox_require("lib/Position")

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

---@param raw string
---@return IntSpan
function parseSpan(raw)
    local parts = ktox_split(raw, ":")
    local a = ktox_toInt(parts[1])
    local b = ktox_toInt(parts[2])
    return IntSpan:new(a, b)
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
    return (step > 0 and current > limit or current < limit)
end

OVERFLOW_SIDE = 1

FUEL_SAFETY_MARGIN = 20

MAX_OVERFLOW_CHESTS = 20

CLEAR_CUT_HEIGHT = 32

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
    println("Excavation complete. Returning home...")
    navigateTo(movement, movement.homeX, movement.homeY, movement.homeZ)
    movement:faceHeading(movement.homeHeading)
    println("Home.")
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
    local yStep = stepFor(ySpan)
    local y = ySpan.start
    while not pastEnd(y, ySpan.finish, yStep) do
        digsiteLayer(m, xSpan, zSpan, y)
        y = ktox_plusAssign(y, yStep)
    end
end

---@param m Movement
---@param xSpan IntSpan
---@param zSpan IntSpan
---@param y number
function digsiteLayer(m, xSpan, zSpan, y)
    local xStep = stepFor(xSpan)
    local zStep = stepFor(zSpan)
    local x = xSpan.start
    local forwardZ = true
    while not pastEnd(x, xSpan.finish, xStep) do
        if forwardZ then
            local z = zSpan.start
            while not pastEnd(z, zSpan.finish, zStep) do
                ensureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z = ktox_plusAssign(z, zStep)
            end
        else
            local z = zSpan.finish
            while not pastEnd(z, zSpan.start, -zStep) do
                ensureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z = ktox_minusAssign(z, zStep)
            end
        end
        forwardZ = not forwardZ
        x = ktox_plusAssign(x, xStep)
    end
end

---@param m Movement
---@param xSpan IntSpan
---@param zSpan IntSpan
function clearCut(m, xSpan, zSpan)
    local floorY = m.homeY
    local ySpan = IntSpan:new(floorY, floorY + CLEAR_CUT_HEIGHT)
    digsiteRoom(m, xSpan, ySpan, zSpan)
end


main({...})
