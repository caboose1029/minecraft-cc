-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-19"]=1,["20"]=76,["21"]=77,["22-23"]=78,["24"]=81,["25"]=82,["26"]=83,["27"]=84,["28"]=86,["29"]=87,["30"]=88,["31-32"]=89,["33-34"]=91,["35"]=96,["36"]=98,["37"]=99,["38"]=100,["39"]=101,["40"]=102,["41"]=104,["42"]=105,["43"]=106,["44"]=107,["45"]=115,["46"]=116,["47"]=118,["48"]=120,["49"]=121,["50"]=122,["51"]=123,["52"]=124,["53"]=126,["54"]=127,["55"]=128,["56"]=129,["57-58"]=130,["59"]=134,["60"]=135,["61"]=145,["62"]=146,["63"]=147,["64-65"]=148,["66"]=150,["67"]=151,["68"]=152,["69"]=153,["70"]=154,["71"]=155,["72-73"]=156,["74"]=158,["75"]=159,["76-77"]=160,["78"]=162,["79"]=163,["80-82"]=164,["83-85"]=167,["86"]=170,["87"]=172,["88"]=178,["89-90"]=179,["91-92"]=181,["93"]=183,["94"]=184,["95"]=185,["96"]=186,["97-100"]=187,["101"]=192,["102"]=193,["103-104"]=194,["105"]=199,["106"]=200,["107"]=201,["108-118"]=202,["119"]=218,["120-121"]=219,["122"]=221,["123"]=222,["124"]=223,["125"]=224,["126-127"]=225,["128"]=227,["129-130"]=228,["131-170"]=230,["171-178"]=243,["179"]=247,["180"]=248,["181"]=249,["182-183"]=250,["184"]=252,["185"]=253,["186-187"]=254,["188"]=256,["189"]=257,["190-191"]=258,["192"]=260,["193-201"]=261,["202"]=270,["203"]=271,["204"]=272,["205"]=273,["206"]=274,["207"]=275,["208"]=276,["209"]=277,["210"]=278,["211"]=279,["212"]=280,["213-214"]=281,["215-217"]=283,["218"]=286,["219"]=287,["220"]=288,["221"]=289,["222-223"]=290,["224-226"]=292,["227"]=295,["228-229"]=296,["230-235"]=298,["236-241"]=304,["242"]=320,["243-244"]=321,["245"]=323,["246"]=324,["247-248"]=325,["249"]=327,["250-251"]=328,["252-257"]=330,["258"]=334,["259"]=335,["260"]=336,["261-262"]=337,["263-269"]=339,["270"]=343,["271-276"]=344,["277"]=349,["278"]=350,["279"]=351,["280-285"]=352,["286"]=361,["287"]=362,["288"]=363,["289"]=364,["290"]=365,["291"]=366,["292-294"]=367,["295-296"]=370,["297-301"]=372,["302"]=376,["303"]=377,["304"]=378,["305"]=379,["306-308"]=381,["309"]=382,["310"]=384,["311"]=389,["312"]=390,["313"]=391,["314"]=392,["315"]=393,["316-318"]=394,["319-323"]=397,["324-334"]=407}, "programs")
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
    local isFirstLayer = true
    local digging = true
    while digging do
        epEnsureFuelAndSpace(movement)
        local blocked = false
        if not digLayer(movement, xSpan, zSpan, y) then
            blocked = true
        end
        if not blocked and hasStaircase and not isFirstLayer then
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
        isFirstLayer = false
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
            turtle.transferTo(TORCH_SLOT, 64)
            handled = true
        end
        return handled
    end)
end


main({...})
