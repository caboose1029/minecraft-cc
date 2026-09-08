-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Cli.kt", {["1-10"]=1,["11"]=22,["12-13"]=23,["14"]=25,["15"]=26,["16"]=27,["17-18"]=28,["19"]=30,["20-21"]=31,["22"]=33,["23-24"]=34,["25"]=36,["26-27"]=37,["28-43"]=39,["44-49"]=56,["50"]=68,["51-52"]=69,["53"]=71,["54"]=72,["55-56"]=73,["57-64"]=75,["65"]=90,["66"]=91,["67-68"]=92,["69-75"]=94,["76"]=103,["77"]=104,["78"]=105,["79"]=106,["80-81"]=107,["82-83"]=109,["84-90"]=111,["91"]=115,["92"]=116,["93"]=117,["94"]=118,["95-96"]=119,["97-98"]=121,["99-104"]=123,["105"]=129,["106-107"]=130,["108-113"]=132,["114"]=136,["115-116"]=137,["117"]=139,["118"]=140,["119"]=141,["120"]=142,["121"]=143,["122"]=144,["123"]=145,["124-125"]=146,["126"]=148,["127-128"]=149,["129"]=150,["130"]=151,["131-134"]=152,["135"]=155,["136-137"]=156,["138"]=159,["139"]=160,["140-141"]=161,["142"]=169,["143"]=170,["144"]=171,["145-146"]=172,["147"]=174,["148"]=175,["149-150"]=176,["151"]=178,["152"]=179,["153"]=180,["154"]=181,["155"]=182,["156"]=183,["157"]=184,["158-159"]=185,["160-161"]=187,["162-163"]=189,["164-165"]=191,["166-171"]=193,["172"]=197,["173-174"]=198,["175"]=200,["176-177"]=201,["178"]=203,["179"]=204,["180"]=205,["181-182"]=206,["183"]=208,["184"]=210,["185"]=211,["186"]=212,["187-188"]=213,["189"]=216,["190-195"]=217,["196"]=226,["197-198"]=227,["199"]=229,["200-201"]=230,["202"]=232,["203"]=233,["204"]=234,["205-206"]=235,["207"]=237,["208"]=239,["209"]=240,["210"]=242,["211"]=243,["212"]=244,["213"]=245,["214-216"]=246,["217"]=255,["218"]=256,["219"]=257,["220"]=258,["221"]=259,["222-223"]=260,["224"]=263,["225-226"]=264,["227"]=267,["228-233"]=268,["234"]=276,["235-236"]=277,["237"]=279,["238-239"]=280,["240"]=282,["241"]=283,["242"]=284,["243-244"]=285,["245"]=287,["246"]=289,["247"]=290,["248-249"]=291,["250"]=294,["251-253"]=295}, "lib")
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

PULL_USAGE = "Usage: pull <name> <qty> (--location=<name>) (-h)" .. "\n" .. "  Pulls <qty> of <name> from the storage pool into a pickup location. --location=<name> targets a specific named one; without it, this terminal\'s own inventory if it\'s itself configured as a pickup location, otherwise whichever pickup location is marked " .. "\"" .. "default" .. "\"" .. " in config/peripherals.json."

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

---@param pickupVault string
---@param itemName string
---@param qty number
---@return number
function deliverToPickupLocation(pickupVault, itemName, qty)
    local selfName = ktoxSelfPeripheralName()
    if selfName ~= "MISSING" and selfName == pickupVault then
        return pushToStoragePoolTarget(pickupVault, itemName, qty)
    end
    return pullFromStoragePool(pickupVault, itemName, qty)
end

---@param parts table
---@param startIndex number
---@return string
function parseLocationFlag(parts, startIndex)
    local idx = startIndex
    while idx <= #(parts) do
        local flagParts = ktox_split(parts[idx], "=")
        if flagParts[1] == "--location" and #(flagParts) >= 2 then
            return flagParts[2]
        end
        idx = ktox_plusAssign(idx, 1)
    end
    return ""
end

---@param parts table
---@param startIndex number
---@return boolean
function parseFetchFlag(parts, startIndex)
    local idx = startIndex
    while idx <= #(parts) do
        local flagParts = ktox_split(parts[idx], "=")
        if flagParts[1] == "--fetch" and #(flagParts) >= 2 and flagParts[2] == "false" then
            return false
        end
        idx = ktox_plusAssign(idx, 1)
    end
    return true
end

---@param explicitLocation string
---@return string
function noPickupLocationMessage(explicitLocation)
    if explicitLocation ~= "" then
        return "No pickup location named " .. "\"" .. tostring(explicitLocation) .. "\"" .. " is configured (" .. "\"" .. "name" .. "\"" .. " under a job.type " .. "\"" .. "pickup" .. "\"" .. " entry in config/peripherals.json)."
    end
    return "No pickup vault configured (job.type " .. "\"" .. "pickup" .. "\"" .. " in config/peripherals.json)."
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
    local location = parseLocationFlag(parts, 4)
    local pickupVault = resolvePickupLocation(location)
    if pickupVault == "MISSING" then
        return noPickupLocationMessage(location)
    end
    local pulled = deliverToPickupLocation(pickupVault, itemName, qty)
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
    local fetch = parseFetchFlag(parts, 4)
    local location = parseLocationFlag(parts, 4)
    local pickupVault = ""
    if fetch then
        pickupVault = resolvePickupLocation(location)
        if pickupVault == "MISSING" then
            return noPickupLocationMessage(location)
        end
    end
    ktoxClearLastCrafterFailure()
    ensureStocked(itemName, qty, 0)
    local crafterFailure = ktoxGetLastCrafterFailure()
    local failureSuffix = ""
    if crafterFailure ~= "" then
        failureSuffix = " " .. tostring(crafterFailure)
    end
    if not fetch then
        return "Crafted " .. tostring(itemName) .. " up to " .. tostring(qty) .. " (left in the storage pool; --fetch=false)." .. tostring(failureSuffix)
    end
    local pulled = deliverToPickupLocation(pickupVault, itemName, qty)
    return "Pulled " .. tostring(pulled) .. " of " .. tostring(itemName) .. " (requested " .. tostring(qty) .. ")." .. tostring(failureSuffix)
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

