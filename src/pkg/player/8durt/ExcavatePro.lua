-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-19"]=1,["20"]=73,["21"]=74,["22-23"]=75,["24"]=78,["25"]=79,["26"]=80,["27"]=81,["28"]=82,["29-30"]=83,["31"]=86,["32"]=87,["33"]=88,["34-35"]=89,["36-37"]=91,["38"]=94,["39"]=95,["40"]=96,["41"]=97,["42"]=98,["43"]=100,["44"]=101,["45"]=102,["46"]=103,["47"]=111,["48"]=112,["49"]=114,["50"]=116,["51"]=117,["52"]=118,["53"]=119,["54"]=120,["55"]=122,["56"]=123,["57"]=124,["58"]=125,["59-60"]=126,["61"]=130,["62"]=131,["63"]=141,["64"]=142,["65"]=143,["66-67"]=144,["68"]=146,["69"]=147,["70"]=148,["71"]=149,["72"]=150,["73"]=151,["74-75"]=152,["76"]=154,["77"]=155,["78-79"]=156,["80"]=158,["81"]=159,["82-84"]=160,["85-87"]=163,["88"]=166,["89"]=168,["90"]=174,["91-92"]=175,["93-94"]=177,["95"]=179,["96"]=180,["97"]=181,["98"]=182,["99-102"]=183,["103"]=188,["104"]=189,["105-106"]=190,["107"]=195,["108"]=196,["109"]=197,["110-120"]=198,["121"]=214,["122-123"]=215,["124"]=217,["125"]=218,["126"]=219,["127"]=220,["128-129"]=221,["130"]=223,["131-132"]=224,["133-172"]=226,["173-180"]=239,["181"]=243,["182"]=244,["183"]=245,["184-185"]=246,["186"]=248,["187"]=249,["188-189"]=250,["190"]=252,["191"]=253,["192-193"]=254,["194"]=256,["195-203"]=257,["204"]=266,["205"]=267,["206"]=268,["207"]=269,["208"]=270,["209"]=271,["210"]=272,["211"]=273,["212"]=274,["213"]=275,["214"]=276,["215-216"]=277,["217-219"]=279,["220"]=282,["221"]=283,["222"]=284,["223"]=285,["224-225"]=286,["226-228"]=288,["229"]=291,["230-231"]=292,["232-237"]=294,["238-243"]=300,["244"]=316,["245-246"]=317,["247"]=319,["248"]=320,["249-250"]=321,["251"]=323,["252-253"]=324,["254-259"]=326,["260"]=330,["261"]=331,["262"]=332,["263-264"]=333,["265-271"]=335,["272"]=339,["273-278"]=340,["279"]=345,["280"]=346,["281"]=347,["282-287"]=348,["288"]=357,["289"]=358,["290"]=359,["291"]=360,["292"]=361,["293"]=362,["294-296"]=363,["297-298"]=366,["299-303"]=368,["304"]=372,["305"]=373,["306"]=374,["307"]=375,["308-310"]=377,["311"]=378,["312"]=380,["313"]=385,["314"]=386,["315"]=387,["316"]=388,["317"]=389,["318-320"]=390,["321-325"]=393,["326-336"]=403}, "programs")
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
        elseif hasYTarget and y <= yTarget then
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
