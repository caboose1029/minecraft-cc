-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Chest.kt", {["1-14"]=1,["15"]=49,["16-17"]=50,["18"]=52,["19-20"]=53,["21"]=55,["22-23"]=56,["24"]=58,["25-26"]=59,["27"]=61,["28-29"]=62,["30-35"]=64,["36"]=72,["37"]=73,["38"]=74,["39"]=75,["40-45"]=76,["46"]=84,["47"]=85,["48"]=86,["49"]=87,["50"]=88,["51-53"]=89,["54-55"]=92,["56-61"]=94,["62"]=101,["63"]=102,["64"]=104,["65"]=105,["66"]=106,["67"]=107,["68"]=108,["69"]=109,["70"]=110,["71"]=111,["72"]=112,["73"]=113,["74"]=114,["75"]=115,["76-77"]=116,["78"]=118,["79-83"]=119,["84-85"]=124,["86"]=127,["87-93"]=128,["94"]=154,["95"]=155,["96"]=156,["97"]=157,["98"]=158,["99"]=159,["100"]=160,["101"]=161,["102-103"]=162,["104"]=164,["105"]=165,["106"]=166,["107"]=167,["108"]=168,["109"]=169,["110"]=170,["111"]=171,["112"]=172,["113-115"]=173,["116-118"]=176,["119"]=179,["120"]=180,["121"]=181,["122"]=182,["123-125"]=183,["126-127"]=186,["128"]=188,["129-131"]=189}, "lib")

CHEST_OVERFLOW_SIDE = 1

CHEST_MAX_OVERFLOW = 20

CHEST_INTAKE_SLOT = 16

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

---@param m Movement
---@param n number
function goToChest(m, n)
    local sideways = (m.homeHeading + CHEST_OVERFLOW_SIDE + 4) % 4
    local targetX = m.homeX + headingDx(sideways) * n
    local targetZ = m.homeZ + headingDz(sideways) * n
    navigateTo(m, targetX, m.homeY, targetZ)
    m:faceHeading((m.homeHeading + 2) % 4)
end

---@param keepSlot (Int) -> Boolean
---@return boolean
function cargoFull(keepSlot)
    local slot = 1
    local full = true
    while slot <= 16 do
        if not keepSlot(slot) then
            if turtle.getItemCount(slot) == 0 then
                full = false
            end
        end
        slot = ktox_plusAssign(slot, 1)
    end
    return full
end

---@param m Movement
---@param keepSlot (Int) -> Boolean
function dumpCargo(m, keepSlot)
    local chestIndex = 1
    goToChest(m, chestIndex)
    local slot = 1
    local giveUp = false
    while slot <= 16 and not giveUp do
        if not keepSlot(slot) then
            local count = turtle.getItemCount(slot)
            if count > 0 then
                turtle.select(slot)
                local dropped = turtle.drop(64)
                while not dropped and not giveUp do
                    chestIndex = ktox_plusAssign(chestIndex, 1)
                    if chestIndex > CHEST_MAX_OVERFLOW then
                        println("All overflow chests full, stopping dump early.")
                        giveUp = true
                    else
                        goToChest(m, chestIndex)
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
---@param maxAttempts number
---@param onOther (String) -> Boolean
function restockChest(m, maxAttempts, onOther)
    goToChest(m, 0)
    local attempts = 0
    local chestEmpty = false
    local stuck = false
    while attempts < maxAttempts and not chestEmpty and not stuck do
        turtle.select(CHEST_INTAKE_SLOT)
        local pulled = turtle.suck(64)
        if not pulled then
            chestEmpty = true
        else
            local name = ktoxGetItemName(CHEST_INTAKE_SLOT)
            local handled = false
            if name ~= nil then
                local value = fuelValue(name)
                if value > 0 then
                    local headroom = turtle.getFuelLimit() - turtle.getFuelLevel()
                    if headroom >= value then
                        turtle.select(CHEST_INTAKE_SLOT)
                        turtle.refuel(64)
                        handled = true
                    end
                elseif onOther(name) then
                    handled = true
                end
            end
            if not handled then
                turtle.select(CHEST_INTAKE_SLOT)
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

