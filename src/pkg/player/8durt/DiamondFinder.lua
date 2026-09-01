-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "DiamondFinder.kt", {["1-11"]=1,["12"]=86,["13-14"]=87,["15"]=89,["16-17"]=90,["18"]=92,["19-20"]=93,["21"]=95,["22-23"]=96,["24"]=98,["25-26"]=99,["27"]=101,["28-29"]=102,["30"]=104,["31-32"]=105,["33-45"]=107,["46"]=116,["47"]=117,["48-49"]=118,["50"]=121,["51"]=122,["52"]=123,["53"]=125,["54"]=126,["55"]=127,["56-57"]=128,["58"]=136,["59"]=137,["60"]=138,["61"]=139,["62"]=140,["63"]=141,["64-65"]=142,["66"]=144,["67-68"]=145,["69"]=148,["70"]=149,["71"]=150,["72"]=151,["73"]=152,["74"]=154,["75"]=155,["76"]=156,["77"]=157,["78"]=158,["79"]=160,["80"]=161,["81"]=162,["82"]=163,["83"]=164,["84"]=165,["85"]=166,["86"]=167,["87"]=168,["88-89"]=169,["90-91"]=172,["92"]=175,["93"]=176,["94-95"]=177,["96"]=179,["97-103"]=180,["104"]=185,["105-106"]=186,["107-112"]=188,["113"]=194,["114"]=195,["115"]=196,["116"]=197,["117"]=198,["118"]=199,["119-120"]=200,["121"]=202,["122-129"]=203,["130"]=223,["131-132"]=224,["133"]=226,["134"]=228,["135"]=229,["136"]=230,["137"]=231,["138-140"]=232,["141"]=236,["142"]=237,["143"]=238,["144"]=239,["145-147"]=240,["148"]=244,["149"]=245,["150"]=246,["151"]=247,["152"]=248,["153-155"]=249,["156"]=252,["157"]=254,["158"]=255,["159"]=256,["160"]=257,["161"]=258,["162-164"]=259,["165"]=262,["166"]=264,["167"]=265,["168"]=266,["169"]=267,["170-180"]=268,["181"]=281,["182"]=282,["183-184"]=283,["185-186"]=285,["187"]=287,["188"]=288,["189-190"]=289,["191-192"]=291,["193"]=293,["194"]=294,["195"]=295,["196"]=296,["197"]=297,["198-199"]=298,["200-202"]=300,["203"]=303,["204"]=304,["205"]=305,["206"]=306,["207"]=307,["208-209"]=308,["210-212"]=310,["213-218"]=313,["219"]=322,["220-221"]=323,["222"]=325,["223"]=326,["224"]=327,["225"]=328,["226-227"]=329,["228"]=331,["229-230"]=332,["231-236"]=334,["237-241"]=340,["242"]=344,["243"]=345,["244"]=346,["245"]=347,["246-249"]=348,["250"]=350,["251"]=351,["252"]=352,["253"]=353,["254"]=354,["255-257"]=356,["258-260"]=357,["261"]=359,["262"]=364,["263"]=365,["264"]=366,["265"]=367,["266"]=368,["267-269"]=369,["270-273"]=372}, "programs")
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
        dfNavigateAndScan(movement, movement.homeX, tierY, movement.homeZ)
        local branch = 0
        while branch < branchCount do
            local lateralOffset = branch * (spacing + 1)
            local startX = movement.homeX + rgtDx * lateralOffset
            local startZ = movement.homeZ + rgtDz * lateralOffset
            dfEnsureFuelAndSpace(movement)
            dfNavigateAndScan(movement, startX, tierY, startZ)
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
---@param targetX number
---@param targetY number
---@param targetZ number
---@return boolean
function dfNavigateAndScan(m, targetX, targetY, targetZ)
    while m.y < targetY do
        if not m:up() then
            return false
        end
        followVein(m, 0)
    end
    while m.y > targetY do
        if not m:down() then
            return false
        end
        followVein(m, 0)
    end
    if m.x ~= targetX then
        local toward = (targetX > m.x and 1 or 3)
        m:faceHeading(toward)
        while m.x ~= targetX do
            if not m:forward() then
                return false
            end
            followVein(m, 0)
        end
    end
    if m.z ~= targetZ then
        local toward = (targetZ > m.z and 2 or 0)
        m:faceHeading(toward)
        while m.z ~= targetZ do
            if not m:forward() then
                return false
            end
            followVein(m, 0)
        end
    end
    return true
end

---@param m Movement
---@return boolean
function returnHomeWithRecovery(m)
    if dfNavigateAndScan(m, m.homeX, m.homeY, m.homeZ) then
        return true
    end
    local attempts = 0
    local reached = false
    while not reached and attempts < MAX_RETURN_ASCENTS do
        if not m:up() then
            return false
        end
        reached = dfNavigateAndScan(m, m.homeX, m.homeY, m.homeZ)
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
