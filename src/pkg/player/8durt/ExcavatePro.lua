-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-19"]=1,["20"]=73,["21"]=74,["22-23"]=75,["24"]=78,["25"]=79,["26"]=80,["27"]=81,["28"]=82,["29-30"]=83,["31"]=86,["32"]=87,["33"]=88,["34"]=89,["35-36"]=90,["37"]=92,["38"]=94,["39"]=95,["40"]=96,["41"]=97,["42"]=98,["43"]=100,["44"]=101,["45"]=102,["46"]=103,["47"]=105,["48"]=107,["49"]=108,["50"]=109,["51"]=110,["52"]=111,["53"]=113,["54"]=114,["55"]=115,["56"]=118,["57"]=119,["58"]=129,["59"]=130,["60"]=131,["61"]=133,["62"]=134,["63"]=135,["64"]=136,["65"]=137,["66"]=138,["67-68"]=139,["69"]=141,["70"]=142,["71-72"]=143,["73"]=145,["74"]=146,["75-77"]=147,["78-79"]=151,["80"]=153,["81"]=155,["82-83"]=156,["84"]=158,["85"]=159,["86"]=160,["87"]=161,["88-91"]=162,["92"]=167,["93"]=168,["94"]=169,["95-134"]=170,["135-142"]=183,["143"]=187,["144"]=188,["145"]=189,["146-147"]=190,["148"]=192,["149"]=193,["150-151"]=194,["152"]=196,["153"]=197,["154-155"]=198,["156"]=200,["157-164"]=201,["165"]=207,["166"]=208,["167"]=209,["168"]=210,["169"]=211,["170"]=212,["171"]=213,["172"]=214,["173"]=215,["174"]=216,["175-177"]=217,["178"]=220,["179"]=221,["180"]=222,["181"]=223,["182-184"]=224,["185"]=227,["186-192"]=228,["193-198"]=235,["199"]=251,["200-201"]=252,["202"]=254,["203"]=255,["204-205"]=256,["206"]=258,["207-208"]=259,["209-214"]=261,["215"]=265,["216"]=266,["217"]=267,["218-219"]=268,["220-226"]=270,["227"]=274,["228-233"]=275,["234"]=280,["235"]=281,["236"]=282,["237-242"]=283,["243"]=292,["244"]=293,["245"]=294,["246"]=295,["247"]=296,["248"]=297,["249-251"]=298,["252-253"]=301,["254-258"]=303,["259"]=307,["260"]=308,["261"]=309,["262"]=310,["263-265"]=312,["266"]=313,["267"]=315,["268"]=318,["269"]=319,["270"]=320,["271"]=321,["272-273"]=322,["274-278"]=324,["279-289"]=334}, "programs")
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
        println("Usage: excavatepro <width> (<length>) (<yTarget>)")
        return
    end
    local width = ktox_toInt(args[1])
    local length = (#(args) >= 2 and ktox_toInt(args[2]) or width)
    local hasYTarget = #(args) >= 3
    local yTarget = 0
    if hasYTarget then
        yTarget = ktox_toInt(args[3])
    end
    println("Calibrating position via GPS...")
    local movement = calibrateMovement()
    if movement == nil then
        println("GPS calibration failed - check the wireless/ender modem and GPS host coverage.")
        return
    end
    println("Home at x=" .. tostring(movement.homeX) .. " y=" .. tostring(movement.homeY) .. " z=" .. tostring(movement.homeZ))
    local fwdDx = headingDx(movement.homeHeading)
    local fwdDz = headingDz(movement.homeHeading)
    local rightHeading = (movement.homeHeading + 1) % 4
    local rgtDx = headingDx(rightHeading)
    local rgtDz = headingDz(rightHeading)
    local xOther = movement.homeX + rgtDx * (width - 1) + fwdDx * (length - 1)
    local zOther = movement.homeZ + rgtDz * (width - 1) + fwdDz * (length - 1)
    local xSpan = IntSpan:new(movement.homeX, xOther)
    local zSpan = IntSpan:new(movement.homeZ, zOther)
    local hasStaircase = width >= 2 and length >= 2
    local y = movement.homeY
    local step = 0
    local levelsSinceTorch = 0
    local isFirstLayer = true
    local digging = true
    while digging do
        epEnsureFuelAndSpace(movement)
        digLayer(movement, xSpan, zSpan, y)
        if hasStaircase and not isFirstLayer then
            local cell = perimeterCell(step, width, length)
            local cellX = movement.homeX + rgtDx * cell.dx + fwdDx * cell.dz
            local cellZ = movement.homeZ + rgtDz * cell.dx + fwdDz * cell.dz
            navigateTo(movement, cellX, y, cellZ)
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
        isFirstLayer = false
        if hasYTarget and y <= yTarget then
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
    navigateTo(movement, movement.homeX, movement.homeY, movement.homeZ)
    movement:faceHeading(movement.homeHeading)
    println("Home.")
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
function digLayer(m, xSpan, zSpan, y)
    local xStep = stepFor(xSpan)
    local zStep = stepFor(zSpan)
    local x = xSpan.start
    local forwardZ = true
    while not pastEnd(x, xSpan.finish, xStep) do
        if forwardZ then
            local z = zSpan.start
            while not pastEnd(z, zSpan.finish, zStep) do
                epEnsureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z = ktox_plusAssign(z, zStep)
            end
        else
            local z = zSpan.finish
            while not pastEnd(z, zSpan.start, -zStep) do
                epEnsureFuelAndSpace(m)
                navigateTo(m, x, y, z)
                z = ktox_minusAssign(z, zStep)
            end
        end
        forwardZ = not forwardZ
        x = ktox_plusAssign(x, xStep)
    end
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
    if slot == TORCH_SLOT and isTorchItem(name) then
        return true
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
    local checked = gpsLocate()
    if checked ~= nil then
        m.x = checked.x
        m.y = checked.y
        m.z = checked.z
    end
    println("Resuming excavation.")
end

---@param m Movement
function restockAtChest(m)
    restockChest(m, RESTOCK_ATTEMPTS, function(name)
        local handled = false
        if isTorchItem(name) then
            turtle.select(CHEST_INTAKE_SLOT)
            turtle.transferTo(TORCH_SLOT, 64)
            handled = true
        end
        return handled
    end)
end


main({...})
