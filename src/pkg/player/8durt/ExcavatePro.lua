-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-21"]=1,["22"]=77,["23"]=78,["24-25"]=79,["26"]=82,["27"]=83,["28"]=84,["29"]=85,["30"]=87,["31"]=88,["32"]=89,["33-34"]=90,["35-36"]=92,["37"]=97,["38"]=99,["39"]=100,["40"]=101,["41"]=102,["42"]=103,["43"]=105,["44"]=106,["45"]=107,["46"]=108,["47"]=129,["48"]=130,["49"]=131,["50"]=132,["51"]=134,["52"]=136,["53"]=137,["54"]=138,["55"]=139,["56"]=141,["57"]=142,["58"]=143,["59"]=144,["60-61"]=145,["62"]=157,["63"]=158,["64"]=168,["65"]=169,["66"]=170,["67-68"]=171,["69"]=181,["70"]=182,["71-72"]=183,["73"]=185,["74"]=186,["75-76"]=187,["77"]=190,["78"]=191,["79"]=196,["80"]=197,["81"]=198,["82"]=199,["83-84"]=200,["85"]=202,["86"]=203,["87"]=204,["88-89"]=205,["90-91"]=207,["92-94"]=209,["95"]=213,["96"]=219,["97-98"]=220,["99-100"]=222,["101"]=224,["102"]=225,["103"]=226,["104"]=227,["105-108"]=228,["109"]=233,["110"]=234,["111-112"]=235,["113"]=240,["114"]=241,["115"]=242,["116-126"]=243,["127"]=259,["128-129"]=260,["130"]=262,["131"]=263,["132"]=264,["133"]=265,["134-135"]=266,["136"]=268,["137-138"]=269,["139-178"]=271,["179-186"]=284,["187"]=288,["188"]=289,["189"]=290,["190-191"]=291,["192"]=293,["193"]=294,["194-195"]=295,["196"]=297,["197"]=298,["198-199"]=299,["200"]=301,["201-211"]=302,["212"]=311,["213"]=312,["214"]=313,["215"]=314,["216"]=315,["217"]=316,["218"]=317,["219"]=318,["220"]=319,["221"]=320,["222"]=321,["223-224"]=322,["225-227"]=324,["228"]=327,["229"]=328,["230"]=329,["231"]=330,["232-233"]=331,["234-236"]=333,["237"]=336,["238-239"]=337,["240-245"]=339,["246-251"]=345,["252"]=359,["253"]=360,["254"]=361,["255"]=362,["256"]=363,["257-258"]=364,["259-260"]=366,["261-266"]=368,["267"]=383,["268-269"]=384,["270"]=386,["271"]=387,["272-273"]=388,["274"]=390,["275-276"]=391,["277"]=393,["278-279"]=394,["280-285"]=396,["286"]=400,["287"]=401,["288"]=402,["289-290"]=403,["291-299"]=405,["300"]=409,["301-308"]=410,["309"]=415,["310"]=416,["311"]=417,["312-317"]=418,["318"]=427,["319"]=428,["320"]=429,["321"]=430,["322"]=431,["323"]=432,["324-326"]=433,["327-328"]=436,["329-335"]=438,["336"]=442,["337"]=443,["338"]=444,["339"]=445,["340"]=452,["341"]=453,["342-344"]=455,["345"]=456,["346"]=458,["347"]=459,["348"]=460,["349"]=465,["350"]=466,["351"]=467,["352"]=468,["353"]=469,["354-356"]=470,["357-361"]=473,["362-371"]=483}, "programs")
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
    local halfWidth = (width - width % 2) / 2
    local halfLength = (length - length % 2) / 2
    local centerX = movement.homeX + rgtDx * halfWidth + fwdDx * halfLength
    local centerZ = movement.homeZ + rgtDz * halfWidth + fwdDz * halfLength
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
