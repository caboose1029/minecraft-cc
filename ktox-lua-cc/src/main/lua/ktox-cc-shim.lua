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

-- Same GET as ktoxDownloadFile, but returns the response body directly
-- instead of writing it to disk — for a small text file whose CONTENT
-- is needed immediately (e.g. GhFetch's own file manifest), not just its
-- bytes saved somewhere. "MISSING" on any failure (matches this
-- codebase's existing missing-value sentinel convention).
function ktoxDownloadFileText(url)
    local response = http.get(url, nil, true)
    if response == nil then
        return "MISSING"
    end
    local data = response.readAll()
    response.close()
    if data == nil then
        return "MISSING"
    end
    return data
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

-- Display primitives for the dashboard UI (see PLAN.md's "Dashboard UI"
-- section) — this computer's own term ONLY. The main use case is a
-- turtle's or pocket computer's own screen, not an external Monitor
-- peripheral (a monitor-driven dashboard, if built, is a separate
-- program later — pocket computers can't carry a Monitor peripheral at
-- all, so it was never going to be one codepath anyway). Named
-- ktoxDisplay* rather than ktoxTerm* on purpose: keeps the same call
-- shape lib/Dashboard.kt already uses, in case that rendering/hit-test
-- code ever gets reused against a different backend later.
function ktoxDisplayInit()
    ktoxDisplayClear()
    return true
end

-- getSize() returns 2 values in Lua; packed as a comma-joined string,
-- same idiom as ktoxGpsLocate.
function ktoxDisplayGetSize()
    local w, h = term.getSize()
    return tostring(w) .. "," .. tostring(h)
end

function ktoxDisplayClear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    return true
end

-- Fills a (w, h) rectangle at (x, y) with bgColor, then writes `text` in
-- textColor on its vertically-centered row, left-aligned, truncated to
-- fit `w`. Pass "" for text to draw a plain filled rectangle (row/tab
-- backgrounds, highlight bars) with no label. This is the ONE drawing
-- primitive the dashboard uses for every visual element (tabs, rows,
-- buttons, the checkbox) — deliberately not specialized per element
-- kind, so there's exactly one code path to get right.
function ktoxDisplayFillRect(x, y, w, h, bgColor, textColor, text)
    term.setBackgroundColor(bgColor)
    term.setTextColor(textColor)
    local row = 0
    while row < h do
        term.setCursorPos(x, y + row)
        term.write(string.rep(" ", w))
        row = row + 1
    end
    if text ~= "" then
        local label = text
        if #label > w then
            label = string.sub(label, 1, w)
        end
        local labelY = y + math.floor(h / 2)
        term.setCursorPos(x, labelY)
        term.setBackgroundColor(bgColor)
        term.setTextColor(textColor)
        term.write(label)
    end
    return true
end

-- Blocks until this computer's own screen is clicked (while its GUI is
-- open in-game - same event a real mouse click in the terminal window
-- fires). Returns the click coords packed as "x,y" (mouse button
-- discarded - every button is treated the same here).
function ktoxDisplayWaitTouch()
    local _, _, x, y = os.pullEvent("mouse_click")
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


-- Moves EVERYTHING out of `fromName` into `toName`, regardless of item
-- identity (no itemName filter, unlike every other transfer helper here)
-- — for emptying a crafter's dedicated staging/output chest, either
-- proactively before a new job (clearing stale leftovers) or to collect
-- a finished craft result. Both `fromName`/`toName` are ordinary
-- inventory peripherals (chests/vaults) here, never a turtle — this is
-- the already-proven dest.pullItems idiom, no new risk. Returns how many
-- stacks were moved (not item count - `desired` isn't meaningful when
-- draining everything).
function ktoxInventoryDrainAll(fromName, toName)
    local dest = peripheral.wrap(toName)
    local source = peripheral.wrap(fromName)
    if dest == nil or source == nil then
        return 0
    end
    local moved = 0
    for slot, item in pairs(source.list()) do
        local ok = dest.pullItems(fromName, slot)
        if ok ~= nil and ok > 0 then
            moved = moved + 1
        end
    end
    return moved
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
-- These loaders narrow the result to exactly what the caller needs,
-- since ktox has no Map/JSON parsing on the Kotlin side. Kotlin side:
-- lib/Config.kt.
--
-- Cached in memory per boot, not re-read from disk on every call. With
-- the original always-re-parse version, every single lookup (findRecipe,
-- ktoxConfigFeederForJob, ...) re-read + re-JSON-decoded the WHOLE file
-- from scratch — fine at a couple dozen recipes, but a real, growing
-- cost as resource-tree.json scales into the hundreds, especially since
-- the planner (ensureStocked) calls these lookups repeatedly while
-- walking one chain. These files don't change during a running session
-- (ghfetch/manual edits only happen between boots), so caching the
-- parsed table is safe with no staleness risk — a reboot always gets a
-- fresh read.
local ktoxJSONCache = {}

local function ktoxReadJSONFile(path)
    if ktoxJSONCache[path] ~= nil then
        return ktoxJSONCache[path]
    end
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
    local parsed = textutils.unserializeJSON(data)
    ktoxJSONCache[path] = parsed
    return parsed
end

-- job-types.json/resource-tree.json moved from JSON to hand-authored Lua
-- data files (config/job-types.lua, config/resource-tree.lua) once their
-- content grew into the hundreds of entries: textutils.unserializeJSON is
-- a hand-written Lua parser walking the text byte by byte, while a plain
-- `return { ... }` Lua file is loaded by Lua's native chunk compiler —
-- much cheaper at this size, and there's no "too long without yielding"
-- risk from parsing one huge JSON blob synchronously. peripherals.json
-- stays JSON since it's the one file players actually hand-edit — a
-- format a player edits by hand should stay JSON; a data file this repo
-- generates and ghfetch overwrites wholesale has no such reason to.
-- Cached the same way and for the same reason as ktoxReadJSONFile above.
local ktoxLuaDataCache = {}

local function ktoxReadLuaDataFile(path)
    if ktoxLuaDataCache[path] ~= nil then
        return ktoxLuaDataCache[path]
    end
    if not fs.exists(path) then
        return nil
    end
    local loaded = dofile(path)
    if loaded == nil then
        return nil
    end
    ktoxLuaDataCache[path] = loaded
    return loaded
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

-- Comma-joined peripheral names whose job.type == "deposit_chest" - a
-- plain chest/vault a player physically loads by hand, opportunistically
-- swept into the storage pool by the head (see lib/DepositChest.kt) the
-- same way passive feeders/farms are checked after each command.
-- Deliberately a distinct job type from the turtle-only `deposit` CLI
-- command (which sweeps a turtle's OWN inventory via job.aboveChest/
-- belowChest) - this one has no turtle involved at all, just an ordinary
-- vault-to-vault drain. Empty string if none configured.
function ktoxConfigDepositVaults()
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config == nil then
        return ""
    end
    local names = {}
    for name, entry in pairs(config) do
        if entry.type == "vault" and entry.job ~= nil and entry.job.type == "deposit_chest" then
            names[#names + 1] = name
        end
    end
    return table.concat(names, ",")
end

-- Optional Stockpile Switch (Advanced Peripherals) wired to a storage
-- vault, packed as "relayName,side" - job.fullSwitch = {"relay": ...,
-- "side": ...} on that vault's OWN peripherals.json entry (same
-- "physically dedicated, so it's a field not a top-level entry" reasoning
-- as job.aboveChest/belowChest). "MISSING" if not configured for this
-- vault.
function ktoxConfigFullSwitchFor(vaultName)
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        local entry = config[vaultName]
        if entry ~= nil and entry.job ~= nil and entry.job.fullSwitch ~= nil
            and entry.job.fullSwitch.relay ~= nil and entry.job.fullSwitch.side ~= nil then
            return entry.job.fullSwitch.relay .. "," .. entry.job.fullSwitch.side
        end
    end
    return "MISSING"
end

-- Reads `vaultName`'s configured Stockpile Switch (see
-- ktoxConfigFullSwitchFor) through its redstone relay, if one is wired
-- up. Returns true/false if a switch is configured and its relay
-- answered, nil if no switch is configured (or the relay didn't answer)
-- - nil is a real third state here (see ktoxLeastFullStorageVault: an
-- unconfigured/unreachable vault is never treated as "full" just because
-- we couldn't ask). ASSUMPTION, unverified in-game: a HIGH signal means
-- the switch considers the vault full (its usual "sound an alarm/stop a
-- belt when full" wiring convention) - flip this if a build's switch is
-- configured to read the opposite way.
function ktoxStockpileSwitchIsFull(vaultName)
    local raw = ktoxConfigFullSwitchFor(vaultName)
    if raw == "MISSING" then
        return nil
    end
    local parts = {}
    for piece in string.gmatch(raw, "[^,]+") do
        parts[#parts + 1] = piece
    end
    local relay = peripheral.wrap(parts[1])
    if relay == nil or relay.getInput == nil then
        return nil
    end
    local ok, result = pcall(relay.getInput, parts[2])
    if not ok then
        return nil
    end
    return result == true
end

-- How full `vaultName` is, as a 0..1 fraction of occupied slots over its
-- total slot count (inv.size()) - a slot-based proxy rather than raw item
-- count, so a vault holding a few full stacks of a high-stack-size item
-- doesn't read as "empty" next to one holding many stacks of a
-- low-stack-size item. Returns 1 (treated as "full", so it's never
-- preferred) for an unreachable peripheral or one reporting zero/no
-- slots at all, rather than crashing or dividing by zero.
function ktoxVaultFullFraction(vaultName)
    local inv = peripheral.wrap(vaultName)
    if inv == nil or inv.size == nil then
        return 1
    end
    local total = inv.size()
    if total == nil or total <= 0 then
        return 1
    end
    local used = 0
    for _ in pairs(inv.list()) do
        used = used + 1
    end
    return used / total
end

-- Picks which of the given storage vaults (comma-joined peripheral
-- names) a new push should land in - the load-balancing counterpart to
-- always dumping into firstStorageVaultName() (see PLAN.md's "Vaults"
-- section - "spreading pushes toward the emptiest vault" was flagged
-- there and deferred). Prefers the least-full vault (ktoxVaultFullFraction)
-- among whichever ones a configured Stockpile Switch does NOT report as
-- full (ktoxStockpileSwitchIsFull); a vault with no switch configured is
-- always a normal candidate (nil ~= true). Falls back to the overall
-- least-full vault if every single one is switch-flagged full, rather
-- than returning "MISSING" and stalling production entirely - a
-- deliberate "somewhere is better than nowhere" choice. "MISSING" only
-- when sourceNamesCsv names no reachable vault at all.
function ktoxLeastFullStorageVault(sourceNamesCsv)
    local best, bestFraction = nil, nil
    local bestNonFull, bestNonFullFraction = nil, nil
    for name in string.gmatch(sourceNamesCsv, "[^,]+") do
        local fraction = ktoxVaultFullFraction(name)
        if best == nil or fraction < bestFraction then
            best = name
            bestFraction = fraction
        end
        if ktoxStockpileSwitchIsFull(name) ~= true then
            if bestNonFull == nil or fraction < bestNonFullFraction then
                bestNonFull = name
                bestNonFullFraction = fraction
            end
        end
    end
    if bestNonFull ~= nil then
        return bestNonFull
    end
    if best ~= nil then
        return best
    end
    return "MISSING"
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

-- Scores a candidate recipe against the current best (nil if this is the
-- first candidate seen), returning the winner. Shared by
-- ktoxConfigProducesLookup and ktoxListCatalog so "which recipe is
-- preferred for this output" can never disagree between what `craft`
-- executes and what `list --craftable` reports. See
-- ktoxConfigProducesLookup's own comment for the actual preference rule
-- (explicit "priority" field beats everything; otherwise lowest total
-- input count per unit of output).
local function ktoxPreferRecipe(candidate, currentBest)
    if currentBest == nil then
        return candidate
    end
    local function scoreOf(recipe)
        local totalInputCount = 0
        for _, input in pairs(recipe.inputs) do
            totalInputCount = totalInputCount + input.count
        end
        if recipe.priority ~= nil then
            return recipe.priority, true
        end
        return totalInputCount / recipe.outputCount, false
    end
    local candidateScore, candidateHasPriority = scoreOf(candidate)
    local bestScore, bestHasPriority = scoreOf(currentBest)
    if candidateHasPriority and not bestHasPriority then
        return candidate
    end
    if candidateHasPriority == bestHasPriority and candidateScore < bestScore then
        return candidate
    end
    return currentBest
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
--
-- More than one recipe can list the same output (e.g. Andesite Alloy:
-- andesite+iron nugget, OR andesite+zinc nugget — both real, both in
-- Create's own data) — this picks the best ONE rather than returning
-- every candidate, since the Kotlin side only ever needs a single
-- Recipe to execute. "Best" is an explicit optional "priority" field on
-- a recipe (lower wins) if ANY candidate sets one — human intent beats
-- guessing; otherwise falls back to total input count per unit of
-- output (fewer raw items consumed per result = preferred), a
-- reasonable default efficiency proxy, not a claim of universal
-- correctness (it can't account for processing time, power cost, or
-- anything else "efficient" might mean to a given recipe).
function ktoxConfigProducesLookup(outputName)
    local tree = ktoxReadLuaDataFile("config/resource-tree.lua")
    if tree == nil or tree.recipes == nil then
        return "MISSING"
    end

    local best = nil
    for _, recipe in pairs(tree.recipes) do
        if recipe.output == outputName and recipe.inputs ~= nil then
            best = ktoxPreferRecipe(recipe, best)
        end
    end

    if best == nil then
        return "MISSING"
    end
    local inputParts = {}
    for _, input in pairs(best.inputs) do
        local slot = ""
        if input.slot ~= nil then
            slot = tostring(input.slot)
        end
        inputParts[#inputParts + 1] = input.item .. "," .. tostring(input.count) .. "," .. slot
    end
    return best.job .. "|" .. tostring(best.outputCount) .. "|" .. table.concat(inputParts, ";")
end

-- The execution kind for a job type ("machine" or "crafter"), from
-- config/job-types.json's optional "kind" field. Defaults to "machine"
-- when absent (every job type before crafty turtles existed).
function ktoxConfigJobKind(jobType)
    local config = ktoxReadLuaDataFile("config/job-types.lua")
    if config ~= nil and config[jobType] ~= nil and config[jobType].kind ~= nil then
        return config[jobType].kind
    end
    return "machine"
end

-- `itemName`'s max stack size, from config/stack-sizes.lua's overrides -
-- 64 (the default for most items) if it's not listed there at all. Used
-- by the dashboard's per-stack up/down buttons (lib/Dashboard.kt).
function ktoxItemStackSize(itemName)
    local overrides = ktoxReadLuaDataFile("config/stack-sizes.lua")
    if overrides ~= nil and overrides[itemName] ~= nil then
        return overrides[itemName]
    end
    return 64
end

-- Every configured farm (job-types.json entries with kind == "farm" — an
-- always-running external process, gated on/off by a relay based on
-- watermarks on its own output(s) in the storage pool, see PLAN.md).
-- Packed the same way as a recipe's inputs (comma within one watermark,
-- semicolon between watermarks, since an item ID's own colon rules out
-- colon as a field separator — see the resource-tree packing comment
-- above): "jobType|item1,low1,high1;item2,low2,high2". Newline-joined,
-- one row per farm. Empty string if none configured.
function ktoxConfigAllFarms()
    local config = ktoxReadLuaDataFile("config/job-types.lua")
    if config == nil then
        return ""
    end
    local lines = {}
    for jobType, entry in pairs(config) do
        if entry.kind == "farm" and entry.watermarks ~= nil then
            local parts = {}
            for _, watermark in pairs(entry.watermarks) do
                parts[#parts + 1] = watermark.item .. "," .. tostring(watermark.lowWatermark) .. "," ..
                    tostring(watermark.highWatermark)
            end
            lines[#lines + 1] = jobType .. "|" .. table.concat(parts, ";")
        end
    end
    return table.concat(lines, "\n")
end

-- Pickup vaults (job.type == "pickup") — where `pull`/`craft` results
-- land for a player (or turtle) to grab. Any addressable inventory
-- peripheral works here, including a turtle's own inventory — see
-- PLAN.md's "Vaults" section for why the old "turtle-as-peripheral-
-- target is unreliable" caveat was dropped (it was never actually
-- verified, just assumed). A peripherals.json world can configure
-- several named pickup locations plus at most one "default": true one —
-- see PLAN.md's "CLI" section for how `pull`/`craft` pick between them.

-- The pickup vault labeled with this exact "name" (job.name), job.type
-- == "pickup". "MISSING" if none matches.
function ktoxConfigPickupVaultByName(locationName)
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        for name, entry in pairs(config) do
            if entry.type == "vault" and entry.job ~= nil and entry.job.type == "pickup"
                and entry.job.name == locationName then
                return name
            end
        end
    end
    return "MISSING"
end

-- The pickup vault marked "default": true (job.type == "pickup").
-- Missing/absent "default" is falsy in Lua, so an entry with no
-- "default" field at all is correctly never picked here — matches
-- "defined as false if it's missing" from PLAN.md with no extra
-- handling needed. "MISSING" if none is marked default.
function ktoxConfigPickupVaultDefault()
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        for name, entry in pairs(config) do
            if entry.type == "vault" and entry.job ~= nil and entry.job.type == "pickup"
                and entry.job.default == true then
                return name
            end
        end
    end
    return "MISSING"
end

-- Every distinct "name" label among job.type == "pickup" entries,
-- comma-joined — for the dashboard UI's location selector (see PLAN.md's
-- "Dashboard UI" section). A pickup vault with no "name" field is
-- skipped (it can never be targeted by name anyway - only reachable as
-- the self location or the "default" one). "" if none are named.
function ktoxConfigPickupVaultNames()
    local config = ktoxReadJSONFile("config/peripherals.json")
    local names = {}
    if config ~= nil then
        for _, entry in pairs(config) do
            if entry.type == "vault" and entry.job ~= nil and entry.job.type == "pickup"
                and entry.job.name ~= nil then
                names[#names + 1] = entry.job.name
            end
        end
    end
    return table.concat(names, ",")
end

-- Whether `peripheralName` itself is configured as a pickup vault
-- (job.type == "pickup") in peripherals.json — used so a head/secondary
-- terminal that IS itself a pickup location (see ktoxSelfPeripheralName)
-- can prefer its own inventory over the configured default.
function ktoxIsConfiguredPickupLocation(peripheralName)
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        local entry = config[peripheralName]
        if entry ~= nil and entry.type == "vault" and entry.job ~= nil and entry.job.type == "pickup" then
            return true
        end
    end
    return false
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

-- This computer/turtle's OWN peripheral name, as seen by the rest of the
-- wired network — so a head/secondary terminal that's also wired in as a
-- pickup vault (a turtle with its own inventory) can find its own
-- peripherals.json entry without it being hand-configured per machine.
-- Works by asking every "computer"/"turtle"-type peripheral on the
-- network for its ID (CC:Tweaked's documented "computer" peripheral —
-- https://tweaked.cc/peripheral/computer.html — exposes getID()) and
-- comparing against os.getComputerID(). UNVERIFIED IN-GAME: never
-- confirmed with two real networked machines that a machine's own wired
-- modem actually exposes itself this way, or that getID() answers with
-- this machine's own ID rather than erroring/being absent — see PLAN.md
-- "Known open items". "MISSING" if no match is found (no modem, not
-- networked, or the assumption above turns out wrong) — every call site
-- must treat that as "no self pickup location", not an error.
function ktoxSelfPeripheralName()
    local myId = os.getComputerID()
    for _, name in ipairs(peripheral.getNames()) do
        local ptype = peripheral.getType(name)
        if ptype == "computer" or ptype == "turtle" then
            local p = peripheral.wrap(name)
            if p ~= nil and p.getID ~= nil and p.getID() == myId then
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

-- The chest-above/chest-below peripheral names dedicated to
-- `peripheralName` (job.aboveChest / job.belowChest on that entry's OWN
-- peripherals.json entry — physically dedicated infrastructure for one
-- turtle, not pooled storage, so it doesn't get its own top-level
-- entries the way vaults do). Shared schema for two callers: the
-- crafter (programs/Crafter.kt) and a turtle-based pickup terminal's
-- self-suckUp/self-deposit path (lib/Cli.kt). Packed as "above,below".
-- "MISSING" if either is absent.
function ktoxConfigChestsFor(peripheralName)
    local config = ktoxReadJSONFile("config/peripherals.json")
    if config ~= nil then
        local entry = config[peripheralName]
        if entry ~= nil and entry.job ~= nil and entry.job.aboveChest ~= nil and entry.job.belowChest ~= nil then
            return entry.job.aboveChest .. "," .. entry.job.belowChest
        end
    end
    return "MISSING"
end

-- True only when this computer itself is a turtle (global `turtle` is
-- non-nil) - guards any physical turtle.* call site so it's never
-- reached on a plain computer head.
function ktoxIsTurtle()
    return turtle ~= nil
end

-- Caches the most recent crafter-job failure reason (from a
-- VAULT_CRAFTER_FAILURE_PROTOCOL reply, or a head-side check like
-- "couldn't stage ingredients" / "no chests configured") across the
-- runCrafterJob/ensureStocked call chain, so runCraftCommand (lib/Cli.kt)
-- can surface a SPECIFIC reason in the final result string instead of a
-- generic "0 produced" — without threading a new return type through
-- ensureStocked's whole recursive call tree. Same "cache one value in a
-- shim local, expose via getter/setter" idiom already proven for
-- ktoxRednetLast* above. Cleared explicitly at the start of each `craft`
-- command (see clearLastCrafterFailure in lib/Cli.kt) so a stale failure
-- from an earlier, unrelated command can't leak into a later one.
local ktoxLastCrafterFailureValue = ""

function ktoxSetLastCrafterFailure(reason)
    ktoxLastCrafterFailureValue = reason
    return true
end

function ktoxGetLastCrafterFailure()
    return ktoxLastCrafterFailureValue
end

function ktoxClearLastCrafterFailure()
    ktoxLastCrafterFailureValue = ""
    return true
end

-- The part of an item id after its "namespace:" prefix (e.g.
-- "create:brass_ingot" -> "brass_ingot"), or the whole name unchanged if
-- it has no colon. Used only for sort ordering (ktoxListCatalog) so
-- items group alphabetically by their real name rather than by mod
-- namespace - the namespace itself is still shown in the actual name.
local function ktoxStrippedItemName(name)
    local stripped = string.match(name, ":(.+)$")
    if stripped ~= nil then
        return stripped
    end
    return name
end

-- Builds the full item catalog for the `list` CLI command: every item
-- either currently stocked in the pool, or mentioned anywhere in
-- config/resource-tree.json, classified as "stocked" (count > 0 in the
-- pool), "craftable" (its own recipe chain can reach a fully-stocked
-- state within MAX_LIST_CRAFT_DEPTH hops - see canProduce below), or
-- "unavailable" (neither). Optionally filtered to one status ("" = all)
-- and/or a substring of the item name ("" = no filter). Returns
-- newline-joined "status,name,count" rows (count is 0 for
-- craftable/unavailable), sorted alphabetically by each item's name with
-- its mod namespace prefix ignored (ktoxStrippedItemName) - ties (same
-- stripped name in two namespaces) fall back to the full name so the
-- order is still deterministic. Kotlin side: lib/Cli.kt.
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

    local tree = ktoxReadLuaDataFile("config/resource-tree.lua")
    local recipeFor = {}
    if tree ~= nil and tree.recipes ~= nil then
        for _, recipe in pairs(tree.recipes) do
            noteItem(recipe.output)
            if recipe.inputs ~= nil then
                for _, input in pairs(recipe.inputs) do
                    noteItem(input.item)
                end
                recipeFor[recipe.output] = ktoxPreferRecipe(recipe, recipeFor[recipe.output])
            end
        end
    end

    -- Whether `jobType` actually has the peripheral it needs configured
    -- in peripherals.json - a "machine" job needs a feeder vault (a
    -- relay is optional, see lib/Executor.kt's runDirectJob - matches
    -- what execution actually requires, not a stricter check), a
    -- "crafter" job needs a crafty turtle. Without this, an item whose
    -- inputs happen to be stocked showed as "craftable" even when
    -- nothing would actually run it (e.g. a lava_spout recipe with
    -- buckets in stock, but no Spout ever wired up in peripherals.json)
    -- - reported directly from in-game use as a real, confusing mismatch
    -- between what `list`/the dashboard claimed and what `craft` could
    -- actually do.
    local function jobIsConfigured(jobType)
        if ktoxConfigJobKind(jobType) == "crafter" then
            return ktoxConfigCrafterForJob(jobType) ~= "MISSING"
        end
        return ktoxConfigFeederForJob(jobType) ~= "MISSING"
    end

    -- How many recipe hops "craftable" is willing to chase before giving
    -- up - matches lib/Planner.kt's MAX_PLANNER_DEPTH so this classifier
    -- never disagrees with what `craft` can actually produce. Previously
    -- this only checked ONE hop (a documented gap in PLAN.md): an item
    -- needing a 2+-level chain (raw copper -> ingot -> sheet) showed as
    -- "unavailable" here even though `craft` could make it.
    local MAX_LIST_CRAFT_DEPTH = 5

    -- Whether `name` is reachable - already stocked, or producible via
    -- its own recipe chain within the remaining depth budget. `memo`
    -- caches a result per item name for the lifetime of one
    -- ktoxListCatalog call (recipes share ingredients constantly, e.g.
    -- copper_ingot feeds dozens of outputs) and doubles as cycle
    -- protection: an item is marked "not yet known" (false) BEFORE
    -- recursing into its own inputs, so a cyclic pair (a
    -- compacting/decompacting recipe, see PLAN.md's brass incident)
    -- resolves to false instead of looping - MAX_LIST_CRAFT_DEPTH is a
    -- second, independent backstop for the same case.
    local function canProduce(name, depth, memo)
        local have = totals[name]
        if have ~= nil and have > 0 then
            return true
        end
        if memo[name] ~= nil then
            return memo[name]
        end
        if depth > MAX_LIST_CRAFT_DEPTH then
            return false
        end
        local recipe = recipeFor[name]
        if recipe == nil or not jobIsConfigured(recipe.job) then
            memo[name] = false
            return false
        end
        memo[name] = false
        local allReachable = true
        for _, input in pairs(recipe.inputs) do
            if not canProduce(input.item, depth + 1, memo) then
                allReachable = false
                break
            end
        end
        memo[name] = allReachable
        return allReachable
    end

    -- Alphabetical by mod-stripped name (see ktoxStrippedItemName above),
    -- ties broken by the full name so two items with the same stripped
    -- name in different namespaces still sort deterministically. table.sort
    -- is not stable, hence the explicit tiebreak rather than relying on
    -- `order`'s original insertion order to survive equal keys.
    table.sort(order, function(a, b)
        local strippedA = ktoxStrippedItemName(a)
        local strippedB = ktoxStrippedItemName(b)
        if strippedA == strippedB then
            return a < b
        end
        return strippedA < strippedB
    end)

    local craftableMemo = {}
    local lines = {}
    for i = 1, #order do
        local name = order[i]
        if substring == "" or string.find(name, substring, 1, true) ~= nil then
            local count = totals[name]
            local status
            if count > 0 then
                status = "stocked"
            elseif recipeFor[name] ~= nil and jobIsConfigured(recipeFor[name].job) and canProduce(name, 1, craftableMemo) then
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
    local config = ktoxReadLuaDataFile("config/job-types.lua")
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
