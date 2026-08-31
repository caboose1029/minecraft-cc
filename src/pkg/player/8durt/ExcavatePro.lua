-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "ExcavatePro.kt", {["1-43"]=1,["44-51"]=54,["52"]=61,["53-54"]=62,["55-60"]=64,["61-66"]=68,["67-74"]=78,["75"]=90,["76-77"]=91,["78"]=93,["79-80"]=94,["81"]=96,["82"]=97,["83"]=98,["84"]=99,["85-87"]=100,["88"]=103,["89"]=104,["90"]=105,["91"]=106,["92-114"]=107,["115"]=125,["116"]=126,["117-118"]=127,["119"]=130,["120"]=131,["121"]=132,["122"]=133,["123"]=134,["124-125"]=135,["126"]=138,["127"]=139,["128"]=140,["129"]=141,["130-131"]=142,["132"]=144,["133"]=146,["134"]=147,["135"]=148,["136"]=149,["137"]=150,["138"]=152,["139"]=153,["140"]=154,["141"]=155,["142"]=156,["143"]=157,["144"]=159,["145"]=161,["146"]=162,["147"]=163,["148"]=164,["149"]=165,["150"]=166,["151"]=167,["152"]=169,["153"]=170,["154"]=171,["155"]=173,["156"]=174,["157"]=175,["158"]=176,["159"]=177,["160"]=178,["161"]=180,["162"]=181,["163"]=182,["164"]=183,["165"]=184,["166"]=185,["167-168"]=186,["169"]=188,["170"]=189,["171"]=190,["172-173"]=191,["174"]=194,["175"]=195,["176"]=196,["177-178"]=197,["179"]=200,["180-181"]=201,["182"]=203,["183"]=204,["184"]=205,["185"]=206,["186-189"]=207,["190"]=212,["191"]=213,["192"]=214,["193-232"]=215,["233-240"]=228,["241"]=232,["242"]=233,["243"]=234,["244-245"]=235,["246"]=237,["247"]=238,["248-249"]=239,["250"]=241,["251"]=242,["252-253"]=243,["254"]=245,["255-265"]=246,["266"]=252,["267"]=253,["268"]=254,["269"]=255,["270"]=256,["271"]=257,["272"]=258,["273"]=259,["274"]=260,["275"]=261,["276-277"]=262,["278-280"]=264,["281"]=267,["282"]=268,["283"]=269,["284"]=270,["285-286"]=271,["287-289"]=273,["290"]=276,["291-297"]=277,["298"]=284,["299-300"]=285,["301"]=287,["302-303"]=288,["304"]=290,["305-306"]=291,["307-312"]=293,["313"]=297,["314"]=298,["315"]=299,["316-317"]=300,["318-322"]=302,["323"]=306,["324"]=307,["325"]=308,["326"]=309,["327"]=310,["328-330"]=311,["331-332"]=314,["333-337"]=316,["338"]=320,["339-344"]=321,["345"]=326,["346-351"]=327,["352"]=332,["353-358"]=333,["359"]=338,["360"]=339,["361"]=340,["362"]=341,["363"]=343,["364"]=344,["365"]=346,["366"]=349,["367"]=350,["368"]=351,["369"]=352,["370-371"]=353,["372-377"]=355,["378"]=362,["379"]=363,["380"]=364,["381"]=365,["382-386"]=366,["387"]=373,["388"]=374,["389"]=376,["390"]=377,["391"]=378,["392"]=379,["393"]=380,["394"]=381,["395"]=382,["396"]=383,["397"]=384,["398"]=385,["399"]=386,["400"]=387,["401-402"]=388,["403"]=390,["404-408"]=391,["409-410"]=396,["411"]=399,["412-417"]=400,["418"]=407,["419-423"]=408,["424"]=415,["425"]=416,["426"]=417,["427"]=418,["428"]=419,["429"]=420,["430"]=421,["431-432"]=422,["433"]=424,["434"]=425,["435"]=426,["436-437"]=427,["438"]=430,["439-440"]=431,["441"]=432,["442"]=433,["443-444"]=434,["445"]=436,["446-449"]=437,["450-451"]=440,["452"]=442,["453-455"]=443}, "programs")
ktox_require("lib/Movement")
ktox_require("lib/Position")

---@class EpSpan
---@field start number
---@field finish number
EpSpan = {}
EpSpan.__index = EpSpan

function EpSpan:new(start, finish)
    local self = setmetatable({}, EpSpan)
    self.start = start
    self.finish = finish
    return self
end

function EpSpan:equals(other)
    return self.start == other.start and self.finish == other.finish
end
EpSpan.__eq = function(a, b) return a:equals(b) end
function EpSpan:toString()
    return "EpSpan(" .. "start=" .. tostring(self.start) .. ", " .. "finish=" .. tostring(self.finish) .. ")"
end
EpSpan.__tostring = function(a) return a:toString() end
function EpSpan:copy(start, finish)
    if start == nil then start = self.start end
    if finish == nil then finish = self.finish end
    return EpSpan:new(start, finish)
end
function EpSpan:component1()
    return self.start
end
function EpSpan:component2()
    return self.finish
end

---@param span EpSpan
---@return number
function epStepFor(span)
    return (span.start <= span.finish and 1 or -1)
end

---@param current number
---@param limit number
---@param step number
---@return boolean
function epPastEnd(current, limit, step)
    if step > 0 then
        return current > limit
    end
    return current < limit
end

---@param h number
---@return number
function epHeadingDx(h)
    return (h == 1 and 1 or (h == 3 and -1 or 0))
end

---@param h number
---@return number
function epHeadingDz(h)
    return (h == 2 and 1 or (h == 0 and -1 or 0))
end

---@param m Movement
---@param targetX number
---@param targetY number
---@param targetZ number
function epNavigateTo(m, targetX, targetY, targetZ)
    while m.y < targetY do
        m:up()
    end
    while m.y > targetY do
        m:down()
    end
    if m.x ~= targetX then
        local toward = (targetX > m.x and 1 or 3)
        m:faceHeading(toward)
        while m.x ~= targetX do
            m:forward()
        end
    end
    if m.z ~= targetZ then
        local toward = (targetZ > m.z and 2 or 0)
        m:faceHeading(toward)
        while m.z ~= targetZ do
            m:forward()
        end
    end
end

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
    local fwdDx = epHeadingDx(movement.homeHeading)
    local fwdDz = epHeadingDz(movement.homeHeading)
    local rightHeading = (movement.homeHeading + 1) % 4
    local rgtDx = epHeadingDx(rightHeading)
    local rgtDz = epHeadingDz(rightHeading)
    local xOther = movement.homeX + rgtDx * (width - 1) + fwdDx * (length - 1)
    local zOther = movement.homeZ + rgtDz * (width - 1) + fwdDz * (length - 1)
    local xSpan = EpSpan:new(movement.homeX, xOther)
    local zSpan = EpSpan:new(movement.homeZ, zOther)
    local xStep = epStepFor(xSpan)
    local zStep = epStepFor(zSpan)
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
            epNavigateTo(movement, cellX, y, cellZ)
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
    epNavigateTo(movement, movement.homeX, movement.homeY, movement.homeZ)
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
---@param xSpan EpSpan
---@param zSpan EpSpan
---@param y number
---@param skipX number
---@param skipZ number
---@param hasSkip boolean
function digLayer(m, xSpan, zSpan, y, skipX, skipZ, hasSkip)
    local xStep = epStepFor(xSpan)
    local zStep = epStepFor(zSpan)
    local x = xSpan.start
    local forwardZ = true
    while not epPastEnd(x, xSpan.finish, xStep) do
        if forwardZ then
            local z = zSpan.start
            while not epPastEnd(z, zSpan.finish, zStep) do
                if not (hasSkip and x == skipX and z == skipZ) then
                    epEnsureFuelAndSpace(m)
                    epNavigateTo(m, x, y, z)
                end
                z = ktox_plusAssign(z, zStep)
            end
        else
            local z = zSpan.finish
            while not epPastEnd(z, zSpan.start, -zStep) do
                if not (hasSkip and x == skipX and z == skipZ) then
                    epEnsureFuelAndSpace(m)
                    epNavigateTo(m, x, y, z)
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
    epNavigateTo(m, returnX, returnY, returnZ)
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
    local targetX = m.homeX + epHeadingDx(sideways) * n
    local targetZ = m.homeZ + epHeadingDz(sideways) * n
    epNavigateTo(m, targetX, m.homeY, targetZ)
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
    epNavigateTo(m, m.homeX, m.homeY, m.homeZ)
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
    epNavigateTo(m, m.homeX, m.homeY, m.homeZ)
    m:faceHeading(m.homeHeading)
end


main({...})
