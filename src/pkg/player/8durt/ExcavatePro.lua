-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-26"]=1,["27"]=75,["28"]=76,["29-30"]=77,["31"]=80,["32"]=81,["33"]=82,["34"]=83,["35"]=84,["36-37"]=85,["38"]=88,["39"]=89,["40"]=90,["41"]=91,["42-43"]=92,["44"]=94,["45"]=96,["46"]=97,["47"]=98,["48"]=99,["49"]=100,["50"]=102,["51"]=103,["52"]=104,["53"]=105,["54"]=106,["55"]=107,["56"]=109,["57"]=111,["58"]=112,["59"]=113,["60"]=114,["61"]=115,["62"]=117,["63"]=118,["64"]=119,["65"]=122,["66"]=123,["67"]=124,["68"]=125,["69"]=126,["70"]=128,["71"]=129,["72"]=130,["73"]=131,["74"]=132,["75"]=133,["76-77"]=134,["78"]=136,["79"]=137,["80"]=138,["81-82"]=139,["83-84"]=142,["85"]=144,["86"]=146,["87-88"]=147,["89"]=149,["90"]=150,["91"]=151,["92"]=152,["93-96"]=153,["97"]=158,["98"]=159,["99"]=160,["100-139"]=161,["140-147"]=174,["148"]=178,["149"]=179,["150"]=180,["151-152"]=181,["153"]=183,["154"]=184,["155-156"]=185,["157"]=187,["158"]=188,["159-160"]=189,["161"]=191,["162-169"]=192,["170"]=198,["171"]=199,["172"]=200,["173"]=201,["174"]=202,["175"]=203,["176"]=204,["177"]=205,["178"]=206,["179"]=207,["180-182"]=208,["183"]=211,["184"]=212,["185"]=213,["186"]=214,["187-189"]=215,["190"]=218,["191-197"]=219,["198"]=226,["199-200"]=227,["201"]=229,["202-203"]=230,["204"]=232,["205-206"]=233,["207-212"]=235,["213"]=239,["214"]=240,["215"]=241,["216-217"]=242,["218-222"]=244,["223"]=248,["224"]=249,["225"]=250,["226"]=251,["227"]=252,["228-230"]=253,["231-232"]=256,["233-237"]=258,["238"]=262,["239-244"]=263,["245"]=268,["246-251"]=269,["252"]=274,["253-258"]=275,["259"]=280,["260"]=281,["261"]=282,["262"]=283,["263"]=285,["264"]=286,["265"]=288,["266"]=291,["267"]=292,["268"]=293,["269"]=294,["270-271"]=295,["272-277"]=297,["278"]=304,["279"]=305,["280"]=306,["281"]=307,["282-286"]=308,["287"]=315,["288"]=316,["289"]=318,["290"]=319,["291"]=320,["292"]=321,["293"]=322,["294"]=323,["295"]=324,["296"]=325,["297"]=326,["298"]=327,["299"]=328,["300"]=329,["301-302"]=330,["303"]=332,["304-308"]=333,["309-310"]=338,["311"]=341,["312-317"]=342,["318"]=349,["319-323"]=350,["324"]=367,["325"]=368,["326"]=369,["327"]=370,["328"]=371,["329"]=372,["330"]=373,["331"]=374,["332-333"]=375,["334"]=377,["335"]=378,["336-337"]=379,["338"]=381,["339-340"]=382,["341"]=385,["342-343"]=386,["344"]=387,["345"]=388,["346-347"]=389,["348"]=391,["349"]=392,["350"]=393,["351-354"]=394,["355-356"]=397,["357"]=399,["358-360"]=400}, "programs")
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
    local isFirstLayer = true
    local digging = true
    while digging do
        epEnsureFuelAndSpace(movement)
        digLayer(movement, xSpan, zSpan, y)
        if hasStaircase and not isFirstLayer then
            local cell = perimeterCell(step, width, length)
            local cellX = xSpan.start + cell.dx * xStep
            local cellZ = zSpan.start + cell.dz * zStep
            navigateTo(movement, cellX, y, cellZ)
            levelsSinceTorch = ktox_plusAssign(levelsSinceTorch, 1)
            if levelsSinceTorch >= TORCH_INTERVAL then
                ensureTorchSupply(movement)
                turtle.digUp()
                turtle.select(TORCH_SLOT)
                turtle.placeUp()
                levelsSinceTorch = 0
            else
                ensureStairSupply(movement)
                turtle.digUp()
                turtle.select(STAIRS_SLOT)
                turtle.placeUp()
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
                    stuck = true
                    println("Chest\'s next item isn\'t usable right now (fuel topped off?) and stairs/torches may be stuck behind it - stopping restock early.")
                end
            end
        end
        attempts = ktox_plusAssign(attempts, 1)
    end
    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m:faceHeading(m.homeHeading)
end


main({...})
