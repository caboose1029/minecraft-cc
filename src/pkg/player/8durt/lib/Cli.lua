-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Cli.kt", {["1-11"]=1,["12"]=17,["13-14"]=18,["15"]=20,["16"]=21,["17"]=22,["18-19"]=23,["20"]=25,["21-22"]=26,["23"]=28,["24-25"]=29,["26-31"]=31,["32"]=35,["33"]=36,["34"]=37,["35"]=38,["36"]=39,["37"]=40,["38"]=41,["39-40"]=42,["41"]=44,["42-43"]=45,["44"]=46,["45"]=47,["46-49"]=48,["50"]=51,["51-52"]=52,["53"]=55,["54"]=56,["55-56"]=57,["57"]=60,["58"]=61,["59"]=62,["60"]=63,["61"]=64,["62"]=65,["63"]=66,["64"]=67,["65"]=68,["66-67"]=69,["68-69"]=71,["70-71"]=73,["72-73"]=75,["74-79"]=77,["80"]=81,["81-82"]=82,["83"]=84,["84"]=85,["85"]=87,["86"]=88,["87-88"]=89,["89"]=92,["90-95"]=93,["96"]=102,["97-98"]=103,["99"]=105,["100"]=106,["101"]=108,["102"]=109,["103-104"]=110,["105"]=113,["106"]=114,["107"]=115,["108-109"]=116,["110"]=119,["111"]=120,["112-113"]=121,["114"]=124,["115"]=125,["116"]=126,["117-118"]=127,["119"]=130,["120"]=131,["121-123"]=132}, "lib")
ktox_require("lib/Config")
ktox_require("lib/Executor")
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
    local pulledFromStock = pullFromStoragePool(pickupVault, itemName, qty)
    local stillNeeded = qty - pulledFromStock
    if stillNeeded <= 0 then
        return "Pulled " .. tostring(pulledFromStock) .. " of " .. tostring(itemName) .. " from stock (requested " .. tostring(qty) .. ")."
    end
    local conversion = findDirectConversion(itemName)
    if conversion == nil then
        return "Pulled " .. tostring(pulledFromStock) .. " of " .. tostring(itemName) .. " from stock; " .. tostring(stillNeeded) .. " more not directly craftable (requested " .. tostring(qty) .. ")."
    end
    local timeout = jobTimeoutSeconds(conversion.jobType)
    local produced = runDirectJob(conversion, stillNeeded, timeout)
    if produced <= 0 then
        return "Pulled " .. tostring(pulledFromStock) .. " of " .. tostring(itemName) .. " from stock; craft job produced none of the remaining " .. tostring(stillNeeded) .. " (requested " .. tostring(qty) .. ")."
    end
    local pulledAfterCraft = pullFromStoragePool(pickupVault, itemName, produced)
    local totalPulled = pulledFromStock + pulledAfterCraft
    return "Pulled " .. tostring(totalPulled) .. " of " .. tostring(itemName) .. " total (" .. tostring(pulledFromStock) .. " from stock, " .. tostring(pulledAfterCraft) .. " freshly crafted) - requested " .. tostring(qty) .. "."
end

