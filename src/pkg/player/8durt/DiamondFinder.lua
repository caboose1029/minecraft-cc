-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "DiamondFinder.kt", {["1-11"]=1,["12"]=76,["13-14"]=77,["15"]=79,["16-17"]=80,["18"]=82,["19-20"]=83,["21"]=85,["22-23"]=86,["24"]=88,["25-26"]=89,["27"]=91,["28-29"]=92,["30"]=94,["31-32"]=95,["33"]=97,["34-35"]=98,["36"]=100,["37-38"]=101,["39"]=103,["40-41"]=104,["42"]=106,["43-44"]=107,["45"]=109,["46-47"]=110,["48"]=112,["49-50"]=113,["51"]=115,["52-53"]=116,["54-66"]=118,["67"]=127,["68"]=128,["69-70"]=129,["71"]=132,["72"]=133,["73"]=134,["74"]=136,["75"]=137,["76"]=138,["77-78"]=139,["79"]=147,["80"]=148,["81"]=149,["82"]=150,["83"]=151,["84"]=152,["85-86"]=153,["87"]=155,["88-89"]=156,["90"]=159,["91"]=160,["92"]=161,["93"]=162,["94"]=163,["95"]=165,["96"]=166,["97"]=167,["98"]=168,["99"]=169,["100"]=171,["101"]=172,["102"]=173,["103"]=174,["104"]=175,["105"]=176,["106"]=177,["107"]=178,["108"]=179,["109-110"]=180,["111-112"]=183,["113"]=186,["114"]=187,["115-116"]=188,["117"]=190,["118-124"]=191,["125"]=196,["126-127"]=197,["128-133"]=199,["134"]=205,["135"]=206,["136"]=207,["137"]=208,["138"]=209,["139"]=210,["140-141"]=211,["142"]=213,["143-150"]=214,["151"]=232,["152-153"]=233,["154"]=235,["155"]=237,["156"]=238,["157"]=239,["158"]=240,["159-161"]=241,["162"]=245,["163"]=246,["164"]=247,["165"]=248,["166-168"]=249,["169"]=253,["170"]=254,["171"]=255,["172"]=256,["173"]=257,["174-176"]=258,["177"]=261,["178"]=263,["179"]=264,["180"]=265,["181"]=266,["182"]=267,["183-185"]=268,["186"]=271,["187"]=273,["188"]=274,["189"]=275,["190"]=276,["191-198"]=277,["199"]=288,["200-201"]=289,["202"]=291,["203"]=292,["204"]=293,["205"]=294,["206-207"]=295,["208"]=297,["209-210"]=298,["211-216"]=300,["217-221"]=306,["222"]=310,["223"]=311,["224"]=312,["225"]=313,["226-229"]=314,["230"]=316,["231"]=317,["232"]=318,["233"]=319,["234"]=320,["235-237"]=322,["238-240"]=323,["241"]=325,["242"]=330,["243"]=331,["244"]=332,["245"]=333,["246"]=334,["247-249"]=335,["250-253"]=338}, "programs")
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
    if movement.gpsEnabled then
        println("Home at x=" .. tostring(movement.homeX) .. " y=" .. tostring(movement.homeY) .. " z=" .. tostring(movement.homeZ))
    else
        println("No GPS available - DiamondFinder targets real diamond-rich depths (y=-56/-59) and needs the turtle\'s actual world Y to do that.")
        println("Enter the turtle\'s current Y coordinate:")
        local input = read()
        local manualY = ktox_toIntOrNull(input)
        if manualY == nil then
            println("Invalid Y value entered - aborting.")
            return
        end
        movement = Movement:new(0, manualY, 0, 0, 0, manualY, 0, 0, false)
        println("Using manual y=" .. tostring(manualY) .. " as home.")
    end
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
        if m.gpsEnabled then
            local checked = gpsLocate()
            if checked ~= nil then
                m.x = checked.x
                m.y = checked.y
                m.z = checked.z
            end
        end
        println("Resuming.")
    end
end


main({...})
