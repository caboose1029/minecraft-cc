-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-24"]=1,["25"]=77,["26"]=78,["27-28"]=79,["29"]=82,["30"]=83,["31"]=84,["32"]=85,["33"]=86,["34-35"]=87,["36"]=90,["37"]=91,["38"]=92,["39"]=93,["40-41"]=94,["42"]=96,["43"]=98,["44"]=99,["45"]=100,["46"]=101,["47"]=102,["48"]=104,["49"]=105,["50"]=106,["51"]=107,["52"]=109,["53"]=111,["54"]=112,["55"]=113,["56"]=114,["57"]=115,["58"]=117,["59"]=118,["60"]=119,["61"]=122,["62"]=123,["63"]=133,["64"]=134,["65"]=135,["66"]=137,["67"]=138,["68"]=139,["69"]=140,["70"]=141,["71"]=142,["72-73"]=143,["74"]=145,["75"]=146,["76-77"]=147,["78"]=149,["79"]=150,["80-82"]=151,["83-84"]=155,["85"]=157,["86"]=159,["87-88"]=160,["89"]=162,["90"]=163,["91"]=164,["92"]=165,["93-96"]=166,["97"]=171,["98"]=172,["99"]=173,["100-139"]=174,["140-147"]=187,["148"]=191,["149"]=192,["150"]=193,["151-152"]=194,["153"]=196,["154"]=197,["155-156"]=198,["157"]=200,["158"]=201,["159-160"]=202,["161"]=204,["162-169"]=205,["170"]=211,["171"]=212,["172"]=213,["173"]=214,["174"]=215,["175"]=216,["176"]=217,["177"]=218,["178"]=219,["179"]=220,["180-182"]=221,["183"]=224,["184"]=225,["185"]=226,["186"]=227,["187-189"]=228,["190"]=231,["191-197"]=232,["198-203"]=239,["204"]=255,["205-206"]=256,["207"]=258,["208"]=259,["209-210"]=260,["211"]=262,["212-213"]=263,["214-219"]=265,["220"]=269,["221"]=270,["222"]=271,["223-224"]=272,["225-229"]=274,["230"]=278,["231"]=279,["232"]=280,["233"]=281,["234"]=282,["235-237"]=283,["238-239"]=286,["240-244"]=288,["245"]=292,["246-251"]=293,["252"]=298,["253"]=299,["254"]=300,["255-260"]=301,["261"]=310,["262"]=311,["263"]=312,["264"]=313,["265"]=314,["266"]=315,["267-269"]=316,["270-271"]=319,["272-276"]=321,["277"]=325,["278"]=326,["279"]=327,["280"]=328,["281"]=330,["282"]=331,["283"]=333,["284"]=336,["285"]=337,["286"]=338,["287"]=339,["288-289"]=340,["290-295"]=342,["296"]=349,["297"]=350,["298"]=351,["299"]=352,["300-304"]=353,["305"]=359,["306"]=360,["307"]=362,["308"]=363,["309"]=364,["310"]=365,["311"]=366,["312"]=367,["313"]=368,["314"]=369,["315"]=370,["316"]=371,["317"]=372,["318"]=373,["319-320"]=374,["321"]=376,["322-326"]=377,["327-328"]=382,["329"]=385,["330-334"]=386,["335"]=403,["336"]=404,["337"]=405,["338"]=406,["339"]=407,["340"]=408,["341"]=409,["342"]=410,["343-344"]=411,["345"]=413,["346"]=414,["347-348"]=415,["349"]=417,["350-351"]=418,["352"]=421,["353-354"]=422,["355"]=424,["356"]=425,["357"]=426,["358-360"]=427,["361-362"]=430,["363"]=432,["364-366"]=433}, "programs")
ktox_require("lib/Span")
ktox_require("lib/Movement")
ktox_require("lib/Position")

EP_OVERFLOW_SIDE = 1

EP_FUEL_SAFETY_MARGIN = 20

EP_MAX_OVERFLOW_CHESTS = 20

TORCH_INTERVAL = 6

TORCH_SLOT = 3

INTAKE_SLOT = 16

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
    if slot == INTAKE_SLOT then
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
    return epInventoryFull()
end

---@return boolean
function epInventoryFull()
    local slot = 1
    local full = true
    while slot <= 16 do
        if not shouldKeepSlot(slot) then
            if turtle.getItemCount(slot) == 0 then
                full = false
            end
        end
        slot = ktox_plusAssign(slot, 1)
    end
    return full
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
    epDumpInventoryAtBase(m)
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
---@param n number
function epGoToChest(m, n)
    local sideways = (m.homeHeading + EP_OVERFLOW_SIDE + 4) % 4
    local targetX = m.homeX + headingDx(sideways) * n
    local targetZ = m.homeZ + headingDz(sideways) * n
    navigateTo(m, targetX, m.homeY, targetZ)
    m:faceHeading((m.homeHeading + 2) % 4)
end

---@param m Movement
function epDumpInventoryAtBase(m)
    local chestIndex = 1
    epGoToChest(m, chestIndex)
    local slot = 1
    local giveUp = false
    while slot <= 16 and not giveUp do
        if not shouldKeepSlot(slot) then
            local count = turtle.getItemCount(slot)
            if count > 0 then
                turtle.select(slot)
                local dropped = turtle.drop(64)
                while not dropped and not giveUp do
                    chestIndex = ktox_plusAssign(chestIndex, 1)
                    if chestIndex > EP_MAX_OVERFLOW_CHESTS then
                        println("All overflow chests full, stopping dump early.")
                        giveUp = true
                    else
                        epGoToChest(m, chestIndex)
                        dropped = turtle.drop(64)
                    end
                end
            end
        end
        slot = ktox_plusAssign(slot, 1)
    end
    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m:faceHeading(m.homeHeading)
end

---@param m Movement
function restockAtChest(m)
    epGoToChest(m, 0)
    local attempts = 0
    local chestEmpty = false
    local stuck = false
    while attempts < RESTOCK_ATTEMPTS and not chestEmpty and not stuck do
        turtle.select(INTAKE_SLOT)
        local pulled = turtle.suck(64)
        if not pulled then
            chestEmpty = true
        else
            turtle.select(INTAKE_SLOT)
            if turtle.getFuelLevel() < turtle.getFuelLimit() then
                turtle.refuel(64)
            end
            local name = ktoxGetItemName(INTAKE_SLOT)
            if name == nil then
            elseif isTorchItem(name) then
                turtle.select(INTAKE_SLOT)
                turtle.transferTo(TORCH_SLOT, 64)
            else
                turtle.select(INTAKE_SLOT)
                turtle.drop(64)
                stuck = true
                println("Chest\'s next item isn\'t usable right now (fuel topped off?) and torches may be stuck behind it - stopping restock early.")
            end
        end
        attempts = ktox_plusAssign(attempts, 1)
    end
    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m:faceHeading(m.homeHeading)
end


main({...})
