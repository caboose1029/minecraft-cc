-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Digsite.kt", {["1-15"]=1,["16"]=77,["17"]=78,["18"]=79,["19"]=80,["20"]=81,["21"]=82,["22-26"]=83,["27"]=87,["28"]=88,["29-30"]=89,["31"]=92,["32"]=93,["33"]=94,["34-35"]=95,["36"]=98,["37"]=99,["38"]=100,["39-40"]=101,["41"]=104,["42"]=105,["43"]=106,["44-45"]=107,["46-47"]=109,["48"]=112,["49"]=113,["50"]=114,["51"]=115,["52"]=116,["53"]=118,["54"]=119,["55"]=120,["56"]=121,["57"]=122,["58-60"]=124,["61"]=128,["62"]=129,["63-64"]=130,["65-67"]=132,["68"]=135,["69"]=136,["70"]=137,["71"]=138,["72"]=140,["73"]=141,["74"]=142,["75"]=143,["76-78"]=145,["79"]=147,["80"]=148,["81-82"]=149,["83-85"]=151,["86"]=155,["87"]=156,["88"]=157,["89-94"]=158,["95"]=162,["96-97"]=163,["98"]=165,["99-100"]=166,["101-106"]=168,["107-112"]=178,["113"]=182,["114"]=183,["115"]=184,["116-117"]=185,["118-124"]=187,["125"]=191,["126-131"]=192,["132"]=197,["133"]=198,["134"]=199,["135"]=200,["136-138"]=202,["139-141"]=206,["142"]=208,["143"]=213,["144"]=214,["145"]=215,["146"]=216,["147"]=217,["148-150"]=218,["151-157"]=221,["158"]=231,["159"]=232,["160"]=233,["161"]=234,["162-170"]=235,["171"]=240,["172"]=241,["173"]=242,["174"]=243,["175"]=244,["176"]=245,["177"]=246,["178"]=247,["179"]=248,["180"]=249,["181-183"]=250,["184"]=253,["185"]=254,["186"]=255,["187"]=256,["188-190"]=257,["191"]=260,["192-198"]=261,["199"]=287,["200"]=288,["201"]=289,["202"]=290,["203"]=291,["204"]=292,["205"]=293,["206"]=294,["207-208"]=295,["209-223"]=297,["224"]=323,["225"]=324,["226"]=325,["227"]=326,["228"]=327,["229"]=328,["230"]=329,["231"]=330,["232"]=331,["233"]=332,["234"]=334,["235"]=335,["236"]=336,["237"]=337,["238-239"]=338,["240"]=340,["241"]=341,["242"]=343,["243"]=344,["244"]=345,["245"]=346,["246-247"]=347,["248"]=349,["249-250"]=350,["251-254"]=352}, "programs")
ktox_require("lib/Chest")
ktox_require("lib/Span")
ktox_require("lib/Movement")
ktox_require("lib/Position")
ktox_require("lib/Shape")

FUEL_SAFETY_MARGIN = 20

CLEAR_CUT_HEIGHT = 32

function printUsage()
    println("Usage: digsite <width> (<length>) (<height>)")
    println("       digsite -t <side> (<height>)   isoceles triangle")
    println("       digsite -rt <side> (<height>)  right triangle (equal legs)")
    println("       digsite -c <radius> (<height>) circle")
    println("       digsite -h                     show this help")
    println("height omitted: clear-cut mode, sweeps up from home Y until a")
    println("layer digs nothing. height given: room mode, exact bounded box.")
end

---@param args table
function main(args)
    if #(args) < 1 then
        printUsage()
        return
    end
    local flag = args[1]
    if flag == "-h" or flag == "--help" then
        printUsage()
        return
    end
    local isShape = flag == "-t" or flag == "-rt" or flag == "-c"
    if isShape and #(args) < 2 then
        printUsage()
        return
    end
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
    if isShape then
        local shape = shapeForFlag(flag)
        local size = ktox_toInt(args[2])
        local hasHeight = #(args) >= 3
        local height = (hasHeight and ktox_toInt(args[3]) or 0)
        local layerFn = function(mv, y)
            return digsiteLayerShaped(mv, movement.homeX, movement.homeZ, rgtDx, rgtDz, fwdDx, fwdDz, shape, size, y)
        end
        if hasHeight then
            local ySpan = IntSpan:new(movement.homeY, movement.homeY + height)
            digsiteRoom(movement, ySpan, layerFn)
        else
            clearCut(movement, layerFn)
        end
    else
        local width = ktox_toInt(args[1])
        local length = (#(args) >= 2 and ktox_toInt(args[2]) or width)
        local hasHeight = #(args) >= 3
        local height = (hasHeight and ktox_toInt(args[3]) or 0)
        local xOther = movement.homeX + rgtDx * (width - 1) + fwdDx * (length - 1)
        local zOther = movement.homeZ + rgtDz * (width - 1) + fwdDz * (length - 1)
        local xSpan = IntSpan:new(movement.homeX, xOther)
        local zSpan = IntSpan:new(movement.homeZ, zOther)
        local layerFn = function(mv, y)
            return digsiteLayer(mv, xSpan, zSpan, y)
        end
        if hasHeight then
            local ySpan = IntSpan:new(movement.homeY, movement.homeY + height)
            digsiteRoom(movement, ySpan, layerFn)
        else
            clearCut(movement, layerFn)
        end
    end
    println("Excavation complete. Returning home...")
    navigateTo(movement, movement.homeX, movement.homeY, movement.homeZ)
    movement:faceHeading(movement.homeHeading)
    println("Home.")
end

---@param flag string
---@return string
function shapeForFlag(flag)
    if flag == "-t" then
        return SHAPE_TRIANGLE
    end
    if flag == "-rt" then
        return SHAPE_RIGHT_TRIANGLE
    end
    return SHAPE_CIRCLE
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
---@param ySpan IntSpan
---@param layerFn (Movement, Int) -> Unit
function digsiteRoom(m, ySpan, layerFn)
    local yStep = stepFor(ySpan)
    local y = ySpan.start
    while not pastEnd(y, ySpan.finish, yStep) do
        layerFn(m, y)
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
---@param layerFn (Movement, Int) -> Unit
function clearCut(m, layerFn)
    local floorY = m.homeY
    local yStep = stepFor(IntSpan:new(floorY, floorY + CLEAR_CUT_HEIGHT))
    local y = floorY
    while not pastEnd(y, floorY + CLEAR_CUT_HEIGHT, yStep) do
        local dugBefore = m.blocksDug
        layerFn(m, y)
        if m.blocksDug == dugBefore then
            println("Layer at y=" .. tostring(y) .. " dug nothing - assuming clear of terrain, stopping.")
            return
        end
        y = ktox_plusAssign(y, yStep)
    end
end

---@param m Movement
---@param homeX number
---@param homeZ number
---@param rgtDx number
---@param rgtDz number
---@param fwdDx number
---@param fwdDz number
---@param shape string
---@param size number
---@param y number
function digsiteLayerShaped(m, homeX, homeZ, rgtDx, rgtDz, fwdDx, fwdDz, shape, size, y)
    local spine = shapeSpineColumn(shape, size)
    local rows = shapeRowCount(shape, size)
    local row = 0
    while row < rows do
        local bounds = shapeRowBounds(shape, size, row)
        if bounds ~= nil then
            local spineX = homeX + rgtDx * spine + fwdDx * row
            local spineZ = homeZ + rgtDz * spine + fwdDz * row
            ensureFuelAndSpace(m)
            navigateTo(m, spineX, y, spineZ)
            local col = spine
            while col > bounds.start do
                col = ktox_minusAssign(col, 1)
                ensureFuelAndSpace(m)
                navigateTo(m, homeX + rgtDx * col + fwdDx * row, y, homeZ + rgtDz * col + fwdDz * row)
            end
            ensureFuelAndSpace(m)
            navigateTo(m, spineX, y, spineZ)
            col = spine
            while col < bounds.finish do
                col = ktox_plusAssign(col, 1)
                ensureFuelAndSpace(m)
                navigateTo(m, homeX + rgtDx * col + fwdDx * row, y, homeZ + rgtDz * col + fwdDz * row)
            end
            ensureFuelAndSpace(m)
            navigateTo(m, spineX, y, spineZ)
        end
        row = ktox_plusAssign(row, 1)
    end
end


main({...})
