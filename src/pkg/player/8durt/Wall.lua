-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Wall.kt", {["1-8"]=1,["9"]=45,["10"]=46,["11"]=47,["12"]=48,["13-18"]=49,["19"]=56,["20"]=57,["21"]=58,["22"]=59,["23"]=60,["24"]=61,["25-27"]=62,["28-29"]=65,["30-35"]=67,["36"]=74,["37"]=75,["38-39"]=76,["40"]=78,["41-49"]=79,["50"]=86,["51"]=87,["52-53"]=88,["54-58"]=90,["59"]=94,["60"]=95,["61-62"]=96,["63-67"]=98,["68"]=102,["69"]=103,["70-71"]=104,["72-76"]=106,["77"]=110,["78"]=111,["79-80"]=112,["81-84"]=114,["85"]=123,["86"]=124,["87"]=125,["88-90"]=126,["91"]=129,["92"]=130,["93"]=131,["94-96"]=132,["97"]=135,["98"]=136,["99"]=137,["100-102"]=138,["103"]=141,["104"]=142,["105"]=143,["106-112"]=144,["113"]=150,["114"]=151,["115-116"]=152,["117"]=154,["118"]=155,["119-120"]=156,["121"]=161,["122"]=162,["123"]=163,["124"]=164,["125-126"]=165,["127"]=168,["128"]=169,["129"]=170,["130-131"]=171,["132"]=174,["133"]=175,["134"]=176,["135-136"]=177,["137"]=180,["138"]=186,["139"]=187,["140-141"]=188,["142"]=191,["143"]=192,["144"]=193,["145"]=194,["146"]=195,["147"]=196,["148"]=197,["149-150"]=198,["151"]=200,["152-153"]=201,["154"]=203,["155"]=210,["156"]=211,["157-158"]=212,["159-160"]=214,["161"]=216,["162"]=217,["163-165"]=218,["166-167"]=221,["168-169"]=223,["170"]=226,["171"]=228,["172-173"]=229,["174-177"]=231}, "programs")

WALL_FUEL_SAFETY_MARGIN = 10

function wallPrintUsage()
    println("Usage: wall <length> <height>")
    println("  length: blocks along the wall\'s run")
    println("  height: rows stacked upward")
    println("Put the wall material in slot 1 before running - only slots")
    println("holding that exact same item are used; other items are left alone.")
end

---@param materialName string
---@return number
function wallFindMaterialSlot(materialName)
    local slot = 1
    local found = -1
    while slot <= 16 and found == -1 do
        if turtle.getItemCount(slot) > 0 then
            local name = ktoxGetItemName(slot)
            if name ~= nil and name == materialName then
                found = slot
            end
        end
        slot = ktox_plusAssign(slot, 1)
    end
    return found
end

---@param materialName string
---@return boolean
function wallPlaceMaterialDown(materialName)
    local slot = wallFindMaterialSlot(materialName)
    if slot == -1 then
        return false
    end
    turtle.select(slot)
    return turtle.placeDown()
end

wallHorizontalOffset = 0

wallVerticalOffset = 0

---@return boolean
function wallStepForward()
    if turtle.forward() then
        wallHorizontalOffset = ktox_plusAssign(wallHorizontalOffset, 1)
        return true
    end
    return false
end

---@return boolean
function wallStepBack()
    if turtle.back() then
        wallHorizontalOffset = ktox_minusAssign(wallHorizontalOffset, 1)
        return true
    end
    return false
end

---@return boolean
function wallStepUp()
    if turtle.up() then
        wallVerticalOffset = ktox_plusAssign(wallVerticalOffset, 1)
        return true
    end
    return false
end

---@return boolean
function wallStepDown()
    if turtle.down() then
        wallVerticalOffset = ktox_minusAssign(wallVerticalOffset, 1)
        return true
    end
    return false
end

function wallReturnHome()
    while wallVerticalOffset > 0 do
        if not wallStepDown() then
            println("Couldn\'t descend while returning home - manual recovery needed.")
            return
        end
    end
    while wallVerticalOffset < 0 do
        if not wallStepUp() then
            println("Couldn\'t ascend while returning home - manual recovery needed.")
            return
        end
    end
    while wallHorizontalOffset > 0 do
        if not wallStepBack() then
            println("Couldn\'t return home - manual recovery needed.")
            return
        end
    end
    while wallHorizontalOffset < 0 do
        if not wallStepForward() then
            println("Couldn\'t return home - manual recovery needed.")
            return
        end
    end
end

---@param args table
function main(args)
    if #(args) < 2 then
        wallPrintUsage()
        return
    end
    if args[1] == "-h" or args[1] == "--help" then
        wallPrintUsage()
        return
    end
    local length = ktox_toIntOrNull(args[1])
    local height = ktox_toIntOrNull(args[2])
    if length == nil or height == nil or length < 1 or height < 1 then
        wallPrintUsage()
        return
    end
    local materialName = ktoxGetItemName(1)
    if materialName == nil then
        println("Slot 1 is empty - put the wall material there first.")
        return
    end
    local neededFuel = length * height + WALL_FUEL_SAFETY_MARGIN
    local fuel = turtle.getFuelLevel()
    if fuel < neededFuel then
        println("Warning: fuel may be too low (have " .. tostring(fuel) .. ", want ~" .. tostring(neededFuel) .. "). Continuing anyway.")
    end
    println("Building a " .. tostring(length) .. "x" .. tostring(height) .. " wall from " .. tostring(materialName) .. "...")
    if not wallStepUp() then
        println("Couldn\'t get into position (blocked above) - aborting.")
        return
    end
    local row = 0
    local placed = 0
    local stoppedShort = false
    while row < height and not stoppedShort do
        local col = 0
        while col < length and not stoppedShort do
            if wallPlaceMaterialDown(materialName) then
                placed = ktox_plusAssign(placed, 1)
            else
                println("Ran out of " .. tostring(materialName) .. " after placing " .. tostring(placed) .. " block(s).")
                stoppedShort = true
            end
            if col < length - 1 and not stoppedShort then
                local moved = false
                if row % 2 == 0 then
                    moved = wallStepForward()
                else
                    moved = wallStepBack()
                end
                if not moved then
                    println("Blocked partway along row " .. tostring(row + 1) .. " - stopping.")
                    stoppedShort = true
                end
            end
            col = ktox_plusAssign(col, 1)
        end
        row = ktox_plusAssign(row, 1)
    end
    wallReturnHome()
    if stoppedShort then
        println("Stopped early - placed " .. tostring(placed) .. " of " .. tostring(length * height) .. " block(s).")
    else
        println("Done - placed " .. tostring(placed) .. " block(s).")
    end
end


main({...})
