-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "DiamondFinder.kt", {["1-11"]=1,["12"]=69,["13-14"]=70,["15"]=72,["16-17"]=73,["18"]=75,["19-20"]=76,["21"]=78,["22-23"]=79,["24"]=81,["25-26"]=82,["27"]=84,["28-29"]=85,["30"]=87,["31-32"]=88,["33"]=90,["34-35"]=91,["36"]=93,["37-38"]=94,["39"]=96,["40-41"]=97,["42"]=99,["43-44"]=100,["45"]=102,["46-47"]=103,["48"]=105,["49-50"]=106,["51"]=108,["52-53"]=109,["54-66"]=111,["67"]=120,["68"]=121,["69-70"]=122,["71"]=125,["72"]=126,["73"]=127,["74"]=129,["75"]=130,["76"]=131,["77"]=132,["78-79"]=133,["80"]=135,["81"]=137,["82"]=138,["83"]=139,["84"]=140,["85"]=141,["86"]=143,["87"]=144,["88"]=145,["89"]=146,["90"]=147,["91"]=149,["92"]=150,["93"]=151,["94"]=152,["95"]=153,["96"]=154,["97"]=155,["98"]=156,["99"]=157,["100-101"]=158,["102-103"]=161,["104"]=164,["105"]=165,["106-107"]=166,["108"]=168,["109-115"]=169,["116"]=174,["117-118"]=175,["119-124"]=177,["125"]=183,["126"]=184,["127"]=185,["128"]=186,["129"]=187,["130"]=188,["131-132"]=189,["133"]=191,["134-141"]=192,["142"]=210,["143-144"]=211,["145"]=213,["146"]=215,["147"]=216,["148"]=217,["149"]=218,["150-152"]=219,["153"]=223,["154"]=224,["155"]=225,["156"]=226,["157-159"]=227,["160"]=231,["161"]=232,["162"]=233,["163"]=234,["164"]=235,["165-167"]=236,["168"]=239,["169"]=241,["170"]=242,["171"]=243,["172"]=244,["173"]=245,["174-176"]=246,["177"]=249,["178"]=251,["179"]=252,["180"]=253,["181"]=254,["182-189"]=255,["190"]=266,["191-192"]=267,["193"]=269,["194"]=270,["195"]=271,["196"]=272,["197-198"]=273,["199"]=275,["200-201"]=276,["202-207"]=278,["208-212"]=284,["213"]=288,["214"]=289,["215"]=290,["216"]=291,["217-220"]=292,["221"]=294,["222"]=295,["223"]=296,["224"]=297,["225"]=298,["226-228"]=300,["229-231"]=301,["232"]=303,["233"]=305,["234"]=306,["235"]=307,["236"]=308,["237-238"]=309,["239-242"]=311}, "programs")
ktox_require("lib/Chest")
ktox_require("lib/Movement")
ktox_require("lib/Position")

---@param name string
---@return boolean
function isValuableOre(name)
    if name == "minecraft:diamond_ore" then
        return true
    end
    if name == "minecraft:deepslate_diamond_ore" then
        return true
    end
    if name == "minecraft:redstone_ore" then
        return true
    end
    if name == "minecraft:deepslate_redstone_ore" then
        return true
    end
    if name == "minecraft:gold_ore" then
        return true
    end
    if name == "minecraft:deepslate_gold_ore" then
        return true
    end
    if name == "minecraft:iron_ore" then
        return true
    end
    if name == "minecraft:deepslate_iron_ore" then
        return true
    end
    if name == "minecraft:copper_ore" then
        return true
    end
    if name == "minecraft:deepslate_copper_ore" then
        return true
    end
    if name == "minecraft:lapis_ore" then
        return true
    end
    if name == "minecraft:deepslate_lapis_ore" then
        return true
    end
    if name == "minecraft:emerald_ore" then
        return true
    end
    if name == "minecraft:deepslate_emerald_ore" then
        return true
    end
    return false
end

DF_FUEL_SAFETY_MARGIN = 20

DF_RESTOCK_ATTEMPTS = 16

MAX_VEIN_DEPTH = 24

MAX_RETURN_ASCENTS = 32

---@param args table
function main(args)
    if #(args) < 2 then
        println("Usage: diamondfinder <branchLength> <branchCount> (<spacing>)")
        return
    end
    local branchLength = ktox_toInt(args[1])
    local branchCount = ktox_toInt(args[2])
    local spacing = (#(args) >= 3 and ktox_toInt(args[3]) or 3)
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
    local tierIndex = 1
    while tierIndex <= 2 do
        local tierY = tierY(tierIndex)
        println("Moving to tier " .. tostring(tierIndex) .. " (y=" .. tostring(tierY) .. ")...")
        navigateTo(movement, movement.homeX, tierY, movement.homeZ)
        local branch = 0
        while branch < branchCount do
            local lateralOffset = branch * (spacing + 1)
            local startX = movement.homeX + rgtDx * lateralOffset
            local startZ = movement.homeZ + rgtDz * lateralOffset
            dfEnsureFuelAndSpace(movement)
            navigateTo(movement, startX, tierY, startZ)
            movement:faceHeading(movement.homeHeading)
            boreBranch(movement, branchLength)
            branch = ktox_plusAssign(branch, 1)
        end
        tierIndex = ktox_plusAssign(tierIndex, 1)
    end
    println("Diamond survey complete. Returning home...")
    if not returnHomeWithRecovery(movement) then
        println("Could not fully reach home - staying put.")
    else
        movement:faceHeading(movement.homeHeading)
        println("Home.")
    end
end

---@param tierIndex number
---@return number
function tierY(tierIndex)
    if tierIndex == 1 then
        return -56
    end
    return -59
end

---@param m Movement
---@param length number
function boreBranch(m, length)
    local i = 0
    local blocked = false
    while i < length and not blocked do
        dfEnsureFuelAndSpace(m)
        if not m:forward() then
            println("Blocked while boring at x=" .. tostring(m.x) .. " y=" .. tostring(m.y) .. " z=" .. tostring(m.z) .. " - stopping this branch.")
            blocked = true
        else
            followVein(m, 0)
            i = ktox_plusAssign(i, 1)
        end
    end
end

---@param m Movement
---@param depth number
function followVein(m, depth)
    if depth >= MAX_VEIN_DEPTH then
        return
    end
    dfEnsureFuelAndSpace(m)
    local upName = ktoxInspectUpName()
    if upName ~= nil and isValuableOre(upName) then
        if m:up() then
            followVein(m, depth + 1)
            m:down()
        end
    end
    local downName = ktoxInspectDownName()
    if downName ~= nil and isValuableOre(downName) then
        if m:down() then
            followVein(m, depth + 1)
            m:up()
        end
    end
    m:turnLeft()
    local leftName = ktoxInspectName()
    if leftName ~= nil and isValuableOre(leftName) then
        if m:forward() then
            followVein(m, depth + 1)
            m:back()
        end
    end
    m:turnRight()
    m:turnRight()
    local rightName = ktoxInspectName()
    if rightName ~= nil and isValuableOre(rightName) then
        if m:forward() then
            followVein(m, depth + 1)
            m:back()
        end
    end
    m:turnLeft()
    local fwdName = ktoxInspectName()
    if fwdName ~= nil and isValuableOre(fwdName) then
        if m:forward() then
            followVein(m, depth + 1)
            m:back()
        end
    end
end

---@param m Movement
---@return boolean
function returnHomeWithRecovery(m)
    if navigateTo(m, m.homeX, m.homeY, m.homeZ) then
        return true
    end
    local attempts = 0
    local reached = false
    while not reached and attempts < MAX_RETURN_ASCENTS do
        if not m:up() then
            return false
        end
        reached = navigateTo(m, m.homeX, m.homeY, m.homeZ)
        attempts = ktox_plusAssign(attempts, 1)
    end
    return reached
end

---@param slot number
---@return boolean
function dfKeepSlot(slot)
    return slot == CHEST_INTAKE_SLOT
end

---@param m Movement
function dfEnsureFuelAndSpace(m)
    local fuel = turtle.getFuelLevel()
    local distance = m:distanceHome()
    local needsService = fuel < distance + DF_FUEL_SAFETY_MARGIN
    if not needsService then
        needsService = cargoFull(function(slot)
            return dfKeepSlot(slot)
        end)
    end
    if needsService then
        println("Returning to base to refuel/dump inventory...")
        local returnX = m.x
        local returnY = m.y
        local returnZ = m.z
        dumpCargo(m, function(slot)
            return dfKeepSlot(slot)
        end)
        restockChest(m, DF_RESTOCK_ATTEMPTS, function(name)
            return false
        end)
        navigateTo(m, returnX, returnY, returnZ)
        local checked = gpsLocate()
        if checked ~= nil then
            m.x = checked.x
            m.y = checked.y
            m.z = checked.z
        end
        println("Resuming.")
    end
end


main({...})
