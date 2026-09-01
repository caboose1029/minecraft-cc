-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-21"]=1,["22"]=77,["23"]=78,["24-25"]=79,["26"]=82,["27"]=83,["28"]=84,["29"]=85,["30"]=87,["31"]=88,["32"]=89,["33-34"]=90,["35-36"]=92,["37"]=97,["38"]=99,["39"]=100,["40"]=101,["41"]=102,["42"]=103,["43"]=105,["44"]=106,["45"]=107,["46"]=108,["47"]=116,["48"]=117,["49"]=119,["50"]=121,["51"]=122,["52"]=123,["53"]=124,["54"]=126,["55"]=127,["56"]=128,["57"]=129,["58-59"]=130,["60"]=142,["61"]=143,["62"]=153,["63"]=154,["64"]=155,["65-66"]=156,["67"]=166,["68"]=167,["69-70"]=168,["71"]=170,["72"]=171,["73-74"]=172,["75"]=175,["76"]=176,["77"]=181,["78"]=182,["79"]=183,["80"]=184,["81-82"]=185,["83"]=187,["84"]=188,["85"]=189,["86-87"]=190,["88-89"]=192,["90-92"]=194,["93"]=198,["94"]=204,["95-96"]=205,["97-98"]=207,["99"]=209,["100"]=210,["101"]=211,["102"]=212,["103-106"]=213,["107"]=218,["108"]=219,["109-110"]=220,["111"]=225,["112"]=226,["113"]=227,["114-124"]=228,["125"]=244,["126-127"]=245,["128"]=247,["129"]=248,["130"]=249,["131"]=250,["132-133"]=251,["134"]=253,["135-136"]=254,["137-176"]=256,["177-184"]=269,["185"]=273,["186"]=274,["187"]=275,["188-189"]=276,["190"]=278,["191"]=279,["192-193"]=280,["194"]=282,["195"]=283,["196-197"]=284,["198"]=286,["199-209"]=287,["210"]=296,["211"]=297,["212"]=298,["213"]=299,["214"]=300,["215"]=301,["216"]=302,["217"]=303,["218"]=304,["219"]=305,["220"]=306,["221-222"]=307,["223-225"]=309,["226"]=312,["227"]=313,["228"]=314,["229"]=315,["230-231"]=316,["232-234"]=318,["235"]=321,["236-237"]=322,["238-243"]=324,["244-249"]=330,["250"]=344,["251"]=345,["252"]=346,["253"]=347,["254"]=348,["255-256"]=349,["257-258"]=351,["259-264"]=353,["265"]=368,["266-267"]=369,["268"]=371,["269"]=372,["270-271"]=373,["272"]=375,["273-274"]=376,["275"]=378,["276-277"]=379,["278-283"]=381,["284"]=385,["285"]=386,["286"]=387,["287-288"]=388,["289-297"]=390,["298"]=394,["299-306"]=395,["307"]=400,["308"]=401,["309"]=402,["310-315"]=403,["316"]=412,["317"]=413,["318"]=414,["319"]=415,["320"]=416,["321"]=417,["322-324"]=418,["325-326"]=421,["327-333"]=423,["334"]=427,["335"]=428,["336"]=429,["337"]=430,["338"]=437,["339"]=438,["340-342"]=440,["343"]=441,["344"]=443,["345"]=444,["346"]=445,["347"]=450,["348"]=451,["349"]=452,["350"]=453,["351"]=454,["352-354"]=455,["355-359"]=458,["360-369"]=468}, "programs")
ktox_require("lib/Chest")
ktox_require("lib/Span")
ktox_require("lib/Movement")
ktox_require("lib/Position")

EP_FUEL_SAFETY_MARGIN = 20

TORCH_INTERVAL = 6

TORCH_SLOT = 3

RESTOCK_ATTEMPTS = 32

COBBLESTONE_RESERVE = 64

---@param args table
function main(args)
    if #(args) < 1 then
        println("Usage: excavatepro <width> (<length>) (<depth>)")
        return
    end
    local width = ktox_toInt(args[1])
    local length = (#(args) >= 2 and ktox_toInt(args[2]) or width)
    local hasDepth = #(args) >= 3
    local depth = (hasDepth and ktox_toInt(args[3]) or 0)
    println("Calibrating position via GPS...")
    local movement = calibrateMovement()
    if movement.gpsEnabled then
        println("Home at x=" .. tostring(movement.homeX) .. " y=" .. tostring(movement.homeY) .. " z=" .. tostring(movement.homeZ))
    else
        println("No GPS available - running on dead reckoning only (no drift checks).")
    end
    local yTarget = movement.homeY - depth
    local fwdDx = headingDx(movement.homeHeading)
    local fwdDz = headingDz(movement.homeHeading)
    local rightHeading = (movement.homeHeading + 1) % 4
    local rgtDx = headingDx(rightHeading)
    local rgtDz = headingDz(rightHeading)
    local xOther = movement.homeX + rgtDx * (width - 1) + fwdDx * (length - 1)
    local zOther = movement.homeZ + rgtDz * (width - 1) + fwdDz * (length - 1)
    local xSpan = IntSpan:new(movement.homeX, xOther)
    local zSpan = IntSpan:new(movement.homeZ, zOther)
    local centerX = movement.homeX + rgtDx * (width / 2) + fwdDx * (length / 2)
    local centerZ = movement.homeZ + rgtDz * (width / 2) + fwdDz * (length / 2)
    local hasStaircase = width >= 2 and length >= 2
    local y = movement.homeY
    local step = 0
    local levelsSinceTorch = 0
    local digging = true
    while digging do
        epEnsureFuelAndSpace(movement, centerX, centerZ)
        local blocked = false
        if not digLayer(movement, xSpan, zSpan, y, centerX, centerZ) then
            blocked = true
        end
        if not blocked and hasStaircase and y + 1 < movement.homeY then
            local cell = perimeterCell(step, width, length)
            local cellX = movement.homeX + rgtDx * cell.dx + fwdDx * cell.dz
            local cellZ = movement.homeZ + rgtDz * cell.dx + fwdDz * cell.dz
            if not navigateTo(movement, cellX, y, cellZ) then
                blocked = true
            else
                local stepSlot = findCobblestoneSlot()
                if stepSlot == -1 then
                    println("No cobblestone on hand for a step at y=" .. tostring(y) .. " - skipping this one.")
                else
                    turtle.digUp()
                    turtle.select(stepSlot)
                    turtle.placeUp()
                end
                levelsSinceTorch = ktox_plusAssign(levelsSinceTorch, 1)
                if levelsSinceTorch >= TORCH_INTERVAL then
                    local torchCell = perimeterCell(step + 1, width, length)
                    local torchX = movement.homeX + rgtDx * torchCell.dx + fwdDx * torchCell.dz
                    local torchZ = movement.homeZ + rgtDz * torchCell.dx + fwdDz * torchCell.dz
                    if not navigateTo(movement, torchX, y, torchZ) then
                        println("Couldn\'t reach a torch position at y=" .. tostring(y) .. " - skipping this one.")
                    else
                        ensureTorchSupply(movement, centerX, centerZ)
                        turtle.digUp()
                        turtle.select(TORCH_SLOT)
                        turtle.placeUp()
                    end
                    levelsSinceTorch = 0
                end
                step = ktox_plusAssign(step, 1)
            end
        end
        if blocked then
            println("Movement blocked at y=" .. tostring(y) .. " (bedrock or another undiggable obstruction) - stopping.")
            digging = false
        elseif hasDepth and y <= yTarget then
            digging = false
        else
            local moved = movement:down()
            y = movement.y
            if not moved then
                println("Hit bedrock (or an undiggable block) at y=" .. tostring(y) .. ".")
                digging = false
            end
        end
    end
    println("Excavation complete. Returning home...")
    if not navigateWithRecovery(movement, centerX, centerZ) then
        println("Could not reach the center column even after climbing - staying put.")
    else
        navigateTo(movement, centerX, movement.homeY, centerZ)
        navigateTo(movement, movement.homeX, movement.homeY, movement.homeZ)
        movement:faceHeading(movement.homeHeading)
        println("Home.")
    end
end

MAX_RECOVERY_ASCENTS = 32

---@param m Movement
---@param targetX number
---@param targetZ number
---@return boolean
function navigateWithRecovery(m, targetX, targetZ)
    if navigateTo(m, targetX, m.y, targetZ) then
        return true
    end
    local attempts = 0
    local reached = false
    while not reached and attempts < MAX_RECOVERY_ASCENTS do
        if not m:up() then
            return false
        end
        reached = navigateTo(m, targetX, m.y, targetZ)
        attempts = ktox_plusAssign(attempts, 1)
    end
    return reached
end

---@class Cell
---@field dx number
---@field dz number
Cell = {}
Cell.__index = Cell

function Cell:new(dx, dz)
    local self = setmetatable({}, Cell)
    self.dx = dx
    self.dz = dz
    return self
end

function Cell:equals(other)
    return self.dx == other.dx and self.dz == other.dz
end
Cell.__eq = function(a, b) return a:equals(b) end
function Cell:toString()
    return "Cell(" .. "dx=" .. tostring(self.dx) .. ", " .. "dz=" .. tostring(self.dz) .. ")"
end
Cell.__tostring = function(a) return a:toString() end
function Cell:copy(dx, dz)
    if dx == nil then dx = self.dx end
    if dz == nil then dz = self.dz end
    return Cell:new(dx, dz)
end
function Cell:component1()
    return self.dx
end
function Cell:component2()
    return self.dz
end

---@param width number
---@param length number
---@return number
function perimeterLength(width, length)
    return 2 * width + 2 * length - 4
end

---@param step number
---@param width number
---@param length number
---@return Cell
function perimeterCell(step, width, length)
    local p = perimeterLength(width, length)
    local i = step % p
    if i < width then
        return Cell:new(i, 0)
    end
    i = ktox_minusAssign(i, width)
    if i < length - 1 then
        return Cell:new(width - 1, i + 1)
    end
    i = ktox_minusAssign(i, (length - 1))
    if i < width - 1 then
        return Cell:new(width - 2 - i, length - 1)
    end
    i = ktox_minusAssign(i, (width - 1))
    return Cell:new(0, length - 2 - i)
end

---@param m Movement
---@param xSpan IntSpan
---@param zSpan IntSpan
---@param y number
---@param centerX number
---@param centerZ number
---@return boolean
function digLayer(m, xSpan, zSpan, y, centerX, centerZ)
    local xStep = stepFor(xSpan)
    local zStep = stepFor(zSpan)
    local x = xSpan.start
    local forwardZ = true
    local ok = true
    while ok and not pastEnd(x, xSpan.finish, xStep) do
        if forwardZ then
            local z = zSpan.start
            while ok and not pastEnd(z, zSpan.finish, zStep) do
                epEnsureFuelAndSpace(m, centerX, centerZ)
                if not navigateTo(m, x, y, z) then
                    ok = false
                end
                z = ktox_plusAssign(z, zStep)
            end
        else
            local z = zSpan.finish
            while ok and not pastEnd(z, zSpan.start, -zStep) do
                epEnsureFuelAndSpace(m, centerX, centerZ)
                if not navigateTo(m, x, y, z) then
                    ok = false
                end
                z = ktox_minusAssign(z, zStep)
            end
        end
        forwardZ = not forwardZ
        x = ktox_plusAssign(x, xStep)
    end
    return ok
end

---@param name string
---@return boolean
function isTorchItem(name)
    return name == "minecraft:torch"
end

---@param slot number
---@return boolean
function withinCobblestoneReserve(slot)
    local s = 1
    local totalBefore = 0
    while s < slot do
        local name = ktoxGetItemName(s)
        if name ~= nil and name == "minecraft:cobblestone" then
            totalBefore = ktox_plusAssign(totalBefore, turtle.getItemCount(s))
        end
        s = ktox_plusAssign(s, 1)
    end
    return totalBefore < COBBLESTONE_RESERVE
end

---@param slot number
---@return boolean
function shouldKeepSlot(slot)
    if slot == CHEST_INTAKE_SLOT then
        return turtle.getItemCount(slot) == 0
    end
    local name = ktoxGetItemName(slot)
    if name == nil then
        return slot == TORCH_SLOT
    end
    if slot == TORCH_SLOT then
        return isTorchItem(name)
    end
    if name == "minecraft:cobblestone" then
        return withinCobblestoneReserve(slot)
    end
    return false
end

---@param m Movement
---@return boolean
function epNeedsService(m)
    local fuel = turtle.getFuelLevel()
    local distance = m:distanceHome()
    if fuel < distance + EP_FUEL_SAFETY_MARGIN then
        return true
    end
    return cargoFull(function(slot)
        return shouldKeepSlot(slot)
    end)
end

---@param m Movement
---@param centerX number
---@param centerZ number
function epEnsureFuelAndSpace(m, centerX, centerZ)
    if epNeedsService(m) then
        epServiceAtBase(m, centerX, centerZ)
    end
end

---@param m Movement
---@param centerX number
---@param centerZ number
function ensureTorchSupply(m, centerX, centerZ)
    local name = ktoxGetItemName(TORCH_SLOT)
    local hasTorch = name ~= nil and isTorchItem(name)
    if not hasTorch then
        epServiceAtBase(m, centerX, centerZ)
    end
end

---@return number
function findCobblestoneSlot()
    local slot = 1
    local found = -1
    while slot <= 16 and found == -1 do
        if turtle.getItemCount(slot) > 0 then
            local name = ktoxGetItemName(slot)
            if name ~= nil and name == "minecraft:cobblestone" then
                found = slot
            end
        end
        slot = ktox_plusAssign(slot, 1)
    end
    return found
end

---@param m Movement
---@param centerX number
---@param centerZ number
function epServiceAtBase(m, centerX, centerZ)
    println("Returning to base to refuel/dump inventory/restock supplies...")
    local returnX = m.x
    local returnY = m.y
    local returnZ = m.z
    navigateTo(m, centerX, m.y, centerZ)
    navigateTo(m, centerX, m.homeY, centerZ)
    dumpCargo(m, function(slot)
        return shouldKeepSlot(slot)
    end)
    restockAtChest(m)
    navigateTo(m, centerX, m.homeY, centerZ)
    navigateTo(m, centerX, returnY, centerZ)
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
function restockAtChest(m)
    restockChest(m, RESTOCK_ATTEMPTS, function(name)
        local handled = false
        if isTorchItem(name) then
            turtle.select(CHEST_INTAKE_SLOT)
            handled = turtle.transferTo(TORCH_SLOT, 64)
        end
        return handled
    end)
end


main({...})
