-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Digsite.kt", {["1-12"]=1,["13"]=46,["14"]=47,["15"]=48,["16-24"]=49,["25"]=59,["26"]=60,["27-28"]=61,["29"]=64,["30"]=65,["31"]=66,["32"]=68,["33"]=69,["34"]=70,["35-36"]=71,["37-38"]=73,["39"]=76,["40"]=77,["41-42"]=78,["43-44"]=80,["45"]=83,["46"]=84,["47"]=85,["48-53"]=86,["54-59"]=96,["60"]=100,["61"]=101,["62"]=102,["63-64"]=103,["65-71"]=105,["72"]=109,["73-78"]=110,["79"]=115,["80"]=116,["81"]=117,["82"]=118,["83-85"]=120,["86-88"]=124,["89"]=126,["90"]=131,["91"]=132,["92"]=133,["93"]=134,["94"]=135,["95-97"]=136,["98-105"]=139,["106"]=145,["107"]=146,["108"]=147,["109"]=148,["110-118"]=149,["119"]=154,["120"]=155,["121"]=156,["122"]=157,["123"]=158,["124"]=159,["125"]=160,["126"]=161,["127"]=162,["128"]=163,["129-131"]=164,["132"]=167,["133"]=168,["134"]=169,["135"]=170,["136-138"]=171,["139"]=174,["140-147"]=175,["148"]=189,["149"]=190,["150-152"]=191}, "programs")
ktox_require("lib/Chest")
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

FUEL_SAFETY_MARGIN = 20

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
    if movement.gpsEnabled then
        println("Home at x=" .. tostring(movement.homeX) .. " y=" .. tostring(movement.homeY) .. " z=" .. tostring(movement.homeZ))
    else
        println("No GPS available - running on dead reckoning only (no drift checks).")
    end
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

---@param slot number
---@return boolean
function keepSlot(slot)
    return slot == CHEST_INTAKE_SLOT
end

---@param m Movement
---@return boolean
function needsService(m)
    local fuel = turtle.getFuelLevel()
    local distance = m:distanceHome()
    if fuel < distance + FUEL_SAFETY_MARGIN then
        return true
    end
    return cargoFull(function(slot)
        return keepSlot(slot)
    end)
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
    dumpCargo(m, function(slot)
        return keepSlot(slot)
    end)
    restockChest(m, 16, function(name)
        return false
    end)
    navigateTo(m, returnX, returnY, returnZ)
    if m.gpsEnabled then
        local checked = gpsLocate()
        if checked ~= nil then
            m.x = checked.x
            m.y = checked.y
            m.z = checked.z
        end
    end
    println("Resuming excavation.")
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
