-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-26"]=1,["27"]=70,["28"]=71,["29-30"]=72,["31"]=75,["32"]=76,["33"]=77,["34"]=78,["35"]=79,["36-37"]=80,["38"]=83,["39"]=84,["40"]=85,["41"]=86,["42-43"]=87,["44"]=89,["45"]=91,["46"]=92,["47"]=93,["48"]=94,["49"]=95,["50"]=97,["51"]=98,["52"]=99,["53"]=100,["54"]=101,["55"]=102,["56"]=104,["57"]=106,["58"]=107,["59"]=108,["60"]=109,["61"]=110,["62"]=111,["63"]=112,["64"]=114,["65"]=115,["66"]=116,["67"]=118,["68"]=119,["69"]=120,["70"]=121,["71"]=122,["72"]=123,["73"]=125,["74"]=126,["75"]=127,["76"]=128,["77"]=129,["78"]=130,["79-80"]=131,["81"]=133,["82"]=134,["83"]=135,["84-85"]=136,["86"]=139,["87"]=140,["88"]=141,["89-90"]=142,["91"]=145,["92-93"]=146,["94"]=148,["95"]=149,["96"]=150,["97"]=151,["98-101"]=152,["102"]=157,["103"]=158,["104"]=159,["105-144"]=160,["145-152"]=173,["153"]=177,["154"]=178,["155"]=179,["156-157"]=180,["158"]=182,["159"]=183,["160-161"]=184,["162"]=186,["163"]=187,["164-165"]=188,["166"]=190,["167-177"]=191,["178"]=197,["179"]=198,["180"]=199,["181"]=200,["182"]=201,["183"]=202,["184"]=203,["185"]=204,["186"]=205,["187"]=206,["188-189"]=207,["190-192"]=209,["193"]=212,["194"]=213,["195"]=214,["196"]=215,["197-198"]=216,["199-201"]=218,["202"]=221,["203-209"]=222,["210"]=229,["211-212"]=230,["213"]=232,["214-215"]=233,["216"]=235,["217-218"]=236,["219-224"]=238,["225"]=242,["226"]=243,["227"]=244,["228-229"]=245,["230-234"]=247,["235"]=251,["236"]=252,["237"]=253,["238"]=254,["239"]=255,["240-242"]=256,["243-244"]=259,["245-249"]=261,["250"]=265,["251-256"]=266,["257"]=271,["258-263"]=272,["264"]=277,["265-270"]=278,["271"]=283,["272"]=284,["273"]=285,["274"]=286,["275"]=288,["276"]=289,["277"]=291,["278"]=294,["279"]=295,["280"]=296,["281"]=297,["282-283"]=298,["284-289"]=300,["290"]=307,["291"]=308,["292"]=309,["293"]=310,["294-298"]=311,["299"]=318,["300"]=319,["301"]=321,["302"]=322,["303"]=323,["304"]=324,["305"]=325,["306"]=326,["307"]=327,["308"]=328,["309"]=329,["310"]=330,["311"]=331,["312"]=332,["313-314"]=333,["315"]=335,["316-320"]=336,["321-322"]=341,["323"]=344,["324-329"]=345,["330"]=352,["331-335"]=353,["336"]=360,["337"]=361,["338"]=362,["339"]=363,["340"]=364,["341"]=365,["342"]=366,["343-344"]=367,["345"]=369,["346"]=370,["347"]=371,["348-349"]=372,["350"]=375,["351-352"]=376,["353"]=377,["354"]=378,["355-356"]=379,["357"]=381,["358-361"]=382,["362-363"]=385,["364"]=387,["365-367"]=388}, "programs")
ktox_require("lib/Span")
ktox_require("lib/Movement")
ktox_require("lib/Position")

EP_OVERFLOW_SIDE = 1

EP_FUEL_SAFETY_MARGIN = 20

EP_MAX_OVERFLOW_CHESTS = 20

TORCH_INTERVAL = 6

STAIRS_SLOT = 2

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
    local xStep = stepFor(xSpan)
    local zStep = stepFor(zSpan)
    local hasStaircase = width >= 2 and length >= 2
    local y = movement.homeY
    local step = 0
    local levelsSinceTorch = 0
    local hasPendingSkip = false
    local pendingSkipX = 0
    local pendingSkipZ = 0
    local digging = true
    while digging do
        epEnsureFuelAndSpace(movement)
        digLayer(movement, xSpan, zSpan, y, pendingSkipX, pendingSkipZ, hasPendingSkip)
        hasPendingSkip = false
        if hasStaircase then
            local cell = perimeterCell(step, width, length)
            local cellX = xSpan.start + cell.dx * xStep
            local cellZ = zSpan.start + cell.dz * zStep
            navigateTo(movement, cellX, y, cellZ)
            levelsSinceTorch = ktox_plusAssign(levelsSinceTorch, 1)
            if levelsSinceTorch >= TORCH_INTERVAL then
                ensureTorchSupply(movement)
                turtle.digDown()
                turtle.select(TORCH_SLOT)
                turtle.placeDown()
                levelsSinceTorch = 0
            else
                ensureStairSupply(movement)
                turtle.digDown()
                turtle.select(STAIRS_SLOT)
                turtle.placeDown()
            end
            pendingSkipX = cellX
            pendingSkipZ = cellZ
            hasPendingSkip = true
            step = ktox_plusAssign(step, 1)
        end
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
---@param skipX number
---@param skipZ number
---@param hasSkip boolean
function digLayer(m, xSpan, zSpan, y, skipX, skipZ, hasSkip)
    local xStep = stepFor(xSpan)
    local zStep = stepFor(zSpan)
    local x = xSpan.start
    local forwardZ = true
    while not pastEnd(x, xSpan.finish, xStep) do
        if forwardZ then
            local z = zSpan.start
            while not pastEnd(z, zSpan.finish, zStep) do
                if not (hasSkip and x == skipX and z == skipZ) then
                    epEnsureFuelAndSpace(m)
                    navigateTo(m, x, y, z)
                end
                z = ktox_plusAssign(z, zStep)
            end
        else
            local z = zSpan.finish
            while not pastEnd(z, zSpan.start, -zStep) do
                if not (hasSkip and x == skipX and z == skipZ) then
                    epEnsureFuelAndSpace(m)
                    navigateTo(m, x, y, z)
                end
                z = ktox_minusAssign(z, zStep)
            end
        end
        forwardZ = not forwardZ
        x = ktox_plusAssign(x, xStep)
    end
end

---@param slot number
---@return boolean
function isReservedSlot(slot)
    if slot == STAIRS_SLOT then
        return true
    end
    if slot == TORCH_SLOT then
        return true
    end
    if slot == INTAKE_SLOT then
        return true
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
    return epInventoryFull()
end

---@return boolean
function epInventoryFull()
    local slot = 1
    local full = true
    while slot <= 16 do
        if not isReservedSlot(slot) then
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
function ensureStairSupply(m)
    if turtle.getItemCount(STAIRS_SLOT) == 0 then
        epServiceAtBase(m)
    end
end

---@param m Movement
function ensureTorchSupply(m)
    if turtle.getItemCount(TORCH_SLOT) == 0 then
        epServiceAtBase(m)
    end
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
        if not isReservedSlot(slot) then
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

---@param name string
---@return boolean
function isStairsItem(name)
    local parts = ktox_split(name, "_")
    return parts[#(parts)] == "stairs"
end

---@param m Movement
function restockAtChest(m)
    epGoToChest(m, 0)
    local attempts = 0
    local chestEmpty = false
    while attempts < RESTOCK_ATTEMPTS and not chestEmpty do
        turtle.select(INTAKE_SLOT)
        local pulled = turtle.suck(64)
        if not pulled then
            chestEmpty = true
        else
            turtle.select(INTAKE_SLOT)
            turtle.refuel(64)
            local name = ktoxGetItemName(INTAKE_SLOT)
            if name == nil then
            elseif isStairsItem(name) then
                turtle.select(INTAKE_SLOT)
                turtle.transferTo(STAIRS_SLOT, 64)
            else
                if name == "minecraft:torch" then
                    turtle.select(INTAKE_SLOT)
                    turtle.transferTo(TORCH_SLOT, 64)
                else
                    turtle.select(INTAKE_SLOT)
                    turtle.drop(64)
                end
            end
        end
        attempts = ktox_plusAssign(attempts, 1)
    end
    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m:faceHeading(m.homeHeading)
end


main({...})
