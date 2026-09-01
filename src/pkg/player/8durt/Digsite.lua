-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Digsite.kt", {["1-15"]=1,["16"]=58,["17"]=59,["18-19"]=60,["20"]=63,["21"]=64,["22"]=65,["23"]=66,["24"]=68,["25"]=69,["26"]=70,["27-28"]=71,["29-30"]=73,["31"]=76,["32"]=77,["33"]=78,["34"]=79,["35"]=80,["36"]=82,["37"]=83,["38"]=84,["39"]=85,["40"]=87,["41"]=88,["42"]=89,["43-44"]=90,["45-46"]=92,["47"]=95,["48"]=96,["49"]=97,["50-55"]=98,["56-61"]=108,["62"]=112,["63"]=113,["64"]=114,["65-66"]=115,["67-73"]=117,["74"]=121,["75-80"]=122,["81"]=127,["82"]=128,["83"]=129,["84"]=130,["85-87"]=132,["88-90"]=136,["91"]=138,["92"]=143,["93"]=144,["94"]=145,["95"]=146,["96"]=147,["97-99"]=148,["100-107"]=151,["108"]=157,["109"]=158,["110"]=159,["111"]=160,["112-120"]=161,["121"]=166,["122"]=167,["123"]=168,["124"]=169,["125"]=170,["126"]=171,["127"]=172,["128"]=173,["129"]=174,["130"]=175,["131-133"]=176,["134"]=179,["135"]=180,["136"]=181,["137"]=182,["138-140"]=183,["141"]=186,["142-149"]=187,["150"]=201,["151"]=202,["152-154"]=203}, "programs")
ktox_require("lib/Chest")
ktox_require("lib/Span")
ktox_require("lib/Movement")
ktox_require("lib/Position")

FUEL_SAFETY_MARGIN = 20

CLEAR_CUT_HEIGHT = 32

---@param args table
function main(args)
    if #(args) < 1 then
        println("Usage: digsite <width> (<length>) (<height>)")
        return
    end
    local width = ktox_toInt(args[1])
    local length = (#(args) >= 2 and ktox_toInt(args[2]) or width)
    local hasHeight = #(args) >= 3
    local height = (hasHeight and ktox_toInt(args[3]) or 0)
    println("Calibrating position via GPS...")
    local movement = calibrateMovement()
    if movement.gpsEnabled then
        println("Home at x=" .. tostring(movement.homeX) .. " y=" .. tostring(movement.homeY) .. " z=" .. tostring(movement.homeZ))
    else
        println("No GPS available - running on dead reckoning only (no drift checks).")
    end
    local fwdDx = headingDx(movement.homeHeading)
    local fwdDz = headingDz(movement.homeHeading)
    local rightHeading = (movement.homeHeading + 1) % 4
    local rgtDx = headingDx(rightHeading)
    local rgtDz = headingDz(rightHeading)
    local xOther = movement.homeX + rgtDx * (width - 1) + fwdDx * (length - 1)
    local zOther = movement.homeZ + rgtDz * (width - 1) + fwdDz * (length - 1)
    local xSpan = IntSpan:new(movement.homeX, xOther)
    local zSpan = IntSpan:new(movement.homeZ, zOther)
    if hasHeight then
        local yOther = movement.homeY + height
        local ySpan = IntSpan:new(movement.homeY, yOther)
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
