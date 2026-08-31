-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "DiamondFinder.kt", {["1-11"]=1,["12"]=64,["13-14"]=65,["15"]=67,["16-17"]=68,["18"]=70,["19-20"]=71,["21"]=73,["22-23"]=74,["24"]=76,["25-26"]=77,["27"]=79,["28-29"]=80,["30"]=82,["31-32"]=83,["33"]=85,["34-35"]=86,["36"]=88,["37-38"]=89,["39"]=91,["40-41"]=92,["42"]=94,["43-44"]=95,["45"]=97,["46-47"]=98,["48"]=100,["49-50"]=101,["51"]=103,["52-53"]=104,["54-66"]=106,["67"]=115,["68"]=116,["69-70"]=117,["71"]=120,["72"]=121,["73"]=122,["74"]=124,["75"]=125,["76"]=126,["77"]=127,["78-79"]=128,["80"]=130,["81"]=132,["82"]=133,["83"]=134,["84"]=135,["85"]=136,["86"]=138,["87"]=139,["88"]=140,["89"]=141,["90"]=142,["91"]=144,["92"]=145,["93"]=146,["94"]=147,["95"]=148,["96"]=149,["97"]=150,["98"]=151,["99"]=152,["100-101"]=153,["102-103"]=156,["104"]=159,["105"]=160,["106-107"]=161,["108"]=163,["109-115"]=164,["116"]=169,["117-118"]=170,["119"]=172,["120-121"]=173,["122-127"]=175,["128"]=181,["129"]=182,["130"]=183,["131"]=184,["132"]=185,["133"]=186,["134-135"]=187,["136"]=189,["137-144"]=190,["145"]=208,["146-147"]=209,["148"]=211,["149"]=213,["150"]=214,["151"]=215,["152"]=216,["153-155"]=217,["156"]=221,["157"]=222,["158"]=223,["159"]=224,["160-162"]=225,["163"]=229,["164"]=230,["165"]=231,["166"]=232,["167"]=233,["168-170"]=234,["171"]=237,["172"]=239,["173"]=240,["174"]=241,["175"]=242,["176"]=243,["177-179"]=244,["180"]=247,["181"]=249,["182"]=250,["183"]=251,["184"]=252,["185-192"]=253,["193"]=264,["194-195"]=265,["196"]=267,["197"]=268,["198"]=269,["199"]=270,["200-201"]=271,["202"]=273,["203-204"]=274,["205-210"]=276,["211-215"]=282,["216"]=286,["217"]=287,["218"]=288,["219"]=289,["220-223"]=290,["224"]=292,["225"]=293,["226"]=294,["227"]=295,["228"]=296,["229-231"]=298,["232-234"]=299,["235"]=301,["236"]=303,["237"]=304,["238"]=305,["239"]=306,["240-241"]=307,["242-245"]=309}, "programs")
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
    while tierIndex <= 3 do
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
        return -51
    end
    if tierIndex == 2 then
        return -55
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
