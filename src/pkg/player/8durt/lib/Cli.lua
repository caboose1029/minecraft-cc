-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Cli.kt", {["1-10"]=1,["11"]=25,["12-13"]=26,["14"]=28,["15"]=29,["16"]=30,["17-18"]=31,["19"]=33,["20-21"]=34,["22"]=36,["23-24"]=37,["25"]=39,["26-27"]=40,["28"]=42,["29-30"]=43,["31-48"]=45,["49-54"]=63,["55"]=75,["56-57"]=76,["58"]=78,["59"]=79,["60-61"]=80,["62-69"]=82,["70"]=103,["71"]=104,["72"]=105,["73-74"]=106,["75"]=108,["76"]=109,["77-78"]=110,["79-80"]=112,["81-86"]=114,["87"]=124,["88-89"]=125,["90"]=127,["91-92"]=128,["93"]=130,["94"]=131,["95-96"]=132,["97"]=134,["98"]=135,["99-100"]=136,["101"]=138,["102-108"]=139,["109"]=148,["110"]=149,["111"]=150,["112"]=151,["113-114"]=152,["115-116"]=154,["117-123"]=156,["124"]=160,["125"]=161,["126"]=162,["127"]=163,["128-129"]=164,["130-131"]=166,["132-137"]=168,["138"]=174,["139-140"]=175,["141-146"]=177,["147"]=181,["148-149"]=182,["150"]=184,["151"]=185,["152"]=186,["153"]=187,["154"]=188,["155"]=189,["156"]=190,["157-158"]=191,["159"]=193,["160-161"]=194,["162"]=195,["163"]=196,["164-167"]=197,["168"]=200,["169-170"]=201,["171"]=204,["172"]=205,["173-174"]=206,["175"]=214,["176"]=215,["177"]=216,["178-179"]=217,["180"]=219,["181"]=220,["182-183"]=221,["184"]=223,["185"]=224,["186"]=225,["187"]=226,["188"]=227,["189"]=228,["190"]=229,["191-192"]=230,["193-194"]=232,["195-196"]=234,["197-198"]=236,["199-204"]=238,["205"]=242,["206-207"]=243,["208"]=245,["209-210"]=246,["211"]=248,["212"]=249,["213"]=250,["214-215"]=251,["216"]=253,["217"]=255,["218"]=256,["219"]=257,["220-221"]=258,["222"]=261,["223-228"]=262,["229"]=271,["230-231"]=272,["232"]=274,["233-234"]=275,["235"]=277,["236"]=278,["237"]=279,["238-239"]=280,["240"]=282,["241"]=284,["242"]=285,["243"]=287,["244"]=288,["245"]=289,["246"]=290,["247-249"]=291,["250"]=300,["251"]=301,["252"]=302,["253"]=303,["254"]=304,["255-256"]=305,["257"]=308,["258-259"]=309,["260"]=312,["261-266"]=313,["267"]=321,["268-269"]=322,["270"]=324,["271-272"]=325,["273"]=327,["274"]=328,["275"]=329,["276-277"]=330,["278"]=332,["279"]=334,["280"]=335,["281-282"]=336,["283"]=339,["284-286"]=340}, "lib")
ktox_require("lib/Inventory")
ktox_require("lib/Planner")

---@param commandLine string
---@return string
function runCliCommand(commandLine)
    if commandLine == "" then
        return "Empty command. Try: list, pull, craft, deposit."
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
    if verb == "deposit" then
        return runDepositCommand(parts)
    end
    return "Unknown command: " .. tostring(verb) .. ". Try: list, pull, craft, trash, deposit."
end

LIST_USAGE = "Usage: list (--stocked|--craftable|--unavailable) (item-name-filter) (-h)" .. "\n" .. "  Lists items in the storage pool. Optional status flag narrows to one status; optional trailing text filters to item names containing that substring (e.g. " .. "\"" .. "list --stocked iron" .. "\"" .. ")."

PULL_USAGE = "Usage: pull <name> <qty> (--location=<name>) (-h)" .. "\n" .. "  Pulls <qty> of <name> from the storage pool into a pickup location. --location=<name> targets a specific named one; without it, this terminal\'s own inventory if it\'s itself configured as a pickup location, otherwise whichever pickup location is marked " .. "\"" .. "default" .. "\"" .. " in config/peripherals.json."

CRAFT_USAGE = "Usage: craft <name> <qty> (--location=<name>) (--fetch=false) (-h)" .. "\n" .. "  Crafts <qty> of <name>, chaining through intermediate jobs as needed, then pulls the result into a pickup location. Defaults to this terminal\'s own inventory if it\'s itself configured as a pickup location, otherwise the config/peripherals.json default; pass --location=<name> to target a specific named pickup location instead. Pass --fetch=false to craft without pulling the result out at all (leaves it in the storage pool)."

TRASH_USAGE = "Usage: trash <name> <qty> (-h)" .. "\n" .. "  Permanently destroys <qty> of <name> from the storage pool via the trash vault (dumped into lava)."

DEPOSIT_USAGE = "Usage: deposit (-h)" .. "\n" .. "  Deposits everything currently in THIS terminal\'s own inventory into the storage pool. Only works when this terminal is itself a turtle with job.aboveChest and job.belowChest configured in config/peripherals.json (same schema as a crafter turtle) - there\'s no way to deposit into a plain computer head, and there\'s rarely a reason to use this over just putting items straight into a storage vault."

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
        if not ktoxIsTurtle() then
            return 0
        end
        local chests = chestsFor(selfName)
        if chests == nil then
            return 0
        end
        return deliverViaSelfSuckUp(chests.above, itemName, qty)
    end
    return pullFromStoragePool(pickupVault, itemName, qty)
end

---@param parts table
---@return string
function runDepositCommand(parts)
    if isHelpFlag(parts) then
        return DEPOSIT_USAGE
    end
    if not ktoxIsTurtle() then
        return "This terminal isn\'t a turtle, so it has no inventory of its own to deposit from - put items directly into a storage vault instead."
    end
    local selfName = ktoxSelfPeripheralName()
    if selfName == "MISSING" then
        return "This terminal isn\'t wired onto the network under a discoverable peripheral name, so it can\'t resolve its own job.belowChest config."
    end
    local chests = chestsFor(selfName)
    if chests == nil then
        return "No aboveChest/belowChest configured for this terminal (job.aboveChest/job.belowChest in config/peripherals.json) - can\'t deposit."
    end
    local deposited = depositSelfInventory(chests.below)
    return "Deposited " .. tostring(deposited) .. " item(s) into storage."
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

