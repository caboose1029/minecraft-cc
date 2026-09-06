-- Hand-written, not ktox-generated. Small purpose-built wrappers around
-- CC:Tweaked native functions that return multiple Lua values — Kotlin
-- functions can only return one value, so these narrow each call down to
-- exactly what's needed, as a single Kotlin-representable value (a scalar,
-- or a comma-joined string for gpsLocate). See AGENTS.md and Gps.kt/
-- Turtle.kt for the Kotlin side of this binding.
--
-- Loaded once at boot by startup.lua, so these are plain globals by the
-- time any program runs.

function ktoxGpsLocate(timeout)
    local x, y, z = gps.locate(timeout)
    if x == nil then
        return nil
    end
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

function ktoxInspectName()
    local ok, data = turtle.inspect()
    if not ok then
        return nil
    end
    return data.name
end

function ktoxInspectUpName()
    local ok, data = turtle.inspectUp()
    if not ok then
        return nil
    end
    return data.name
end

function ktoxInspectDownName()
    local ok, data = turtle.inspectDown()
    if not ok then
        return nil
    end
    return data.name
end

-- turtle.getItemDetail() returns a whole table; narrow to just the name.
-- See common/Turtle.kt.
function ktoxGetItemName(slot)
    local detail = turtle.getItemDetail(slot)
    if detail == nil then
        return nil
    end
    return detail.name
end

-- Wraps http.get()'s response handle and fs.open()'s write handle, neither
-- of which Kotlin can model directly. See common/Http.kt.
function ktoxDownloadFile(url, path)
    local response = http.get(url, nil, true)
    if response == nil then
        return false
    end
    local data = response.readAll()
    response.close()
    if data == nil then
        return false
    end
    local file = fs.open(path, "wb")
    if file == nil then
        return false
    end
    file.write(data)
    file.close()
    return true
end

-- Monitor test-GUI helpers. Assumes exactly one monitor peripheral on the
-- network (peripheral.find("monitor") returns the first match) — fine for
-- a single-monitor test rig, not meant to generalize to multiple monitors.
-- See common/Monitor.kt for the Kotlin side of this binding.

function ktoxMonitorClear()
    local m = peripheral.find("monitor")
    if m == nil then
        return false
    end
    m.setTextScale(1)
    m.setBackgroundColor(colors.black)
    m.clear()
    return true
end

-- monitor.getSize() returns 2 values in Lua; packed as a comma-joined
-- string, same idiom as ktoxGpsLocate. See lib/Position.kt for the parsed
-- gps equivalent this mirrors.
function ktoxMonitorGetSize()
    local m = peripheral.find("monitor")
    if m == nil then
        return nil
    end
    local w, h = m.getSize()
    return tostring(w) .. "," .. tostring(h)
end

-- Draws a solid, centered-label rectangle "button" at (x, y), size (w, h),
-- filled with the given CC:Tweaked color constant.
function ktoxMonitorDrawButton(x, y, w, h, text, bgColor)
    local m = peripheral.find("monitor")
    if m == nil then
        return false
    end
    m.setBackgroundColor(bgColor)
    m.setTextColor(colors.white)
    local row = 0
    while row < h do
        m.setCursorPos(x, y + row)
        m.write(string.rep(" ", w))
        row = row + 1
    end
    local labelX = x + math.floor((w - #text) / 2)
    local labelY = y + math.floor(h / 2)
    m.setCursorPos(labelX, labelY)
    m.write(text)
    return true
end

-- Blocks until the monitor is touched; returns the touch coords packed as
-- a comma-joined "x,y" string (side is discarded — single-monitor rig).
function ktoxWaitMonitorTouch()
    local _, _, x, y = os.pullEvent("monitor_touch")
    return tostring(x) .. "," .. tostring(y)
end

-- Generic peripheral dispatch: calls a named method on a named peripheral
-- with a custom packed argument string, returning its single return
-- value JSON-encoded. See PLAN.md ("Generic peripheral-call shim") for
-- why this exists — built after Monitor's ad-hoc per-operation shim
-- pattern proved it wouldn't scale to every future peripheral operation.
-- Every caller this project has (redstone relay's setOutput/getInput)
-- returns at most one value, so no multi-return packing is needed here.
--
-- Arguments are NOT plain JSON array syntax on purpose: a Kotlin string
-- literal containing `[` or `]` transpiles to invalid Lua (a confirmed
-- ktox codegen bug — see AGENTS.md), so the Kotlin call site can never
-- safely build "[...]" text. Instead each argument is packed as
-- "<tag>:<value>" joined by "|" — tag is S (string), B (boolean), or N
-- (number), e.g. "S:right|B:true". Pass "" for no arguments.
--
-- Returns the sentinel string "MISSING" if the peripheral or method
-- doesn't exist (distinguishable from any real JSON value), "null" if the
-- call itself returned nothing, or the JSON encoding of the real result
-- otherwise. Kotlin side: common/Peripheral.kt.
function ktoxPeripheralCall(peripheralName, methodName, argsPacked)
    local p = peripheral.wrap(peripheralName)
    if p == nil then
        return "MISSING"
    end
    local method = p[methodName]
    if method == nil then
        return "MISSING"
    end
    local args = {}
    if argsPacked ~= "" then
        for piece in string.gmatch(argsPacked, "[^|]+") do
            local tag = string.sub(piece, 1, 1)
            local value = string.sub(piece, 3)
            if tag == "B" then
                args[#args + 1] = (value == "true")
            elseif tag == "N" then
                args[#args + 1] = tonumber(value)
            else
                args[#args + 1] = value
            end
        end
    end
    local result = method(table.unpack(args, 1, #args))
    if result == nil then
        return "null"
    end
    return textutils.serializeJSON(result)
end

-- Inventory helpers. Unlike the generic dispatch above, these need actual
-- looping over list()'s contents (find matching slots, sum counts) — that
-- can't be expressed as a single peripheral method call, so they stay as
-- purpose-built Lua rather than going through ktoxPeripheralCall. See
-- PLAN.md: the dispatcher unifies simple single-call operations; anything
-- needing real logic over a table's contents still needs its own
-- function, same as before, just narrower in scope. Kotlin side:
-- lib/Inventory.kt.

-- Sums how much of the named item exists across all of the given source
-- inventories (comma-joined peripheral names). Missing/unreachable
-- inventories are skipped rather than erroring, so one bad name in the
-- list doesn't zero out the whole count.
function ktoxInventoryCountNamed(sourceNamesCsv, itemName)
    local total = 0
    for sourceName in string.gmatch(sourceNamesCsv, "[^,]+") do
        local inv = peripheral.wrap(sourceName)
        if inv ~= nil then
            for _, item in pairs(inv.list()) do
                if item.name == itemName then
                    total = total + item.count
                end
            end
        end
    end
    return total
end

-- Whether the named inventory has nothing in it at all. Used to wait for
-- a feeder vault to actually drain before pushing the next ingredient in
-- a multi-ingredient job (see lib/Executor.kt's interleaved push) —
-- dumping several stacks of one ingredient before the other arrives can
-- clog the funnel/basin downstream (confirmed by observation in-game).
-- Treats a missing peripheral as "empty" (nothing to wait for).
function ktoxInventoryIsEmpty(vaultName)
    local inv = peripheral.wrap(vaultName)
    if inv == nil then
        return true
    end
    return next(inv.list()) == nil
end

-- Pulls up to `desired` total of the named item out of `fromName` (a
-- single source inventory) into `toName`, stopping early once enough has
-- been moved or the source runs out. Returns how many were actually
-- pulled.
function ktoxInventoryPullNamed(toName, fromName, itemName, desired)
    local dest = peripheral.wrap(toName)
    local source = peripheral.wrap(fromName)
    if dest == nil or source == nil then
        return 0
    end
    local pulled = 0
    for slot, item in pairs(source.list()) do
        if pulled >= desired then
            break
        end
        if item.name == itemName then
            pulled = pulled + dest.pullItems(fromName, slot, desired - pulled)
        end
    end
    return pulled
end

-- Same as ktoxInventoryPullNamed, but searches every inventory in
-- sourceNamesCsv (comma-joined) in order until `desired` is satisfied or
-- every source is exhausted — this is the actual pooled-storage pull used
-- by the `pull`/`craft` CLI commands, since storage is treated as one
-- logical resource spread across possibly many vaults (see PLAN.md).
-- Returns how many were actually pulled in total.
function ktoxInventoryPullNamedFromPool(toName, sourceNamesCsv, itemName, desired)
    local pulled = 0
    for sourceName in string.gmatch(sourceNamesCsv, "[^,]+") do
        if pulled >= desired then
            break
        end
        pulled = pulled + ktoxInventoryPullNamed(toName, sourceName, itemName, desired - pulled)
    end
    return pulled
end

-- Same as ktoxInventoryPullNamed, but lands the items in a SPECIFIC slot
-- of `toName` rather than wherever the destination's own pullItems
-- logic would put them — needed for a crafter turtle's crafting grid,
-- where placement matters (see PLAN.md "Crafter role"). Uses
-- pullItems's optional 4th (toSlot) argument.
function ktoxInventoryPullNamedToSlot(toName, toSlot, fromName, itemName, desired)
    local dest = peripheral.wrap(toName)
    local source = peripheral.wrap(fromName)
    if dest == nil or source == nil then
        return 0
    end
    local pulled = 0
    for slot, item in pairs(source.list()) do
        if pulled >= desired then
            break
        end
        if item.name == itemName then
            pulled = pulled + dest.pullItems(fromName, slot, desired - pulled, toSlot)
        end
    end
    return pulled
end

-- Pool version of ktoxInventoryPullNamedToSlot — searches every vault in
-- sourceNamesCsv until `desired` is satisfied or all are exhausted.
function ktoxInventoryPullNamedToSlotFromPool(toName, toSlot, sourceNamesCsv, itemName, desired)
    local pulled = 0
    for sourceName in string.gmatch(sourceNamesCsv, "[^,]+") do
        if pulled >= desired then
            break
        end
        pulled = pulled + ktoxInventoryPullNamedToSlot(toName, toSlot, sourceName, itemName, desired - pulled)
    end
    return pulled
end

-- Returns a newline-joined "name,count" row per distinct item found
-- across all of the given source inventories (comma-joined peripheral
-- names), aggregated by name. Used by the `list` CLI command. Empty
-- string if nothing found.
function ktoxInventoryListPooled(sourceNamesCsv)
    local totals = {}
    local order = {}
    for sourceName in string.gmatch(sourceNamesCsv, "[^,]+") do
        local inv = peripheral.wrap(sourceName)
        if inv ~= nil then
            for _, item in pairs(inv.list()) do
                if totals[item.name] == nil then
                    totals[item.name] = 0
                    order[#order + 1] = item.name
                end
                totals[item.name] = totals[item.name] + item.count
            end
        end
    end
    local lines = {}
    for i = 1, #order do
        local name = order[i]
        lines[#lines + 1] = name .. "," .. tostring(totals[name])
    end
    return table.concat(lines, "\n")
end

-- Config loading. All three files live under config/. Only
-- peripherals.json is player-owned (see PLAN.md) — ghfetch must never
-- fetch or overwrite it. job-types.json and resource-tree.json describe
-- the game's recipe graph, not per-world physical facts, so they ARE
-- fetched/overwritten on every ghfetch run, same as any program file. A
-- "job" descriptor is recursive: {type = "<kind>",
-- job = <nested job, optional>} — a feeder vault's job nests the machine
-- it feeds, e.g. {type="feeder", job={type="mechanical_press_depot"}}.
-- These loaders read + JSON-decode the whole file per call (small files,
-- called a few times per CLI command, not a hot loop) and narrow the
-- result to exactly what the caller needs, since ktox has no Map/JSON
-- parsing on the Kotlin side. Kotlin side: lib/Config.kt.

local function ktoxReadJSONFile(path)
    if not fs.exists(path) then
        return nil
    end
    local file = fs.open(path, "r")
    if file == nil then
        return nil
    end
    local data = file.readAll()
    file.close()
    if data == nil then
        return nil
    end
    return textutils.unserializeJSON(data)
end

-- Comma-joined peripheral names whose job.type == "storage". Empty
-- string if the config file is missing or none are configured.
function ktoxConfigStorageVaultNames()
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config == nil then
        return ""
    end
    local names = {}
    for name, entry in pairs(config) do
        if entry.type == "vault" and entry.job ~= nil and entry.job.type == "storage" then
            names[#names + 1] = name
        end
    end
    return table.concat(names, ",")
end

-- The feeder vault's peripheral name for the given job/machine type.
-- "MISSING" if none is configured (avoids returning Lua nil across the
-- binding — see common/Peripheral.kt's ktoxPeripheralCall for the same
-- sentinel convention).
function ktoxConfigFeederForJob(jobType)
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        for name, entry in pairs(config) do
            if entry.type == "vault" and entry.job ~= nil and entry.job.type == "feeder"
                and entry.job.job ~= nil and entry.job.job.type == jobType then
                return name
            end
        end
    end
    return "MISSING"
end

-- The redstone relay peripheral name + side controlling the given job/
-- machine type, packed as "relayName,side". "MISSING" if none configured.
function ktoxConfigRelayForJob(jobType)
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        for name, entry in pairs(config) do
            if entry.type == "relay" and entry.connections ~= nil then
                for side, connection in pairs(entry.connections) do
                    if connection.job ~= nil and connection.job.type == jobType then
                        return name .. "," .. side
                    end
                end
            end
        end
    end
    return "MISSING"
end

-- The direct conversion that produces `outputName`, from
-- config/resource-tree.json — searches every item's convertsTo list.
-- Packed as "inputName,jobType,inputCount,outputCount". "MISSING" if no
-- direct (single-hop) recipe produces it — multi-hop chains are phase 2
-- (see PLAN.md), this only ever finds one level.
-- config/resource-tree.json is a flat recipe list (not keyed by a single
-- input) so multi-ingredient recipes (brass: copper + zinc) and shaped
-- crafter recipes (a turtle-craft ingredient pinned to a specific grid
-- slot) both fit — see PLAN.md. Each recipe: {output, outputCount, job,
-- inputs: [{item, count, slot?}, ...]}. "slot" is only present for
-- crafter-kind recipes (a turtle's 3x3 crafting grid position);
-- omitted/nil for ordinary machine recipes.
--
-- Packed as "jobType|outputCount|item1,count1,slot1;item2,count2,slot2"
-- (slot blank when absent) rather than JSON, since Kotlin has no JSON
-- parser and no working growable collection to hold a variable number of
-- parsed inputs anyway (see AGENTS.md) — the Kotlin side re-splits this
-- string per-access instead of materializing a parsed list. Comma (not
-- colon) separates the fields within one input, since an item ID's own
-- namespace separator IS a colon ("minecraft:copper_ingot") — confirmed
-- live: colon-delimited packing broke immediately on the first real item
-- name, since splitting "minecraft:copper_ingot:1:" on ":" doesn't give
-- back 3 fields, it gives back 4. "MISSING" if no recipe produces this
-- output at all.
function ktoxConfigProducesLookup(outputName)
    local tree = ktoxReadJSONFile("config/resource-tree.json")
    if tree ~= nil and tree.recipes ~= nil then
        for _, recipe in pairs(tree.recipes) do
            if recipe.output == outputName and recipe.inputs ~= nil then
                local inputParts = {}
                for _, input in pairs(recipe.inputs) do
                    local slot = ""
                    if input.slot ~= nil then
                        slot = tostring(input.slot)
                    end
                    inputParts[#inputParts + 1] = input.item .. "," .. tostring(input.count) .. "," .. slot
                end
                return recipe.job .. "|" .. tostring(recipe.outputCount) .. "|" .. table.concat(inputParts, ";")
            end
        end
    end
    return "MISSING"
end

-- The execution kind for a job type ("machine" or "crafter"), from
-- config/job-types.json's optional "kind" field. Defaults to "machine"
-- when absent (every job type before crafty turtles existed).
function ktoxConfigJobKind(jobType)
    local config = ktoxReadJSONFile("config/job-types.json")
    if config ~= nil and config[jobType] ~= nil and config[jobType].kind ~= nil then
        return config[jobType].kind
    end
    return "machine"
end

-- The pickup vault's peripheral name (job.type == "pickup") — where
-- `pull`/`craft` results are pushed for a player to grab, since a turtle
-- targeting its OWN inventory as a named peripheral is not reliably
-- supported by CC:Tweaked (see PLAN.md's open items). "MISSING" if none
-- configured.
function ktoxConfigPickupVault()
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        for name, entry in pairs(config) do
            if entry.type == "vault" and entry.job ~= nil and entry.job.type == "pickup" then
                return name
            end
        end
    end
    return "MISSING"
end

-- The trash vault's peripheral name (job.type == "trash") — a vault that
-- dumps whatever's pushed into it into lava, permanently destroying it.
-- Functionally identical wiring to a feeder vault; semantically very
-- different (irreversible), so it's never targeted by anything except an
-- explicit `trash` CLI command — it has no entry in resource-tree.json
-- and nothing routes to it automatically. "MISSING" if none configured.
function ktoxConfigTrashVault()
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        for name, entry in pairs(config) do
            if entry.type == "vault" and entry.job ~= nil and entry.job.type == "trash" then
                return name
            end
        end
    end
    return "MISSING"
end

-- The crafty turtle's peripheral name for the given job type
-- (top-level "type": "crafter", not a vault — see PLAN.md "Crafter
-- role"). Used to push ingredients into its crafting-grid slots.
-- "MISSING" if none configured.
function ktoxConfigCrafterForJob(jobType)
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        for name, entry in pairs(config) do
            if entry.type == "crafter" and entry.job ~= nil and entry.job.type == jobType then
                return name
            end
        end
    end
    return "MISSING"
end

-- Builds the full item catalog for the `list` CLI command: every item
-- either currently stocked in the pool, or mentioned anywhere in
-- config/resource-tree.json, classified as "stocked" (count > 0 in the
-- pool), "craftable" (not stocked, but its direct conversion's input IS
-- stocked), or "unavailable" (neither). Optionally filtered to one
-- status ("" = all) and/or a substring of the item name ("" = no
-- filter). Returns newline-joined "status,name,count" rows (count is 0
-- for craftable/unavailable). Kotlin side: lib/Cli.kt.
function ktoxListCatalog(sourceNamesCsv, filter, substring)
    local totals = {}
    local order = {}
    local function noteItem(name)
        if totals[name] == nil then
            totals[name] = 0
            order[#order + 1] = name
        end
    end

    for sourceName in string.gmatch(sourceNamesCsv, "[^,]+") do
        local inv = peripheral.wrap(sourceName)
        if inv ~= nil then
            for _, item in pairs(inv.list()) do
                noteItem(item.name)
                totals[item.name] = totals[item.name] + item.count
            end
        end
    end

    local tree = ktoxReadJSONFile("config/resource-tree.json")
    local recipeFor = {}
    if tree ~= nil and tree.recipes ~= nil then
        for _, recipe in pairs(tree.recipes) do
            noteItem(recipe.output)
            if recipe.inputs ~= nil then
                for _, input in pairs(recipe.inputs) do
                    noteItem(input.item)
                end
                if recipeFor[recipe.output] == nil then
                    recipeFor[recipe.output] = recipe
                end
            end
        end
    end

    -- "craftable" (one hop only - see PLAN.md's known gap) needs EVERY
    -- input of the recipe to be stocked, not just one, now that recipes
    -- can have multiple ingredients (brass: copper AND zinc).
    local function allInputsStocked(recipe)
        for _, input in pairs(recipe.inputs) do
            local have = totals[input.item]
            if have == nil or have <= 0 then
                return false
            end
        end
        return true
    end

    local lines = {}
    for i = 1, #order do
        local name = order[i]
        if substring == "" or string.find(name, substring, 1, true) ~= nil then
            local count = totals[name]
            local status
            if count > 0 then
                status = "stocked"
            elseif recipeFor[name] ~= nil and allInputsStocked(recipeFor[name]) then
                status = "craftable"
            else
                status = "unavailable"
            end
            if filter == "" or filter == status then
                lines[#lines + 1] = status .. "," .. name .. "," .. tostring(count)
            end
        end
    end
    return table.concat(lines, "\n")
end

-- The configured timeout (in seconds) for a job type, from
-- config/job-types.json's optional "timeoutSeconds" field. Returns -1 if
-- not configured (job type missing, file missing, or field absent) —
-- Kotlin falls back to a sensible default in that case (see
-- lib/Executor.kt's DEFAULT_JOB_TIMEOUT_SECONDS).
function ktoxConfigJobTimeoutSeconds(jobType)
    local config = ktoxReadJSONFile("config/job-types.json")
    if config ~= nil and config[jobType] ~= nil and config[jobType].timeoutSeconds ~= nil then
        return config[jobType].timeoutSeconds
    end
    return -1
end

-- Rednet helpers. See PLAN.md's "Terminal roles" section for the
-- protocol this supports (head/secondary, role collision detection,
-- command forwarding). rednet.open needs a peripheral/side NAME, but
-- Kotlin code shouldn't need to know or care which modem that is — this
-- finds the first one present, wired or wireless (rednet itself works
-- over either, see PLAN.md).
--
-- rednet.receive returns THREE values (senderId, message, protocol) —
-- Kotlin can't express that directly, so rather than pack them into one
-- delimited string (risky: command/response text can contain almost any
-- character, so no safe delimiter exists), the three values are cached
-- here and exposed via three separate single-value getters. Not
-- reentrant, but this project only ever has one receive in flight per
-- computer at a time. Kotlin side: common/Rednet.kt.

local ktoxRednetLastSenderIdValue = nil
local ktoxRednetLastMessageValue = nil
local ktoxRednetLastProtocolValue = nil

function ktoxRednetOpenAny()
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" then
            rednet.open(name)
            return true
        end
    end
    return false
end

-- Listens for a message on ANY protocol (the head needs this — it has
-- to handle more than one message kind on one inbound channel).
function ktoxRednetReceiveAny(timeoutSeconds)
    local senderId, message, protocol = rednet.receive(timeoutSeconds)
    if senderId == nil then
        return false
    end
    ktoxRednetLastSenderIdValue = senderId
    ktoxRednetLastMessageValue = message
    ktoxRednetLastProtocolValue = protocol
    return true
end

-- Listens for a message on one specific protocol only — used wherever
-- the expected reply kind is already known (a role reply, a command
-- result), to avoid an unrelated message being mistaken for it.
function ktoxRednetReceiveProtocol(protocol, timeoutSeconds)
    local senderId, message = rednet.receive(protocol, timeoutSeconds)
    if senderId == nil then
        return false
    end
    ktoxRednetLastSenderIdValue = senderId
    ktoxRednetLastMessageValue = message
    ktoxRednetLastProtocolValue = protocol
    return true
end

function ktoxRednetLastSenderId()
    return ktoxRednetLastSenderIdValue
end

function ktoxRednetLastMessage()
    return ktoxRednetLastMessageValue
end

function ktoxRednetLastProtocol()
    return ktoxRednetLastProtocolValue
end

-- Per-machine role persistence (see TerminalSetup.kt / PLAN.md). A plain
-- text file rather than the `settings` API — this project already has a
-- proven fs.open/readAll/write/close idiom (ktoxReadJSONFile,
-- ktoxDownloadFile) and no reason to introduce a second, unverified
-- persistence mechanism just for one string.

function ktoxReadRoleFile()
    if not fs.exists("role.txt") then
        return ""
    end
    local file = fs.open("role.txt", "r")
    if file == nil then
        return ""
    end
    local data = file.readAll()
    file.close()
    if data == nil then
        return ""
    end
    return data
end

function ktoxWriteRoleFile(role)
    local file = fs.open("role.txt", "w")
    if file == nil then
        return false
    end
    file.write(role)
    file.close()
    return true
end

-- Every configured passive feeder (job.type == "passive" — a vault that
-- tries to always hold a full stack of one item, sitting above a
-- deployer, see PLAN.md). Returns newline-joined
-- "vaultName,item,lowWatermark,highWatermark" rows, one per configured
-- passive feeder. Empty string if none configured.
function ktoxConfigPassiveFeeders()
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config == nil then
        return ""
    end
    local lines = {}
    for name, entry in pairs(config) do
        if entry.type == "vault" and entry.job ~= nil and entry.job.type == "passive" then
            lines[#lines + 1] = name .. "," .. entry.job.item .. "," ..
                tostring(entry.job.lowWatermark) .. "," .. tostring(entry.job.highWatermark)
        end
    end
    return table.concat(lines, "\n")
end
