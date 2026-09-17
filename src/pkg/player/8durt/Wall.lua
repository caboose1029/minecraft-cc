-- package: programs

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "Wall.kt", {["1-8"]=1,["9"]=43,["10"]=44,["11"]=45,["12"]=46,["13-18"]=47,["19"]=54,["20"]=55,["21"]=56,["22"]=57,["23"]=58,["24"]=59,["25-27"]=60,["28-29"]=63,["30-35"]=65,["36"]=72,["37"]=73,["38-39"]=74,["40"]=76,["41-45"]=77,["46"]=81,["47"]=82,["48-49"]=83,["50"]=85,["51"]=86,["52-53"]=87,["54"]=92,["55"]=93,["56"]=94,["57"]=95,["58-59"]=96,["60"]=99,["61"]=100,["62"]=101,["63-64"]=102,["65"]=105,["66"]=106,["67"]=107,["68-69"]=108,["70"]=111,["71"]=117,["72"]=118,["73-74"]=119,["75"]=122,["76"]=123,["77"]=124,["78"]=125,["79"]=126,["80"]=127,["81"]=128,["82-83"]=129,["84"]=131,["85-86"]=132,["87"]=134,["88"]=141,["89"]=142,["90-91"]=143,["92-93"]=145,["94"]=147,["95"]=148,["96-98"]=149,["99-100"]=152,["101-102"]=154,["103"]=157,["104-105"]=158,["106-109"]=160}, "programs")

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
    if not turtle.up() then
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
                    moved = turtle.forward()
                else
                    moved = turtle.back()
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
    if stoppedShort then
        println("Stopped early - placed " .. tostring(placed) .. " of " .. tostring(length * height) .. " block(s).")
    else
        println("Done - placed " .. tostring(placed) .. " block(s).")
    end
end


main({...})
