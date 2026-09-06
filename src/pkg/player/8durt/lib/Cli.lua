-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Cli.kt", {["1-10"]=1,["11"]=15,["12-13"]=16,["14"]=18,["15"]=19,["16"]=20,["17-18"]=21,["19"]=23,["20-21"]=24,["22"]=26,["23-24"]=27,["25-30"]=29,["31"]=33,["32"]=34,["33"]=35,["34"]=36,["35"]=37,["36"]=38,["37"]=39,["38-39"]=40,["40"]=42,["41-42"]=43,["43"]=44,["44"]=45,["45-48"]=46,["49"]=49,["50-51"]=50,["52"]=53,["53"]=54,["54-55"]=55,["56"]=58,["57"]=59,["58"]=60,["59"]=61,["60"]=62,["61"]=63,["62"]=64,["63"]=65,["64"]=66,["65-66"]=67,["67-68"]=69,["69-70"]=71,["71-72"]=73,["73-78"]=75,["79"]=79,["80-81"]=80,["82"]=82,["83"]=83,["84"]=85,["85"]=86,["86-87"]=87,["88"]=90,["89-94"]=91,["95"]=100,["96-97"]=101,["98"]=103,["99"]=104,["100"]=106,["101"]=107,["102-103"]=108,["104"]=111,["105"]=112,["106-108"]=113}, "lib")
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
    return "Unknown command: " .. tostring(verb) .. ". Try: list, pull, craft."
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
    local qty = ktox_toInt(ktox_toDouble(parts[3]))
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
    local qty = ktox_toInt(ktox_toDouble(parts[3]))
    local pickupVault = ktoxConfigPickupVault()
    if pickupVault == "MISSING" then
        return "No pickup vault configured (job.type " .. "\"" .. "pickup" .. "\"" .. " in config/peripherals.json)."
    end
    ensureStocked(itemName, qty, 0)
    local pulled = pullFromStoragePool(pickupVault, itemName, qty)
    return "Pulled " .. tostring(pulled) .. " of " .. tostring(itemName) .. " (requested " .. tostring(qty) .. ")."
end

