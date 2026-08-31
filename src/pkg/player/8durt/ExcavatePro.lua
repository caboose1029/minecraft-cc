-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-24"]=1,["25"]=77,["26"]=78,["27-28"]=79,["29"]=82,["30"]=83,["31"]=84,["32"]=85,["33"]=86,["34-35"]=87,["36"]=90,["37"]=91,["38"]=92,["39"]=93,["40-41"]=94,["42"]=96,["43"]=98,["44"]=99,["45"]=100,["46"]=101,["47"]=102,["48"]=104,["49"]=105,["50"]=106,["51"]=107,["52"]=109,["53"]=111,["54"]=112,["55"]=113,["56"]=114,["57"]=115,["58"]=117,["59"]=118,["60"]=119,["61"]=122,["62"]=123,["63"]=133,["64"]=134,["65"]=135,["66"]=137,["67"]=138,["68"]=139,["69"]=140,["70"]=141,["71"]=142,["72-73"]=143,["74"]=145,["75"]=146,["76-77"]=147,["78"]=149,["79"]=150,["80-82"]=151,["83-84"]=155,["85"]=157,["86"]=159,["87-88"]=160,["89"]=162,["90"]=163,["91"]=164,["92"]=165,["93-96"]=166,["97"]=171,["98"]=172,["99"]=173,["100-139"]=174,["140-147"]=187,["148"]=191,["149"]=192,["150"]=193,["151-152"]=194,["153"]=196,["154"]=197,["155-156"]=198,["157"]=200,["158"]=201,["159-160"]=202,["161"]=204,["162-169"]=205,["170"]=211,["171"]=212,["172"]=213,["173"]=214,["174"]=215,["175"]=216,["176"]=217,["177"]=218,["178"]=219,["179"]=220,["180-182"]=221,["183"]=224,["184"]=225,["185"]=226,["186"]=227,["187-189"]=228,["190"]=231,["191-197"]=232,["198-203"]=239,["204"]=258,["205-206"]=259,["207"]=261,["208-209"]=262,["210"]=264,["211-212"]=265,["213"]=267,["214-215"]=268,["216"]=270,["217-218"]=271,["219-224"]=273,["225-230"]=277,["231"]=293,["232-233"]=294,["234"]=296,["235"]=297,["236-237"]=298,["238"]=300,["239-240"]=301,["241-246"]=303,["247"]=307,["248"]=308,["249"]=309,["250-251"]=310,["252-256"]=312,["257"]=316,["258"]=317,["259"]=318,["260"]=319,["261"]=320,["262-264"]=321,["265-266"]=324,["267-271"]=326,["272"]=330,["273-278"]=331,["279"]=336,["280"]=337,["281"]=338,["282-287"]=339,["288"]=348,["289"]=349,["290"]=350,["291"]=351,["292"]=352,["293"]=353,["294-296"]=354,["297-298"]=357,["299-303"]=359,["304"]=363,["305"]=364,["306"]=365,["307"]=366,["308"]=368,["309"]=369,["310"]=371,["311"]=374,["312"]=375,["313"]=376,["314"]=377,["315-316"]=378,["317-322"]=380,["323"]=387,["324"]=388,["325"]=389,["326"]=390,["327-331"]=391,["332"]=397,["333"]=398,["334"]=400,["335"]=401,["336"]=402,["337"]=403,["338"]=404,["339"]=405,["340"]=406,["341"]=407,["342"]=408,["343"]=409,["344"]=410,["345"]=411,["346-347"]=412,["348"]=414,["349-353"]=415,["354-355"]=420,["356"]=423,["357-361"]=424,["362"]=441,["363"]=442,["364"]=443,["365"]=444,["366"]=445,["367"]=446,["368"]=447,["369"]=448,["370-371"]=449,["372"]=451,["373"]=452,["374"]=453,["375"]=454,["376"]=455,["377"]=456,["378"]=457,["379"]=458,["380-382"]=459,["383"]=462,["384"]=463,["385-387"]=464,["388"]=467,["389"]=468,["390"]=469,["391"]=470,["392-394"]=471,["395-396"]=474,["397"]=476,["398-400"]=477}, "programs")
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

---@param name string
---@return number
function fuelValue(name)
    if name == "minecraft:charcoal" then
        return 80
    end
    if name == "minecraft:coal" then
        return 80
    end
    if name == "minecraft:coal_block" then
        return 800
    end
    if name == "minecraft:lava_bucket" then
        return 1000
    end
    if name == "minecraft:dried_kelp_block" then
        return 4000
    end
    return 0
end

---@param name string
---@return boolean
function isAllowedFuel(name)
    return fuelValue(name) > 0
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
            local name = ktoxGetItemName(INTAKE_SLOT)
            local handled = false
            if name ~= nil then
                if isAllowedFuel(name) then
                    local headroom = turtle.getFuelLimit() - turtle.getFuelLevel()
                    if headroom >= fuelValue(name) then
                        turtle.select(INTAKE_SLOT)
                        turtle.refuel(64)
                        handled = true
                    end
                elseif isTorchItem(name) then
                    turtle.select(INTAKE_SLOT)
                    turtle.transferTo(TORCH_SLOT, 64)
                    handled = true
                end
            end
            if not handled then
                turtle.select(INTAKE_SLOT)
                turtle.drop(64)
                stuck = true
                println("Chest\'s next item isn\'t usable right now (unrecognized, or would waste a high-value fuel item near the cap) - stopping restock early.")
            end
        end
        attempts = ktox_plusAssign(attempts, 1)
    end
    navigateTo(m, m.homeX, m.homeY, m.homeZ)
    m:faceHeading(m.homeHeading)
end


main({...})
