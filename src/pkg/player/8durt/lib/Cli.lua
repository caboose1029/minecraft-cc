-- package: lib

require("ktox-lib")
ktox_sourcemap_traceback(debug and debug.getinfo and (debug.getinfo(1) or {}).short_src or "", "lib/Cli.kt", {["1-10"]=1,["11"]=19,["12-13"]=20,["14"]=22,["15"]=23,["16"]=24,["17-18"]=25,["19"]=27,["20-21"]=28,["22"]=30,["23-24"]=31,["25"]=33,["26-27"]=34,["28-43"]=36,["44-49"]=53,["50"]=65,["51-52"]=66,["53"]=68,["54"]=69,["55-56"]=70,["57-63"]=72,["64"]=81,["65"]=82,["66"]=83,["67"]=84,["68-69"]=85,["70-71"]=87,["72-78"]=89,["79"]=93,["80"]=94,["81"]=95,["82"]=96,["83-84"]=97,["85-86"]=99,["87-92"]=101,["93"]=107,["94-95"]=108,["96-101"]=110,["102"]=114,["103-104"]=115,["105"]=117,["106"]=118,["107"]=119,["108"]=120,["109"]=121,["110"]=122,["111"]=123,["112-113"]=124,["114"]=126,["115-116"]=127,["117"]=128,["118"]=129,["119-122"]=130,["123"]=133,["124-125"]=134,["126"]=137,["127"]=138,["128-129"]=139,["130"]=147,["131"]=148,["132"]=149,["133-134"]=150,["135"]=152,["136"]=153,["137-138"]=154,["139"]=156,["140"]=157,["141"]=158,["142"]=159,["143"]=160,["144"]=161,["145"]=162,["146-147"]=163,["148-149"]=165,["150-151"]=167,["152-153"]=169,["154-159"]=171,["160"]=175,["161-162"]=176,["163"]=178,["164-165"]=179,["166"]=181,["167"]=182,["168"]=183,["169-170"]=184,["171"]=186,["172"]=188,["173"]=189,["174"]=190,["175-176"]=191,["177"]=194,["178-183"]=195,["184"]=204,["185-186"]=205,["187"]=207,["188-189"]=208,["190"]=210,["191"]=211,["192"]=212,["193-194"]=213,["195"]=215,["196"]=217,["197"]=218,["198"]=220,["199"]=221,["200"]=222,["201"]=223,["202-204"]=224,["205"]=228,["206"]=230,["207-208"]=231,["209"]=234,["210-215"]=235,["216"]=243,["217-218"]=244,["219"]=246,["220-221"]=247,["222"]=249,["223"]=250,["224"]=251,["225-226"]=252,["227"]=254,["228"]=256,["229"]=257,["230-231"]=258,["232"]=261,["233-235"]=262}, "lib")
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

