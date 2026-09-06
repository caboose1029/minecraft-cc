-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Cli.kt", {["1-9"]=1,["10"]=14,["11-12"]=15,["13"]=17,["14"]=18,["15"]=19,["16-17"]=20,["18"]=22,["19-20"]=23,["21-26"]=25,["27"]=29,["28"]=30,["29"]=31,["30"]=32,["31"]=33,["32"]=34,["33"]=35,["34-35"]=36,["36"]=38,["37-38"]=39,["39"]=40,["40"]=41,["41-44"]=42,["45"]=45,["46-47"]=46,["48"]=49,["49"]=50,["50-51"]=51,["52"]=54,["53"]=55,["54"]=56,["55"]=57,["56"]=58,["57"]=59,["58"]=60,["59"]=61,["60"]=62,["61-62"]=63,["63-64"]=65,["65-66"]=67,["67-68"]=69,["69-74"]=71,["75"]=75,["76-77"]=76,["78"]=78,["79"]=79,["80"]=81,["81"]=82,["82-83"]=83,["84"]=86,["85-87"]=87}, "lib")
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

