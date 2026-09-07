-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Cli.kt", {["1-10"]=1,["11"]=20,["12-13"]=21,["14"]=23,["15"]=24,["16"]=25,["17-18"]=26,["19"]=28,["20-21"]=29,["22"]=31,["23-24"]=32,["25"]=34,["26-27"]=35,["28-43"]=37,["44-49"]=54,["50"]=66,["51-52"]=67,["53"]=69,["54"]=70,["55-56"]=71,["57-64"]=73,["65"]=88,["66"]=89,["67-68"]=90,["69-75"]=92,["76"]=101,["77"]=102,["78"]=103,["79"]=104,["80-81"]=105,["82-83"]=107,["84-90"]=109,["91"]=113,["92"]=114,["93"]=115,["94"]=116,["95-96"]=117,["97-98"]=119,["99-104"]=121,["105"]=127,["106-107"]=128,["108-113"]=130,["114"]=134,["115-116"]=135,["117"]=137,["118"]=138,["119"]=139,["120"]=140,["121"]=141,["122"]=142,["123"]=143,["124-125"]=144,["126"]=146,["127-128"]=147,["129"]=148,["130"]=149,["131-134"]=150,["135"]=153,["136-137"]=154,["138"]=157,["139"]=158,["140-141"]=159,["142"]=167,["143"]=168,["144"]=169,["145-146"]=170,["147"]=172,["148"]=173,["149-150"]=174,["151"]=176,["152"]=177,["153"]=178,["154"]=179,["155"]=180,["156"]=181,["157"]=182,["158-159"]=183,["160-161"]=185,["162-163"]=187,["164-165"]=189,["166-171"]=191,["172"]=195,["173-174"]=196,["175"]=198,["176-177"]=199,["178"]=201,["179"]=202,["180"]=203,["181-182"]=204,["183"]=206,["184"]=208,["185"]=209,["186"]=210,["187-188"]=211,["189"]=214,["190-195"]=215,["196"]=224,["197-198"]=225,["199"]=227,["200-201"]=228,["202"]=230,["203"]=231,["204"]=232,["205-206"]=233,["207"]=235,["208"]=237,["209"]=238,["210"]=240,["211"]=241,["212"]=242,["213"]=243,["214-216"]=244,["217"]=248,["218"]=250,["219-220"]=251,["221"]=254,["222-227"]=255,["228"]=263,["229-230"]=264,["231"]=266,["232-233"]=267,["234"]=269,["235"]=270,["236"]=271,["237-238"]=272,["239"]=274,["240"]=276,["241"]=277,["242-243"]=278,["244"]=281,["245-247"]=282}, "lib")
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
    ensureStocked(itemName, qty, 0)
    if not fetch then
        return "Crafted " .. tostring(itemName) .. " up to " .. tostring(qty) .. " (left in the storage pool; --fetch=false)."
    end
    local pulled = deliverToPickupLocation(pickupVault, itemName, qty)
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

