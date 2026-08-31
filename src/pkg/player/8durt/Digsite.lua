-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Digsite.kt", {["1-43"]=1,["44"]=43,["45"]=44,["46"]=45,["47-52"]=46,["53-60"]=50,["61"]=64,["62-63"]=65,["64-76"]=67,["77"]=82,["78"]=83,["79-80"]=84,["81"]=87,["82"]=88,["83"]=89,["84"]=91,["85"]=92,["86"]=93,["87"]=94,["88-89"]=95,["90"]=97,["91"]=99,["92"]=100,["93-94"]=101,["95-96"]=103,["97"]=106,["98"]=107,["99"]=108,["100-105"]=109,["106-111"]=115,["112-119"]=125,["120"]=137,["121-122"]=138,["123"]=140,["124-125"]=141,["126"]=143,["127"]=144,["128"]=145,["129"]=146,["130-132"]=147,["133"]=150,["134"]=151,["135"]=152,["136"]=153,["137-144"]=154,["145"]=162,["146"]=163,["147"]=164,["148-149"]=165,["150-154"]=167,["155"]=171,["156"]=172,["157"]=173,["158"]=174,["159-160"]=175,["161-162"]=177,["163-167"]=179,["168"]=183,["169-174"]=184,["175"]=189,["176"]=190,["177"]=191,["178"]=192,["179"]=194,["180"]=195,["181"]=197,["182"]=198,["183"]=200,["184"]=203,["185"]=204,["186"]=205,["187"]=206,["188-189"]=207,["190-195"]=209,["196"]=216,["197"]=217,["198"]=218,["199"]=219,["200-204"]=220,["205"]=228,["206"]=229,["207"]=231,["208"]=232,["209"]=233,["210"]=234,["211"]=235,["212"]=236,["213"]=237,["214"]=238,["215"]=239,["216"]=240,["217"]=241,["218-219"]=242,["220"]=244,["221-224"]=245,["225-226"]=249,["227"]=252,["228-232"]=253,["233"]=257,["234"]=258,["235"]=259,["236"]=260,["237"]=261,["238"]=262,["239"]=263,["240"]=264,["241-242"]=265,["243-245"]=267,["246-253"]=270,["254"]=276,["255"]=277,["256"]=278,["257"]=279,["258-266"]=280,["267"]=285,["268"]=286,["269"]=287,["270"]=288,["271"]=289,["272"]=290,["273"]=291,["274"]=292,["275"]=293,["276"]=294,["277-279"]=295,["280"]=298,["281"]=299,["282"]=300,["283"]=301,["284-286"]=302,["287"]=305,["288-295"]=306,["296"]=320,["297"]=321,["298-300"]=322}, "programs")
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
    if step > 0 then
        return current > limit
    end
    return current < limit
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
    local slot = 2
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
