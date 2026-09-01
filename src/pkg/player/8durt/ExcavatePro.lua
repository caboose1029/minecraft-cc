-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-19"]=1,["20"]=76,["21"]=77,["22-23"]=78,["24"]=81,["25"]=82,["26"]=83,["27"]=84,["28"]=86,["29"]=87,["30"]=88,["31-32"]=89,["33-34"]=91,["35"]=96,["36"]=98,["37"]=99,["38"]=100,["39"]=101,["40"]=102,["41"]=104,["42"]=105,["43"]=106,["44"]=107,["45"]=115,["46"]=116,["47"]=118,["48"]=120,["49"]=121,["50"]=122,["51"]=123,["52"]=125,["53"]=126,["54"]=127,["55"]=128,["56-57"]=129,["58"]=141,["59"]=142,["60"]=152,["61"]=153,["62"]=154,["63-64"]=155,["65"]=157,["66"]=158,["67"]=159,["68"]=160,["69"]=161,["70"]=162,["71-72"]=163,["73"]=165,["74"]=166,["75-76"]=167,["77"]=169,["78"]=170,["79-81"]=171,["82-84"]=174,["85"]=178,["86"]=184,["87-88"]=185,["89-90"]=187,["91"]=189,["92"]=190,["93"]=191,["94"]=192,["95-98"]=193,["99"]=198,["100"]=199,["101-102"]=200,["103"]=205,["104"]=206,["105"]=207,["106-116"]=208,["117"]=224,["118-119"]=225,["120"]=227,["121"]=228,["122"]=229,["123"]=230,["124-125"]=231,["126"]=233,["127-128"]=234,["129-168"]=236,["169-176"]=249,["177"]=253,["178"]=254,["179"]=255,["180-181"]=256,["182"]=258,["183"]=259,["184-185"]=260,["186"]=262,["187"]=263,["188-189"]=264,["190"]=266,["191-199"]=267,["200"]=276,["201"]=277,["202"]=278,["203"]=279,["204"]=280,["205"]=281,["206"]=282,["207"]=283,["208"]=284,["209"]=285,["210"]=286,["211-212"]=287,["213-215"]=289,["216"]=292,["217"]=293,["218"]=294,["219"]=295,["220-221"]=296,["222-224"]=298,["225"]=301,["226-227"]=302,["228-233"]=304,["234-239"]=310,["240"]=326,["241-242"]=327,["243"]=329,["244"]=330,["245-246"]=331,["247"]=333,["248-249"]=334,["250-255"]=336,["256"]=340,["257"]=341,["258"]=342,["259-260"]=343,["261-267"]=345,["268"]=349,["269-274"]=350,["275"]=355,["276"]=356,["277"]=357,["278-283"]=358,["284"]=367,["285"]=368,["286"]=369,["287"]=370,["288"]=371,["289"]=372,["290-292"]=373,["293-294"]=376,["295-299"]=378,["300"]=382,["301"]=383,["302"]=384,["303"]=385,["304-306"]=387,["307"]=388,["308"]=390,["309"]=395,["310"]=396,["311"]=397,["312"]=398,["313"]=399,["314-316"]=400,["317-321"]=403,["322-331"]=413}, "programs")
ktox_require("lib/Chest")
ktox_require("lib/Span")
ktox_require("lib/Movement")
ktox_require("lib/Position")

EP_FUEL_SAFETY_MARGIN = 20

TORCH_INTERVAL = 6

TORCH_SLOT = 3

RESTOCK_ATTEMPTS = 32

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
        epEnsureFuelAndSpace(movement)
        local blocked = false
        if not digLayer(movement, xSpan, zSpan, y) then
            blocked = true
        end
        if not blocked and hasStaircase and y + 1 < movement.homeY then
            local cell = perimeterCell(step, width, length)
            local cellX = movement.homeX + rgtDx * cell.dx + fwdDx * cell.dz
            local cellZ = movement.homeZ + rgtDz * cell.dx + fwdDz * cell.dz
            if not navigateTo(movement, cellX, y, cellZ) then
                blocked = true
            else
                levelsSinceTorch = ktox_plusAssign(levelsSinceTorch, 1)
                if levelsSinceTorch >= TORCH_INTERVAL then
                    ensureTorchSupply(movement)
                    turtle.digUp()
                    turtle.select(TORCH_SLOT)
                    turtle.placeUp()
                    levelsSinceTorch = 0
                else
                    local stepSlot = findCobblestoneSlot()
                    if stepSlot == -1 then
                        println("No cobblestone on hand for a step at y=" .. tostring(y) .. " - skipping this one.")
                    else
                        turtle.digUp()
                        turtle.select(stepSlot)
                        turtle.placeUp()
                    end
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
---@return boolean
function digLayer(m, xSpan, zSpan, y)
    local xStep = stepFor(xSpan)
    local zStep = stepFor(zSpan)
    local x = xSpan.start
    local forwardZ = true
    local ok = true
    while ok and not pastEnd(x, xSpan.finish, xStep) do
        if forwardZ then
            local z = zSpan.start
            while ok and not pastEnd(z, zSpan.finish, zStep) do
                epEnsureFuelAndSpace(m)
                if not navigateTo(m, x, y, z) then
                    ok = false
                end
                z = ktox_plusAssign(z, zStep)
            end
        else
            local z = zSpan.finish
            while ok and not pastEnd(z, zSpan.start, -zStep) do
                epEnsureFuelAndSpace(m)
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
    return name == "minecraft:cobblestone"
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
function epEnsureFuelAndSpace(m)
    if epNeedsService(m) then
        epServiceAtBase(m)
    end
end

---@param m Movement
function ensureTorchSupply(m)
    local name = ktoxGetItemName(TORCH_SLOT)
    local hasTorch = name ~= nil and isTorchItem(name)
    if not hasTorch then
        epServiceAtBase(m)
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
function epServiceAtBase(m)
    println("Returning to base to refuel/dump inventory/restock supplies...")
    local returnX = m.x
    local returnY = m.y
    local returnZ = m.z
    dumpCargo(m, function(slot)
        return shouldKeepSlot(slot)
    end)
    restockAtChest(m)
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
