-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Digsite.kt", {["1-11"]=1,["12"]=47,["13"]=48,["14"]=49,["15-27"]=50,["28"]=65,["29"]=66,["30-31"]=67,["32"]=70,["33"]=71,["34"]=72,["35"]=74,["36"]=75,["37"]=76,["38"]=77,["39-40"]=78,["41"]=80,["42"]=82,["43"]=83,["44-45"]=84,["46-47"]=86,["48"]=89,["49"]=90,["50"]=91,["51-56"]=92,["57"]=98,["58"]=99,["59"]=100,["60-61"]=101,["62-66"]=103,["67"]=107,["68"]=108,["69"]=109,["70"]=110,["71-72"]=111,["73-74"]=113,["75-79"]=115,["80"]=119,["81-86"]=120,["87"]=125,["88"]=126,["89"]=127,["90"]=128,["91"]=130,["92"]=131,["93"]=133,["94"]=134,["95"]=136,["96"]=139,["97"]=140,["98"]=141,["99"]=142,["100-101"]=143,["102-107"]=145,["108"]=152,["109"]=153,["110"]=154,["111"]=155,["112-116"]=156,["117"]=164,["118"]=165,["119"]=167,["120"]=168,["121"]=169,["122"]=170,["123"]=171,["124"]=172,["125"]=173,["126"]=174,["127"]=175,["128"]=176,["129"]=177,["130-131"]=178,["132"]=180,["133-136"]=181,["137-138"]=185,["139"]=188,["140-144"]=189,["145"]=193,["146"]=194,["147"]=195,["148"]=196,["149"]=197,["150"]=198,["151"]=199,["152"]=200,["153-154"]=201,["155-157"]=203,["158-165"]=206,["166"]=212,["167"]=213,["168"]=214,["169"]=215,["170-178"]=216,["179"]=221,["180"]=222,["181"]=223,["182"]=224,["183"]=225,["184"]=226,["185"]=227,["186"]=228,["187"]=229,["188"]=230,["189-191"]=231,["192"]=234,["193"]=235,["194"]=236,["195"]=237,["196-198"]=238,["199"]=241,["200-207"]=242,["208"]=256,["209"]=257,["210-212"]=258}, "programs")
ktox_require("lib/Span")
ktox_require("lib/Movement")
ktox_require("lib/Position")

---@param raw string
---@return IntSpan
function parseSpan(raw)
    local parts = ktox_split(raw, ":")
    local a = ktox_toInt(parts[1])
    local b = ktox_toInt(parts[2])
    return IntSpan:new(a, b)
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
