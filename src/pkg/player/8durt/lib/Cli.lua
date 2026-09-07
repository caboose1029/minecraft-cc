-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Cli.kt", {["1-10"]=1,["11"]=19,["12-13"]=20,["14"]=22,["15"]=23,["16"]=24,["17-18"]=25,["19"]=27,["20-21"]=28,["22"]=30,["23-24"]=31,["25"]=33,["26-27"]=34,["28-43"]=36,["44-49"]=53,["50"]=65,["51-52"]=66,["53"]=68,["54"]=69,["55-56"]=70,["57-62"]=72,["63"]=76,["64-65"]=77,["66"]=79,["67"]=80,["68"]=81,["69"]=82,["70"]=83,["71"]=84,["72"]=85,["73-74"]=86,["75"]=88,["76-77"]=89,["78"]=90,["79"]=91,["80-83"]=92,["84"]=95,["85-86"]=96,["87"]=99,["88"]=100,["89-90"]=101,["91"]=109,["92"]=110,["93"]=111,["94-95"]=112,["96"]=114,["97"]=115,["98-99"]=116,["100"]=118,["101"]=119,["102"]=120,["103"]=121,["104"]=122,["105"]=123,["106"]=124,["107-108"]=125,["109-110"]=127,["111-112"]=129,["113-114"]=131,["115-120"]=133,["121"]=137,["122-123"]=138,["124"]=140,["125-126"]=141,["127"]=143,["128"]=144,["129"]=145,["130-131"]=146,["132"]=148,["133"]=150,["134"]=151,["135-136"]=152,["137"]=155,["138-143"]=156,["144"]=165,["145-146"]=166,["147"]=168,["148-149"]=169,["150"]=171,["151"]=172,["152"]=173,["153-154"]=174,["155"]=176,["156"]=183,["157"]=184,["158"]=185,["159"]=186,["160"]=187,["161"]=188,["162"]=189,["163"]=190,["164-166"]=191,["167"]=194,["168-170"]=195,["171-172"]=198,["173"]=201,["174"]=202,["175"]=203,["176"]=204,["177"]=205,["178-179"]=206,["180-182"]=208,["183"]=212,["184"]=214,["185-186"]=215,["187"]=218,["188-193"]=219,["194"]=227,["195-196"]=228,["197"]=230,["198-199"]=231,["200"]=233,["201"]=234,["202"]=235,["203-204"]=236,["205"]=238,["206"]=240,["207"]=241,["208-209"]=242,["210"]=245,["211-213"]=246}, "lib")
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

LIST_USAGE = "Usage: list (--stocked|--craftable|--unavailable) (item-name-filter) (-h)" .. "\n" .. "  Lists items in the storage pool. Optional status flag narrows to one status; optional trailing text filters to item names containing that substring (e.g. " .. "\"" .. "list --stocked iron" .. "\"" .. ")."

PULL_USAGE = "Usage: pull <name> <qty> (-h)" .. "\n" .. "  Pulls <qty> of <name> from the storage pool into a pickup location - this terminal\'s own inventory if it\'s itself configured as a pickup location, otherwise whichever pickup location is marked " .. "\"" .. "default" .. "\"" .. " in config/peripherals.json."

CRAFT_USAGE = "Usage: craft <name> <qty> (--location=<name>) (--fetch=false) (-h)" .. "\n" .. "  Crafts <qty> of <name>, chaining through intermediate jobs as needed, then pulls the result into a pickup location. Defaults to this terminal\'s own inventory if it\'s itself configured as a pickup location, otherwise the config/peripherals.json default; pass --location=<name> to target a specific named pickup location instead. Pass --fetch=false to craft without pulling the result out at all (leaves it in the storage pool)."

TRASH_USAGE = "Usage: trash <name> <qty> (-h)" .. "\n" .. "  Permanently destroys <qty> of <name> from the storage pool via the trash vault (dumped into lava)."

LIST_DISPLAY_LIMIT = 6

---@param parts table
---@return boolean
function isHelpFlag(parts)
    return #(parts) >= 2 and (parts[2] == "-h" or parts[2] == "--help")
end

---@param explicitLocation string
---@return string
function resolvePickupLocation(explicitLocation)
    if explicitLocation ~= "" then
        return ktoxConfigPickupVaultByName(explicitLocation)
    end
    local selfName = ktoxSelfPeripheralName()
    if selfName ~= "MISSING" and ktoxIsConfiguredPickupLocation(selfName) then
        return selfName
    end
    return ktoxConfigPickupVaultDefault()
end

---@param parts table
---@return string
function runListCommand(parts)
    if isHelpFlag(parts) then
        return LIST_USAGE
    end
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
    local startIndex = 1
    if #(rows) > LIST_DISPLAY_LIMIT then
        startIndex = #(rows) - LIST_DISPLAY_LIMIT + 1
    end
    local output = ""
    if startIndex > 1 then
        output = "(showing last " .. tostring(LIST_DISPLAY_LIMIT) .. " of " .. tostring(#(rows)) .. " - narrow with a status flag or item-name filter)" .. "\n"
    end
    local i = startIndex
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
    if isHelpFlag(parts) then
        return PULL_USAGE
    end
    if #(parts) < 3 then
        return PULL_USAGE
    end
    local itemName = parts[2]
    local qtyRaw = ktox_toDoubleOrNull(parts[3])
    if qtyRaw == nil then
        return tostring(PULL_USAGE) .. "\n" .. "\"" .. tostring(parts[3]) .. "\"" .. " isn\'t a number."
    end
    local qty = ktox_toInt(qtyRaw)
    local pickupVault = resolvePickupLocation("")
    if pickupVault == "MISSING" then
        return "No pickup vault configured (job.type " .. "\"" .. "pickup" .. "\"" .. " in config/peripherals.json)."
    end
    local pulled = pullFromStoragePool(pickupVault, itemName, qty)
    return "Pulled " .. tostring(pulled) .. " of " .. tostring(itemName) .. " into the pickup vault (requested " .. tostring(qty) .. ")."
end

---@param parts table
---@return string
function runCraftCommand(parts)
    if isHelpFlag(parts) then
        return CRAFT_USAGE
    end
    if #(parts) < 3 then
        return CRAFT_USAGE
    end
    local itemName = parts[2]
    local qtyRaw = ktox_toDoubleOrNull(parts[3])
    if qtyRaw == nil then
        return tostring(CRAFT_USAGE) .. "\n" .. "\"" .. tostring(parts[3]) .. "\"" .. " isn\'t a number."
    end
    local qty = ktox_toInt(qtyRaw)
    local fetch = true
    local location = ""
    local flagIndex = 4
    while flagIndex <= #(parts) do
        local flagParts = ktox_split(parts[flagIndex], "=")
        local flagName = flagParts[1]
        if flagName == "--fetch" then
            if #(flagParts) >= 2 and flagParts[2] == "false" then
                fetch = false
            end
        elseif flagName == "--location" then
            if #(flagParts) >= 2 then
                location = flagParts[2]
            end
        end
        flagIndex = ktox_plusAssign(flagIndex, 1)
    end
    local pickupVault = ""
    if fetch then
        pickupVault = resolvePickupLocation(location)
        if pickupVault == "MISSING" then
            if location ~= "" then
                return "No pickup location named " .. "\"" .. tostring(location) .. "\"" .. " is configured (" .. "\"" .. "name" .. "\"" .. " under a job.type " .. "\"" .. "pickup" .. "\"" .. " entry in config/peripherals.json)."
            end
            return "No pickup vault configured (job.type " .. "\"" .. "pickup" .. "\"" .. " in config/peripherals.json)."
        end
    end
    ensureStocked(itemName, qty, 0)
    if not fetch then
        return "Crafted " .. tostring(itemName) .. " up to " .. tostring(qty) .. " (left in the storage pool; --fetch=false)."
    end
    local pulled = pullFromStoragePool(pickupVault, itemName, qty)
    return "Pulled " .. tostring(pulled) .. " of " .. tostring(itemName) .. " (requested " .. tostring(qty) .. ")."
end

---@param parts table
---@return string
function runTrashCommand(parts)
    if isHelpFlag(parts) then
        return TRASH_USAGE
    end
    if #(parts) < 3 then
        return TRASH_USAGE
    end
    local itemName = parts[2]
    local qtyRaw = ktox_toDoubleOrNull(parts[3])
    if qtyRaw == nil then
        return tostring(TRASH_USAGE) .. "\n" .. "\"" .. tostring(parts[3]) .. "\"" .. " isn\'t a number."
    end
    local qty = ktox_toInt(qtyRaw)
    local trashVault = ktoxConfigTrashVault()
    if trashVault == "MISSING" then
        return "No trash vault configured (job.type " .. "\"" .. "trash" .. "\"" .. " in config/peripherals.json)."
    end
    local trashed = pullFromStoragePool(trashVault, itemName, qty)
    return "Destroyed " .. tostring(trashed) .. " of " .. tostring(itemName) .. " (requested " .. tostring(qty) .. ")."
end

