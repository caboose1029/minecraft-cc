-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Digsite.kt", {["1-15"]=1,["16"]=82,["17"]=83,["18"]=84,["19"]=85,["20"]=86,["21"]=87,["22-26"]=88,["27"]=92,["28"]=93,["29-30"]=94,["31"]=97,["32"]=98,["33"]=99,["34-35"]=100,["36"]=103,["37"]=104,["38"]=105,["39-40"]=106,["41"]=109,["42"]=110,["43"]=111,["44-45"]=112,["46-47"]=114,["48"]=117,["49"]=118,["50"]=119,["51"]=120,["52"]=121,["53"]=123,["54"]=124,["55"]=125,["56"]=126,["57"]=127,["58-60"]=129,["61"]=133,["62"]=134,["63-64"]=135,["65-67"]=137,["68"]=140,["69"]=141,["70"]=142,["71"]=143,["72"]=145,["73"]=146,["74"]=147,["75"]=148,["76-78"]=150,["79"]=152,["80"]=153,["81-82"]=154,["83-85"]=156,["86"]=160,["87"]=161,["88"]=162,["89-94"]=163,["95"]=167,["96-97"]=168,["98"]=170,["99-100"]=171,["101-106"]=173,["107-112"]=183,["113"]=187,["114"]=188,["115"]=189,["116-117"]=190,["118-124"]=192,["125"]=196,["126-134"]=197,["135"]=215,["136"]=216,["137-142"]=217,["143"]=222,["144"]=223,["145"]=224,["146"]=225,["147-149"]=227,["150-152"]=231,["153"]=233,["154"]=238,["155"]=239,["156"]=240,["157"]=241,["158"]=242,["159-161"]=243,["162-168"]=246,["169"]=256,["170"]=257,["171"]=258,["172"]=259,["173-181"]=260,["182"]=265,["183"]=266,["184"]=267,["185"]=268,["186"]=269,["187"]=270,["188"]=271,["189"]=272,["190"]=273,["191"]=274,["192-194"]=275,["195"]=278,["196"]=279,["197"]=280,["198"]=281,["199-201"]=282,["202"]=285,["203-209"]=286,["210"]=312,["211"]=313,["212"]=314,["213"]=315,["214"]=316,["215"]=317,["216"]=318,["217"]=319,["218-219"]=320,["220-234"]=322,["235"]=357,["236"]=358,["237"]=359,["238"]=360,["239"]=361,["240"]=362,["241"]=363,["242"]=364,["243"]=365,["244"]=366,["245"]=368,["246"]=369,["247"]=370,["248"]=371,["249-250"]=372,["251"]=374,["252"]=375,["253"]=377,["254"]=378,["255"]=379,["256"]=380,["257-258"]=381,["259"]=383,["260-261"]=384,["262-265"]=386}, "programs")
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
---@param spineX number
---@param y number
---@param spineZ number
function ensureFuelAndSpaceShaped(m, spineX, y, spineZ)
    if needsService(m) then
        navigateTo(m, spineX, y, spineZ)
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
            local spineX = homeX + fwdDx * row
            local spineZ = homeZ + fwdDz * row
            ensureFuelAndSpaceShaped(m, spineX, y, spineZ)
            navigateTo(m, spineX, y, spineZ)
            local col = spine
            while col > bounds.start do
                col = ktox_minusAssign(col, 1)
                ensureFuelAndSpaceShaped(m, spineX, y, spineZ)
                navigateTo(m, homeX + rgtDx * (col - spine) + fwdDx * row, y, homeZ + rgtDz * (col - spine) + fwdDz * row)
            end
            ensureFuelAndSpaceShaped(m, spineX, y, spineZ)
            navigateTo(m, spineX, y, spineZ)
            col = spine
            while col < bounds.finish do
                col = ktox_plusAssign(col, 1)
                ensureFuelAndSpaceShaped(m, spineX, y, spineZ)
                navigateTo(m, homeX + rgtDx * (col - spine) + fwdDx * row, y, homeZ + rgtDz * (col - spine) + fwdDz * row)
            end
            ensureFuelAndSpaceShaped(m, spineX, y, spineZ)
            navigateTo(m, spineX, y, spineZ)
        end
        row = ktox_plusAssign(row, 1)
    end
end


main({...})
