-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "DiamondFinder.kt", {["1-11"]=1,["12"]=83,["13-14"]=84,["15"]=86,["16-17"]=87,["18"]=89,["19-20"]=90,["21"]=92,["22-23"]=93,["24"]=95,["25-26"]=96,["27"]=98,["28-29"]=99,["30"]=101,["31-32"]=102,["33-45"]=104,["46"]=113,["47"]=114,["48-49"]=115,["50"]=118,["51"]=119,["52"]=120,["53"]=122,["54"]=123,["55"]=124,["56-57"]=125,["58"]=133,["59"]=134,["60"]=135,["61"]=136,["62"]=137,["63"]=138,["64-65"]=139,["66"]=141,["67-68"]=142,["69"]=145,["70"]=146,["71"]=147,["72"]=148,["73"]=149,["74"]=151,["75"]=152,["76"]=153,["77"]=154,["78"]=155,["79"]=157,["80"]=158,["81"]=159,["82"]=160,["83"]=161,["84"]=162,["85"]=163,["86"]=164,["87"]=165,["88-89"]=166,["90-91"]=169,["92"]=172,["93"]=173,["94-95"]=174,["96"]=176,["97-103"]=177,["104"]=182,["105-106"]=183,["107-112"]=185,["113"]=191,["114"]=192,["115"]=193,["116"]=194,["117"]=195,["118"]=196,["119-120"]=197,["121"]=199,["122-129"]=200,["130"]=218,["131-132"]=219,["133"]=221,["134"]=223,["135"]=224,["136"]=225,["137"]=226,["138-140"]=227,["141"]=231,["142"]=232,["143"]=233,["144"]=234,["145-147"]=235,["148"]=239,["149"]=240,["150"]=241,["151"]=242,["152"]=243,["153-155"]=244,["156"]=247,["157"]=249,["158"]=250,["159"]=251,["160"]=252,["161"]=253,["162-164"]=254,["165"]=257,["166"]=259,["167"]=260,["168"]=261,["169"]=262,["170-177"]=263,["178"]=274,["179-180"]=275,["181"]=277,["182"]=278,["183"]=279,["184"]=280,["185-186"]=281,["187"]=283,["188-189"]=284,["190-195"]=286,["196-200"]=292,["201"]=296,["202"]=297,["203"]=298,["204"]=299,["205-208"]=300,["209"]=302,["210"]=303,["211"]=304,["212"]=305,["213"]=306,["214-216"]=308,["217-219"]=309,["220"]=311,["221"]=316,["222"]=317,["223"]=318,["224"]=319,["225"]=320,["226-228"]=321,["229-232"]=324}, "programs")
ktox_require("lib/Chest")
ktox_require("lib/Movement")
ktox_require("lib/Position")

---@param name string
---@return boolean
function isValuableOre(name)
    if ktox_contains(name, "diamond") then
        return true
    end
    if ktox_contains(name, "redstone") then
        return true
    end
    if ktox_contains(name, "gold") then
        return true
    end
    if ktox_contains(name, "iron") then
        return true
    end
    if ktox_contains(name, "copper") then
        return true
    end
    if ktox_contains(name, "lapis") then
        return true
    end
    if ktox_contains(name, "emerald") then
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
