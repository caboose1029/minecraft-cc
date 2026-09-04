-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "DiamondFinder.kt", {["1-11"]=1,["12"]=86,["13-14"]=87,["15"]=89,["16-17"]=90,["18"]=92,["19-20"]=93,["21"]=95,["22-23"]=96,["24"]=98,["25-26"]=99,["27"]=101,["28-29"]=102,["30"]=104,["31-32"]=105,["33"]=107,["34-35"]=108,["36-48"]=110,["49"]=119,["50"]=120,["51-52"]=121,["53"]=124,["54"]=125,["55"]=126,["56"]=128,["57"]=129,["58"]=130,["59-60"]=131,["61"]=139,["62"]=140,["63"]=141,["64"]=142,["65"]=143,["66"]=144,["67-68"]=145,["69"]=147,["70-71"]=148,["72"]=151,["73"]=152,["74"]=153,["75"]=154,["76"]=155,["77"]=157,["78"]=158,["79"]=159,["80"]=160,["81"]=161,["82"]=163,["83"]=164,["84"]=165,["85"]=166,["86"]=167,["87"]=168,["88"]=169,["89"]=170,["90"]=171,["91-92"]=172,["93-94"]=175,["95"]=178,["96"]=179,["97-98"]=180,["99"]=182,["100-106"]=183,["107"]=188,["108-109"]=189,["110-115"]=191,["116"]=197,["117"]=198,["118"]=199,["119"]=200,["120"]=201,["121"]=202,["122-123"]=203,["124"]=205,["125-132"]=206,["133"]=226,["134-135"]=227,["136"]=229,["137"]=231,["138"]=232,["139"]=233,["140"]=234,["141-143"]=235,["144"]=239,["145"]=240,["146"]=241,["147"]=242,["148-150"]=243,["151"]=247,["152"]=248,["153"]=249,["154"]=250,["155"]=251,["156-158"]=252,["159"]=255,["160"]=257,["161"]=258,["162"]=259,["163"]=260,["164"]=261,["165-167"]=262,["168"]=265,["169"]=267,["170"]=268,["171"]=269,["172"]=270,["173-183"]=271,["184"]=284,["185"]=285,["186-187"]=286,["188-189"]=288,["190"]=290,["191"]=291,["192-193"]=292,["194-195"]=294,["196"]=296,["197"]=297,["198"]=298,["199"]=299,["200"]=300,["201-202"]=301,["203-205"]=303,["206"]=306,["207"]=307,["208"]=308,["209"]=309,["210"]=310,["211-212"]=311,["213-215"]=313,["216-221"]=316,["222"]=325,["223-224"]=326,["225"]=328,["226"]=329,["227"]=330,["228"]=331,["229-230"]=332,["231"]=334,["232-233"]=335,["234-239"]=337,["240-244"]=343,["245"]=347,["246"]=348,["247"]=349,["248"]=350,["249-252"]=351,["253"]=353,["254"]=354,["255"]=355,["256"]=356,["257"]=357,["258-260"]=359,["261-263"]=360,["264"]=362,["265"]=367,["266"]=368,["267"]=369,["268"]=370,["269"]=371,["270-272"]=372,["273-276"]=375}, "programs")
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
    if ktox_contains(name, "zinc") then
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
