-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Cli.kt", {["1-10"]=1,["11"]=16,["12-13"]=17,["14"]=19,["15"]=20,["16"]=21,["17-18"]=22,["19"]=24,["20-21"]=25,["22"]=27,["23-24"]=28,["25"]=30,["26-27"]=31,["28-33"]=33,["34"]=37,["35"]=38,["36"]=39,["37"]=40,["38"]=41,["39"]=42,["40"]=43,["41-42"]=44,["43"]=46,["44-45"]=47,["46"]=48,["47"]=49,["48-51"]=50,["52"]=53,["53-54"]=54,["55"]=57,["56"]=58,["57-58"]=59,["59"]=62,["60"]=63,["61"]=64,["62"]=65,["63"]=66,["64"]=67,["65"]=68,["66"]=69,["67"]=70,["68-69"]=71,["70-71"]=73,["72-73"]=75,["74-75"]=77,["76-81"]=79,["82"]=83,["83-84"]=84,["85"]=86,["86"]=87,["87"]=88,["88-89"]=89,["90"]=91,["91"]=93,["92"]=94,["93-94"]=95,["95"]=98,["96-101"]=99,["102"]=108,["103-104"]=109,["105"]=111,["106"]=112,["107"]=113,["108-109"]=114,["110"]=116,["111"]=118,["112"]=119,["113-114"]=120,["115"]=123,["116"]=124,["117-122"]=125,["123"]=133,["124-125"]=134,["126"]=136,["127"]=137,["128"]=138,["129-130"]=139,["131"]=141,["132"]=143,["133"]=144,["134-135"]=145,["136"]=148,["137-139"]=149}, "lib")
ktox_require("lib/Planner")
ktox_require("lib/Inventory")

---@param commandLine string
---@return string
function runCliCommand(commandLine)
    if commandLine == "" then
        return "Empty command. Try: list, pull, craft."
    end
    local parts = ktox_split(commandLine, " ")
    local verb = parts[1]
    if verb == "list" then
        return runListCommand(parts)
    end
    if verb == "pull" then
        return runPullCommand(parts)
    end
    if verb == "craft" then
        return runCraftCommand(parts)
    end
    if verb == "trash" then
        return runTrashCommand(parts)
    end
    return "Unknown command: " .. tostring(verb) .. ". Try: list, pull, craft, trash."
end

---@param parts table
---@return string
function runListCommand(parts)
    local filter = ""
    local substring = ""
    local nextIndex = 2
    if #(parts) >= 2 then
        local maybeFlag = parts[2]
        if maybeFlag == "--stocked" then
            filter = "stocked"
            nextIndex = 3
        elseif maybeFlag == "--craftable" then
            filter = "craftable"
            nextIndex = 3
        else
            if maybeFlag == "--unavailable" then
                filter = "unavailable"
                nextIndex = 3
            end
        end
    end
    if #(parts) >= nextIndex then
        substring = parts[nextIndex]
    end
    local raw = ktoxListCatalog(ktoxConfigStorageVaultNames(), filter, substring)
    if raw == "" then
        return "No items found."
    end
    local rows = ktox_split(raw, "\n")
    local output = ""
    local i = 1
    while i <= #(rows) do
        local cols = ktox_split(rows[i], ",")
        local status = cols[1]
        local name = cols[2]
        local count = cols[3]
        if status == "stocked" then
            output = tostring(output) .. tostring(name) .. ": " .. tostring(count) .. " in stock" .. "\n"
        elseif status == "craftable" then
            output = tostring(output) .. tostring(name) .. ": craftable" .. "\n"
        else
            output = tostring(output) .. tostring(name) .. ": unavailable" .. "\n"
        end
        i = ktox_plusAssign(i, 1)
    end
    return output
end

---@param parts table
---@return string
function runPullCommand(parts)
    if #(parts) < 3 then
        return "Usage: pull <name> <qty>"
    end
    local itemName = parts[2]
    local qtyRaw = ktox_toDoubleOrNull(parts[3])
    if qtyRaw == nil then
        return "Usage: pull <name> <qty> - " .. "\"" .. tostring(parts[3]) .. "\"" .. " isn\'t a number."
    end
    local qty = ktox_toInt(qtyRaw)
    local pickupVault = ktoxConfigPickupVault()
    if pickupVault == "MISSING" then
        return "No pickup vault configured (job.type " .. "\"" .. "pickup" .. "\"" .. " in config/peripherals.json)."
    end
    local pulled = pullFromStoragePool(pickupVault, itemName, qty)
    return "Pulled " .. tostring(pulled) .. " of " .. tostring(itemName) .. " into the pickup vault (requested " .. tostring(qty) .. ")."
end

---@param parts table
---@return string
function runCraftCommand(parts)
    if #(parts) < 3 then
        return "Usage: craft <name> <qty>"
    end
    local itemName = parts[2]
    local qtyRaw = ktox_toDoubleOrNull(parts[3])
    if qtyRaw == nil then
        return "Usage: craft <name> <qty> - " .. "\"" .. tostring(parts[3]) .. "\"" .. " isn\'t a number."
    end
    local qty = ktox_toInt(qtyRaw)
    local pickupVault = ktoxConfigPickupVault()
    if pickupVault == "MISSING" then
        return "No pickup vault configured (job.type " .. "\"" .. "pickup" .. "\"" .. " in config/peripherals.json)."
    end
    ensureStocked(itemName, qty, 0)
    local pulled = pullFromStoragePool(pickupVault, itemName, qty)
    return "Pulled " .. tostring(pulled) .. " of " .. tostring(itemName) .. " (requested " .. tostring(qty) .. ")."
end

---@param parts table
---@return string
function runTrashCommand(parts)
    if #(parts) < 3 then
        return "Usage: trash <name> <qty>"
    end
    local itemName = parts[2]
    local qtyRaw = ktox_toDoubleOrNull(parts[3])
    if qtyRaw == nil then
        return "Usage: trash <name> <qty> - " .. "\"" .. tostring(parts[3]) .. "\"" .. " isn\'t a number."
    end
    local qty = ktox_toInt(qtyRaw)
    local trashVault = ktoxConfigTrashVault()
    if trashVault == "MISSING" then
        return "No trash vault configured (job.type " .. "\"" .. "trash" .. "\"" .. " in config/peripherals.json)."
    end
    local trashed = pullFromStoragePool(trashVault, itemName, qty)
    return "Destroyed " .. tostring(trashed) .. " of " .. tostring(itemName) .. " (requested " .. tostring(qty) .. ")."
end

