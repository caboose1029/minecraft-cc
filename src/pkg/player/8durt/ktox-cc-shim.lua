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

-- Config loading. All three files live under config/ and are 100%
-- player-maintained (see PLAN.md) — ghfetch must never fetch or
-- overwrite them. A "job" descriptor is recursive: {type = "<kind>",
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
function ktoxConfigProducesLookup(outputName)
    local tree = ktoxReadJSONFile("config/resource-tree.json")
    if tree ~= nil then
        for inputName, entry in pairs(tree) do
            if entry.convertsTo ~= nil then
                for _, conversion in pairs(entry.convertsTo) do
                    if conversion.output == outputName then
                        return inputName .. "," .. conversion.job .. "," ..
                            tostring(conversion.inputCount) .. "," .. tostring(conversion.outputCount)
                    end
                end
            end
        end
    end
    return "MISSING"
end
