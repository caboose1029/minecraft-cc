-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-19"]=1,["20"]=76,["21"]=77,["22-23"]=78,["24"]=81,["25"]=82,["26"]=83,["27"]=84,["28"]=86,["29"]=87,["30"]=88,["31-32"]=89,["33-34"]=91,["35"]=96,["36"]=98,["37"]=99,["38"]=100,["39"]=101,["40"]=102,["41"]=104,["42"]=105,["43"]=106,["44"]=107,["45"]=115,["46"]=116,["47"]=118,["48"]=120,["49"]=121,["50"]=122,["51"]=123,["52"]=125,["53"]=126,["54"]=127,["55"]=128,["56-57"]=129,["58"]=141,["59"]=142,["60"]=152,["61"]=153,["62"]=154,["63-64"]=155,["65"]=165,["66"]=166,["67-68"]=167,["69"]=169,["70"]=170,["71-72"]=171,["73"]=174,["74"]=175,["75"]=180,["76"]=181,["77"]=182,["78"]=183,["79-80"]=184,["81"]=186,["82"]=187,["83"]=188,["84-85"]=189,["86-87"]=191,["88-90"]=193,["91"]=197,["92"]=203,["93-94"]=204,["95-96"]=206,["97"]=208,["98"]=209,["99"]=210,["100"]=211,["101-104"]=212,["105"]=217,["106"]=218,["107-108"]=219,["109"]=224,["110"]=225,["111"]=226,["112-122"]=227,["123"]=243,["124-125"]=244,["126"]=246,["127"]=247,["128"]=248,["129"]=249,["130-131"]=250,["132"]=252,["133-134"]=253,["135-174"]=255,["175-182"]=268,["183"]=272,["184"]=273,["185"]=274,["186-187"]=275,["188"]=277,["189"]=278,["190-191"]=279,["192"]=281,["193"]=282,["194-195"]=283,["196"]=285,["197-205"]=286,["206"]=295,["207"]=296,["208"]=297,["209"]=298,["210"]=299,["211"]=300,["212"]=301,["213"]=302,["214"]=303,["215"]=304,["216"]=305,["217-218"]=306,["219-221"]=308,["222"]=311,["223"]=312,["224"]=313,["225"]=314,["226-227"]=315,["228-230"]=317,["231"]=320,["232-233"]=321,["234-239"]=323,["240-245"]=329,["246"]=345,["247-248"]=346,["249"]=348,["250"]=349,["251-252"]=350,["253"]=352,["254-255"]=353,["256-261"]=355,["262"]=359,["263"]=360,["264"]=361,["265-266"]=362,["267-273"]=364,["274"]=368,["275-280"]=369,["281"]=374,["282"]=375,["283"]=376,["284-289"]=377,["290"]=386,["291"]=387,["292"]=388,["293"]=389,["294"]=390,["295"]=391,["296-298"]=392,["299-300"]=395,["301-305"]=397,["306"]=401,["307"]=402,["308"]=403,["309"]=404,["310-312"]=406,["313"]=407,["314"]=409,["315"]=414,["316"]=415,["317"]=416,["318"]=417,["319"]=418,["320-322"]=419,["323-327"]=422,["328-337"]=432}, "programs")
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
                        ensureTorchSupply(movement)
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
